# NVIDIA / PRIME — Operator's Manual

A practical guide to the NVIDIA Optimus (PRIME render-offload) setup
on `ayse`. Read this when the dGPU misbehaves, when you need to use
the iGPU-only fallback, or when you want to understand what every
option in `nvidia.nix` is doing.

The host (`ayse`) is a **Dell Inspiron 7580** with an Intel UHD 630
iGPU and an NVIDIA GeForce MX150 dGPU (Pascal, GP108M). The dGPU is
wired to a 3D controller class (no display), so PRIME render-offload
is the only way to use it.

---

## Table of contents

- [Hardware and topology](#hardware-and-topology)
- [What this module does](#what-this-module-does)
- [How PRIME render-offload works here](#how-prime-render-offload-works-here)
- [Boot-time GPU wake](#boot-time-gpu-wake)
- [The `igpu` fallback specialisation](#the-igpu-fallback-specialisation)
- [Verifying the setup](#verifying-the-setup)
- [Running apps on the dGPU](#running-apps-on-the-dgpu)
- [CUDA / PyTorch / Kokoro GPU mode](#cuda--pytorch--kokoro-gpu-mode)
- [Common problems](#common-problems)
- [Recovering from a broken driver](#recovering-from-a-broken-driver)
- [Updating the driver](#updating-the-driver)

---

## Hardware and topology

| Component | Hardware | Notes |
|-----------|----------|-------|
| iGPU | Intel UHD 630 | PCI 00:02.0, drives the laptop's built-in display |
| dGPU | NVIDIA GeForce MX150 (GP108M, Pascal) | PCI 01:00.0, class 0302 (3D controller) — not wired to a display |
| Compute capability | 6.1 | Pascal, requires legacy driver 580.x |
| Display output | iGPU only | The dGPU renders into the iGPU's framebuffer via reverse PRIME |

### Why the 580.x driver

Pascal (sm_60/sm_61) support was dropped from the 595+ production
branch. The 580.x legacy branch is the last one that supports
Maxwell/Pascal/Volta. The 580.x branch is also the last to ship
precompiled kernel modules for Pascal on common Linux kernels, so
we don't need `nv-kernel-open-style` from-source builds.

### Why `open = false`

The open kernel modules (`nvidia-open`) only support Turing (sm_75)
and newer. Pascal needs the proprietary modules. Setting
`hardware.nvidia.open = false` is mandatory.

---

## What this module does

The module `mon/mehmangi/ayse/nukleus/nvidia.nix` configures:

```nix
nixpkgs.config.cudaCapabilities = [ "6.1" ];

services.xserver.videoDrivers = [ "nvidia" ];

hardware.nvidia = {
  open = false;
  package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  modesetting.enable = true;
  powerManagement.enable = false;
  nvidiaPersistenced = true;
  nvidiaSettings = true;
  prime = {
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:0:1:0";
    offload.enable = true;
    offload.enableOffloadCmd = true;
    reverseSync.enable = true;
  };
};

hardware.graphics = {
  enable = true;
  enable32Bit = true;
  extraPackages = with pkgs; [ mesa libglvnd egl-wayland ];
};

environment.systemPackages = with pkgs; [ mesa-demos vulkan-tools ];

boot.kernelParams = [
  "pcie_aspm=off"
  "nvidia-drm.modeset=1"
];

services.udev.extraRules = ''
  ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", \
    ATTR{power/control}="on", ATTR{d3cold_allowed}="0"
'';

environment.sessionVariables = {
  XKB_DEFAULT_LAYOUT = "us,br"; # example, or whatever is there
};
# (Global PRIME env vars removed; default is iGPU)

systemd.services.nvidia-persistenced = {
  wantedBy = [ "multi-user.target" ];
  after = [ "systemd-udevd.service" "systemd-modules-load.service" ];
  wants = [ "systemd-udevd.service" "systemd-modules-load.service" ];
};
```

That's a lot — here's the section-by-section explanation.

---

## How PRIME render-offload works here

PRIME render-offload is the mechanism Optimus laptops use to make a
discrete GPU available on-demand while the iGPU drives the display.

```
┌────────────┐   reverse PRIME   ┌────────────┐
│  iGPU      │<─────────────────│  dGPU      │
│  (display) │                   │  (render)  │
│  Intel UHD │                   │  MX150     │
│  630       │                   │  (Pascal)  │
└────────────┘                   └────────────┘
       ▲
       │
  prime-run glxgears
  (explicit opt-in via prime-run)
```

- **Reverse PRIME** lets the dGPU render into the iGPU's
  framebuffer, which is what makes "use the dGPU" work on a laptop
  where only the iGPU has a display wired to it.
- **PRIME offload** lets a single process render with the dGPU and
  present via the iGPU. On this host, you opt in explicitly by launching
  applications with the `prime-run` wrapper (e.g. `prime-run steam`).
  By default, all desktop processes and everyday apps like Firefox
  run on the cooler, more responsive Intel iGPU.
- `nvidiaPersistenced = true` keeps VRAM warm so launches are fast.
- `nvidia-drm.modeset=1` is required for Wayland.

---

## Boot-time GPU wake

The MX150's firmware parks the dGPU in D3cold when the laptop is
cold-booted. Without intervention, the nvidia kernel module probes
the PCI device, finds it in D3, and fails with `No such device`.

The module fixes this with two complementary mechanisms:

### Kernel parameter: `pcie_aspm=off`

Disables PCI Express Active State Power Management at the kernel
level. Without it, even after we wake the device, the kernel's ASPM
policy can re-park it. This is heavy-handed but reliable for
hybrid laptops.

### udev rule

```udev
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", \
  ATTR{power/control}="on", ATTR{d3cold_allowed}="0"
```

When the dGPU PCI device appears, force it into D0 and prevent it
from being parked again by runtime PM.

### The arch wiki reference

This pattern is from the Arch Wiki "NVIDIA" page, section "hybrid
graphics". The wiki notes that "Eco mode" (Dell-specific power
management) may fully disable the dGPU, making it undetectable.
The udev rule above is the standard workaround.

---

## iGPU Fallback

Because we no longer force the dGPU globally, the desktop environment and all normal applications run natively on the Intel integrated GPU (iGPU). If the dGPU fails to wake or is not probed, the system boots and operates normally without issue, rendering the previous `igpu` specialisation redundant. It has been removed.

---

## Verifying the setup

### Check the kernel module is loaded

```bash
lsmod | grep nvidia
```

Expected: `nvidia`, `nvidia_drm`, `nvidia_modeset`, `nvidia_uvm` all
present.

### Check the dGPU is visible

```bash
lspci | grep -i nvidia
```

Expected: `01:00.0 ... NVIDIA Corporation GP108M [GeForce MX150]`.

### Check the device nodes

```bash
ls -la /dev/nvidia*
```

Expected: `nvidia0`, `nvidiactl`, `nvidia-uvm*` etc.

### Check nvidia-persistenced is running

```bash
systemctl status nvidia-persistenced
```

Should be `active (running)`.

### Run a quick GPU test

```bash
nvidia-smi
```

Should show the MX150, its driver version, and a "No running
processes found" line (no process is using the GPU yet).

### Test PRIME offload

```bash
# Default: runs on the iGPU
glxinfo | grep "OpenGL renderer"

# Run on the dGPU
prime-run glxinfo | grep "OpenGL renderer"
```

You should see different `OpenGL renderer` strings (e.g.
`Mesa Intel(R) UHD Graphics 630` vs `NVIDIA GeForce MX150/PCIe/SSE2`).

---

## Running apps on the dGPU

### Per-app: `prime-run`

```bash
prime-run glxgears
prime-run steam
prime-run blender
prime-run vkcube
```

The `prime-run` wrapper is at
`/run/current-system/sw/bin/prime-run` (because
`offload.enableOffloadCmd = true`).

### Default Rendering on iGPU

Since we do not set these variables globally, apps default to running on the cooler and more power-efficient Intel iGPU. This avoids copy-overhead stuttering and saves battery.

To run an app on the dGPU, prepend it with the `prime-run` command:
```bash
prime-run glxgears   # dGPU
glxgears             # iGPU (default)
```

---

## CUDA / PyTorch / Kokoro GPU mode

The module's `nixpkgs.config.cudaCapabilities = [ "6.1" ]` is what
makes CUDA packages in nixpkgs target the MX150's compute capability.

- PyTorch with CUDA support will be built (or downloaded) for sm_61.
- `nix-env -iA nixpkgs.torch` or `nix shell nixpkgs#python3Packages.torch`
  give you CUDA-enabled PyTorch out of the box.
- The Kokoro TTS service uses this when you set
  `drevosim.servi.kokoro.gpu = true`. See `gida/kokoro.md` for the
  full GPU-mode workflow.

### Verify CUDA is functional

```bash
nix shell nixpkgs#python3Packages.torch
python -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"
```

Expected: `True`, `NVIDIA GeForce MX150`.

---

## Common problems

### "No such device" when loading `nvidia`

The dGPU is in D3cold. Either:

- Boot into the `igpu` specialisation first, then reboot normally
  (sometimes the warm boot wakes it).
- Check the BIOS for a setting like "Hybrid mode" or "dGPU Eco
  mode" and disable it.

### Module loads but `nvidia-smi` fails

```bash
dmesg | grep -i nvrm
```

Look for `NVRM: GPU 0000:01:00.0: RmInitAdapter failed`. This often
indicates a kernel/driver version mismatch. Make sure
`hardware.nvidia.package` is pinned to `legacy_580` and the running
kernel is one that 580.x supports.

### `prime-run` doesn't exist

The wrapper is at
`/run/current-system/sw/bin/prime-run`. If it's not there:

```bash
sudo nixos-rebuild switch --flake .
```

And confirm `hardware.nvidia.prime.offload.enableOffloadCmd = true`
in the module.

### Performance is bad / dGPU not used

Check the env vars are set:

```bash
echo $__NV_PRIME_RENDER_OFFLOAD
```

Since the PRIME offload environment variables are not set globally, this check is only relevant for shells launched with `prime-run`.

### Vulkan doesn't work

```bash
vulkaninfo | head -30
```

Should list the Intel iGPU and the NVIDIA dGPU. If NVIDIA is
missing, the nvidia module isn't loaded properly.

### Wayland session is blank

`nvidia-drm.modeset=1` is in the kernel params. If you removed
it, Wayland compositors that need the nvidia explicit sync (e.g.
KDE Plasma 6) will fail to start.

### Battery drains fast

The dGPU is on. Check:

```bash
cat /proc/driver/nvidia/params | grep -i power
```

If `NVreg_OpenRmEnableUnsupportedGpus` or similar show the dGPU is
active, check which processes are running on the dGPU using `nvidia-smi`.

---

## Recovering from a broken driver

If a kernel or driver update breaks things and you can't boot:

1. Hold `Space` during boot to enter the systemd-boot menu.
2. Pick the previous generation (the boot menu shows them all).
3. If even the previous generation is broken, you can boot into a NixOS live USB to fix the configuration.
4. Once in the iGPU-only system, revert the offending change:
   ```bash
   cd /persistent/nixos
   git log --oneline -10
   git revert HEAD   # or `git reset --hard HEAD~1`
   sudo nixos-rebuild switch --flake .
   ```
5. Reboot normally.

---

## Updating the driver

The driver is pinned to `legacy_580`. If you need to bump:

```nix
hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
```

becomes

```nix
hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
```

(when the 580 branch gets merged into a new "production" branch),
or you switch to the open modules if you upgrade the hardware:

```nix
hardware.nvidia.open = true;
hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
```

After any driver change, `sudo nixos-rebuild switch --flake .` and
reboot. The first boot may take longer if the kernel modules need
to be rebuilt.

---

## Quick reference

```bash
# Is the dGPU alive?
nvidia-smi
lspci | grep -i nvidia

# What's on the dGPU right now?
nvidia-smi pmon -c 1

# Test PRIME offload
prime-run glxinfo | grep "OpenGL renderer"
glxinfo | grep "OpenGL renderer"

# Force iGPU-only
# (Everyday apps run on iGPU by default; no special action is needed)

# Logs
journalctl -b | grep -i nvrm
dmesg | grep -i nvrm

# Module state
lsmod | grep nvidia
ls -la /dev/nvidia*
```

If something doesn't work, `dmesg | grep -i nvrm` is usually the
first place to look.
