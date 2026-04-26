{ self, inputs, ... }:
{
  flake.nixosModules.kwm =
  { pkgs, lib, ... }:
  let
    misuKwm = self.packages.${pkgs.stdenv.hostPlatform.system}.kwm;
  in
  {
    environment.systemPackages = [ misuKwm ];
    services.displayManager.sessionPackages = [ misuKwm ];
    environment.sessionVariables.RIVER_WM = "${misuKwm}/bin/kwm";
    users.users.eter.maid = {
      file.xdg_config."kwm/config.zon" = {
        text = /* zig */ ''
        '';
      };
    };
  };
  perSystem =
  { pkgs, ... }:
  let
    kwm-deps = {
      xkbcommon = pkgs.fetchzip {
        url = "https://codeberg.org/ifreund/zig-xkbcommon/archive/v0.3.0.tar.gz";
        sha256 = "sha256-e5bPEfxl4SQf0cqccLt/py1KOW1+Q1+kWZUEXBbh9oQ=";
      };
      wayland = pkgs.fetchzip {
        url = "https://codeberg.org/ifreund/zig-wayland/archive/v0.5.0.tar.gz";
        sha256 = "sha256-mhqOtC26iACIvQUq74AbLSXSPsnWMi3AvDV7G2uElpo=";
      };
      mvzr = pkgs.fetchzip {
        url = "https://github.com/mnemnion/mvzr/archive/refs/tags/v0.3.8.tar.gz";
        sha256 = "sha256-weWDvirm7PndEoiDRK62NE4CJS6BiXca5/XVpppzWUA=";
      };
      fcft = pkgs.fetchzip {
        url = "https://git.sr.ht/~novakane/zig-fcft/archive/v2.0.0.tar.gz";
        sha256 = "sha256-qDEtiZNSkzN8jUSnZP/itqh8rMf+lakJy4xMB0I8sxQ=";
      };
      pixman = pkgs.fetchzip {
        url = "https://codeberg.org/ifreund/zig-pixman/archive/v0.3.0.tar.gz";
        sha256 = "sha256-8tA4auo5FEI4IPnomV6bkpQHUe302tQtorFQZ1l14NU=";
      };
      kwim = pkgs.fetchzip {
        url = "https://github.com/kewuaa/kwim/archive/refs/tags/v0.1.4.tar.gz";
        sha256 = "sha256-YTcIzE3rpBc3v70/Y5YKo+bc2DfOkF8LzawSst/QJjA=";
      };
      mvzr-kwim = pkgs.fetchzip {
        url = "https://github.com/mnemnion/mvzr/archive/refs/tags/v0.3.7.tar.gz";
        sha256 = "sha256-RsnjkmsAZAuwO75S9Zy2dW117E6APOgHRKC2ReMAkik=";
      };
      xkbcommon-kwim = pkgs.fetchzip {
        url = "https://codeberg.org/ifreund/zig-xkbcommon/archive/v0.4.0.tar.gz";
        sha256 = "sha256-zQkmP/cuhAtjOLqYS5D15khKzpqyhbyZ0TD6/8jOkqE=";
      };
      clap-kwim = pkgs.fetchzip {
        url = "https://github.com/Hejsil/zig-clap/archive/refs/tags/0.11.0.tar.gz";
        sha256 = "sha256-XytqwtoE0xaR43YustgK68sAQPVfC0Dt+uCs8UTfkbU=";
      };
    };
  in
  {
    packages.kwm = pkgs.stdenv.mkDerivation {
      pname = "kwm";
      version = "master";
      src = inputs.kwm-src;
      nativeBuildInputs = [
        pkgs.zig
        pkgs.pkg-config
        pkgs.pixman
        pkgs.fcft
      ];
      buildInputs = [
        pkgs.wayland
        pkgs.wayland-scanner
        pkgs.wayland-protocols
        pkgs.libxkbcommon
      ];
      dontConfigure = true;
      dontInstall = true;
      preBuild = /* sh */ ''
        export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache

        register_zig_dep() {
          local src="$1"
          local cache_name="$2"
          local target="$ZIG_GLOBAL_CACHE_DIR/p/$cache_name"
          mkdir -p "$target"
          cp -r "$src"/* "$target/"
          chmod -R +w "$target"
          touch "$target/.zig-checksum"
        }

        register_zig_dep "${kwm-deps.xkbcommon}" "xkbcommon-0.3.0-VDqIe3K9AQB2fG5ZeRcMC9i7kfrp5m2rWgLrmdNn9azr"
        register_zig_dep "${kwm-deps.wayland}" "wayland-0.5.0-lQa1knz8AQCh08NA8BeQrwJB9U3CfqcVAdHZYGRKIGuu"
        register_zig_dep "${kwm-deps.pixman}" "pixman-0.3.0-LClMnz2VAAAs7QSCGwLimV5VUYx0JFnX5xWU6HwtMuDX"
        register_zig_dep "${kwm-deps.mvzr}" "mvzr-0.3.7-ZSOky1dvAQDTEE_8S0pvpasmoEWQHVA29tMBdxL_hwra"
        register_zig_dep "${kwm-deps.fcft}" "fcft-2.0.0-zcx6C5EaAADIEaQzDg5D4UvFFMjSEwDE38vdE9xObeN9"
        register_zig_dep "${kwm-deps.kwim}" "kwim-0.1.4-Ewp5Gx_UAgD84P2X7z3_sv96iQjX21bxMenSp4wv8GRZ"
        register_zig_dep "${kwm-deps.mvzr-kwim}" "mvzr-0.3.7-ZSOky5FtAQB2VrFQPNbXHQCFJxWTMAYEK7ljYEaMR6jt"
        register_zig_dep "${kwm-deps.xkbcommon-kwim}" "xkbcommon-0.4.0-VDqIe0i2AgDRsok2GpMFYN8SVhQS10_PI2M_CnHXsJJZ"
        register_zig_dep "${kwm-deps.clap-kwim}" "clap-0.11.0-oBajB-HnAQDPCKYzwF7rO3qDFwRcD39Q0DALlTSz5H7e"
      '';
      buildPhase = /* sh */ ''
        runHook preBuild
        zig build -Doptimize=ReleaseSafe --prefix $out install
        runHook postBuild
      '';
      postBuild = /* sh */ ''
        mkdir -p $out/share/wayland-sessions
        cat > $out/share/wayland-sessions/river-kwm.desktop <<EOF
        [Desktop Entry]
        Name=River (kwm)
        Comment=River Wayland compositor with kwm
        Exec=${pkgs.river}/bin/river -c ${placeholder "out"}/bin/kwm
        Type=Application
        DesktopNames=river
        EOF
      '';
      passthru.providedSessions = [ "river-kwm" ];
    };
  };
}
