{ self, inputs, ... }:
{
  flake.nixosModules.noctalia =
  { pkgs, lib, ... }:
  let
    misuNoctalia = self.packages.${pkgs.stdenv.hostPlatform.system}.misuNoctalia;
  in
  {
    environment.systemPackages = [ misuNoctalia ];
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
