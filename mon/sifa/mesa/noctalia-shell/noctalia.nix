{ self, inputs, ... }:
{
  flake.nixosModules.noctalia =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.mesa.noctalia-shell.noctalia;
      misuNoctalia = self.packages.${pkgs.stdenv.hostPlatform.system}.misuNoctalia;
    in
    {
      options.taluji.sifa.mesa.noctalia-shell.noctalia = {
        enable = lib.mkEnableOption "Noctalia shell config/package";
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ misuNoctalia ];
      };
    };
  perSystem = { pkgs, ... }:
  {
    packages.misuNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;
      outOfStoreConfig = "$HOME/.config/noctalia";
      settings = {
        bar.position = "bottom";
        colorSchemes.darkMode = true;
      };
    };
  };
}
