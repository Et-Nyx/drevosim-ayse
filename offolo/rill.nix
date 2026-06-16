{ linkFarm, fetchzip, fetchgit, ... }:
linkFarm "zig-packages" [
  {
    name = "wayland-0.6.0-lQa1kqz8AQADQmdNJsNhLoNHcnEGEUjrOaPV-dtEnEmX";
    path = fetchzip {
      url = "https://codeberg.org/ifreund/zig-wayland/archive/v0.6.0.tar.gz";
      hash = "sha256-3m/ITNhZUJ/5uD/Tqm+0uZSktGoYgWF5oldOqOCUkIE=";
    };
  }
  {
    name = "xkbcommon-0.4.0-VDqIe0i2AgDRsok2GpMFYJ8SVhQS10_PI2M_CnHXsJJZ";
    path = fetchzip {
      url = "https://codeberg.org/ifreund/zig-xkbcommon/archive/v0.4.0.tar.gz";
      hash = "sha256-zQkmP/cuhAtjOLqYS5D15khKzpqyhbyZ0TD6/8jOkqE=";
    };
  }
]
