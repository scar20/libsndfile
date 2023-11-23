#!/bin/bash

# This script will build libsndfile for Android using the NDK

# Ensure all library sources are within a top-level directory.
# Place and run this script from within that top-level directory.
# It will generate build directories for each ABI/configuration in libsndfile subdirectory.
# An Android Studio 'AndroidStudio' directory structure will be produced in the top-level directory.
# It will contain the headers and libs for each ABI/configuration and the testsuite archives
# if testing is enabled.


# ------- User configuration ------- #

# set to your NDK root location : "path/to/android-ndk-<your_version_number>"
ANDROID_NDK_HOME=""

# Minimum API level supported by the NDK - adjust according to your project min sdk
# ex: API_MIN="android-21"
api_min=""

# Lists of ABIs and configurations
# Adjust as needed from those values:
# abi_list=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
# config_list=("Debug" "Release")
abi_list=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
config_list=("Debug" "Release")

# set to OFF to build a static library
shared_lib=ON

# set to ON to enable testsuite generation
# The archive will be generated in the build_{abi} directory
# or in the build_{abi}_testsuite directory if shared_lib=ON
build_android_testing=OFF

# set to ON to perform the tests inlined with the build
# If no device is connected or available, the tests will be skipped
test_inline=ON

# Device path where the testsuite archive will be stored
# This should not be changed, added here in case it needs to be changed in the future
device_path="/data/local/tmp"

# ------- End of user configuration ------- #

# Function to run the testsuite on a connected device
run_tests_on_device() {
    target_abi=$1

    # Fetch list of attached and authorized devices
    devices=$(adb devices | awk '/\tdevice$/ {print $1}')

    if [ -z "$devices" ]; then
        echo "No authorized devices found. Please check device connections and authorizations."
        return
    fi

    # Check and run tests on each connected device
    for device in $devices; do
        connected_abi=$(adb -s "$device" shell getprop ro.product.cpu.abi | tr -d '\r')

        if [ "$connected_abi" = "$target_abi" ]; then
            echo "Transferring the archive to device $device. This might take a while, please be patient..."
            adb push -p "${archive_name}.tar.gz" "${device_path}"
            echo "Running tests for ABI: $target_abi on device $device with archive $archive_name"
            adb shell << EOF
cd "${device_path}"
tar xvf ${archive_name}.tar.gz
cd ${archive_name}
sh ./test_wrapper.sh | tee ../tests_result
cd ..
rm -r ${archive_name}*
EOF
            adb pull "${device_path}/tests_result" .
            echo "Tests completed and results pulled for ABI: $target_abi"
        else
            echo "Connected device $device ABI ($connected_abi) does not match target ABI ($target_abi). Skipping tests on this device."
        fi
    done
} # Usage: run_tests_on_device "${abi}"

# Export NDK root location and add it to the PATH
export ANDROID_NDK_HOME="$ANDROID_NDK_HOME"
export PATH="$PATH:$ANDROID_NDK_HOME"

# Check if ANDROID_NDK_HOME and api_min are set
if [ -z "$ANDROID_NDK_HOME" ]; then
	echo "Error: ANDROID_NDK_ROOT must be set"
	exit 1
elif [ -z "$api_min" ]; then
	echo "Error: api_min must be set"
	exit 1
fi

# We should be in the top-level dir where all the libraries are located
ROOT_LOC=$(pwd)

# Set all external libs root locations
OGG_ROOT_PATH=$(echo ${ROOT_LOC}/libogg*)
FLAC_ROOT_PATH=$(echo ${ROOT_LOC}/flac*)
VORBIS_ROOT_PATH=$(echo ${ROOT_LOC}/libvorbis*)
OPUS_ROOT_PATH=$(echo ${ROOT_LOC}/opus*)
MPG123_ROOT_PATH=$(echo ${ROOT_LOC}/mpg123*)
MP3LAME_ROOT_PATH=$(echo ${ROOT_LOC}/lame*)

# Navigate to libsndfile library source directory
cd "${ROOT_LOC}/libsndfile"

# Swith to toggle between the two possible arm32 triplets
BINUTILS_TRIPLET=OFF
if [ "$BINUTILS_TRIPLET" == "ON" ]; then
    arm32_triplet="arm-linux-androideabi"
else
    arm32_triplet="armv7a-linux-androideabi"
fi

# Create a build directory for each ABI and configuration
for abi in "${abi_list[@]}"; do

    # Assign a corresponding triplet for each ABI
    if [ "$abi" == "armeabi-v7a" ]; then
        triplet=${arm32_triplet}
    elif [ "$abi" == "arm64-v8a" ]; then
        triplet="aarch64-linux-android"
    elif [ "$abi" == "x86" ]; then
        triplet="i686-linux-android"
    elif [ "$abi" == "x86_64" ]; then
        triplet="x86_64-linux-android"
    fi

    # Set archive name for testsuite
    archive_name="libsndfile-testsuite-${triplet}"

    for config in "${config_list[@]}"; do
        
        # Conditionally set dir name and relevant C/C++ flags
        if [ "$config" == "Debug" ]; then
            build_dir="build_${abi}_d"
            c_flags="-O0 -g"
            cxx_flags="-O0 -g"
            testing="OFF"
            android_lib_dir="Debug"
        else
            build_dir="build_${abi}"
            c_flags="-O3"
            cxx_flags="-O3 -std=c++17 -Werror -Wno-deprecated-declarations -fexceptions -frtti"
            # Conditionally set testing flag
            if [ "$shared_lib" == "ON" ]; then
                testing="OFF"
            else
                testing="${build_android_testing}"
            fi
            android_lib_dir="Release"
        fi

        mkdir -p "${build_dir}"
        cd "${build_dir}"
        
        # Set the search path for all external libs
        SEARCH_ROOT_PATH="${OGG_ROOT_PATH}/${build_dir};${FLAC_ROOT_PATH}/${build_dir};${VORBIS_ROOT_PATH}/${build_dir};${OPUS_ROOT_PATH}/${build_dir};${MPG123_ROOT_PATH}/${build_dir};${MP3LAME_ROOT_PATH}/${build_dir}"
        
        # CMake command with Android toolchain and relevant flags and search paths
        cmake .. \
            -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" \
            -DANDROID_ABI="${abi}" \
            -DANDROID_PLATFORM="${api_min}" \
            -DCMAKE_BUILD_TYPE="${config}" \
            -DCMAKE_C_FLAGS="${c_flags}" \
            -DCMAKE_CXX_FLAGS="${cxx_flags}" \
            -DBUILD_SHARED_LIBS="${shared_lib}"\
            -DINSTALL_DOCS=OFF \
            -DINSTALL_PKG_CONFIG_MODULE=ON \
            -DINSTALL_CMAKE_PACKAGE_MODULE=ON \
            -DBUILD_PROGRAMS=OFF \
            -DBUILD_EXAMPLES=OFF \
            -DBUILD_TESTING=OFF \
            -DBUILD_ANDROID_TESTING="${testing}" \
            -DTARGET_ARCHITECTURE="${triplet}" \
            -DARCHIVE_NAME="${archive_name}" \
            -DINSTALL_MANPAGES=OFF \
            -DCMAKE_INSTALL_PREFIX="${ROOT_LOC}/libsndfile/${build_dir}" \
            -DCMAKE_FIND_ROOT_PATH="${SEARCH_ROOT_PATH}" \
            -DCMAKE_PREFIX_PATH="${SEARCH_ROOT_PATH}"
                 
        # Build library
        make
        
        # Install library and headers
        make install
        
        # Copy include and lib/ content to android studio file structure
        mkdir -p "${ROOT_LOC}/AndroidStudio/libs/libsndfile/include"
	    cp -r "${ROOT_LOC}/libsndfile/${build_dir}/include/"* "${ROOT_LOC}/AndroidStudio/libs/libsndfile/include/"

	    mkdir -p "${ROOT_LOC}/AndroidStudio/libs/libsndfile/lib/${android_lib_dir}/${abi}"
	    cp -r "${ROOT_LOC}/libsndfile/${build_dir}/lib/libsndfile."* "${ROOT_LOC}/AndroidStudio/libs/libsndfile/lib/${android_lib_dir}/${abi}/"

        # Run or build the testsuite for Release configuration
        if [ "$build_android_testing" == "ON" ] && [ "$config" == "Release" ]; then
            # If this is a static build, run the testsuite
            if [ "$shared_lib" == "OFF" ]; then
                if [ "$test_inline" == "ON" ]; then
                    run_tests_on_device "${abi}"
                fi
                # Copy testsuite archive to android studio directory
                cp "${ROOT_LOC}/libsndfile/${build_dir}/${archive_name}.tar.gz" "${ROOT_LOC}/AndroidStudio/"
            
            else
                # This is a shared build, the testsuite cannot be build in shared mode
                # so we build the testsuite as a second run in static mode

                # Navigate back to the libsndfile library source directory
                cd ..

                # Create a build directory for the testsuite with current ABI 
                build_dir="build_${abi}_testsuite"
                mkdir -p "${build_dir}"
                cd "${build_dir}"
                
                # CMake command with Android toolchain and relevant flags and search paths
                cmake .. \
                    -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" \
                    -DANDROID_ABI="${abi}" \
                    -DANDROID_PLATFORM="${api_min}" \
                    -DCMAKE_BUILD_TYPE="${config}" \
                    -DCMAKE_C_FLAGS="${c_flags}" \
                    -DCMAKE_CXX_FLAGS="${cxx_flags}" \
                    -DBUILD_SHARED_LIBS="OFF"\
                    -DINSTALL_DOCS=OFF \
                    -DINSTALL_PKG_CONFIG_MODULE=ON \
                    -DINSTALL_CMAKE_PACKAGE_MODULE=ON \
                    -DBUILD_PROGRAMS=OFF \
                    -DBUILD_EXAMPLES=OFF \
                    -DBUILD_TESTING=OFF \
                    -DBUILD_ANDROID_TESTING="ON" \
                    -DTARGET_ARCHITECTURE="${triplet}" \
                    -DINSTALL_MANPAGES=OFF \
                    -DCMAKE_INSTALL_PREFIX="${ROOT_LOC}/libsndfile/${build_dir}" \
                    -DCMAKE_FIND_ROOT_PATH="${SEARCH_ROOT_PATH}" \
                    -DCMAKE_PREFIX_PATH="${SEARCH_ROOT_PATH}"
                        
                # Build library
                make
                
                # Install library and headers
                make install

                # Run the tests
                if [ "$test_inline" == "ON" ]; then
                    run_tests_on_device "${abi}"
                fi

                # Copy testsuite archive to android studio directory
                cp "${ROOT_LOC}/libsndfile/${build_dir}/${archive_name}.tar.gz" "${ROOT_LOC}/AndroidStudio/"
                
            fi
        fi

         # Navigate back to the libsndfile library source directory
        cd ..
    done
done

# Copy license files to android studio directory
cp -r "${ROOT_LOC}/libsndfile/COPYING" "${ROOT_LOC}/AndroidStudio/libs/libsndfile/"