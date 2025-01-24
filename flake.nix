{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-linux" "aarch64-darwin" "x86_64-linux" "x86_64-darwin"];
      perSystem = {pkgs, ...}: {
        packages = let
          builder = inputFormat:
            pkgs.writeScriptBin "${inputFormat}2nix" ''
              #!${pkgs.nushell}/bin/nu --stdin
              use ${./.}/to-nix.nu *

              # Convert ${inputFormat} to nix
              def main [
                --raw (-r) # remove all unnecessary whitespace
                --indent (-i): number = 2 # specify indentation width
                --tabs (-t): number # specify indentation tab quantity
                --strip-outer-bracket # strip the brackets of the outermost list or attribute set, so the result can be pasted verbatim into an existing list / attrset
                ]: string -> string {
                  from ${inputFormat} | to nix --raw=$raw --indent=$indent --tabs=$tabs --strip-outer-bracket=$strip_outer_bracket
              }
            '';
        in rec {
          json2nix = builder "json";
          yaml2nix = builder "yaml";
          toml2nix = builder "toml";
          default = json2nix;
        };
      };
    };
}
