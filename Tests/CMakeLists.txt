find_package(Catch2 CONFIG REQUIRED)
find_package(etl CONFIG REQUIRED)

include(Catch)

add_subdirectory(UnitTests)
add_subdirectory(IntegrationTests)

# --- Utility target for invoking Valgrind ---

add_custom_target(
    MemCheck
    COMMAND
        "${CMAKE_CTEST_COMMAND}" -C $<CONFIG> -T memcheck -LE NoMemCheck --output-on-failure
        --no-tests=error
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    USES_TERMINAL
    VERBATIM
)

add_folder(Tests)
