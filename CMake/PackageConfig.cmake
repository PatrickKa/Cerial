include(CMakeFindDependencyMacro)

if(NOT TARGET Cerial::Cerial)
    include("${CMAKE_CURRENT_LIST_DIR}/CerialTargets.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/CerialGenerate.cmake")
endif()
