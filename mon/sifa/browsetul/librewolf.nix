{ self, inputs, ... }:
{
  flake.nixosModules.librewolf =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.browsetul.librewolf;
    in
    {
      options.taluji.sifa.browsetul.librewolf = {
        enable = lib.mkEnableOption "Librewolf browser";
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs;[ librewolf ];
      };
    };
}
