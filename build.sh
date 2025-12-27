#!/usr/bin/env bash
#
# build.sh - Automatic kernel building script
#
# Copyright (C) 2025, EndCredits <me@leemina.moe>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

# Function to show an informational message
function msg() {
    echo -e "\e[1;32m$(date +"%Y-%m-%d %H:%M:%S") $@\e[0m"
}

# Setup toolchains, if unsure, leave it empty.
# TOOLCHAIN_CLANG_PATH=/srv/media/micron/toolchians/clang-google-a11/clang-r383902b1/bin/
# TOOLCHAIN_GCC_AARCH64=/srv/media/micron/toolchians/gcc-4.9-aarch64/bin/
# TOOLCHAIN_GCC_ARM32=/srv/media/micron/toolchians/gcc-4.9-arm32/bin/

# Get script location
CURRENT_LOCATION=$(pwd)

# Check if toolchains available
if [ -e $TOOLCHAIN_CLANG_PATH/clang ]; then
    msg "clang exists."
else
    if ! [ -e $CURRENT_LOCATION/clang-r383902b1/ ]; then
        msg "clang doesn't exists. cloning..."
        git clone https://github.com/credits-infra/clang-r383902b1
    else
        msg "clang cloned."
    fi
    msg "setting clang toolchain path to: $CURRENT_LOCATION/clang-r383902b1/bin"
    TOOLCHAIN_CLANG_PATH=$CURRENT_LOCATION/clang-r383902b1/bin
    msg "exporting path with clang"
    echo "[+] export PATH=$TOOLCHAIN_CLANG_PATH:$PATH"
    export PATH=$TOOLCHAIN_CLANG_PATH:$PATH
fi

if [ -e $TOOLCHAIN_GCC_AARCH64/aarch64-linux-android-gcc ]; then
    msg "gcc 4.9 aarch64 toolchain exists."
else
    if ! [ -e $CURRENT_LOCATION/gcc-4.9-aarch64/ ]; then
        msg "gcc 4.9 aarch64 toolchain doesn't exists. cloning..."
        git clone https://github.com/xiangfeidexiaohuo/GCC-4.9 -b gcc4.9 gcc-4.9-aarch64 --depth=1
    else
        msg "gcc 4.9 aarch64 cloned."
    fi
    msg "setting toolchain path to: $CURRENT_LOCATION/gcc-4.9-aarch64/bin"
    TOOLCHAIN_GCC_AARCH64=$CURRENT_LOCATION/gcc-4.9-aarch64/bin
fi

if [ -e $TOOLCHAIN_GCC_ARM32/arm-linux-androideabi-gcc ]; then
    msg "gcc 4.9 arm32 toolchain exists."
else
    if ! [ -e $CURRENT_LOCATION/gcc-4.9-arm32/ ]; then
        msg "gcc 4.9 arm32 toolchain doesn't exists. cloning..."
        git clone https://github.com/xiangfeidexiaohuo/GCC-4.9 -b arm32 gcc-4.9-arm32 --depth=1
    else
        msg "gcc 4.9 arm32 cloned."
    fi
    msg "setting toolchain path to: $CURRENT_LOCATION/gcc-4.9-arm32/bin"
    TOOLCHAIN_GCC_ARM32=$CURRENT_LOCATION/gcc-4.9-arm32/bin
fi

# Setup kernel su
if [ -e .gitmodules ]; then
    msg "Building with KernelSU"
    if ! [ -e ./KernelSU ]; then
        msg "KernelSU source doesn't exists, syncing submodule."
        git submodule init
        git submodule update --checkout
    else
        msg "KernelSU source exists, skipping syncing."
    fi
fi

# Start build kernel, setup kernel build params
KERNEL_BUILD_PARAMS="ARCH=arm64"
KERNEL_BUILD_PARAMS+=" CC=$TOOLCHAIN_CLANG_PATH/clang"
KERNEL_BUILD_PARAMS+=" CROSS_COMPILE=$TOOLCHAIN_GCC_AARCH64/aarch64-linux-android-"
KERNEL_BUILD_PARAMS+=" CROSS_COMPILE_COMPAT=$TOOLCHAIN_GCC_ARM32/arm-linux-androideabi-"
KERNEL_BUILD_PARAMS+=" CLANG_TRIPLE=aarch64-linux-gnu-"
KERNEL_BUILD_PARAMS+=" LD=ld.lld"
KERNEL_BUILD_PARAMS+=" -j$(nproc)"

# Setup output dir
OUTPUT_DIR="./out"
KERNEL_BUILD_PARAMS+=" O=$OUTPUT_DIR"

msg "Building kernel with params: $KERNEL_BUILD_PARAMS"

# Setup defconfig name
TARGET_DEFCONFIG_NAME="op9_defconfig"

# build kernel defconfig
msg "Building kernel defconfig"
echo "[+] make $KERNEL_BUILD_PARAMS $TARGET_DEFCONFIG_NAME"
make $KERNEL_BUILD_PARAMS $TARGET_DEFCONFIG_NAME

# building the kernel
msg "Building the kernel"
echo "[+] make $KERNEL_BUILD_PARAMS"
make $KERNEL_BUILD_PARAMS

if [ $? -eq 0 ]; then
    msg "Build finished successfully."
    msg "Target boot image: $OUTPUT_DIR/arch/arm64/boot/Image"
fi