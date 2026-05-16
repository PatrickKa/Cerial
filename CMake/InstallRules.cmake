include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# The name of the package used in find_package()
set(package Cerial)

install(
    TARGETS Cerial_Cerial
    EXPORT ${package}Targets
    RUNTIME COMPONENT Cerial_Runtime
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}/${package}" COMPONENT Cerial_Development
    FILE_SET HEADERS COMPONENT Cerial_Development
)

# Allow package maintainers to freely override the path for the configs
set(Cerial_INSTALL_CMAKEDIR
    "share/${package}"
    CACHE PATH
    "Location of CMake package configuration files relative to the install prefix"
)
mark_as_advanced(Cerial_INSTALL_CMAKEDIR)

install(
    FILES "CMake/PackageConfig.cmake"
    DESTINATION "${Cerial_INSTALL_CMAKEDIR}"
    RENAME ${package}Config.cmake
    COMPONENT Cerial_Development
)

write_basic_package_version_file(
    "${PROJECT_BINARY_DIR}/${package}ConfigVersion.cmake"
    VERSION "${CMAKE_PROJECT_VERSION}"
    COMPATIBILITY SameMajorVersion
)

install(
    FILES "${PROJECT_BINARY_DIR}/${package}ConfigVersion.cmake"
    DESTINATION "${Cerial_INSTALL_CMAKEDIR}"
    COMPONENT Cerial_Development
)

install(
    EXPORT ${package}Targets
    DESTINATION "${Cerial_INSTALL_CMAKEDIR}"
    NAMESPACE Cerial::
    COMPONENT Cerial_Development
)

install(
    FILES
        "CMake/CerialGenerate.cmake"
        "CMake/CerialGenerateDriver.cmake"
        "CMake/CerialGenerateHelpers.cmake"
    DESTINATION "${Cerial_INSTALL_CMAKEDIR}"
    COMPONENT Cerial_Development
)
