{ ... }:
{
  flake.nixosModules.ayse.loka =
  { ... }:
  {
    time.timeZone = "America/Recife";
    i18n.defaultLocale = "pt_BR.UTF-8";
  };
}
