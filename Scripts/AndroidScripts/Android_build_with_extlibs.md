# Building libsndfile with External Libraries for Android

The `Scripts/AndroidScripts` directory contains scripts to build libsndfile with all the Xiph libraries and MPEG support for Android.


## Requirements

* `Android NDK` ["developer.android.com/ndk"](https://developer.android.com/ndk/) Official Android Native Development Kit
* `libogg` ["www.xiph.org/ogg/"](www.xiph.org/ogg/) Library for manipulating ogg bitstreams; Required to enable Vorbis and Opus support.
* `libvorbis` ["www.vorbis.com/"](www.vorbis.com/) Open source lossy audio codec; Enables Vorbis support.
* `FLAC` ["www.xiph.org/flac/"](www.xiph.org/flac/) Free Lossless Audio Codec Library; Enables FLAC support.
* `opus` ["www.opus-codec.org/"](www.opus-codec.org/) Standardized open source low-latency fullband codec; Enables experimental Opus support.
* `mpg123` ["https://www.mpg123.de/"](https://www.mpg123.de/) MPEG Audio Layer I/II/III decoder; Enables MPEG Audio reading support.
* `libmp3lame` ["https://lame.sourceforge.io/"](https://lame.sourceforge.io/) High quality MPEG Audio Layer III (MP3) encoder; Enables MPEG layer III (MP3) writing support.

Precompiled binaries of the Xiph and MPEG libraries supporting 4 ABI's (`armeabi-v7a`, `arm64-v8a`, `x86_64`, `x86`) are available in the Releases section of this site. Alternatively, you can build them using the provided `build_extlibs.sh` master script and their individual scripts.


## Building with Precompiled Libraries

Place the precompiled libraries along with the libsndfile source, in a top-level directory. Ensure only one version of each library exists in this directory.

1. Untar the libraries in your top-level directory.
2. Copy `Scripts/AndroidScripts/build_libsndfile.sh` to your top-level directory.
3. Set `ANDROID_NDK_HOME` and `api_min` in the script to match your setup.
4. Run `./build_libsndfile.sh` from the top-level directory.

This builds by default a shared libsndfile library with support for all external libraries across four ABIs (Debug/Release). `build_<abi>` and `build_<abi>_d` directories will be created in the libsndfile root, along with an `AndroidStudio` directory in the top-level directory containing headers and libraries organized for Android Studio.


## Building with Library Sources

Follow the same steps as with precompiled libraries, but build the external libraries first:

1. Untar each library's source in your top-level directory.
2. Copy all the files from `Script/AndroidScripts/` to the top-level directory.
3. Set `ANDROID_NDK_HOME` and `api_min` in both `build_extlibs.sh` and `build_libsndfile.sh`.
4. Run `./build_extlibs.sh` and then `./build_libsndfile.sh` as with precompiled libraries.

### Individual Library Building
    
You can also build each library individually using their scripts. `OGG` must be build first as other Xiph libraries depends on it. Keep in mind that settings in individual scripts would be overridden by `build_extlibs.sh` master script.

**Note 1**: It is highly recommended to get the tarballs of those libraries rather than sources as pristine source tree may need additional steps before being used.

**Note 2**: `libmp3lame` require a patch (`android-lame.patch`), provided with the scripts, to be able to build for Android. Place it along the others in the top-level directory. It is handled automatically by the script.

## User Configuration

#### User configurable mandatory or optional variables common to all scripts:
* `ANDROID_NDK_HOME` (mandatory): Your NDK root location (e.g., `"/path/to/android-ndk-<version>"`)
* `api_min` (mandatory): Minimum API level supported by the NDK (e.g., `"android-21"`)
* `abi_list`: Default is `("armeabi-v7a" "arm64-v8a" "x86" "x86_64")`
* `config_list`: Default is `("Debug" "Release")`

#### Variables exclusive to `build_libsndfile.sh`:

* `shared_lib`: Build shared library when `ON`,
  build static library othervise. This option is `ON` by default.
* `build_android_testing`: Will create archives to be uploaded and run on device if `ON`. This option is `OFF` by default. See [Building the testsuite](#building-the-testsuite) for details.
* `test_inline`: Will attempt to run the tests inline during the build. This option is `ON` by default - have no effect if `build_android_testing=OFF`. See [Building the testsuite](#building-the-testsuite) for details.
* `device_path`: Device path where the testsuite archive will be stored and run. Provided in case of future changes in Android architecture. Currently set to `"/data/local/tmp"`

#### Variables exclusive to the external libraries scripts:

* `GENERATE_PRECOMPILED_LIBS` and `generate_precompiled_lib`: Enable the generation of streamlined precompiled lib packages including license information. This option is `OFF` by default. The former is the master switch from `build_extlibs.sh` and will override the later in individual scripts.

### Building the testsuite

While you can build libsndfile for android from a pristine source tree, using `build_android_testing=ON` requires that libsndfile source have been installed on the user machine. Please refer to [README.md](../../README.md) for proper installation and environment settings

The libsndfile test suite for Android must be installed on a device or emulator. The `test_inline` option runs the tests immediately if a device is found. The archives produced can be found in each ABI's build directory and the `AndroidStudio` directory. Use these commands to upload and run the test suite on a device:

    adb push -p <archive_name>.tar.gz /data/local/tmp
    adb shell
    cd /data/local/tmp
    tar xvf <archive_name>.tar.gz
    cd <archive_name>
    sh ./test_wrapper.sh
    cd ..
    rm -r <archive_name>*
    exit

The archive name is "libsndfile-testsuite-" followed by a triplet for each ABI:

- armeabi-v7a: armv7a-linux-androideabi
- arm64-v8a: aarch64-linux-android
- x86_64: x86_64-linux-android
- x86: i686-linux-android

Tests are performed only on release versions. For `shared_lib` builds, the testsuite must be linked with a release version of libsndfile, resulting in an additional `build_<ABI>_testsuite` directory.