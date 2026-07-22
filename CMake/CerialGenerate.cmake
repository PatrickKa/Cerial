# cerial_generate(
#     TARGET <target>
#     HEADERS <headers>...
#     [OUTPUT_DIR <output-dir>]
#     [INCLUDE_DIR <include-dir>]
# )
#
# Generates a cerial::Reflection<T> specialization for every struct in the given header files
# annotated with "// @Cerial", giving each first-class Cerial support (SerialSize(), SerializeTo(),
# DeserializeFrom(), and the isStaticallySized trait are all derived from it). The generated files
# are named <stem>.cerial.hpp and placed in <output-dir>. <include-dir> is added to the target's
# include directories.
#
# Defaults: OUTPUT_DIR = CMAKE_CURRENT_BINARY_DIR, INCLUDE_DIR = CMAKE_BINARY_DIR
#
# The source header's include path inside the generated file is computed automatically from the
# target's include directories.
function(cerial_generate)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "TARGET;OUTPUT_DIR;INCLUDE_DIR" "HEADERS")

    if(NOT ARG_TARGET)
        message(FATAL_ERROR "cerial_generate: TARGET is required")
    endif()
    if(NOT ARG_HEADERS)
        message(FATAL_ERROR "cerial_generate: HEADERS is required")
    endif()
    if(NOT ARG_OUTPUT_DIR)
        set(ARG_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    endif()
    if(NOT ARG_INCLUDE_DIR)
        set(ARG_INCLUDE_DIR "${CMAKE_BINARY_DIR}")
    endif()

    set(driver_script "${_cerial_module_dir}/CerialGenerateDriver.cmake")
    set(generated_files "")

    foreach(header IN LISTS ARG_HEADERS)
        cmake_path(ABSOLUTE_PATH header BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

        # MyStruct.hpp -> MyStruct.cerial.hpp
        cmake_path(GET header FILENAME header_filename)
        cmake_path(GET header_filename STEM stem)
        cmake_path(GET header_filename EXTENSION LAST_ONLY extension)
        set(output_file "${ARG_OUTPUT_DIR}/${stem}.cerial${extension}")

        # Write a parameter file that resolves generator expressions at generation time
        set(parameter_file "${ARG_OUTPUT_DIR}/_CerialParameters_${stem}.cmake")
        file(
            GENERATE OUTPUT "${parameter_file}"
            CONTENT
                "\
set(cerial_source_file \"${header}\")
set(cerial_output_file \"${output_file}\")
set(cerial_include_dirs
    \"$<TARGET_PROPERTY:${ARG_TARGET},INCLUDE_DIRECTORIES>\"
    \"$<TARGET_PROPERTY:${ARG_TARGET},INTERFACE_INCLUDE_DIRECTORIES>\"
)
"
        )

        add_custom_command(
            OUTPUT "${output_file}"
            COMMAND
                "${CMAKE_COMMAND}" "-DCERIAL_PARAMETER_FILE=${parameter_file}" -P "${driver_script}"
            DEPENDS "${header}"
            COMMENT "Generating serialization code for ${header_filename}"
            VERBATIM
        )

        list(APPEND generated_files "${output_file}")
    endforeach()

    # Custom target to drive generation, then wire it into the user's target. Adding the generated
    # files as sources of the user's target would only work if the target is defined in the same
    # CMakeLists.txt where cerial_generate() is called, which is not guaranteed.
    add_custom_target(${ARG_TARGET}_CerialGenerate DEPENDS ${generated_files})
    add_dependencies(${ARG_TARGET} ${ARG_TARGET}_CerialGenerate)

    set(scope PUBLIC)
    get_target_property(target_type ${ARG_TARGET} TYPE)
    if(target_type STREQUAL "INTERFACE_LIBRARY")
        set(scope INTERFACE)
    endif()
    target_include_directories(${ARG_TARGET} ${scope} "$<BUILD_INTERFACE:${ARG_INCLUDE_DIR}>")
    target_link_libraries(${ARG_TARGET} ${scope} Cerial::Cerial)
endfunction()

# Must be set outside the function to resolve to this file's directory and not the caller's one
set(_cerial_module_dir "${CMAKE_CURRENT_LIST_DIR}")
