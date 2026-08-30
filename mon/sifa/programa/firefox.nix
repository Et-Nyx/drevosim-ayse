{ ... }:
{
  flake.nixosModules.sifa.programa.firefox =
  { config, lib, pkgs, ... }:
  let
    opsyon = config.drevosim.programa.firefox;
  in
  {
    options.drevosim.programa.firefox = {
      enable = lib.mkEnableOption "Mozilla Firefox browser" // {
        default = true;
      };
    };

    config = lib.mkIf opsyon.enable {
      systemd.tmpfiles.rules = [
        "d /home/eter/.cache 0755 eter users - -"
        "d /home/eter/.cache/mozilla 0755 eter users - -"
      ];

      programs.firefox = {
        enable = true;
        package = pkgs.firefox;
        languagePacks = [ "pt-BR" ];

        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          #DisableFirefoxAccounts = true;
          FirefoxHome = {
            Pocket = false;
            SponsoredPocket = false;
            SponsoredTopSites = false;
            Highlights = false;
          };
          UserMessaging = {
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
          };
          SearchEngines = {
            Default = "DuckDuckGo";
            PreventInstalls = false;
          };
          #HttpsOnlyMode = "force_enabled";
          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              default_area = "navbar";
            };
            "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/return-youtube-dislikes/latest.xpi";
              default_area = "navbar";
            };
            "sponsorBlocker@ajay.app" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
              default_area = "navbar";
            };
          };
          Preferences = {
            "sidebar.verticalTabs" = true;
          };
        };
      };
    };
  };
}
