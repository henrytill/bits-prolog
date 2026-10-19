{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The Prolog parser (universal-ctags/ctags#4249) is not yet in a release
    ctags-src = {
      url = "github:universal-ctags/ctags/82494361bb3e7d4f7cf1d2bdc0d0e9001c926e45";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      git-hooks,
      nix-github-actions,
      ctags-src,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;
        universal-ctags = pkgs.universal-ctags.overrideAttrs {
          version = "0-unstable-${builtins.substring 0 8 ctags-src.lastModifiedDate}";
          src = ctags-src;
        };
        configs = {
          bits-gprolog = {
            packages = [ pkgs.gprolog ];
            testScript = "gprolog --consult-file p99_test.pl --query-goal main --query-goal 'halt(1)'";
          };
          bits-swipl = {
            packages = [ pkgs.swi-prolog ];
            testScript = "swipl --on-error=halt -s p99_test.pl -g main";
          };
          bits-trealla = {
            packages = [ pkgs.trealla ];
            # tpl reports load errors only on stderr, and still exits 0
            testScript = ''
              { errors=$(tpl p99_test.pl -g main 2>&1 >&3 3>&-) || status=$?; } 3>&1
              if [ -n "$errors" ]; then
                printf '%s\n' "$errors" >&2
              fi
              if ${lib.getExe pkgs.gnugrep} -q '^Error:' <<<"$errors"; then
                exit 1
              fi
              exit "''${status:-0}"
            '';
          };
        };
        genTestScript =
          config:
          pkgs.writeShellApplication {
            name = "test-bits";
            runtimeInputs = config.packages;
            text = config.testScript;
          };
        tagsScript = pkgs.writeShellApplication {
          name = "generate-tags";
          runtimeInputs = [
            pkgs.git
            universal-ctags
          ];
          text = ''
            # lastpipe keeps a git failure under pipefail
            shopt -s lastpipe
            git ls-files -z -- '*.pl' | mapfile -d "" files
            if [ "''${#files[@]}" -gt 0 ]; then
              ctags "''${files[@]}"
              ctags -e "''${files[@]}"
            fi
          '';
        };
        testHook = config: {
          enable = true;
          name = "Run Prolog tests";
          entry = lib.getExe (genTestScript config);
          extraPackages = config.packages;
          files = "(\\.pl$|flake\\.(nix|lock))";
          pass_filenames = false;
        };
        tagsHook = {
          enable = true;
          name = "Generate Prolog tags files";
          entry = lib.getExe tagsScript;
          files = "(\\.pl$|flake\\.(nix|lock))";
          pass_filenames = false;
        };
        genShell =
          _: config:
          let
            preCommitCheck = git-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                prolog-tests = testHook config;
                prolog-tags = tagsHook;
                nixfmt.enable = true;
              };
            };
          in
          pkgs.mkShell {
            inherit (preCommitCheck) shellHook;
            packages = preCommitCheck.enabledPackages;
          };
        shells = lib.mapAttrs genShell configs;
        sourcesWithExt =
          ext:
          lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.fileFilter (file: file.hasExt ext) ./.;
          };
        genCheck =
          _: config:
          git-hooks.lib.${system}.run {
            src = sourcesWithExt "pl";
            hooks.prolog-tests = testHook config;
          };
        checks = lib.mapAttrs genCheck configs // {
          nixfmt = git-hooks.lib.${system}.run {
            src = sourcesWithExt "nix";
            hooks.nixfmt.enable = true;
          };
        };
      in
      {
        inherit checks;
        formatter = pkgs.nixfmt-tree;
        devShells = shells // {
          default = shells.bits-swipl;
        };
      }
    )
    // {
      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks = nixpkgs.lib.getAttrs [ "x86_64-linux" ] self.checks;
      };
    };
}
