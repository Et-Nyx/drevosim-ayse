{ self, ... }:
{
  flake.nixosModules.ayse.nukleus.siri =
  { ... }:
  {
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
