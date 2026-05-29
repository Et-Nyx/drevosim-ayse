{ self, inputs, ... }:
{
  flake.nixosModules.foot =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.terminal.foot;
      misuFoot = self.packages.${pkgs.stdenv.hostPlatform.system}.misuFoot;
    in
    {
      options.taluji.sifa.terminal.foot = {
        enable = lib.mkEnableOption "Foot terminal emulator";
      };
      config = lib.mkIf cfg.enable {
        programs.foot = {
          enable = true;
          package = misuFoot;
        };
      };
    };
  perSystem = { pkgs, ... }:
  {
    packages.misuFoot = inputs.wrapper-modules.wrappers.foot.wrap {
      inherit pkgs;
      settings = {
        main.font = "monospace:size=12";
        cursor = {
          style = "block";
          blink = "no";
        };
        mouse.hide-when-typing = "yes";
        csd.preferred = "server";
        scrollback.lines = "1000";
      };
    };
  };
}
