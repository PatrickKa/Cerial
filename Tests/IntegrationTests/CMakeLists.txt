# Test cerial_generate() on two different target types: an INTERFACE library that is linked to the
# test, and the test itself, which is an executable.

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../CMake")

include(CerialGenerate)

add_library(CerialTests_InterfaceLibrary INTERFACE)
target_include_directories(CerialTests_InterfaceLibrary INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}")

cerial_generate(
    TARGET CerialTests_InterfaceLibrary
    HEADERS InterfaceStructs.hpp
    INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}"
)

add_and_set_up_test(CerialTests_CerialGenerate)
target_include_directories(CerialTests_CerialGenerate PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(
    CerialTests_CerialGenerate
    PRIVATE Catch2::Catch2WithMain CerialTests_InterfaceLibrary
)

cerial_generate(
    TARGET CerialTests_CerialGenerate
    HEADERS Structs.hpp
    INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}"
)

catch_discover_tests(CerialTests_CerialGenerate)
