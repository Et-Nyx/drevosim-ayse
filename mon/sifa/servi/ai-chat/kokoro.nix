{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;

  # Kokoro-FastAPI is not in nixpkgs, so we package it manually.
  # The upstream repo provides an OpenAI-compatible FastAPI server around
  # the Kokoro TTS model. We bundle the model weights and voice packs so
  # the service works offline and does not download anything at runtime.
  mkKokoroFastApi =
    { pkgs
    , cudaSupport ? false
    }:
    let
      pname = "kokoro-fastapi";
      version = "0.5.0";

      # Python interpreter with the required packages. When GPU support is
      # requested we override `torch` with CUDA enabled; the global
      # `nixpkgs.config.cudaCapabilities = [ "6.1" ]` (set in ayse/nukleus/nvidia.nix)
      # makes CUDA PyTorch target the Pascal MX150.
      python = pkgs.python3.override {
        packageOverrides = self: super: {
          torch = if cudaSupport then
            super.torch.override {
              cudaSupport = true;
              triton = self.triton-cuda;
            }
          else
            super.torch;
        };
        self = python;
      };

      # misaki (used by Kokoro for English G2P) tries to download this spaCy
      # model at runtime. Bundle it so the service works offline.
      en_core_web_sm = pkgs.stdenvNoCC.mkDerivation rec {
        pname = "en_core_web_sm";
        version = "3.8.0";
        src = pkgs.fetchurl {
          url = "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-${version}/en_core_web_sm-${version}.tar.gz";
          hash = "sha256-FKLzG8R2r4cBmBnqjJlI+r39RzpELt1rHLpivwwsD1U=";
        };
        installPhase = ''
          runHook preInstall
          mkdir -p "$out/lib/${python.libPrefix}/site-packages"
          cp -r en_core_web_sm "$out/lib/${python.libPrefix}/site-packages/"
          cp -r en_core_web_sm.egg-info "$out/lib/${python.libPrefix}/site-packages/"
          runHook postInstall
        '';
      };

      pythonEnv = python.withPackages (ps: with ps; [
        aiofiles
        av
        fastapi
        gputil
        inflect
        kokoro
        loguru
        misaki
        num2words
        phonemizer
        psutil
        pydantic
        pydantic-settings
        pydub
        python-dotenv
        regex
        scipy
        soundfile
        spacy
        spacy-curated-transformers
        transformers
        uvicorn
      ]);

      src = pkgs.fetchFromGitHub {
        owner = "remsky";
        repo = "Kokoro-FastAPI";
        rev = "refs/tags/v${version}";
        hash = "sha256-I2tf3sFt0GqphKNFJHXlQKDgeR34sCOSHMLMSNXNLqY=";
      };

      # Kokoro-82M v1.0 model weights. The source ships the config JSON under
      # api/src/builds/v1_0, so we only need the .pth from HuggingFace.
      modelWeights = pkgs.fetchurl {
        url = "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/kokoro-v1_0.pth";
        hash = "sha256-SW26EY0aWPXz2y78iNvcIW4Eg/yJ/m5H7h8sU/GK0eQ=";
      };

      sitePackages = "lib/${python.libPrefix}/site-packages";
    in
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;

      nativeBuildInputs = [ pkgs.makeWrapper ];

      dontUnpack = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        sp="$out/${sitePackages}"
        mkdir -p "$sp/api/src"

        # Install the Python application under the `api.src` namespace so the
        # upstream uvicorn command `api.src.main:app` keeps working.
        cp -r ${src}/api/src/* "$sp/api/src/"
        touch "$sp/api/__init__.py"

        # VERSION is read by api/src/core/config.py as parents[3]/VERSION.
        cp ${src}/VERSION "$sp/api/VERSION"

        # The source tree is shipped read-only; make our copy writable so we
        # can inject the model weights and voice packs below.
        chmod -R u+w "$sp/api/src"

        # Model weights and config.
        mkdir -p "$sp/api/src/models/v1_0"
        cp ${modelWeights} "$sp/api/src/models/v1_0/kokoro-v1_0.pth"
        cp ${src}/api/src/builds/v1_0/config.json "$sp/api/src/models/v1_0/config.json"

        # Voice packs bundled with the upstream source.
        mkdir -p "$sp/api/src/voices/v1_0"
        cp ${src}/api/src/voices/v1_0/*.pt "$sp/api/src/voices/v1_0/"

        # Dashboard UI and wrapper script
        cp ${./dashboard_main.py} "$sp/api/src/dashboard_main.py"
        cp ${./dashboard.html} "$sp/api/src/dashboard.html"

        # English G2P model required by misaki. Copy it (and its egg-info
        # metadata, so spacy.util.is_package finds it) into the same
        # site-packages so spacy can load it without downloading anything.
        cp -r ${en_core_web_sm}/${sitePackages}/en_core_web_sm "$sp/"
        cp -r ${en_core_web_sm}/${sitePackages}/en_core_web_sm.egg-info "$sp/"

        mkdir -p "$out/bin"
        makeWrapper ${pythonEnv.interpreter} "$out/bin/kokoro-tts-api" \
          --add-flags "-m uvicorn api.src.dashboard_main:app" \
          --prefix PYTHONPATH : "$sp" \
          --prefix PATH : "${lib.makeBinPath [ pkgs.ffmpeg ]}" \
          --set-default ENABLE_WEB_PLAYER "false" \
          --set-default MODEL_DIR "$sp/api/src/models" \
          --set-default DEFAULT_VOICES_DIR "$sp/api/src/voices/v1_0" \
          --set-default VOICES_DIR "$sp/api/src/voices/v1_0" \
          --set-default ESPEAK_DATA_PATH "${pkgs.espeak-ng}/share/espeak-ng-data"

        runHook postInstall
      '';

      passthru = {
        inherit python pythonEnv sitePackages;
      };

      meta = with lib; {
        description = "OpenAI-compatible FastAPI server for Kokoro TTS";
        homepage = "https://github.com/remsky/Kokoro-FastAPI";
        license = licenses.asl20;
        platforms = platforms.linux;
      };
    };
in
{
  flake.nixosModules.sifa.servi.ai-chat.kokoro =
  { config, pkgs, lib, ... }:
  let
    cfg = config.drevosim.servi.kokoro;
    pkg = mkKokoroFastApi { inherit pkgs; cudaSupport = cfg.gpu; };
  in
  {
    options.drevosim.servi.kokoro = {
      enable = lib.mkEnableOption "Kokoro TTS API server" // {
        default = false;
      };

      gpu = lib.mkEnableOption "CUDA GPU acceleration for Kokoro TTS" // {
        default = false;
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = "Address to bind the Kokoro TTS API to.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8880;
        description = "Port to bind the Kokoro TTS API to.";
      };

      openFirewall = lib.mkEnableOption "firewall access to the Kokoro TTS API" // {
        default = true;
      };

      stateDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/kokoro-tts";
        readOnly = true;
        description = "Runtime working directory for the service.";
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !cfg.gpu || (config.hardware.nvidia.modesetting.enable or false);
          message = "Kokoro TTS GPU support requires NVIDIA hardware configuration (see ayse/nukleus/nvidia.nix).";
        }
      ];

      # Dedicated static user/group. This avoids the DynamicUser + StateDirectory
      # conflict with preservation's bind-mount at /var/lib/kokoro-tts.
      users.users.kokoro-tts = {
        isSystemUser = true;
        group = "kokoro-tts";
        home = cfg.stateDir;
      };
      users.groups.kokoro-tts = { };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

      systemd.services.kokoro-tts = {
        description = "Kokoro TTS API server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          API_TITLE = "Kokoro TTS API";
          API_VERSION = "0.5.0";
          HOST = cfg.host;
          PORT = toString cfg.port;
          ENABLE_WEB_PLAYER = "false";
          USE_GPU = lib.boolToString cfg.gpu;
          DEVICE_TYPE = if cfg.gpu then "cuda" else "cpu";
          PYTHONUNBUFFERED = "1";
          VOICES_DIR = "${cfg.stateDir}/voices";
        };

        serviceConfig = {
          Type = "exec";
          # Pass host/port explicitly to uvicorn. The application reads HOST/PORT
          # for its own settings, but uvicorn itself only honours CLI flags here.
          ExecStart = "${pkg}/bin/kokoro-tts-api --host ${cfg.host} --port ${toString cfg.port}";
          Restart = "on-failure";
          RestartSec = "5";

          User = "kokoro-tts";
          Group = "kokoro-tts";
          SupplementaryGroups = lib.optional cfg.gpu "video";
          StateDirectory = "kokoro-tts";
          WorkingDirectory = cfg.stateDir;

          # Hardening
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = cfg.stateDir;
          PrivateTmp = true;
        };
      };

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.preservation.enable or false) [
        {
          directory = cfg.stateDir;
          user = "kokoro-tts";
          group = "kokoro-tts";
          mode = "0750";
        }
      ];
    };
  };

  perSystem =
  { pkgs, system, ... }:
  lib.mkIf (system == "x86_64-linux")
  {
    # CPU variant is exposed as a flake package for easy testing.
    # The CUDA variant is intentionally not exposed here: evaluating it
    # requires `config.allowUnfree = true`, which is set in the NixOS
    # configuration but not during `nix flake check`. GPU mode remains
    # available through `drevosim.servi.kokoro.gpu = true`.
    packages.kokoro-fastapi = mkKokoroFastApi { inherit pkgs; };
  };
}
