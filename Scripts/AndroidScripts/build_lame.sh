#!/bin/bash

# This script will build libmp3lame for Android using the NDK
# It can be run alone or from the master 'build_extlibs.sh' script

# Ensure all library sources are within a top-level directory.
# Place and run this script from within that top-level directory.
# It will generate build directories for each ABI/configuration in lame subdirectory.
# Build directory name: build_<abi> for release and build_<abi>_d for debug

# ------- User configuration ------- #

# set to your NDK root location : "path/to/android-ndk-your_version_number"
ANDROID_NDK_ROOT=""

# Minimum API level supported by the NDK - adjust according to your project min sdk
# ex: api_min="android-21"
api_min=""

# Lists of ABIs and configurations
# Adjust as needed from those values:
# ABI_LIST=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
# CONFIG_LIST=("Debug" "Release")
abi_list=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
config_list=("Debug" "Release")

# Set to "ON" to enable precompiled lib
# A precompiled_libs directory will be created in the top-level directory
generate_precompiled_lib="OFF"

# ------- End of user configuration ------- #


# Set from outside variables or default to user settings
ANDROID_NDK_HOME=${ANDROID_NDK_HOME:-$ANDROID_NDK_ROOT}
api_min=${API_MIN:-$api_min}

# Check if ANDROID_NDK_HOME and api_min are set
if [ -z "$ANDROID_NDK_HOME" ]; then
	echo "Error: ANDROID_NDK_ROOT must be set"
	exit 1
elif [ -z "$api_min" ]; then
	echo "Error: api_min must be set"
	exit 1
fi

# Set from outside variables or use provided default
android_toolchain="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"
toolchain=${ANDROID_TOOLCHAIN:-$android_toolchain}

# If ABI_LIST and CONFIG_LIST are set, copy into their conterpart variables
if [ -n "${ABI_LIST+1}" ]; then
    abi_list=("${ABI_LIST[@]}")
fi
if [ -n "${CONFIG_LIST+1}" ]; then
    config_list=("${CONFIG_LIST[@]}")
fi

# Override from master script or use default
GENERATE_PRECOMPILED_LIBS=${GENERATE_PRECOMPILED_LIBS:-$generate_precompiled_lib}

# We should be in the top-level dir where all the libraries are located
ROOT_LOC=$(pwd)

# Set lib root locations
lame_root=$(echo ${ROOT_LOC}/lame*)

# Navigate to lame library source directory
cd "${lame_root}" || exit

# We need to apply a patch to the lib for the android build
patch --forward -p0 < ../android-lame.patch || true


# Additional variables

# Set NDK and HOST_TAG variables
export NDK=$ANDROID_NDK_HOME
export HOST_TAG=linux-x86_64
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$HOST_TAG
SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot

# Set API to minSdkVersion from numerial value of api_min
export API=$(echo $api_min | grep -o '[0-9]*')

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

# Copy the static library to the precompiled_libs directory if enabled
if [ "$GENERATE_PRECOMPILED_LIBS" = "ON" ]; then
    DEST=$ROOT_LOC/precompiled_libs/lame
    mkdir -p $DEST
    for abi in "${abi_list[@]}"; do
        for config in "${config_list[@]}"; do
            # Conditionally set build directory name
            if [ "$config" = "Debug" ]; then
                BUILD_DIR="build_${abi}_d"
            else
                BUILD_DIR="build_${abi}"
            fi
            
            mkdir -p $DEST/$BUILD_DIR/lib          
            cp $lame_root/$BUILD_DIR/lib/libmp3lame.a $DEST/$BUILD_DIR/lib/libmp3lame.a
            cp -r $lame_root/$BUILD_DIR/include $DEST/$BUILD_DIR/include
        done
        cp $(pwd)/COPYING $DEST/COPYING
        cp $(pwd)/LICENSE $DEST/LICENSE
    done
fi

# Navigate back to the top level directory
cd ..

