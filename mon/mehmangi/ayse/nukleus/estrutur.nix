{ ... }:
{
  flake.nixosModules.ayse.nukleus.estrutur =
  { pkgs, ... }:
  {
    networking.hostName = "ayse";
    networking.networkmanager.enable = true;

    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    services.libinput.enable = true;

    nix.gc.automatic = true;
    nix.gc.options = "--delete-older-than 7d";
    nix.settings.auto-optimise-store = true;

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
    };
    networking.firewall.allowedTCPPorts = [ 22 ];

    systemd.tmpfiles.rules = [
      "L+ /etc/nixos - - - - /home/eter/nixos"
    ];

    programs.firefox.enable = true;

    environment.systemPackages = with pkgs; [
      neovim
      git
      wget
      chromium
      opencode
    ];

    system.stateVersion = "26.05";
  };
}
