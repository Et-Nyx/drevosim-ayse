# secrets/secrets.nix
# This file maps host and admin public SSH keys to their respective encrypted secrets.
# Edit this file to add your actual SSH/Age public keys before running agenix!

let
  # The laptop's host public SSH key (run: cat /etc/ssh/ssh_host_ed25519_key.pub)
  portaible = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPd5V8+PZMi129McqH/Xz251PeB64WO7F41awulgnlN1 root@portaible";

  # Your personal backup/admin key (e.g. from your laptop/age key)
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILf6zR2AU/KdQasAXBZoz7CIVr+gw/QktmTLGf9vOBCk Portaible";

  # Future host machines (e.g., ayse)
  # ayse = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...";
in
{
  "portaible-root-password.age".publicKeys = [ portaible admin ];
  "portaible-eter-password.age".publicKeys = [ portaible admin ];

  # Future ayse isolated secrets can be added here cleanly:
  # "ayse-root-password.age".publicKeys = [ ayse admin ];
}
