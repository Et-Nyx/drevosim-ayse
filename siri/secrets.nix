let
  portaible = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPd5V8+PZMi129McqH/Xz251PeB64WO7F41awulgnlN1 root@portaible";
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILf6zR2AU/KdQasAXBZoz7CIVr+gw/QktmTLGf9vOBCk Portaible";
in
{
  "portaible-root-password.age".publicKeys = [ portaible admin ];
  "portaible-eter-password.age".publicKeys = [ portaible admin ];
}
