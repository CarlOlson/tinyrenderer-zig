{
  pkgs ? import <nixpkgs> {},
}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [ zig_0_15 zls_0_15 imagemagick ];
}
