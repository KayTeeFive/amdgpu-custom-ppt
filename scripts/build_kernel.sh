#!/bin/bash

#apt source linux

cd /usr/src/linux-6.17.13

patch -p0 < amdgpu_custom_ppt.patch

make -j$(nproc) bindeb-pkg LOCALVERSION=-custom

