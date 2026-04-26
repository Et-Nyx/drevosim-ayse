{ self, inputs, ... }:
{
  flake.nixosModules.fuzzel =
  { pkgs, lib, ... }:
  let
    misuFuzzel = self.packages.${pkgs.stdenv.hostPlatform.system}.misuFuzzel;
  in
  {
    environment.systemPackages = [ misuFuzzel ];
    environment.sessionVariables.FUZZEL_LAUNCHER = "${misuFuzzel}/bin/fuzzel";
  };
  perSystem = { pkgs, ... }:
  {
    packages.misuFuzzel = inputs.wrapper-modules.wrappers.fuzzel.wrap {
      inherit pkgs;
      settings = {
        main = {
          font = "monospace:size=12";
          dpi-aware = "auto";
          icons-enabled = "yes";
          match-mode = "fzf";
        };
      };
    };
  };
}
