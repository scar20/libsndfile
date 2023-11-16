#!/bin/bash

# Setting up environment
export ANDROID_NDK_HOME=/opt/android-ndk-r25c
export PATH=$PATH:$ANDROID_NDK_HOME

# Navigate to OGG library source directory
cd ~/Repository/libogg

# Lists of ABIs and configurations
abi_list=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
config_list=("Debug" "Release")

# Flags for C and C++ compilers
c_flags=""
cxx_flags=""

# OGG library build directory name - build_<abi> for release and build_<abi>_d for debug
build_dir=""

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
        cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
                 -DANDROID_ABI=${abi} \
                 -DANDROID_PLATFORM=android-21 \
                 -DCMAKE_BUILD_TYPE=${config} \
                 -DCMAKE_C_FLAGS="${c_flags}" \
                 -DCMAKE_CXX_FLAGS="${cxx_flags}" \
                 -DBUILD_SHARED_LIBS=OFF \
                 -DINSTALL_DOCS=OFF \
                 -DINSTALL_PKG_CONFIG_MODULE=ON \
                 -DINSTALL_CMAKE_PACKAGE_MODULE=ON \
                 -DCMAKE_INSTALL_PREFIX=/home/scar/Repository/libogg/${build_dir}
        
        # Build library
        make
        
        # Install library and headers
        make install
        
        # Navigate back to the OGG library source directory
        cd ..
    done
done



# Test if output is found by FindOgg.cmake
# Do this after each build to check if package found
# cmake .. -DCMAKE_PREFIX_PATH=~/Repository/libogg/build_<abi>



