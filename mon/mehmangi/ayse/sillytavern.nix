{ ... }:
{
  flake.nixosModules.ayse.sillytavern =
  { config, ... }:
  {
    drevosim.servi.sillytavern = {
      enable = true;
      # Bind to all interfaces so Tailscale devices can reach it.
      host = "0.0.0.0";
      port = 8000;
      # Default TTS voice (English). Change to pf_dora for Portuguese.
      defaultVoice = "af_heart";
      # Points to the local Kokoro TTS service.
      ttsApiUrl = "http://127.0.0.1:8880/v1";
      # OpenCode Go relay via Cloudflare Worker.
      llmRelayUrl = "https://go-relay.eter-nyx-635.workers.dev/v1";
      llmRelayKeyFile = config.age.secrets.ayse-go-relay.path;
      llmDefaultModel = "minimax-m3";
    };
  };
}
