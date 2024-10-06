{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in rec {
    packages.${system} = {
      python = pkgs.python3.override {
        self = packages.${system}.python;
        packageOverrides = pyfinal: pyprev: {
          amulet_nbt = pyfinal.callPackage ({
            buildPythonPackage,
            fetchPypi,
            setuptools,
            wheel,
            cython,
            versioneer,
            numpy,
            mutf8
          }: buildPythonPackage rec {
            pname = "amulet-nbt";
            version = "2.1.3";
            src = fetchPypi {
              inherit pname version;
              hash = "sha256-qd5P4GgynHqSHwndTOw3wlwBrCq+tOEAAOguUm420Pw=";
            };

            postPatch = ''
              substituteInPlace pyproject.toml \
                --replace 'versioneer-518' 'versioneer'
            '';

            propagatedBuildInputs = [
              numpy
              mutf8
            ];

            pyproject = true;
            build-system = [
              setuptools
              wheel
              cython
              versioneer
            ];
          }) {};

          amulet_leveldb = pyfinal.callPackage ({
            buildPythonPackage,
            fetchPypi,
            setuptools,
            wheel,
            cython,
            versioneer,
            zlib
          }: buildPythonPackage rec {
            pname = "amulet_leveldb";
            version = "1.0.2";
            src = fetchPypi {
              inherit pname version;
              hash = "sha256-s6pRHvcb9rxrIeljlb3tDzkrHcCT71jVU1Bn2Aq0FUE=";
            };

            buildInputs = [
              zlib
            ];

            pyproject = true;
            build-system = [
              setuptools
              wheel
              cython
              versioneer
            ];
          }) {};

          pymctranslate = pyfinal.callPackage ({
            buildPythonPackage,
            fetchPypi,
            setuptools,
            wheel,
            versioneer,
            numpy,
            amulet_nbt
          }: buildPythonPackage rec {
            pname = "pymctranslate";
            version = "1.2.28";
            src = fetchPypi {
              inherit pname version;
              hash = "sha256-Lh5ctBp0V44BkDvmOpFmKpiSJex0kxwef2fzZNJKDjg=";
            };

            postPatch = ''
              substituteInPlace pyproject.toml \
                --replace 'versioneer-518' 'versioneer'
            '';

            propagatedBuildInputs = [
              numpy
              amulet_nbt
            ];

            pyproject = true;
            build-system = [
              setuptools
              wheel
              versioneer
            ];
          }) {};

          minecraft-resource-pack = pyfinal.callPackage ({
            buildPythonPackage,
            fetchPypi,
            setuptools,
            wheel,
            versioneer,
            pillow,
            numpy,
            platformdirs,
            amulet_nbt,
          }: buildPythonPackage rec {
            pname = "minecraft_resource_pack";
            version = "1.4.5";
            src = fetchPypi {
              inherit pname version;
              hash = "sha256-Puhy2CFS2cCqUgQrACtnerMP+493DySzuXtVcgCLxZc=";
            };

            postPatch = ''
              substituteInPlace setup.cfg \
                --replace 'platformdirs~=3.1' platformdirs
            '';

            propagatedBuildInputs = [
              pillow
              numpy
              platformdirs
              amulet_nbt
            ];

            pyproject = true;
            build-system = [
              setuptools
              wheel
              versioneer
            ];
          }) {};

          amulet_core = pyfinal.callPackage ({
            buildPythonPackage,
            fetchPypi,
            setuptools,
            wheel,
            cython,
            versioneer,
            numpy,
            lz4,
            platformdirs,
            amulet_nbt,
            amulet_leveldb,
            pymctranslate,
            portalocker
          }: buildPythonPackage rec {
            pname = "amulet_core";
            version = "1.9.25";
            src = fetchPypi {
              inherit pname version;
              hash = "sha256-udA4JJT7ldj0lJhM8UslZtSQHYVILl9HWNKFFGb4S2g=";
            };

            postPatch = ''
              substituteInPlace pyproject.toml \
                --replace 'versioneer-518' 'versioneer'

              substituteInPlace setup.cfg \
                --replace 'platformdirs~=3.1' platformdirs
            '';

            propagatedBuildInputs = [
              numpy
              lz4
              platformdirs
              amulet_nbt
              amulet_leveldb
              pymctranslate
              portalocker
            ];

            pyproject = true;
            build-system = [
              setuptools
              wheel
              cython
              versioneer
            ];
          }) {};

          amulet_map_editor = pyfinal.callPackage ({
            buildPythonPackage,
            fetchPypi,
            setuptools,
            wheel,
            cython,
            numpy,
            versioneer,
            wxpython,
            pillow,
            pyopengl,
            platformdirs,
            amulet_core,
            amulet_nbt,
            pymctranslate,
            minecraft-resource-pack,
            gtk3,
            wrapGAppsHook3
          }: buildPythonPackage rec {
            pname = "amulet_map_editor";
            version = "0.10.36";
            src = fetchPypi {
              inherit pname version;
              hash = "sha256-pb9gptS1tCrULM8dagiU7Zflga59F+eQeXk1iQ+YGnU=";
            };

            postPatch = ''
              substituteInPlace setup.cfg \
                --replace 'platformdirs~=3.1' platformdirs
            '';

            buildInputs = [
              wrapGAppsHook3
              gtk3
            ];

            propagatedBuildInputs = [
              wxpython
              pillow
              pyopengl
              platformdirs
              amulet_core
              amulet_nbt
              pymctranslate
              minecraft-resource-pack
            ];

            strictDeps = false;

            dontWrapGApps = true;
            preFixup = ''
              makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
            '';

            pyproject = true;
            build-system = [
              setuptools
              wheel
              cython
              numpy
              versioneer
            ];
          }) {};
        };
      };

      # cbscript = pkgs.callPackage ({
      #   stdenv,
      #   python3,
      #   python3Packages,
      #   fetchFromGitHub,
      #   writeText
      # }: let
      #   python = python3.withPackages (pp: with pp; [ pyyaml ply ]);
      # in stdenv.mkDerivation {
      #   pname = "cbscript";
      #   version = "1.20";
      #   src = fetchFromGitHub {
      #     owner = "SethBling";
      #     repo = "cbscript";
      #     rev = "157c9b66b2ffe3b5e4bfe3636f691edd74b85102";
      #     hash = "sha256-CQxouSa7+tkgu8/Cu/rr9E7JpAy8WCPwZaTpw89v0ks=";
      #   };

      #   doBuild = false;

      #   installPhase = ''
      #    mkdir -p $out/lib
      #    cp -r $src/* $out/lib

      #    mkdir -p $out/bin
      #    cat <<EOF >$out/bin/cbscript
      #    ${python}/bin/python3 $out/lib/compile.py
      #    EOF

      #    chmod 755 $out/bin/cbscript
      #   '';
      # }) {};
    };

    devShells.${system}.default = pkgs.mkShell {
      name = "linux-in-minecraft";

      packages = [
        pkgs.clang_18
        pkgs.llvmPackages_18.llvm
        (packages.${system}.python.withPackages (pp: with pp; [
          ply
          pyyaml
          amulet_map_editor
        ]))
        pkgs.zig
      ];
    };
  };
}
