{ ... }:

{
  flake.nixosModules.ayse.nukleus.nvidia =
  { config, pkgs, lib, ... }:
  {
    # CUDA support for the Pascal MX150 (compute capability 6.1).
    nixpkgs.config.cudaCapabilities = [ "6.1" ];

    # NVIDIA driver configuration
    # Hardware: Dell Inspiron 7580, Intel UHD 630 (iGPU) + NVIDIA GeForce MX150
    # (GP108M, Pascal). dGPU at PCI 01:00.0 is a 3D controller (class 0302) -
    # not wired to any display, so PRIME render-offload is the only way to use it.

    # NixOS gates hardware.nvidia.enabled on this list. Setting it to ["nvidia"]
    # is required even on Wayland-only systems (it's only used as a flag;
    # services.xserver is NOT enabled).
    services.xserver.videoDrivers = [ "nvidia" ];

    # Pascal does NOT support the open kernel modules. Must be false.
    hardware.nvidia = {
      open = false;

      # Pin to the legacy 580.x driver. The MX150 is Pascal and the 595+
      # production branch dropped Pascal support (NVRM: "supported through
      # the NVIDIA 580.xx Legacy drivers"). 580.x is the last branch with
      # support for Maxwell/Pascal/Volta.
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

      # Modesetting is required for Wayland
      modesetting.enable = true;

      # Keep power management off: it is known to cause suspend issues
      # on hybrid laptops, and on this machine the dGPU is already
      # mismanaged by firmware (kept in D3cold). Leave it off.
      powerManagement.enable = false;

      # Persistenced keeps VRAM warm so processes don't pay the cost on launch
      nvidiaPersistenced = true;

      # nvidia-settings GUI panel
      nvidiaSettings = true;

      # PRIME render-offload: lets the iGPU drive the display while the
      # dGPU does the heavy lifting on demand. This is the correct config
      # for an MX150 in an Optimus laptop.
      prime = {
        # Bus IDs of the two GPUs. Detected on this machine:
        #   iGPU:  PCI 00:02.0 (Intel UHD 630)
        #   dGPU:  PCI 01:00.0 (NVIDIA MX150)
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:0:1:0";

        # Enable offload. Apps launched with `prime-run` use the dGPU.
        offload.enable = true;

        # Create the `prime-run` wrapper script in /run/current-system/sw/bin.
        # Lets you run `prime-run glxgears`, `prime-run steam`, etc.
        offload.enableOffloadCmd = true;

        # Reverse PRIME: lets the dGPU render to the iGPU's display
        # (needed when the laptop panel is wired to the iGPU).
        reverseSync.enable = true;
      };
    };

    # Enable hardware-accelerated graphics system-wide
    hardware.graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        mesa
        libglvnd
        egl-wayland
      ];
    };

    environment.systemPackages = with pkgs; [
      mesa-demos
      vulkan-tools
    ];

    # Force the dGPU out of D3cold at boot. Without this, the nvidia module
    # probes the PCI device, finds it in D3, and fails with "No such device".
    # This is a well-known issue on hybrid laptops whose firmware parks the
    # dGPU in D3cold (Arch Wiki: NVIDIA "hybrid graphics ... Eco mode ...
    # may fully disable the NVIDIA discrete GPU, making it undetectable").
    boot.kernelParams = [
      "pcie_aspm=off"
      "nvidia-drm.modeset=1"
    ];

    services.udev.extraRules = ''
      # When the dGPU PCI device appears, force it to D0 and disable
      # runtime PM so it cannot be parked again.
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", \
        ATTR{power/control}="on", ATTR{d3cold_allowed}="0"
    '';

    # Global PRIME render-offload env vars. Makes the dGPU the primary
    # renderer for user-launched apps. Apps that want to opt out can
    # `unset __NV_PRIME_RENDER_OFFLOAD` at launch.
    environment.sessionVariables = {
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
    };

    # Make nvidia-persistenced wait for the nvidia kernel module and the
    # device nodes it creates. We depend on the nvidia module (which is in
    # boot.extraModulePackages and gets autoloaded on first use) and on the
    # udev service that creates /dev/nvidia*, rather than on dev-nvidia*.device
    # units which nvidia's udev rules don't tag.
    systemd.services.nvidia-persistenced = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "systemd-udevd.service"
        "systemd-modules-load.service"
      ];
      wants = [
        "systemd-udevd.service"
        "systemd-modules-load.service"
      ];
    };

    # iGPU-only fallback specialisation. Boot into this from the boot menu
    # if the NVIDIA dGPU fails to wake from D3 (or any other driver issue).
    # The system comes up clean on the Intel iGPU.
    specialisation.igpu.configuration = {
      system.nixos.tags = [ "igpu" ];
      boot.kernelParams = lib.mkForce [ "nvidia-drm.modeset=0" ];
      services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
      hardware.nvidia.modesetting.enable = lib.mkForce false;
      services.udev.extraRules = lib.mkForce "";
      # Unset the PRIME offload vars; preserve everything else.
      environment.sessionVariables = {
        __NV_PRIME_RENDER_OFFLOAD = lib.mkForce null;
        __NV_PRIME_RENDER_OFFLOAD_PROVIDER = lib.mkForce null;
        __GLX_VENDOR_LIBRARY_NAME = lib.mkForce null;
        __VK_LAYER_NV_optimus = lib.mkForce null;
      };
    };
  };
}
