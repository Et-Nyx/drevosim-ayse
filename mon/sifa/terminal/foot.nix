{ self, inputs, ... }:
{
  flake.nixosModules.foot =
  { pkgs, lib, ... }:
  let
    misuFoot = self.packages.${pkgs.stdenv.hostPlatform.system}.misuFoot;
  in
  {
    programs.foot = {
      enable = true;
      package = misuFoot;
    };
  };
  perSystem = { pkgs, ... }:
  {
    packages.misuFoot = inputs.wrapper-modules.wrappers.foot.wrap {
      inherit pkgs;
      settings = {
        main = {
          font = "monospace:size=12";
        };
        cursor = {
          style = "block";
          blink = "no";
        };
        mouse = {
          hide-when-typing = "yes";
        };
        csd = {
          preferred = "server";
        };
        scrollback = {
          lines = "1000";
        };
      };
    };
  };
}
