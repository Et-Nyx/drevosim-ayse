{ self, inputs, ... }:
{
  flake.nixosModules.zed =
  { pkgs, ... }:
  {
    programs.zed-editor-fhs = {
      enable = true;
    };
  };
}
