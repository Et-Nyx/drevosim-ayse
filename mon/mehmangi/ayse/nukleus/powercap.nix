{ ... }:
{
  flake.nixosModules.ayse.nukleus.powercap =
  { pkgs, ... }:
  {
    # Intel thermal daemon — monitors temps and enforces thermal limits
    # as a safety net alongside our RAPL caps.
    services.thermald.enable = true;

    # Ensure the powercap/RAPL sysfs interface is available at boot.
    boot.kernelModules = [ "intel_rapl_common" "intel_rapl_msr" ];

    # Cap CPU power at boot so peak draw never exceeds the 65 W adapter.
    #
    # Without the battery acting as a power buffer, turbo spikes (PL2 up
    # to 44 W) combined with the dGPU (25 W) and the rest of the system
    # (~14 W) exceed the 65 W adapter's capacity, triggering instant
    # shutdowns.
    #
    # PL1 (sustained) = 15 W  — base TDP, no change from factory
    # PL2 (burst/turbo) = 25 W — down from ~44 W factory default
    #
    # With PL2=25W + GPU=25W + rest≈14W = 64 W < 65 W adapter.
    systemd.services.intel-rapl-cap = {
      description = "Cap Intel CPU power limits (RAPL) for AC-only operation";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      wants = [ "systemd-modules-load.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "set-rapl-limits" ''
          set -euo pipefail
          RAPL=/sys/class/powercap/intel-rapl/intel-rapl:0

          if [ ! -d "$RAPL" ]; then
            echo "intel-rapl sysfs not found, skipping"
            exit 0
          fi

          # PL1 (constraint_0) — sustained power limit
          echo 15000000 > "$RAPL/constraint_0_power_limit_uw"

          # PL2 (constraint_1) — short-term burst limit
          echo 25000000 > "$RAPL/constraint_1_power_limit_uw"

          echo "RAPL caps applied: PL1=15W PL2=25W"
          cat "$RAPL/constraint_0_power_limit_uw" "$RAPL/constraint_1_power_limit_uw"
        '';
      };
    };
  };
}
