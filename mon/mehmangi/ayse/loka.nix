{ ... }:
{
  flake.nixosModules.ayse.loka =
  { ... }:
  {
    time.timeZone = "America/Recife";

    i18n.defaultLocale = "pt_BR.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "pt_BR.UTF-8";
      LC_IDENTIFICATION = "pt_BR.UTF-8";
      LC_MEASUREMENT = "pt_BR.UTF-8";
      LC_MONETARY = "pt_BR.UTF-8";
      LC_NAME = "pt_BR.UTF-8";
      LC_NUMERIC = "pt_BR.UTF-8";
      LC_PAPER = "pt_BR.UTF-8";
      LC_TELEPHONE = "pt_BR.UTF-8";
      LC_TIME = "pt_BR.UTF-8";
    };

    environment.sessionVariables = {
      XKB_DEFAULT_LAYOUT = "us,br";
      XKB_DEFAULT_VARIANT = "altgr-intl,abnt2";
      XKB_DEFAULT_OPTIONS = "lv3:rctrl_switch,grp:win_space_toggle";
    };

    services.xserver.xkb = {
      layout = "us,br";
      variant = "altgr-intl,abnt2";
      options = "lv3:switch,grp:win_space_toggle";
    };

    console.useXkbConfig = true;
  };
}
