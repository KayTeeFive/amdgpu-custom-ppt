# Building a Debian Kernel with Patched AMDGPU Driver

Working directly via SYSFS with `/sys/class/drm/card0/device/pp_table` is unstable.

Using the Python utility [upp](https://github.com/sibradzic/upp) to modify PowerPlay tables can cause random GPU freezes and AMDGPU driver crashes:

```
$ upp -p /sys/class/drm/card1/device/pp_table set --write overdrive_table/cap/0=1
...
kernel: amdgpu 0000:03:00.0: amdgpu: SMU: I'm not done with your previous command: SMN_C2PMSG_66:0x00000006 SMN_C2PMSG_82:0x00000000
kernel: amdgpu 0000:03:00.0: amdgpu: Failed to enable requested dpm features!
kernel: amdgpu 0000:03:00.0: amdgpu: Failed to setup smc hw!
kernel: amdgpu 0000:03:00.0: amdgpu: smu reset failed, ret = -62
``` 

To solve this, there is a patch that loads custom PowerPlay Tables early during boot:
```
amdgpu 0000:03:00.0: amdgpu: smu driver if version = 0x0000000d, smu fw if version = 0x00000010, smu fw program = 0, version = 0x00492400 (73.36.0)
amdgpu 0000:03:00.0: amdgpu: SMU driver if version not matched
amdgpu 0000:03:00.0: amdgpu: [SMU v11] using custom pptable amdgpu/custom_ppt_1002_743f.bin (size=2690)
amdgpu 0000:03:00.0: amdgpu: SMU is initialized successfully!
```

⚠️ Important Notice ⚠️

Patch, `amdgpu_custom_ppt_v6.12.57.patch`,  affects only SMU v11 and SMU v13 implementations in the AMDGPU driver.

SMU v14 and newer are not modified

GPUs using SMU v14+ are completely unaffected by this patch

### Steps to Build a Custom Kernel
It is recommended to build a custom kernel to modify and test the `amdgpu` module safely:
1. Install Build Dependencies:
    ```
    apt build-dep linux
    ``` 
2. Download Debian Kernel Sources: 
    ```
    apt source linux
    ``` 
3. Enter Kernel Source Directory localed in `/usr/src/linux-6.x.x`: 
    ```
    cd /usr/src/linux-6.17.13
    ```   
   _(Replace 6.17.13 with your actual kernel version)_
4. Apply patch:
    ```
    patch -p0 < amdgpu_custom_ppt_v6.12.57.patch
    ```
   - to revert patch: `patch -p0 -R < amdgpu_custom_ppt_v6.12.57.patch`
5. Build the Kernel with Custom Suffix:
    ```
    make -j$(nproc) bindeb-pkg LOCALVERSION=-custom
    ```
6. Install the DEB Packages: 
    ```
    cd /usr/src
    dpkg -i linux-headers-6.17.13-custom_6.17.13-2_amd64.deb linux-image-6.17.13-custom_6.17.13-2_amd64.deb
    ```
7. Reboot
8. Verify Custom PowerPlay Table Loading:
    ```
    amdgpu 0000:03:00.0: firmware: failed to load amdgpu/custom_ppt_1002_743f.bin (-2)
    amdgpu 0000:03:00.0: firmware: failed to load amdgpu/custom_ppt_1002_743f.bin (-2)
    amdgpu 0000:03:00.0: firmware: failed to load amdgpu/custom_ppt_1002_743f.bin (-2)
    amdgpu 0000:03:00.0: Direct firmware load for amdgpu/custom_ppt_1002_743f.bin failed with error -2
    amdgpu 0000:03:00.0: amdgpu: no custom pptable from amdgpu/custom_ppt_1002_743f.bin (-2)
    ```
   If you see failed to load, it indicates that your custom PowerPlay Table is missing from firmware directory, and you are on the right path to debug it.

**Note:**

- The patch for kernel 6.12.57 (Debian Trixie) is compatible with kernel 6.17.13 (Debian Testing).
- Next steps:
  - place custom PowerPlay Table binary (custom_ppt_1002_743f.bin) to /lib/firmware/amdgpu/
  - update initramfs hooks to include custom PowerPlay Table into initramfs kernel image

# Rebuilding Patched AMDGPU Driver
You can rebuild only the amdgpu driver without recompiling the entire kernel.

⚠️ Note: The first time you build with changes, all GPU/DRM modules may be rebuilt. 

Subsequent builds that modify only amdgpu will rebuild just this module.

1. Enter Kernel Source Directory: 
    ```
    cd /usr/src/linux-6.17.13
    ```   
   _(Replace 6.17.13 with your actual kernel version)_
2. Re-apply Patches:
   - apply: `patch -p0 < amdgpu_custom_ppt_v6.12.57_pid_vid.patch`
   - revert: `patch -p0 -R < amdgpu_custom_ppt_v6.12.57_pid_vid.patch`
3. Build Only the Changed `amdgpu` Module:
    ```
    make -j10 M=drivers/gpu/drm modules
    ```
   `M=drivers/gpu/drm` tells the kernel build system to compile only modules in the `drivers/gpu/drm` directory.
4. Strip the `amdgpu` Module:
    ```
    strip --strip-unneeded drivers/gpu/drm/amd/amdgpu/amdgpu.ko
    ```
   Reduces module size and removes unneeded symbols.
5. Install the New `amdgpu` Module:
    ```
    cp drivers/gpu/drm/amd/amdgpu/amdgpu.ko .
    xz --threads=1 --check=crc32 --lzma2=dict=512KiB amdgpu.ko
    cp amdgpu.ko.xz /lib/modules/6.17.13-custom/kernel/drivers/gpu/drm/amd/amdgpu/
    depmod -a
    ```
   Adjust paths for your kernel version. Compressing with xz is optional but recommended for space efficiency in initramfs.
6. Update Initramfs:
    ```
    update-initramfs -k 6.17.13-custom -u
    ```
   Ensures your new amdgpu driver is included in the initramfs.
7. Reboot to your custom kernel with new `amdgpu` (it's easier to avoid amount module usage problem for amdgpu module reload)

**Tip**: After reboot, check dmesg | grep amdgpu to verify the custom driver is loaded correctly.

# Initramfs HOOK: Add Custom PowerPlay Table into Initramfs

Hook script works only with Custom PowerPlay Tables located in `/lib/firmware/amdgpu/`.

1. Place script [custom_firmware_ppt](../scripts/custom_firmware_ppt) into `/etc/initramfs-tools/hooks/`
2. Place **Custom PowerPlay Table** into `/lib/firmware/amdgpu/`
3. Update Initramfs:
    ```
    update-initramfs -k 6.17.13-custom -u
    ```
   Ensures your **Custom PowerPlay Table** is included in the initramfs.
4. Reboot to your custom kernel and check, that **Custom PowerPlay Table** is loaded and used by SMU:
    ```
    amdgpu 0000:03:00.0: amdgpu: smu driver if version = 0x0000000d, smu fw if version = 0x00000010, smu fw program = 0, version = 0x00492400 (73.36.0)
    amdgpu 0000:03:00.0: amdgpu: SMU driver if version not matched
    amdgpu 0000:03:00.0: amdgpu: [SMU v11] using custom pptable amdgpu/custom_ppt_1002_743f.bin (size=2690)
    amdgpu 0000:03:00.0: amdgpu: SMU is initialized successfully!
    ```
5. Check that **Custom PowerPlay Table** works:
    ```
    $ cat /sys/class/drm/card1/device/pp_od_clk_voltage                                                                                                                                                                                                                                               18:26:45 :)
    OD_SCLK:
    0: 500Mhz
    1: 500Mhz
    OD_MCLK:
    0: 97Mhz
    1: 1000MHz
    OD_VDDGFX_OFFSET:
    0mV
    OD_RANGE:
    SCLK:     500Mhz       2322Mhz
    MCLK:      97Mhz       1075Mhz
    ```