{ self, ... }:
{
  flake.nixosModules.portaible.estrutur =
  { config, ... }:
  {
    age.secrets.root-password = {
      file = self + "/siri/portaible-root-password.age";
    };

    users.users.root.hashedPasswordFile = config.age.secrets.root-password.path;

    networking.hostName = "portaible"; # Define your hostname.

    # Enable networking
    networking.networkmanager.enable = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = [
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      #  wget
    ];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.11"; # Did you read the comment?
  };
}
