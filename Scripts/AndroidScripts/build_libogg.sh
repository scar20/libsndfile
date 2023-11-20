#!/bin/bash

# This script will build libogg for Android using the NDK
# It can be run alone or from the master 'build_extlibs.sh' script

# Ensure all library sources are within a top-level directory.
# Place and run this script from within that top-level directory.
# It will generate build directories for each ABI/configuration in libogg subdirectory.
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
ogg_root=$(echo ${ROOT_LOC}/libogg*)


# Navigate to OGG library source directory
cd "${ogg_root}" || exit

# Create a build directory for each ABI and configuration
for abi in "${abi_list[@]}"; do
    for config in "${config_list[@]}"; do
        
        # Conditionally set dir name and relevant C/C++ flags
        if [ "$config" = "Debug" ]; then
            build_dir=build_${abi}_d          
            c_flags="-O0 -g"
            cxx_flags="-O0 -g"
        else
            build_dir=build_${abi}
            c_flags="-O3"
            cxx_flags="-O3 -std=c++17 -Werror -Wno-deprecated-declarations -fexceptions -frtti"
        fi

        mkdir -p ${build_dir}
        cd ${build_dir}
        
        # CMake command with Android toolchain and relevant flags
        cmake .. -DCMAKE_TOOLCHAIN_FILE="${toolchain}" \
                 -DANDROID_ABI="${abi}" \
                 -DANDROID_PLATFORM="${api_min}" \
                 -DCMAKE_BUILD_TYPE="${config}" \
                 -DCMAKE_C_FLAGS="${c_flags}" \
                 -DCMAKE_CXX_FLAGS="${cxx_flags}" \
                 -DBUILD_SHARED_LIBS=OFF \
                 -DINSTALL_DOCS=OFF \
                 -DINSTALL_PKG_CONFIG_MODULE=ON \
                 -DINSTALL_CMAKE_PACKAGE_MODULE=ON \
                 -DCMAKE_INSTALL_PREFIX=${ogg_root}/${build_dir}
        
        # Build library
        make
        
        # Install library and headers
        make install
        
        # Navigate back to the OGG library source directory
        cd ..
    done
done

# Copy the static library to the precompiled_libs directory if enabled
if [ "$GENERATE_PRECOMPILED_LIBS" = "ON" ]; then
    DEST=$ROOT_LOC/precompiled_libs/libogg
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
            cp $ogg_root/$BUILD_DIR/lib/libogg.a $DEST/$BUILD_DIR/lib/libogg.a
            cp -r $ogg_root/$BUILD_DIR/include $DEST/$BUILD_DIR/include
        done
        cp $(pwd)/COPYING $DEST/COPYING
    done
fi

# Navigate back to the top level directory
cd ..



