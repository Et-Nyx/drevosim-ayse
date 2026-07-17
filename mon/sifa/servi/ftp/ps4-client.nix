{ ... }:
{
  flake.nixosModules.sifa.servi.ftp-ps4-client =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.servi.ftp-ps4-client;
    ps4Ip = "192.168.15.200";
    ps4Port = "2121";
  in
  {
    options.drevosim.servi.ftp-ps4-client = {
      enable = lib.mkEnableOption "traditional PS4 FTP client integration (FileZilla + lftp)";
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.filezilla
        pkgs.lftp
      ];

      # Add easy shell aliases for fast terminal operations (using lftp)
      environment.shellAliases = {
        # List files on PS4
        ps4-ls = "lftp -c 'open ftp://${ps4Ip}:${ps4Port}; ls'";
        
        # Upload a file/directory to PS4 /data
        ps4-push = "lftp -c 'open ftp://${ps4Ip}:${ps4Port}; put -O /data'";
        
        # Download a file from PS4
        ps4-pull = "lftp -c 'open ftp://${ps4Ip}:${ps4Port}; get'";
        
        # Interactive shell into PS4
        ps4-ftp = "lftp ftp://${ps4Ip}:${ps4Port}";
      };
    };
  };
}
