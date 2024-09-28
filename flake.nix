{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in rec {
    #   cbscript = pkgs.callPackage ({
    #     stdenv,
    #     python3,
    #     python3Packages,
    #     fetchFromGitHub,
    #     writeText
    #   }: let
    #     python = python3.withPackages (pp: with pp; [ pyyaml ply ]);
    #   in stdenv.mkDerivation {
    #     pname = "cbscript";
    #     version = "1.20";
    #     src = fetchFromGitHub {
    #       owner = "SethBling";
    #       repo = "cbscript";
    #       rev = "157c9b66b2ffe3b5e4bfe3636f691edd74b85102";
    #       hash = "sha256-CQxouSa7+tkgu8/Cu/rr9E7JpAy8WCPwZaTpw89v0ks=";
    #     };

    #     doBuild = false;

    #     installPhase = ''
    #      mkdir -p $out/lib
    #      cp -r $src/* $out/lib

    #      mkdir -p $out/bin
    #      cat <<EOF >$out/bin/cbscript
    #      ${python}/bin/python3 $out/lib/compile.py
    #      EOF

    #      chmod 755 $out/bin/cbscript
    #     '';
    #   }) {};

    devShells.${system}.default = pkgs.mkShell {
      name = "linux-in-minecraft";

      packages = [
        pkgs.clang_18
        pkgs.llvmPackages_18.llvm
        (pkgs.python3.withPackages (pp: with pp; [
          ply
          pyyaml
        ]))
        pkgs.zig
      ];
    };
  };
}
