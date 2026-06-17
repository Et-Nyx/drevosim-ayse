{ self, inputs, ... }:
{
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
        sha256 = "sha256-sIrzqbTmCbulZgtyY1jD+F/Y0GCp4fL53t1iv0aViiw=";
      };
      cargoHash = lib.fakeHash;
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
  };
}
