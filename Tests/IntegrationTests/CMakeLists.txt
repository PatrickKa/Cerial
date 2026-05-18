include(CerialGenerate)

add_and_set_up_test(CerialTests_CerialGenerate)
target_link_libraries(CerialTests_CerialGenerate PRIVATE Catch2::Catch2WithMain)
target_include_directories(CerialTests_CerialGenerate PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

cerial_generate(
    TARGET CerialTests_CerialGenerate
    HEADERS Structs.hpp
    INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}"
)

catch_discover_tests(CerialTests_CerialGenerate)
