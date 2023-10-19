# Build the test suite for Android libsndfile
# 2023, Sylvain Carette, based on the original CMakeLists.txt from libsndfile

# Initial set up

cmake_minimum_required (VERSION 3.0)

# Do not run this script if using MSVC compiler
if (CMAKE_SYSTEM_NAME STREQUAL "Android" AND MSVC)
    message(FATAL_ERROR "Error: Must use Clang to compile for Android, not MSVC.")
endif()

# Locate config.h
set(CONFIG_H_FILE "${CMAKE_CURRENT_BINARY_DIR}/src/config.h")

# Extract PACKAGE_VERSION
file(STRINGS ${CONFIG_H_FILE} PACKAGE_VERSION_DEFN REGEX "#define PACKAGE_VERSION")
string(REGEX REPLACE "#define PACKAGE_VERSION \"([^\"]+)\"" "\\1" PACKAGE_VERSION ${PACKAGE_VERSION_DEFN})

# Extract LIB_VERSION
string(REGEX REPLACE "([0-9]+\\.[0-9]+\\.[0-9]+).*" "\\1" LIB_VERSION ${PACKAGE_VERSION})

# Set the absolute source directory
set(ABS_TOP_SRCDIR "${CMAKE_CURRENT_SOURCE_DIR}/..")

# User definable device path to the test script - default to data/local/tmp
set(DEVICE_TESTS_PATH "/data/local/tmp/sndfileTests")

set(MILESTONE_CONTENT [=[
echo "----------------------------------------------------------------------"
echo "  $sfversion ${message}"
echo "----------------------------------------------------------------------"
]=]) # End MILESTONE_CONTENT

# Create the first content segment for test_wrapper file
set(TEST_WRAPPER_CONTENT [=[
#!/system/bin/sh

# Build the test suite for Android libsndfile
# 2023, Sylvain Carette, based on the original CMakeLists.txt from libsndfile
# This file is generated by CMake
# Copyright (C) 2008-2017 Erik de Castro Lopo <erikd@mega-nerd.com>
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#     * Neither the author nor the names of any contributors may be used
#       to endorse or promote products derived from this software without
#       specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This file is generated by CMake

HOST_TRIPLET=${TARGET_ARCHITECTURE}
PACKAGE_VERSION=${PACKAGE_VERSION}
LIB_VERSION=${LIB_VERSION}
ABS_TOP_SRCDIR=${ABS_TOP_SRCDIR}

# Set target device library path if needed
export LD_LIBRARY_PATH=${DEVICE_TESTS_PATH}/lib:$LD_LIBRARY_PATH

echo "Starting tests..."

sfversion=$(./tests/sfversion | grep libsndfile | sed "s/-exp$//")

if test "$sfversion" != libsndfile-$PACKAGE_VERSION ; then
	echo "Error : sfversion ($sfversion) and PACKAGE_VERSION ($PACKAGE_VERSION) don't match."
	exit 1
	fi

# Force exit on errors.
set -e

]=]) # End first segment TEST_WRAPPER_CONTENT


# Create the command script file
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/test_wrapper.sh "${TEST_WRAPPER_CONTENT}")

# Macro to add a milestone to the command script
macro(add_milestone message)
	file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/test_wrapper.sh "${MILESTONE_CONTENT}")
endmacro(add_milestone)

# Macro to add test to the command script
macro(add_android_test test_name)
	file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/test_wrapper.sh "./tests/${test_name}\n")
endmacro(add_android_test)

# Macro to add test with arguments to the command script
macro(add_android_test_args test_name args)
	file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/test_wrapper.sh "./tests/${test_name} ${args}\n")
endmacro(add_android_test_args)

# Keep a list of all the test programs for the tarball
set(TEST_PROGRAMS_LIST "")

# Add pedantic header test
# As we don't have a C compiler on the host, we need to perform this test as we build the test suite
execute_process(
    COMMAND ${CMAKE_C_COMPILER} -std=c99 -Werror -pedantic -I../src -I${CMAKE_CURRENT_SOURCE_DIR}/src -I../include ../tests/sfversion.c -o /dev/null
    RESULT_VARIABLE PEDANTIC_TEST_RESULT
)

if(PEDANTIC_TEST_RESULT EQUAL 0)
    file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/test_wrapper.sh "echo 'Pedantic header test: ok'\n")
else()
    file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/test_wrapper.sh "echo 'Pedantic header test: failed'\n")
endif()

# Here we continue with almost the original CMakeLists.txt from libsndfile

include (CMakeAutoGen)

# generate tests sources from autogen templates

macro (wrap_test_sources)
	foreach (test_source ${ARGN})
		get_filename_component (test_name ${test_source} NAME_WE)
		file (READ ${test_source} test_content)
		string (REGEX REPLACE "int[[:space:]]+main[[:space:]]*\\(([^)]*)\\)" "${test_name}_wrapper(\\1)" wrapped_content "${test_content}")
		file (WRITE ${CMAKE_CURRENT_BINARY_DIR}/${test_name}_wrapped.c "${wrapped_content}")
		list (APPEND wrapped_test_sources ${CMAKE_CURRENT_BINARY_DIR}/${test_name}_wrapped.c)
	endforeach ()
	set (WRAPPED_TEST_SOURCES ${wrapped_test_sources} PARENT_SCOPE)
endmacro ()
lsf_autogen (tests benchmark c)
lsf_autogen (tests floating_point_test c)
lsf_autogen (tests header_test c)
lsf_autogen (tests pcm_test c)
lsf_autogen (tests pipe_test c)
lsf_autogen (tests rdwr_test c)
lsf_autogen (tests scale_clip_test c)
lsf_autogen (tests utils c h)
lsf_autogen (tests write_read_test c)
lsf_autogen (src test_endswap c)

# utils static library
add_library(test_utils STATIC tests/utils.c)
target_include_directories (test_utils
	PUBLIC
		src
		${CMAKE_CURRENT_BINARY_DIR}/src
		${CMAKE_CURRENT_BINARY_DIR}/tests
	)
target_link_libraries(test_utils PRIVATE sndfile)

### test_main

add_executable (test_main
	src/test_main.c
	src/test_main.h
	src/test_conversions.c
	src/test_float.c
	src/test_endswap.c
	src/test_audio_detect.c
	src/test_log_printf.c
	src/test_file_io.c
	src/test_ima_oki_adpcm.c
	src/test_strncpy_crlf.c
	src/test_broadcast_var.c
	src/test_cart_var.c
	src/test_binheader_writef.c
	src/test_nms_adpcm.c
	)
target_include_directories (test_main
	PUBLIC
		src
		${CMAKE_CURRENT_BINARY_DIR}/src
		${CMAKE_CURRENT_BINARY_DIR}/tests
	)
target_link_libraries (test_main PRIVATE sndfile)
if (MSVC)
	target_compile_definitions (test_main PRIVATE _USE_MATH_DEFINES)
endif ()
add_android_test (test_main test_main)
list(APPEND TEST_PROGRAMS_LIST tests/test_main)



# Run the Python script and check result
# As we don't have python on the host, we need to perform this test as we build the test suite
execute_process(
    COMMAND ${PYTHON_EXECUTABLE} "${ABS_TOP_SRCDIR}/src/binheader_writef_check.py" "${ABS_TOP_SRCDIR}/src"/*.c
    RESULT_VARIABLE BINHEADER_TEST_RESULT
    OUTPUT_VARIABLE BINHEADER_TEST_OUTPUT
    ERROR_VARIABLE BINHEADER_TEST_ERROR
)

# Embed the result in the test script
if(${BINHEADER_TEST_RESULT} EQUAL 0)
	add_milestone("binheader_writef_check.py passed")
else()
	add_milestone("binheader_writef_check.py failed: ${BINHEADER_TEST_ERROR}")
endif()


set (SNDFILE_TEST_TARGETS
		test_utils
		test_main
		sfversion
		)

set_target_properties(${SNDFILE_TEST_TARGETS} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tests)


# Add the test programs to the tarball
add_custom_target(create_tarball
    COMMAND ${CMAKE_COMMAND} -E tar "czf" ${TARBALL} ${TEST_PROGRAMS_LIST}
    COMMENT "Creating tarball ${TARBALL}"
)
