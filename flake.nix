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
      prologConfigs = pkgs: {
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
        (prev.lib.mapAttrs (name: config: genBits name config) (prologConfigs final));
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
        genScript =
          name: config: pkgs.writeShellScriptBin "test-${name}" ("set -o errexit\n" + config.checkPhase);
        genShell =
          name: config:
          pkgs.mkShell {
            buildInputs = config.buildInputs ++ [ (genScript name config) ];
          };
        shells = (pkgs.lib.mapAttrs genShell (prologConfigs pkgs));
        checks = (pkgs.lib.mapAttrs (name: _: pkgs.${name}) (prologConfigs pkgs));
      in
      rec {
        inherit checks;
        devShells = shells // {
          default = shells.bits-swipl;
        };
      }
    );
}
