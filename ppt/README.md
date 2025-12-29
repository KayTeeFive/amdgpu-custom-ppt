# AMD Radeon RX6000

## Dell RX 6300 2 GB

### SPEC 
- https://www.techpowerup.com/gpu-specs/radeon-rx-6300.c4138

### BIOS
- https://www.techpowerup.com/vgabios/278099/dell-rx6300-2048-220919

### HW mod
1. Solder GDDR6 2GB chip: `Hynix H56G42AS8DX014`
2. Flash `Sapphire RX 6400 4 GB BIOS` to activate all 4GB GDDR6 VRAM:
    - https://www.techpowerup.com/vgabios/257504/257504
    - MD5 Hash:	`e6a68f5c13f76b362088ac5295f54027`
    - SHA1 Hash: `c4d4d69d04b57fe3234a03b9ab85db74b54a717d`

Pros:
- Navi 24 XL now works with 4GB GDDR6

Cons:
- Max GPU Frequency locked to 500MHz

**Note:**

**Fix GPU 500Mhz frequency lock -> Apply Custom PowerPlay Table** 

## Sapphire RX 6400 4 GB BIOS

### SPEC 
- https://www.techpowerup.com/gpu-specs/radeon-rx-6400.c3813

### BIOS
- https://www.techpowerup.com/vgabios/245758/245758
- https://www.techpowerup.com/vgabios/252671/252671
- https://www.techpowerup.com/vgabios/257504/257504

### PowerPlay Tables (tuned)
- custom_ppt_1002_743f.bin
- custom_ppt_1002_743f.dump
- custom_ppt_1002_743f.mpt

Note:
- Tested with BIOS ROM: https://www.techpowerup.com/vgabios/257504/257504
- MD5 Hash:	`e6a68f5c13f76b362088ac5295f54027`
- SHA1 Hash: `c4d4d69d04b57fe3234a03b9ab85db74b54a717d`


# Create Custom PowerPlay Table
There are two ways:
1. Using windows utility [MorePowerTools](https://www.igorslab.de/en/download-area-new-version-of-morepowertool-mpt-and-final-release-of-redbioseditor-rbe/)
2. Using [UPP](https://github.com/sibradzic/upp)

## MorePowerTools utility

By MorePowerTools:
1. Load you GPU bios
2. Edit `PPT Features` and `Overdrive Features` on your wish 
3. Save it as `custom_ppt_1002_743f.mpt`, where `1002` and `743f` is correct VID and PID for your GPU
4. On Linux by `upp` extract PPT from MPT-file:
   ```
   upp -m custom_ppt_1002_743f.mpt dump
   mv custom_ppt_1002_743f.mpt.pp_table custom_ppt_1002_743f.bin
   ```
5. Now you have Custom PowerPlay Table

## UPP utility

By UPP:
1. Change PPT `/sys/class/drm/card0/device/pp_table` by `upp`
   ```
   upp -p /sys/class/drm/card0/device/pp_table set --write overdrive_table/cap/0=1
   upp -p /sys/class/drm/card0/device/pp_table set --write overdrive_table/cap/1=1
   ...
   upp -p /sys/class/drm/card0/device/pp_table set --write overdrive_table/cap/6=1
   ...
   ```
   For more info, please, follow official guide - [UPP](https://github.com/sibradzic/upp).
2. If you are lucky (no GPU crashes appeared) you can dump Custom PowerPlay Table:
   ```
   cat /sys/class/drm/card0/device/pp_table > custom_ppt_1002_743f.bin
   ```
   , where `1002` and `743f` is correct VID and PID for your GPU
3. Now you have Custom PowerPlay Table

## Custom PowerPlay Table naming convention

Please, strictly follow naming convention:
```
custom_ppt_<VID>_<PID>.mct
custom_ppt_<VID>_<PID>.bin
```
Where:
- VID = vendor ID (hexadecimal)
- PID = device ID (hexadecimal)

Example #1: `custom_ppt_1002_743f.bin`

Example #2: `custom_ppt_1002_743f.mct`

Kernel patches are expecting exactly `custom_ppt_<VID>_<PID>.bin` naming convention

### VID/PID in Custom PowerPlay Tables

Each custom PowerPlay Table file uses a naming convention based on the GPU's Vendor ID (VID) and Device ID (PID):
```
custom_ppt_<VID>_<PID>.bin
```

#### Purpose
This ensures that PowerPlay Table collisions are avoided when multiple AMD GPUs are installed in the system.

Without correct VID/PID matching, the driver may load the wrong PPT for a GPU, leading to:
- Incorrect clock/voltage settings
- GPU instability or crashes
- Unexpected SMU behavior

#### Recommendation
Always verify the VID/PID for your GPU before creating or naming a custom PowerPlay Table. Use tools like:
```
lspci -nn | grep VGA
```

Example:
```
1002:743f → Vendor ID: 1002, Device ID: 743f
```
Then name the PPT accordingly:
```
custom_ppt_1002_743f.bin
```
