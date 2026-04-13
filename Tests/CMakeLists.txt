find_package(Catch2 CONFIG REQUIRED)
include(Catch)

add_subdirectory(UnitTests)
add_subdirectory(IntegrationTests)

add_folder(Tests)
