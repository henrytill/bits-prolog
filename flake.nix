{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      git-hooks,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;
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
        genTagsScript =
          tool:
          pkgs.writeShellApplication {
            name = "generate-${tool}";
            runtimeInputs = [
              pkgs.git
              pkgs.findutils
              pkgs.emacs-nox
            ];
            text = "git ls-files -z -- '*.pl' | xargs -0 --no-run-if-empty ${tool} -l prolog";
          };
        genHooks = config: {
          prolog-tests = {
            enable = true;
            name = "Run Prolog tests";
            entry = lib.getExe (genTestScript config);
            files = "(\\.pl$|flake\\.lock)";
            pass_filenames = false;
          };
          prolog-ctags = {
            enable = true;
            name = "Generate Prolog ctags file";
            entry = lib.getExe (genTagsScript "ctags");
            files = "\\.pl$";
            pass_filenames = false;
          };
          prolog-etags = {
            enable = true;
            name = "Generate Prolog etags file";
            entry = lib.getExe (genTagsScript "etags");
            files = "\\.pl$";
            pass_filenames = false;
          };
        };
        genShell =
          name: config:
          let
            preCommitCheck = git-hooks.lib.${system}.run {
              src = ./.;
              hooks = genHooks config;
            };
          in
          pkgs.mkShell {
            inherit (preCommitCheck) shellHook;
            packages = config.packages ++ preCommitCheck.enabledPackages;
          };
        shells = lib.mapAttrs genShell configs;
        genCheck =
          name: config:
          git-hooks.lib.${system}.run {
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.fileFilter (file: file.hasExt "pl") ./.;
            };
            hooks = { inherit (genHooks config) prolog-tests; };
          };
        checks = lib.mapAttrs genCheck configs;
      in
      {
        inherit checks;
        devShells = shells // {
          default = shells.bits-swipl;
        };
      }
    );
}
