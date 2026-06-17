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
        hash = lib.fakeSha256;
      };
      cargoHash = lib.fakeSha256;
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
