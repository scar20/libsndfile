#!/bin/bash




# This script will build mpg123 for Android using the NDK
# It can be run alone or from the master 'build_extlibs.sh' script

# Ensure all library sources are within a top-level directory.
# Place and run this script from within that top-level directory.
# It will generate build directories for each ABI/configuration in mpg123 subdirectory.
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


# We should be in the top-level dir where all the libraries are located
ROOT_LOC=$(pwd)

# Set lib root locations
mpg123_root=$(echo ${ROOT_LOC}/mpg123*)

# Navigate to mpg123 library source directory
cd "${mpg123_root}" || exit

# Enabing debug message
messages="OFF"


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
            messages=ON
        fi

        mkdir -p ${build_dir}
        cd ${build_dir}
        
        # CMake command with Android toolchain and relevant flags
        cmake ../ports/cmake \
        -DCMAKE_TOOLCHAIN_FILE="${toolchain}" \
                 -DANDROID_ABI="${abi}" \
                 -DANDROID_PLATFORM="${api_min}" \
                 -DCMAKE_BUILD_TYPE="${config}" \
                 -DCMAKE_C_FLAGS="${c_flags}" \
                 -DCMAKE_CXX_FLAGS="${cxx_flags}" \
                 -DBUILD_SHARED_LIBS=OFF \
                 -DBUILD_LIBOUT123=OFF\
                 -DNO_MESSAGES=${messages} \
                 -DCMAKE_INSTALL_PREFIX=${mpg123_root}/${build_dir}                         
     
        # Build library
        make
        
        # Install library and headers
        make install
        
        # Navigate back to the library source directory
       cd ..
    done
done

# Navigate back to the top level directory
cd ..