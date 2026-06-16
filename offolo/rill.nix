{ linkFarm, fetchzip, ... }:
linkFarm "zig-packages" [
  {
    name = "wayland-0.5.0-lQa1knz8AQCh08NA8BeQrwJB9U3CfqcVAdHZYGRKIGuu";
    path = fetchzip {
      url = "https://codeberg.org/ifreund/zig-wayland/archive/v0.5.0.zip";
      sha256 = "sha256-mhqOtC26iACIvQUq74AbLSXSPsnWMi3AvDV7G2uElpo=";
    };
  }
]
