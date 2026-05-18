# Build-time driver script for generating serialization code. Invoked by cerial_generate() via
# add_custom_command(). Expects CERIAL_PARAMETER_FILE to be set via -D.

if(NOT DEFINED CERIAL_PARAMETER_FILE)
    message(FATAL_ERROR "CerialGenerateDriver: CERIAL_PARAMETER_FILE is required")
endif()

include("${CERIAL_PARAMETER_FILE}")

include("${CMAKE_CURRENT_LIST_DIR}/CerialGenerateHelpers.cmake")

cerial_compute_source_include("${cerial_source_file}" "${cerial_include_dirs}" source_include)

cerial_get_structs("${cerial_source_file}" structs)
cerial_generate_code(structs "${source_include}" code)
file(WRITE "${cerial_output_file}" "${code}")
