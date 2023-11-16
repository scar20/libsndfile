#!/bin/bash

# Setting up environment
# Set NDK Home
export ANDROID_NDK_HOME=/opt/android-ndk-r25c
# Set NDK and HOST_TAG variables
export NDK=$ANDROID_NDK_HOME
export HOST_TAG=linux-x86_64
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$HOST_TAG

# Navigate to lame  source directory
cd ~/Repository/lame

# Lists of ABIs and configurations
# abi_list=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
# config_list=("Debug" "Release")
abi_list=("x86_64")
config_list=("Release")


# Set build directory
BUILD_DIR=""


# Additional variables
SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot

# Set API to minSdkVersion
export API=21

# Type sizes for x86 and arm32
TYPE_DEFINES_32="-DSIZEOF_SHORT=2 \
	-DSIZEOF_UNSIGNED_SHORT=2 \
	-DSIZEOF_INT=4 \
	-DSIZEOF_UNSIGNED_INT=4 \
	-DSIZEOF_LONG=4 \
	-DSIZEOF_UNSIGNED_LONG=4 \
	-DSIZEOF_LONG_LONG=8 \
	-DSIZEOF_UNSIGNED_LONG_LONG=8 \
	-DSIZEOF_FLOAT=4 \
	-DSIZEOF_DOUBLE=8"
# Type sizes for x86_64 and arm64
TYPE_DEFINES_64="-DSIZEOF_SHORT=2 \
	-DSIZEOF_UNSIGNED_SHORT=2 \
	-DSIZEOF_INT=4 \
	-DSIZEOF_UNSIGNED_INT=4 \
	-DSIZEOF_LONG=8 \
	-DSIZEOF_UNSIGNED_LONG=8 \
	-DSIZEOF_LONG_LONG=8 \
	-DSIZEOF_UNSIGNED_LONG_LONG=8 \
	-DSIZEOF_FLOAT=4 \
	-DSIZEOF_DOUBLE=8"

# Create a build directory for each ABI and configuration
for abi in "${abi_list[@]}"; do

    # Set TARGET and TYPE_DEFINES according to ABI
    if [ "$abi" = "armeabi-v7a" ]; then
        TARGET=armv7a-linux-androideabi
        TYPE_DEFINES=$TYPE_DEFINES_32
    elif [ "$abi" = "arm64-v8a" ]; then
        TARGET=aarch64-linux-android
        TYPE_DEFINES=$TYPE_DEFINES_64
    elif [ "$abi" = "x86" ]; then
        TARGET=i686-linux-android
        TYPE_DEFINES=$TYPE_DEFINES_32
    elif [ "$abi" = "x86_64" ]; then
        TARGET=x86_64-linux-android
        TYPE_DEFINES=$TYPE_DEFINES_64
    fi

    # Configure options
    CONFIG_OPTIONS="--host=$TARGET \
    --disable-shared \
    --enable-nasm \
    --disable-gtktest \
    --disable-efence \
    --disable-analyzer-hooks \
    --disable-frontend \
    --with-pic \
    --with-sysroot=$SYSROOT"

    for config in "${config_list[@]}"; do
        
        # Conditionally set build directory name
        if [ "$config" = "Debug" ]; then
            BUILD_DIR=$(pwd)/build_${abi}_d
            CURRENT_CONFIG_OPTIONS="$CONFIG_OPTIONS --prefix=$BUILD_DIR --enable-debug=norm"        
        else
            BUILD_DIR=$(pwd)/build_${abi}
            CURRENT_CONFIG_OPTIONS="$CONFIG_OPTIONS --prefix=$BUILD_DIR"
        fi

        # Configure and build
        export AR=$TOOLCHAIN/bin/llvm-ar
        export CC="$TOOLCHAIN/bin/$TARGET$API-clang"
        export AS=$CC
        export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
        export LD=$TOOLCHAIN/bin/ld
        export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
        export STRIP=$TOOLCHAIN/bin/llvm-strip

        # Create build directory
        mkdir -p $BUILD_DIR

        make distclean

        # Run the configure script and make, and save output to a log file
        CONFIG_DEFS=$TYPE_DEFINES ./configure $CURRENT_CONFIG_OPTIONS 2>&1 | tee -a "$BUILD_DIR/configure_and_make.log"
        make 2>&1 | tee -a "$BUILD_DIR/configure_and_make.log"
        make install 2>&1 | tee -a "$BUILD_DIR/configure_and_make.log"

#        make distclean
                
    done
done



