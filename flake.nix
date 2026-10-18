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
      self,
      nixpkgs,
      flake-utils,
      git-hooks,
      ...
    }:
    let
      configs = pkgs: {
        bits-gprolog = {
          buildInputs = [ pkgs.gprolog ];
          checkPhase = "${pkgs.lib.getExe' pkgs.gprolog "gprolog"} --consult-file p99_test.pl --query-goal main";
        };
        bits-swipl = {
          buildInputs = [ pkgs.swi-prolog ];
          checkPhase = "${pkgs.lib.getExe pkgs.swi-prolog} -s p99_test.pl -g main";
        };
        bits-trealla = {
          buildInputs = [ pkgs.trealla ];
          checkPhase = "${pkgs.lib.getExe pkgs.trealla} p99_test.pl -g main";
        };
      };
      overlay =
        final: prev:
        let
          src = self;
          genBits =
            name:
            { buildInputs, checkPhase }:
            final.stdenvNoCC.mkDerivation {
              inherit
                name
                src
                buildInputs
                checkPhase
                ;
              dontBuild = true;
              doCheck = true;
              installPhase = ''
                mkdir "$out"
              '';
            };
        in
        (prev.lib.mapAttrs genBits (configs final));
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
        genTestScript =
          config: pkgs.writeShellScriptBin "test-bits" ("set -o errexit\n" + config.checkPhase);
        generateEtagsScript = pkgs.writeShellScriptBin "generate-etags" ''
          set -o errexit
          ${lib.getExe pkgs.git} ls-files | ${lib.getExe pkgs.gnugrep} -E ".*\.(pl)$" | xargs ${lib.getExe' pkgs.emacs "etags"} -l prolog
        '';
        generateCtagsScript = pkgs.writeShellScriptBin "generate-ctags" ''
          set -o errexit
          ${lib.getExe pkgs.git} ls-files | ${lib.getExe pkgs.gnugrep} -E ".*\.(pl)$" | xargs ${lib.getExe' pkgs.emacs "ctags"} -l prolog
        '';
        genPreCommitCheck =
          config:
          git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
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
          };
        genShell =
          name: config:
          let
            preCommitCheck = genPreCommitCheck config;
          in
          pkgs.mkShell {
            inherit (preCommitCheck) shellHook;
            packages = config.buildInputs ++ preCommitCheck.enabledPackages;
          };
        lib = pkgs.lib;
        shells = lib.mapAttrs genShell (configs pkgs);
        checks = lib.mapAttrs (name: _: pkgs.${name}) (configs pkgs);
      in
      {
        inherit checks;
        devShells = shells // {
          default = shells.bits-swipl;
        };
      }
    );
}
