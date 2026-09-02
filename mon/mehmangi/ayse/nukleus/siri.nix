{ self, ... }:
{
  flake.nixosModules.ayse.nukleus.siri =
  { ... }:
  {
    age.identityPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key"
    ];

    age.secrets = {
      ayse-root-pasalexi = {
        file = self + /siri/ayse-root-pasalexi.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      ayse-eter-pasalexi = {
        file = self + /siri/ayse-eter-pasalexi.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      ayse-go-relay = {
        file = self + /siri/ayse-go-relay.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      ayse-tailscale-auth = {
        file = self + /siri/ayse-tailscale-auth.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      ayse-sillytavern = {
        file = self + /siri/ayse-sillytavern.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
  };
}
