{ self, inputs, ... }:
{
  flake.nixosModules.fish =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.terminal.fish;
    in
    {
      options.taluji.sifa.terminal.fish = {
        enable = lib.mkEnableOption "Fish shell integration";
      };
      config = lib.mkIf cfg.enable {
        programs.fish.enable = true;
        users = {
          defaultUserShell = pkgs.fish;
          users.eter = {
            maid = {
              file.xdg_config."fish/config.fish" = {
                text = /* fish */ ''
                  if status is-interactive
                  end
                '';
              };
            };
          };
        };
      };
    };
}
