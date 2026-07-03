{ self, ... }:
{
  flake.nixosModules.ayse.nukleus.siri =
  { ... }:
  {
    age.identityPaths = [
      "/persistent/etc/ssh/ssh_host_ed25519_key"
      "/persistent/etc/ssh/ssh_host_rsa_key"
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
    };
  };
}
