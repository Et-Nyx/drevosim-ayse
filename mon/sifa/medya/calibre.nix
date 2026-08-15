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
        default = "/storage/home/eter/Biblioteca do calibre";
        description = "Calibre library directory on the HDD, symlinked to ~/Biblioteca do calibre. Uses the localized folder name Calibre defaults to under pt_BR.";
      };
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [ pkgs.calibre ];

      systemd.tmpfiles.rules = [
        "R /home/eter/Calibre Library"
        "d ${cfg.libraryDir} 0755 eter users - -"
        "L+ /home/eter/Biblioteca do calibre - - - - ${cfg.libraryDir}"
      ];
    };
  };
}
