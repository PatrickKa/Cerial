add_and_set_up_test(CerialTests_Cerial)
target_link_libraries(CerialTests_Cerial PRIVATE Cerial::Cerial Catch2::Catch2WithMain)
catch_discover_tests(CerialTests_Cerial)

add_and_set_up_test(CerialTests_Dummy)
target_link_libraries(CerialTests_Dummy PRIVATE Catch2::Catch2WithMain)
catch_discover_tests(CerialTests_Dummy)

add_test(
    NAME CerialGenerateHelpers
    COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_SOURCE_DIR}/CerialGenerateHelpers.test.cmake"
)
