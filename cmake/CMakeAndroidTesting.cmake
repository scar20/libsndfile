

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
add_test (test_main test_main)

### sfversion_test

add_executable (sfversion tests/sfversion.c)
target_include_directories (sfversion
	PRIVATE
		src
		${CMAKE_CURRENT_BINARY_DIR}/src
	)
target_link_libraries (sfversion sndfile)
add_test (sfversion sfversion)
set_tests_properties (sfversion PROPERTIES
	PASS_REGULAR_EXPRESSION "${PACKAGE_NAME}-${CPACK_PACKAGE_VERSION_FULL}"
	)

### error_test

add_executable (error_test tests/error_test.c)
target_link_libraries (error_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (error_test error_test)

### ulaw_test
add_executable (ulaw_test tests/ulaw_test.c)
target_link_libraries (ulaw_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (ulaw_test ulaw_test)

### alaw_test
add_executable (alaw_test tests/alaw_test.c)
target_link_libraries (alaw_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (alaw_test alaw_test)

### dwvw_test

add_executable (dwvw_test tests/dwvw_test.c)
target_link_libraries (dwvw_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (dwvw_test dwvw_test)

### command_test

add_executable (command_test tests/command_test.c)
target_link_libraries (command_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (command_test command_test all)

### floating_point_test

add_executable (floating_point_test
	tests/dft_cmp.c
	tests/floating_point_test.c
	)
target_link_libraries (floating_point_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
target_include_directories (floating_point_test PRIVATE tests)
add_test (floating_point_test floating_point_test)

### checksum_test

add_executable (checksum_test tests/checksum_test.c)
target_link_libraries (checksum_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (checksum_test checksum_test)

### scale_clip_test

add_executable (scale_clip_test tests/scale_clip_test.c)
target_link_libraries (scale_clip_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (scale_clip_test scale_clip_test)

### headerless_test

add_executable (headerless_test tests/headerless_test.c)
target_link_libraries (headerless_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (headerless_test headerless_test)

### rdwr_test

add_executable (rdwr_test tests/rdwr_test.c)
target_link_libraries (rdwr_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (rdwr_test rdwr_test)

### locale_test

add_executable (locale_test tests/locale_test.c)
target_link_libraries (locale_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (locale_test locale_test)

### cpp_test

add_executable (cpp_test tests/cpp_test.cc)
target_link_libraries (cpp_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (cpp_test cpp_test)

### external_libs_test

add_executable (external_libs_test tests/external_libs_test.c)
target_link_libraries (external_libs_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (external_libs_test external_libs_test)

### format_check_test

add_executable (format_check_test tests/format_check_test.c)
target_link_libraries (format_check_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (format_check_test format_check_test)

### channel_test

add_executable (channel_test tests/channel_test.c)
target_link_libraries (channel_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (channel_test channel_test)

### pcm_test

add_executable (pcm_test tests/pcm_test.c)
target_link_libraries (pcm_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (pcm_test pcm_test)

### common test executables

add_executable (write_read_test
	tests/generate.c
	tests/write_read_test.c
)
target_link_libraries (write_read_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
target_include_directories (write_read_test PRIVATE tests)

add_executable (lossy_comp_test tests/lossy_comp_test.c)
target_link_libraries (lossy_comp_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (peak_chunk_test tests/peak_chunk_test.c)
target_link_libraries (peak_chunk_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (header_test tests/header_test.c)
target_link_libraries (header_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (misc_test tests/misc_test.c)
target_link_libraries (misc_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (string_test tests/string_test.c)
target_link_libraries (string_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (multi_file_test tests/multi_file_test.c)
target_link_libraries (multi_file_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (aiff_rw_test tests/aiff_rw_test.c)
target_link_libraries (aiff_rw_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (chunk_test tests/chunk_test.c)
target_link_libraries (chunk_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (long_read_write_test tests/long_read_write_test.c)
target_link_libraries (long_read_write_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (raw_test tests/raw_test.c)
target_link_libraries (raw_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (compression_size_test tests/compression_size_test.c)
target_link_libraries (compression_size_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (ogg_test tests/ogg_test.c)
target_link_libraries (ogg_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (ogg_opus_test tests/ogg_opus_test.c)
target_link_libraries (ogg_opus_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (mpeg_test tests/mpeg_test.c)
target_link_libraries (mpeg_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (stdin_test tests/stdin_test.c)
target_link_libraries (stdin_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
set_target_properties (stdin_test PROPERTIES RUNTIME_OUTPUT_DIRECTORY "tests")

add_executable (stdout_test tests/stdout_test.c)
target_link_libraries (stdout_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
set_target_properties (stdout_test PROPERTIES RUNTIME_OUTPUT_DIRECTORY "tests")

add_executable (stdio_test tests/stdio_test.c)
target_link_libraries (stdio_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (pipe_test tests/pipe_test.c)
target_link_libraries (pipe_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

add_executable (virtual_io_test tests/virtual_io_test.c)
target_link_libraries (virtual_io_test
	PRIVATE
		sndfile
		test_utils
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)

### g72x_test

add_executable (g72x_test src/G72x/g72x_test.c)
target_include_directories (g72x_test
	PRIVATE
		src
		${CMAKE_CURRENT_BINARY_DIR}/src
	)
target_link_libraries (g72x_test
	PRIVATE
		sndfile
		$<$<BOOL:${LIBM_REQUIRED}>:m>
	)
add_test (g72x_test g72x_test all)

### aiff-tests

add_test (write_read_test_aiff write_read_test aiff)
add_test (lossy_comp_test_aiff_ulaw lossy_comp_test aiff_ulaw)
add_test (lossy_comp_test_aiff_alaw lossy_comp_test aiff_alaw)
add_test (lossy_comp_test_aiff_gsm610 lossy_comp_test aiff_gsm610)
add_test (peak_chunk_test_aiff peak_chunk_test aiff)
add_test (header_test_aiff header_test aiff)
add_test (misc_test_aiff misc_test aiff)
add_test (string_test_aiff string_test aiff)
add_test (multi_file_test_aiff multi_file_test aiff)
add_test (aiff_rw_test aiff_rw_test)

### au-tests

add_test (write_read_test_au write_read_test au)
add_test (lossy_comp_test_au_ulaw lossy_comp_test au_ulaw)
add_test (lossy_comp_test_au_alaw lossy_comp_test au_alaw)
add_test (lossy_comp_test_au_g721 lossy_comp_test au_g721)
add_test (lossy_comp_test_au_g723 lossy_comp_test au_g723)
add_test (header_test_au header_test au)
add_test (misc_test_au misc_test au)
add_test (multi_file_test_au multi_file_test au)

### caf-tests

add_test (write_read_test_caf write_read_test caf)
add_test (lossy_comp_test_caf_ulaw lossy_comp_test caf_ulaw)
add_test (lossy_comp_test_caf_alaw lossy_comp_test caf_alaw)
add_test (header_test_caf header_test caf)
add_test (peak_chunk_test_caf peak_chunk_test caf)
add_test (misc_test_caf misc_test caf)
add_test (chunk_test_caf chunk_test caf)
add_test (string_test_caf string_test caf)
add_test (long_read_write_test_alac long_read_write_test alac)

# wav-tests
add_test (write_read_test_wav write_read_test wav)
add_test (lossy_comp_test_wav_pcm lossy_comp_test wav_pcm)
add_test (lossy_comp_test_wav_ima lossy_comp_test wav_ima)
add_test (lossy_comp_test_wav_msadpcm lossy_comp_test wav_msadpcm)
add_test (lossy_comp_test_wav_ulaw lossy_comp_test wav_ulaw)
add_test (lossy_comp_test_wav_alaw lossy_comp_test wav_alaw)
add_test (lossy_comp_test_wav_gsm610 lossy_comp_test wav_gsm610)
add_test (lossy_comp_test_wav_g721 lossy_comp_test wav_g721)
add_test (lossy_comp_test_wav_nmsadpcm lossy_comp_test wav_nmsadpcm)
add_test (peak_chunk_test_wav peak_chunk_test wav)
add_test (header_test_wav header_test wav)
add_test (misc_test_wav misc_test wav)
add_test (string_test_wav string_test wav)
add_test (multi_file_test_wav multi_file_test wav)
add_test (chunk_test_wav chunk_test wav)

### w64-tests

add_test (write_read_test_w64 write_read_test w64)
add_test (lossy_comp_test_w64_ima lossy_comp_test w64_ima)
add_test (lossy_comp_test_w64_msadpcm lossy_comp_test w64_msadpcm)
add_test (lossy_comp_test_w64_ulaw lossy_comp_test w64_ulaw)
add_test (lossy_comp_test_w64_alaw lossy_comp_test w64_alaw)
add_test (lossy_comp_test_w64_gsm610 lossy_comp_test w64_gsm610)
add_test (header_test_w64 header_test w64)
add_test (misc_test_w64 misc_test w64)

### rf64-tests

add_test (write_read_test_rf64 write_read_test rf64)
add_test (header_test_rf64 header_test rf64)
add_test (misc_test_rf64 misc_test rf64)
add_test (string_test_rf64 string_test rf64)
add_test (peak_chunk_test_rf64 peak_chunk_test rf64)
add_test (chunk_test_rf64 chunk_test rf64)

### raw-tests
add_test (write_read_test_raw write_read_test raw)
add_test (lossy_comp_test_raw_ulaw lossy_comp_test raw_ulaw)
add_test (lossy_comp_test_raw_alaw lossy_comp_test raw_alaw)
add_test (lossy_comp_test_raw_gsm610 lossy_comp_test raw_gsm610)
add_test (lossy_comp_test_vox_adpcm lossy_comp_test vox_adpcm)
add_test (raw_test raw_test)

### paf-tests
add_test (write_read_test_paf write_read_test paf)
add_test (header_test_paf header_test paf)
add_test (misc_test_paf misc_test paf)

### svx-tests
add_test (write_read_test_svx write_read_test svx)
add_test (header_test_svx header_test svx)
add_test (misc_test_svx misc_test svx)

### nist-tests
add_test (write_read_test_nist write_read_test nist)
add_test (lossy_comp_test_nist_ulaw lossy_comp_test nist_ulaw)
add_test (lossy_comp_test_nist_alaw lossy_comp_test nist_alaw)
add_test (header_test_nist header_test nist)
add_test (misc_test_nist misc_test nist)

### ircam-tests
add_test (write_read_test_ircam write_read_test ircam)
add_test (lossy_comp_test_ircam_ulaw lossy_comp_test ircam_ulaw)
add_test (lossy_comp_test_ircam_alaw lossy_comp_test ircam_alaw)
add_test (header_test_ircam header_test ircam)
add_test (misc_test_ircam misc_test ircam)

### voc-tests
add_test (write_read_test_voc write_read_test voc)
add_test (lossy_comp_test_voc_ulaw lossy_comp_test voc_ulaw)
add_test (lossy_comp_test_voc_alaw lossy_comp_test voc_alaw)
add_test (header_test_voc header_test voc)
add_test (misc_test_voc misc_test voc)

### mat4-tests
add_test (write_read_test_mat4 write_read_test mat4)
add_test (header_test_mat4 header_test mat4)
add_test (misc_test_mat4 misc_test mat4)

### mat5-tests
add_test (write_read_test_mat5 write_read_test mat5)
add_test (header_test_mat5 header_test mat5)
add_test (misc_test_mat5 misc_test mat5)

### pvf-tests
add_test (write_read_test_pvf write_read_test pvf)
add_test (header_test_pvf header_test pvf)
add_test (misc_test_pvf misc_test pvf)

### xi-tests
add_test (lossy_comp_test_xi_dpcm lossy_comp_test xi_dpcm)

### htk-tests
add_test (write_read_test_htk write_read_test htk)
add_test (header_test_htk header_test htk)
add_test (misc_test_htk misc_test htk)

### avr-tests
add_test (write_read_test_avr write_read_test avr)
add_test (header_test_avr header_test avr)
add_test (misc_test_avr misc_test avr)

### sds-tests
add_test (write_read_test_sds write_read_test sds)
add_test (header_test_sds header_test sds)
add_test (misc_test_sds misc_test sds)

# sd2-tests
add_test (write_read_test_sd2 write_read_test sd2)

### wve-tests
add_test (lossy_comp_test_wve lossy_comp_test wve)

### mpc2k-tests
add_test (write_read_test_mpc2k write_read_test mpc2k)
add_test (header_test_mpc2k header_test mpc2k)
add_test (misc_test_mpc2k misc_test mpc2k)

### flac-tests
add_test (write_read_test_flac write_read_test flac)
add_test (compression_size_test_flac compression_size_test flac)
add_test (string_test_flac string_test flac)

### vorbis-tests
add_test (ogg_test ogg_test)
add_test (compression_size_test_vorbis compression_size_test vorbis)
add_test (lossy_comp_test_ogg_vorbis lossy_comp_test ogg_vorbis)
add_test (string_test_ogg string_test ogg)
add_test (misc_test_ogg misc_test ogg)

### opus-tests ###
add_test (ogg_opus_test ogg_opus_test)
add_test (compression_size_test_opus compression_size_test opus)
add_test (lossy_comp_test_ogg_opus lossy_comp_test ogg_opus)
add_test (string_test_opus string_test opus)

### mpeg-tests ###
add_test (mpeg_test mpeg_test)
add_test (compression_size_test_mpeg compression_size_test mpeg)

### io-tests
add_test (stdio_test stdio_test)
add_test (pipe_test pipe_test)
add_test (virtual_io_test virtual_io_test)

set (SNDFILE_TEST_TARGETS
	test_utils
	test_main
	sfversion
	error_test
	ulaw_test
	alaw_test
	dwvw_test
	command_test
	floating_point_test
	checksum_test
	scale_clip_test
	headerless_test
	rdwr_test
	locale_test
	cpp_test
	external_libs_test
	format_check_test
	channel_test
	pcm_test
	write_read_test
	lossy_comp_test
	peak_chunk_test
	header_test
	misc_test
	string_test
	multi_file_test
	aiff_rw_test
	chunk_test
	long_read_write_test
	raw_test
	compression_size_test
	ogg_test
	stdin_test
	stdout_test
	stdio_test
	pipe_test
	virtual_io_test
	g72x_test
	)


set_target_properties(${SNDFILE_TEST_TARGETS} PROPERTIES FOLDER Tests)

