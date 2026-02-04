{ pkgs ? import <nixpkgs> {} }:

let devEnv = import ./dev-env.nix { pkgs = pkgs; };
in pkgs.mkShell {
  inherit (devEnv) buildInputs shellHook;
}