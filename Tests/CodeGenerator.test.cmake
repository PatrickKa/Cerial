cmake_minimum_required(VERSION 3.31)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../CMake")
include(CMakeUnit)
include(CerialCodeGenerator)

set(data_dir "${CMAKE_CURRENT_LIST_DIR}/Data")

# --- Structs in namespaces ---

cerial_get_structs("${data_dir}/StructsInNamespaces.hpp" structs)
check("GlobalStruct" IN_LIST structs)
check("n::NamespacedStruct" IN_LIST structs)
check("n::m::NestedNamespaceStruct" IN_LIST structs)
check("n::a::b::InlineNamespaceStruct" IN_LIST structs)
check("AnonymousNamespaceStruct" IN_LIST structs)
list(LENGTH structs n_structs)
check("${n_structs}" EQUAL 5)

# --- Ignored declarations ---

cerial_get_structs("${data_dir}/IgnoredDeclarations.hpp" structs)
check("ParentStruct" IN_LIST structs)
list(LENGTH structs n_structs)
check("${n_structs}" EQUAL 1)

print_test_report()
