#!/bin/bash

# This script will build all libsndfile external libs for Android using the NDK

# Ensure all library sources and scripts are within a top-level directory.
# Place and run this script from within that top-level directory.
# It will generate build directories for each ABI/configuration in each lib subdirectory.
# Build directory name: build_<abi> for release and build_<abi>_d for debug

# ------- User configuration ------- #

# set to your NDK root location : "path/to/android-ndk-<your_version_number>"
ANDROID_NDK_HOME="/opt/android-ndk-r25c"

# Minimum API level supported by the NDK - adjust according to your project min sdk
# ex: API_MIN="android-21"
API_MIN="android-21"

# Lists of ABIs and configurations
# Adjust as needed
# ABI_LIST=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
# CONFIG_LIST=("Debug" "Release")
ABI_LIST=("armeabi-v7a" "arm64-v8a")
CONFIG_LIST=("Debug" "Release")

# ------- End of user configuration ------- #

# Check if ANDROID_NDK_HOME and API_MIN are set
if [ -z "$ANDROID_NDK_HOME" ]; then
	echo "Error: ANDROID_NDK_HOME must be set"
	exit 1
elif [ -z "$API_MIN" ]; then
	echo "Error: API_MIN must be set"
	exit 1
fi		

# Preset to the current toolchain location - it may change in the future
ANDROID_TOOLCHAIN="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"

source ./build_libogg.sh
#.... other build
