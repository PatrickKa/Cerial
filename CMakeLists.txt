cmake_minimum_required(VERSION 3.31)

include(CMake/InSourceBuildGuard.cmake)
include(CMake/MetadataFromVcpkg.cmake)

project(
    Cerial
    VERSION ${version_from_vcpkg}
    DESCRIPTION ${description_from_vcpkg}
    HOMEPAGE_URL ${homepage_from_vcpkg}
    LANGUAGES CXX
)

include(CMake/LanguageStandard.cmake)
include(CMake/OptionsAndVariables.cmake)
include(CMake/AddAndSetUpTargets.cmake)

# --- Find dependencies ---

# --- Declare targets ---

add_and_set_up_library(Cerial_Cerial INTERFACE)

add_subdirectory(Cerial)

# --- Install rules ---

if(NOT CMAKE_SKIP_INSTALL_RULES)
    include(CMake/InstallRules.cmake)
endif()

# --- Developer mode ---

if(NOT Cerial_DEVELOPER_MODE)
    return()
elseif(NOT PROJECT_IS_TOP_LEVEL)
    message(AUTHOR_WARNING "Developer mode is intended for developers of Cerial")
endif()

include(CMake/DeveloperMode.cmake)
