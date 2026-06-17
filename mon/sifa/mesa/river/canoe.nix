{ self, inputs, ... }:
{
  flake.nixosModules.canoe =
  {}:
  {

  };

  perSystem =
  { pkgs, self', lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.canoe = pkgs.rustPlatform.buildRustPackage rec {
      pname = "canoe";
      version = "0.5.1";
      src = pkgs.fetchFromGitHub {
        owner = "roblillack";
        repo = "canoe";
        rev = "refs/tags/v${version}";
        hash = "sha256-oHaoeLQhj0L+1URXIrgfuFkAScXVVWqDiGdxq14zUqI=";
      };
      cargoHash = "sha256-qMzqyZ6dSyIYhsXBjvtSiX4pptKP+6G3fze8NSPeza4=";
      nativeBuildInputs = with pkgs; [
        pkg-config
        clang
      ];
      buildInputs = with pkgs; [
        wayland
        libxkbcommon
        freetype
        fontconfig
      ];
      env = {
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        CC = lib.getExe pkgs.clang;
      };
      meta.mainProgram = "canoe";
    };
    packages.misuCanoe = inputs.wrapper-modules.lib.wrapPackage [
      ({ config, lib, wlib, ... }:
      {
        imports = [ wlib.modules.default ];
        options.configPath = lib.mkOption {
          type = lib.type.path;
          description = "Path to the canoe config.toml file";
        };
        config = {
          package = self'.packages.canoe;
          constructFiles.canoe-config = {
            relPath = "config/canoe/canoe.toml";
            content = builtins.readFile config.configPath;
          };
          env.XDG_CONFIG_HOME = "${placeholder "out"}/config";
        };
      })
      {
        inherit pkgs;
        configPath = ./faylu/canoe.toml;
      }
    ];
  };
}
