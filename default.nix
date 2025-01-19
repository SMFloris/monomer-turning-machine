{ pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = [ pkgs.glfw pkgs.raylib ];
}
