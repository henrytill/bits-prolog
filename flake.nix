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
    let
      configs = pkgs: {
        bits-gprolog = {
          packages = [ pkgs.gprolog ];
          checkPhase = "${pkgs.lib.getExe' pkgs.gprolog "gprolog"} --consult-file p99_test.pl --query-goal main --query-goal 'halt(1)'";
        };
        bits-swipl = {
          packages = [ pkgs.swi-prolog ];
          checkPhase = "${pkgs.lib.getExe pkgs.swi-prolog} --on-error=halt -s p99_test.pl -g main";
        };
        bits-trealla = {
          packages = [ pkgs.trealla ];
          # tpl reports load errors only on stderr, and still exits 0
          checkPhase = ''
            { errors=$(${pkgs.lib.getExe pkgs.trealla} p99_test.pl -g main 2>&1 >&3 3>&-) || status=$?; } 3>&1
            if [ -n "$errors" ]; then
              printf '%s\n' "$errors" >&2
              if ${pkgs.lib.getExe pkgs.gnugrep} -q '^Error:' <<<"$errors"; then
                exit 1
              fi
            fi
            exit "''${status:-0}"
          '';
        };
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;
        genTestScript =
          config:
          pkgs.writeShellApplication {
            name = "test-bits";
            runtimeInputs = config.packages;
            text = config.checkPhase;
          };
        generateEtagsScript = pkgs.writeShellScriptBin "generate-etags" ''
          set -o errexit
          ${lib.getExe pkgs.git} ls-files -z -- '*.pl' | ${lib.getExe' pkgs.findutils "xargs"} -0 --no-run-if-empty ${lib.getExe' pkgs.emacs-nox "etags"} -l prolog
        '';
        generateCtagsScript = pkgs.writeShellScriptBin "generate-ctags" ''
          set -o errexit
          ${lib.getExe pkgs.git} ls-files -z -- '*.pl' | ${lib.getExe' pkgs.findutils "xargs"} -0 --no-run-if-empty ${lib.getExe' pkgs.emacs-nox "ctags"} -l prolog
        '';
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
            entry = lib.getExe generateCtagsScript;
            files = "\\.pl$";
            pass_filenames = false;
          };
          prolog-etags = {
            enable = true;
            name = "Generate Prolog etags file";
            entry = lib.getExe generateEtagsScript;
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
        shells = lib.mapAttrs genShell (configs pkgs);
        genCheck =
          name: config:
          git-hooks.lib.${system}.run {
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.fileFilter (file: file.hasExt "pl") ./.;
            };
            hooks = { inherit (genHooks config) prolog-tests; };
          };
        checks = lib.mapAttrs genCheck (configs pkgs);
      in
      {
        inherit checks;
        devShells = shells // {
          default = shells.bits-swipl;
        };
      }
    );
}
