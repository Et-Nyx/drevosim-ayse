{ ... }:
{
  flake.nixosModules.sifa.medya.calibre =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.medya.calibre;
      # systemd path fields split on spaces; escape so paths like
      # "Biblioteca do calibre" stay one field.
      escapedLibraryDir = lib.replaceStrings [ " " ] [ "\\x20" ] cfg.libraryDir;
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
        "R /home/eter/Calibre\\x20Library"
        "d ${escapedLibraryDir} 0755 eter users - -"
        "L+ /home/eter/Biblioteca\\x20do\\x20calibre - - - - ${cfg.libraryDir}"
      ];
    };
  };
}
