cmake_minimum_required(VERSION 3.20)

cmake_path(GET CMAKE_CURRENT_LIST_DIR PARENT_PATH project_root_dir)
list(APPEND CMAKE_MODULE_PATH "${project_root_dir}/CMake")

include(FormatScriptHelpers)

file(
    GLOB_RECURSE files
    "${project_root_dir}/Cerial/*.[chi]pp"
    "${project_root_dir}/Tests/*.[chi]pp"
)
list(FILTER files EXCLUDE REGEX "/Tests/Data/ExpectedOutput/")

if(FIX)
    format_cpp_code(${files})
else()
    check_cpp_code_formatting(${files})
endif()
