{ linkFarm, fetchzip }:
linkFarm "zig-packages" [
  {
    name = "wayland-0.5.0-lQa1knz8AQCh08NA8BeQrwJB9U3CfqcVAdHZYGRKIGuu";
    src = fetchzip {
      url = "https://codeberg.org/ifreund/zig-wayland/archive/v0.5.0.zip";
      sha256 = "sha256-0hcql2jzdr9wqvf2f6j4krvvlx8mnbsn0ys6wm264ngbzygnsvc1";
    };
  }
]
