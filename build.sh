#!/usr/bin/env bash

 #
 # Script For Building Android arm64 Kernel
 #

 # Specify Kernel Directory
KERNEL_DIR="$(pwd)"

# Zip Name
ZIPNAME="Mimir-Kernel"

# Specify compiler ( eva , azure , proton , arter , aosp & nexus )
COMPILER=nexus+KSU

# Device Name and Model
DEVICE=lavender

# Kernel Defconfig
DEFCONFIG=lavender_defconfig

# Linker
LINKER=ld.lld

# Path
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb

# Verbose Build
VERBOSE=0

# Kernel Version
KERVER=$(make kernelversion)

COMMIT_HEAD=$(git log --oneline -1)

FINAL_ZIP=${ZIPNAME}-EAS-KSU-${DEVICE}.zip
##----------------------------------------------------------##

# Cloning Dependencies
function clone() {
    # Clone Toolchain
        if [ $COMPILER = "azure" ]; then
                post_msg " Cloning Azure Clang ToolChain "
		git clone --depth=1  https://gitlab.com/ImSpiDy/azure-clang.git clang
		PATH="${KERNEL_DIR}/clang/bin:$PATH"
		elif [ $COMPILER = "proton" ]; then
		post_msg " Cloning Proton Clang ToolChain "
		git clone --depth=1  https://github.com/kdrag0n/proton-clang.git clang
		PATH="${KERNEL_DIR}/clang/bin:$PATH"
		elif [ $COMPILER = "nexus" ]; then
		git clone --depth=1 -b nexus-14  https://gitlab.com/Project-Nexus/nexus-clang.git clang
		PATH="${KERNEL_DIR}/clang/bin:$PATH"
                elif [ $COMPILER = "nexus+KSU" ]; then
                git clone --depth=1 -b nexus-14  https://gitlab.com/Project-Nexus/nexus-clang.git clang
                rm -rf KernelSU && curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
                PATH="${KERNEL_DIR}/clang/bin:$PATH"
		elif [ $COMPILER = "aosp" ]; then
		post_msg " Cloning Aosp Clang 14.0.2 ToolChain "
		git clone --depth=1 https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r445002.git -b 12.0 aosp-clang
                git clone https://github.com/sohamxda7/llvm-stable -b gcc64 --depth=1 gcc
                git clone https://github.com/sohamxda7/llvm-stable -b gcc32  --depth=1 gcc32
                PATH="${KERNEL_DIR}/aosp-clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
		elif [ $COMPILER = "arter" ]; then
		post_msg " Cloning Arter GCC 9.3.0 ToolChain "
		git clone --depth=1 -b gcc64 https://github.com/ImSpiDy/gcc-9.3.0 gcc64
		git clone --depth=1 -b gcc32 https://github.com/ImSpiDy/gcc-9.3.0 gcc32
		PATH=$KERNEL_DIR/gcc64/bin/:$KERNEL_DIR/gcc32/bin/:/usr/bin:$PATH
		elif [ $COMPILER = "eva" ]; then
		post_msg " Cloning Eva GCC ToolChain "
		git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git gcc64
		git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git gcc32
		PATH=$KERNEL_DIR/gcc64/bin/:$KERNEL_DIR/gcc32/bin/:/usr/bin:$PATH
        fi
        # Clone AnyKernel3
		git clone --depth=1 https://github.com/Vhmit/AnyKernel3 AnyKernel3
}
##------------------------------------------------------##

function exports() {
    if [ -d ${KERNEL_DIR}/clang ]; then
    export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
    elif [ -d ${KERNEL_DIR}/aosp-clang ]; then
    export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/aosp-clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
    elif [ -d ${KERNEL_DIR}/gcc64 ]; then
    export KBUILD_COMPILER_STRING=$("$KERNEL_DIR/gcc64"/bin/aarch64-elf-gcc --version | head -n 1)
    fi
    export ARCH=arm64
    export SUBARCH=arm64
    export LOCALVERSION="-${VERSION}"
    export KBUILD_BUILD_HOST=Nobara
    export KBUILD_BUILD_USER="Vhmit"
    export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
    export CI_BRANCH=$DRONE_BRANCH
    export PROCS=$(nproc --all)

}

##----------------------------------------------------------##

function compile() {
	post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"
	                        make O=out ARCH=arm64 ${DEFCONFIG}
	                        if [ -d ${KERNEL_DIR}/clang ]; then
	                        make -kj$(nproc --all) O=out \
				ARCH=arm64 \
				CC=clang \
				CROSS_COMPILE=aarch64-linux-gnu- \
				CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
				LLVM=1 \
				LLVM_IAS=1 \
				LD=${LINKER} \
				AR=llvm-ar \
				NM=llvm-nm \
				OBJCOPY=llvm-objcopy \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip \
				READELF=llvm-readelf \
				OBJSIZE=llvm-size \
				V=$VERBOSE 2>&1 | tee error.log
                                elif [ -d ${KERNEL_DIR}/gcc64 ]; then
				make -kj$(nproc --all) O=out \
				ARCH=arm64 \
				CROSS_COMPILE_ARM32=arm-eabi- \
				CROSS_COMPILE=aarch64-elf- \
				LD=aarch64-elf-${LINKER} \
				AR=llvm-ar \
				NM=llvm-nm \
				OBJCOPY=llvm-objcopy \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip \
				OBJSIZE=llvm-size \
				V=$VERBOSE 2>&1 | tee error.log
				elif [ -d ${KERNEL_DIR}/aosp-clang ]; then
				make -kj$(nproc --all) O=out \
				ARCH=arm64 \
				CC=clang \
				CLANG_TRIPLE=aarch64-linux-gnu- \
				CROSS_COMPILE=aarch64-linux-android- \
				CROSS_COMPILE_ARM32=arm-linux-androideabi- \
				LD=${LINKER} \
				AR=llvm-ar \
				NM=llvm-nm \
				OBJCOPY=llvm-objcopy \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip \
				READELF=llvm-readelf \
				OBJSIZE=llvm-size \
				V=$VERBOSE 2>&1 | tee error.log
				fi

    if ! [ -a "$IMAGE" ]; then
        push "error.log" "Build Throws Errors"
        exit 1
    fi
    # Copy Files To AnyKernel3 Zip
    cp $IMAGE AnyKernel3
}
##----------------------------------------------------------##

function zipping() {
    cd AnyKernel3 || exit 1
    zip -r9 ${FINAL_ZIP} *
    MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
    push "$FINAL_ZIP"
    cd ..
}
##----------------------------------------------------------##

clone
exports
compile
zipping

##----------------*****-----------------------------##
