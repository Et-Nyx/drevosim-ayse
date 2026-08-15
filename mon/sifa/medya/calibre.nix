{ ... }:
{
  flake.nixosModules.sifa.medya.calibre =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.medya.calibre;
  in
  {
    options.drevosim.medya.calibre = {
      enable = lib.mkEnableOption "Calibre e-book manager" // {
        default = true;
      };

      libraryDir = lib.mkOption {
        type = lib.types.str;
        default = "/storage/home/eter/Calibre Library";
        description = "Calibre library directory on the HDD, symlinked to ~/Calibre Library.";
      };
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [ pkgs.calibre ];

      systemd.tmpfiles.rules = [
        "d ${cfg.libraryDir} 0755 eter users - -"
        "L+ /home/eter/Calibre Library - - - - ${cfg.libraryDir}"
      ];
    };
  };
}
