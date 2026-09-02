let
  ayse = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsp4531DnJUhaPOQ3OingU54i0JpUPXI5AI9FK2B/MH root@ayse";
in
{
  "ayse-root-pasalexi.age".publicKeys = [ ayse ];
  "ayse-eter-pasalexi.age".publicKeys = [ ayse ];
  "ayse-go-relay.age".publicKeys = [ ayse ];
  "ayse-tailscale-auth.age".publicKeys = [ ayse ];
  "ayse-sillytavern.age".publicKeys = [ ayse ];
}
