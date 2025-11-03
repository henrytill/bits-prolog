{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      configs = pkgs: {
        bits-gprolog = {
          buildInputs = [ pkgs.gprolog ];
          checkPhase = "${pkgs.gprolog}/bin/gprolog --consult-file p99_test.pl --query-goal main";
        };
        bits-swipl = {
          buildInputs = [ pkgs.swi-prolog ];
          checkPhase = "${pkgs.swi-prolog}/bin/swipl -s p99_test.pl -g main";
        };
        bits-trealla = {
          buildInputs = [ pkgs.trealla ];
          checkPhase = "${pkgs.trealla}/bin/tpl p99_test.pl -g main";
        };
      };
      overlay =
        final: prev:
        let
          src = builtins.path {
            path = ./.;
            name = "bits-src";
          };
          genBits =
            name:
            { buildInputs, checkPhase }:
            final.stdenvNoCC.mkDerivation {
              inherit name;
              inherit src;
              inherit buildInputs;
              inherit checkPhase;
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
        genScript =
          name: config: pkgs.writeShellScriptBin "test-bits" ("set -o errexit\n" + config.checkPhase);
        generateEtagsScript = pkgs.writeShellScriptBin "generate-etags" ''
          set -o errexit
          ${pkgs.git}/bin/git ls-files | ${pkgs.gnugrep}/bin/grep -E ".*\.(pl)$" | xargs ${pkgs.emacs}/bin/etags -l prolog
        '';
        generateCtagsScript = pkgs.writeShellScriptBin "generate-ctags" ''
          set -o errexit
          ${pkgs.git}/bin/git ls-files | ${pkgs.gnugrep}/bin/grep -E ".*\.(pl)$" | xargs ${pkgs.emacs}/bin/ctags -l prolog
        '';
       genShell =
          name: config:
          pkgs.mkShell {
            buildInputs = config.buildInputs ++ [
              pkgs.pre-commit
              (genScript name config)
              generateCtagsScript
              generateEtagsScript
            ];
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
