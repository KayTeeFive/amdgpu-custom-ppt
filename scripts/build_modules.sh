#!/bin/bash

#apt source linux

cd /usr/src/linux-6.17.13

patch -p0 < ~/amdgpu_custom_ppt_v6.12.57_pid_vid.patch

make -j10 M=drivers/gpu/drm modules

#make M=drivers/gpu/drm/amd modules_install

strip --strip-unneeded drivers/gpu/drm/amd/amdgpu/amdgpu.ko

cp drivers/gpu/drm/amd/amdgpu/amdgpu.ko .

xz --threads=1 --check=crc32 --lzma2=dict=512KiB amdgpu.ko

cp amdgpu.ko.xz /lib/modules/6.17.13-custom/kernel/drivers/gpu/drm/amd/amdgpu/

depmod -a

update-initramfs -k 6.17.13-custom -u

#reboot

