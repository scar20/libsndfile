#!/bin/bash

#correction /cmake/src/compat/CMakelist.txt line 13 
#set_target_properties(${TARGET}_str PROPERTIES POSITION_INDEPENDENT_CODE ON)
#instead of
#set_target_properties(${TARGET}_dl PROPERTIES POSITION_INDEPENDENT_CODE ON)

#commenting out duplicate source /cmake/src/libmpg123/CMakeList.txt line 147-148

# added a WITH_SSE (default ON) user flag for cross compile android x86 build


# Setting up environment
export ANDROID_NDK_HOME=/opt/android-ndk-r25c
export PATH=$PATH:$ANDROID_NDK_HOME

# Navigate to mpg123 library source directory
cd ~/Repository/mpg123
# Lists of ABIs and configurations
abi_list=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
config_list=("Debug" "Release")

# Enabing debug message
messages="OFF"

# Flags for C and C++ compilers
c_flags=""
cxx_flags=""

# mpg123 library build directory name - build_<abi> for release and build_<abi>_d for debug
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
            messages=ON
        fi

        mkdir -p ${build_dir}
        cd ${build_dir}
        
        # CMake command with Android toolchain and relevant flags
        cmake ../ports/cmake \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
                 -DANDROID_ABI=${abi} \
                 -DANDROID_PLATFORM=android-21 \
                 -DCMAKE_BUILD_TYPE=${config} \
                 -DCMAKE_C_FLAGS="${c_flags}" \
                 -DCMAKE_CXX_FLAGS="${cxx_flags}" \
                 -DBUILD_SHARED_LIBS=OFF \
                 -DBUILD_LIBOUT123=OFF\
                 -DNO_MESSAGES=${messages} \
                 -DCMAKE_INSTALL_PREFIX=/home/scar/Repository/mpg123/${build_dir}                         
     
        # Build library
        make
        
        # Install library and headers
        make install
        
        # Navigate back to the library source directory
       cd ..
    done
done

