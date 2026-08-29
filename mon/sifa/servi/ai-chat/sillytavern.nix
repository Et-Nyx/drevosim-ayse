{ inputs, ... }:
let
  # CharacterLibrary's extension settings key in settings.json.
  charLibSettingsKey = "SillyTavernCharacterGallery";
in
{
  flake.nixosModules.sifa.servi.ai-chat.sillytavern =
  { config, pkgs, lib, ... }:
  let
    cfg = config.drevosim.servi.sillytavern;
    stPkg = config.services.sillytavern.package;

    # Curated third-party extensions, sourced from flake inputs so their
    # revisions + hashes live in flake.lock.
    characterLibrarySrc = pkgs.stdenvNoCC.mkDerivation {
      name = "SillyTavern-CharacterLibrary-patched";
      src = inputs.sillytavern-characterlibrary.outPath;
      phases = [ "unpackPhase" "patchPhase" "installPhase" ];
      patchPhase = ''
        # Always use cl-helper proxy when apiRequest is available.
        substituteInPlace modules/providers/chartavern/chartavern-api.js \
          --replace-fail 'if (apiRequest && (ctSessionActive || await ctHelperAvailable(apiRequest))) {' 'if (apiRequest) {'
      '';
      installPhase = ''
        cp -r . "$out"
      '';
    };

    topInfoBarSrc = inputs.sillytavern-topinfobar.outPath;
    quickPersonaSrc = inputs.sillytavern-quickpersona.outPath;
    promptInspectorSrc = inputs.sillytavern-promptinspector.outPath;
    typingIndicatorSrc = inputs.sillytavern-typingindicator.outPath;
    notebookSrc = inputs.sillytavern-notebook.outPath;
    objectiveSrc = inputs.sillytavern-objective.outPath;
    ultimateChatAssistantSrc = inputs.sillytavern-ultimate-chatassistant.outPath;

    defaultExtensions = [
      { name = "SillyTavern-CharacterLibrary"; src = characterLibrarySrc; }
      { name = "Extension-TopInfoBar"; src = topInfoBarSrc; }
      { name = "Extension-QuickPersona"; src = quickPersonaSrc; }
      { name = "Extension-PromptInspector"; src = promptInspectorSrc; }
      { name = "Extension-TypingIndicator"; src = typingIndicatorSrc; }
      { name = "Extension-Notebook"; src = notebookSrc; }
      { name = "Extension-Objective"; src = objectiveSrc; }
      { name = "Ultimate-ChatAssistant"; src = ultimateChatAssistantSrc; }
    ];

    isPluginEnabled = cfg.enableCharacterLibraryPlugins;
    pluginsBindPath = "%S/SillyTavern/plugins:${stPkg}/lib/node_modules/sillytavern/plugins";

    # Seed TTS settings to point at the local Kokoro service, and do minimal
    # first-boot setup. LLM connection settings are intentionally left for the
    # user to configure (they will be added via the UI or a later agenix-based
    # seeder once the Opencode Go relay secret is in place).
    seedSillyTavernState = pkgs.writeShellScript "sillytavern-seed-state" ''
      set -euo pipefail
      BASE_DIR="/var/lib/SillyTavern"
      CFG_FILE="$BASE_DIR/config.local.yaml"
      ST_DIR="$BASE_DIR/data/default-user"

      # --- 1. Bootstrappable config.local.yaml from the package default ---
      if [ ! -f "$CFG_FILE" ]; then
        echo "sillytavern-seed: bootstrapping $CFG_FILE from package default"
        cp "${stPkg}/lib/node_modules/sillytavern/default/config.yaml" "$CFG_FILE"
        chmod 600 "$CFG_FILE"
      fi

      # --- 2. Patch declarative config.yaml flags ---
      ${pkgs.yq-go}/bin/yq -i '.listen = true' "$CFG_FILE"
      ${pkgs.yq-go}/bin/yq -i '.listenAddress.ipv4 = "127.0.0.1"' "$CFG_FILE"
      ${pkgs.yq-go}/bin/yq -i '.whitelistMode = true' "$CFG_FILE"
      ${pkgs.yq-go}/bin/yq -i '.whitelist = ["127.0.0.1", "::1", "100.64.0.0/10"]' "$CFG_FILE"
      ${pkgs.yq-go}/bin/yq -i '.extensions.autoUpdate = false' "$CFG_FILE"
      ${pkgs.yq-go}/bin/yq -i '.extensions.enabled = true' "$CFG_FILE"
      ${pkgs.yq-go}/bin/yq -i '.enableServerPluginsAutoUpdate = false' "$CFG_FILE"
      ${lib.optionalString isPluginEnabled ''
        ${pkgs.yq-go}/bin/yq -i '.enableServerPlugins = true' "$CFG_FILE"
        ${pkgs.yq-go}/bin/yq -i '.enableCorsProxy = true' "$CFG_FILE"
      ''}
      chown sillytavern:sillytavern "$CFG_FILE"

      # --- 3. Seed default-user settings (TTS + LLM + firstRun) ---
      mkdir -p "$ST_DIR"
      chmod 700 "$ST_DIR"

      # Read relay access token if a key file is configured.
      RELAY_KEY=""
      ${lib.optionalString (cfg.llmRelayKeyFile != null) ''
        if [ -f "${cfg.llmRelayKeyFile}" ]; then
          RELAY_KEY=$(${pkgs.gnused}/bin/sed -n 's/^ACCESS_TOKEN=//p' "${cfg.llmRelayKeyFile}" | head -n1)
          if [ -z "$RELAY_KEY" ]; then
            RELAY_KEY=$(${pkgs.coreutils}/bin/cat "${cfg.llmRelayKeyFile}" | ${pkgs.coreutils}/bin/tr -d '\n')
          fi
        fi
      ''}

      # secrets.json: store the Custom provider API key (plaintext by ST design).
      SECRETS="$ST_DIR/secrets.json"
      if [ -n "$RELAY_KEY" ]; then
        if [ -f "$SECRETS" ]; then
          ${pkgs.jq}/bin/jq --arg token "$RELAY_KEY" \
            '.api_key_custom = [{id:"seed-go-relay", value:$token, label:"OpenCode Go Relay", active:true}]' \
            "$SECRETS" > "$SECRETS.tmp"
        else
          ${pkgs.jq}/bin/jq -n --arg token "$RELAY_KEY" \
            '{api_key_custom:[{id:"seed-go-relay", value:$token, label:"OpenCode Go Relay", active:true}]}' \
            > "$SECRETS.tmp"
        fi
        mv "$SECRETS.tmp" "$SECRETS"
        chmod 600 "$SECRETS"
      fi

      SETTINGS="$ST_DIR/settings.json"
      if [ -f "$SETTINGS" ]; then
        ${pkgs.jq}/bin/jq \
          --arg voice "${cfg.defaultVoice}" \
          --arg ttsUrl "${cfg.ttsApiUrl}" \
          --arg relayUrl "${cfg.llmRelayUrl}" \
          --arg relayModel "${cfg.llmDefaultModel}" \
          --argjson hasKey "$([ -n \"$RELAY_KEY\" ] && echo true || echo false)" \
          '.firstRun = false
           | .tts = (.tts // {})
           | .tts.enabled = true
           | .tts.ttsEnabled = true
           | .tts.provider = "OpenAI Compatible"
           | .tts.currentProvider = "OpenAI Compatible"
           | .tts."OpenAI Compatible" = (.tts."OpenAI Compatible" // {})
           | .tts."OpenAI Compatible".provider_endpoint = $ttsUrl
           | .tts."OpenAI Compatible".model = "kokoro"
           | .tts."OpenAI Compatible".available_voices = [
               "af_heart", "af_alloy", "af_aoede", "af_bella", "af_jadzia",
               "af_jessica", "af_kore", "af_nicole", "af_nova", "af_river",
               "af_sarah", "af_sky", "am_adam", "am_echo", "am_eric",
               "am_fenrir", "am_liam", "am_michael", "am_onyx", "am_puck",
               "bf_emma", "bf_isabella", "bm_daniel", "bm_george"
             ]
           | .tts."OpenAI Compatible".voiceMap = (.tts."OpenAI Compatible".voiceMap // {
               "[Default Voice]": $voice,
               "User": "[Default Voice]"
             })
           | .extension_settings = (.extension_settings // {})
           | .extension_settings.tts = .tts
           | .extension_settings."${charLibSettingsKey}" = (.extension_settings."${charLibSettingsKey}" // {})
           | if $hasKey then
               .main_api = (.main_api // "openai")
               | .oai_settings = (.oai_settings // {})
               | .oai_settings.chat_completion_source = "custom"
               | .oai_settings.custom_url = $relayUrl
               | .oai_settings.custom_model = (.oai_settings.custom_model // $relayModel)
             else . end' \
          "$SETTINGS" > "$SETTINGS.tmp"
      else
        ${pkgs.jq}/bin/jq -n \
          --arg voice "${cfg.defaultVoice}" \
          --arg ttsUrl "${cfg.ttsApiUrl}" \
          --arg relayUrl "${cfg.llmRelayUrl}" \
          --arg relayModel "${cfg.llmDefaultModel}" \
          --argjson hasKey "$([ -n \"$RELAY_KEY\" ] && echo true || echo false)" \
          '{
             firstRun: false,
             tts: {
               enabled: true,
               ttsEnabled: true,
               provider: "OpenAI Compatible",
               currentProvider: "OpenAI Compatible",
               "OpenAI Compatible": {
                 provider_endpoint: $ttsUrl,
                 model: "kokoro",
                 available_voices: [
                   "af_heart", "af_alloy", "af_aoede", "af_bella", "af_jadzia",
                   "af_jessica", "af_kore", "af_nicole", "af_nova", "af_river",
                   "af_sarah", "af_sky", "am_adam", "am_echo", "am_eric",
                   "am_fenrir", "am_liam", "am_michael", "am_onyx", "am_puck",
                   "bf_emma", "bf_isabella", "bm_daniel", "bm_george"
                 ],
                 voiceMap: {
                   "[Default Voice]": $voice,
                   "User": "[Default Voice]"
                 }
               }
             }
           }
           | .extension_settings = {
               tts: .tts,
               "'"${charLibSettingsKey}"'": {}
             }
           | if $hasKey then
               .main_api = "openai"
               | .oai_settings = {
                   chat_completion_source: "custom",
                   custom_url: $relayUrl,
                   custom_model: $relayModel
                 }
             else . end' \
          > "$SETTINGS.tmp"
      fi
      mv "$SETTINGS.tmp" "$SETTINGS"
      chmod 600 "$SETTINGS"

      chown -R sillytavern:sillytavern "$ST_DIR"
      echo "sillytavern-seed: wrote TTS settings (provider: OpenAI, url: ${cfg.ttsApiUrl}, voice: ${cfg.defaultVoice})"
      ${lib.optionalString (cfg.llmRelayKeyFile != null) ''
        if [ -n "$RELAY_KEY" ]; then
          echo "sillytavern-seed: wrote LLM relay settings (url: ${cfg.llmRelayUrl}, model: ${cfg.llmDefaultModel})"
        else
          echo "sillytavern-seed: warning: relay key file not found, skipping LLM settings"
        fi
      ''}
    '';
  in
  {
    options.drevosim.servi.sillytavern = {
      enable = lib.mkEnableOption "SillyTavern web UI" // {
        default = false;
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8000;
        description = "Port to bind SillyTavern to.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Address to bind SillyTavern to.";
      };

      openFirewall = lib.mkEnableOption "firewall access to SillyTavern" // {
        default = true;
      };

      ttsApiUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8880/v1";
        description = "OpenAI-compatible TTS API URL (points to Kokoro by default).";
      };

      defaultVoice = lib.mkOption {
        type = lib.types.str;
        default = "af_heart";
        description = "Default TTS voice seeded into SillyTavern.";
      };

      llmRelayUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://go-relay.eter-nyx-635.workers.dev/v1";
        description = "OpenAI-compatible chat relay URL. SillyTavern fetches the model list from /v1/models.";
      };

      llmRelayKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = config.age.secrets.ayse-go-relay.path or null;
        description = ''
          Path to a file containing the relay access token.
          If set, SillyTavern's Custom chat provider is seeded with this key
          and the relay URL. The file may contain either the raw token or
          an ACCESS_TOKEN=... line.
        '';
      };

      llmDefaultModel = lib.mkOption {
        type = lib.types.str;
        default = "minimax-m3";
        description = "Fallback model name seeded before SillyTavern connects to the relay.";
      };

      enableCharacterLibraryPlugins = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable the cl-helper server plugin from CharacterLibrary.
          This also enables FlareSolverr for Cloudflare bypass.
        '';
      };

      extensions = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Directory name under /var/lib/SillyTavern/extensions/.";
            };
            src = lib.mkOption {
              type = lib.types.path;
              description = "Store path containing the extension's manifest.json.";
            };
          };
        });
        default = defaultExtensions;
        description = "Third-party SillyTavern extensions to symlink into the global extensions directory.";
      };
    };

    config = lib.mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

      services.sillytavern = {
        enable = true;
        port = cfg.port;
        # Do NOT use the upstream module's listen/listenAddressIPv4/whitelist
        # options: it passes them as CLI args like --listen=1, which SillyTavern's
        # yargs parser misinterprets. We set them declaratively in
        # config.local.yaml via the seeder instead.
        configFile = "/var/lib/SillyTavern/config.local.yaml";
      };

      services.flaresolverr.enable = lib.mkIf isPluginEnabled true;

      systemd.services.sillytavern = {
        serviceConfig = {
          BindPaths = lib.mkIf isPluginEnabled [ pluginsBindPath ];
          ExecStartPre = [ "+${seedSillyTavernState}" ];
        };
        restartTriggers = [ seedSillyTavernState ] ++ map (ext: ext.src) cfg.extensions;
        after = [
          "kokoro-tts.service"
          "systemd-tmpfiles-setup.service"
          "systemd-tmpfiles-resetup.service"
        ];
        wants = [ "kokoro-tts.service" ];
      };

      systemd.tmpfiles.settings.sillytavern-extras =
        {
          "/var/lib/SillyTavern/extensions".d = {
            mode = "0700";
            user = "sillytavern";
            group = "sillytavern";
          };
        }
        // (builtins.listToAttrs (
          map (ext: {
            name = "/var/lib/SillyTavern/extensions/${ext.name}";
            value."L+" = {
              argument = "${ext.src}";
              mode = "0444";
              user = "sillytavern";
              group = "sillytavern";
            };
          }) cfg.extensions
        ))
        // (lib.optionalAttrs isPluginEnabled {
          "/var/lib/SillyTavern/plugins".d = {
            mode = "0755";
            user = "sillytavern";
            group = "sillytavern";
          };
          "/var/lib/SillyTavern/plugins/cl-helper"."L+" = {
            argument = "${characterLibrarySrc}/extras/cl-helper";
            mode = "0444";
            user = "sillytavern";
            group = "sillytavern";
          };
        });

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.preservation.enable or false) [
        {
          directory = "/var/lib/SillyTavern";
          user = "sillytavern";
          group = "sillytavern";
          mode = "0750";
        }
      ];
    };
  };
}
