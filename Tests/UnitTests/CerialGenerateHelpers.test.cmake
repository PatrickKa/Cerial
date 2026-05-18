cmake_minimum_required(VERSION 3.31)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../CMake")
include(CMakeUnit)
include(CerialGenerateHelpers)

set(data_dir "${CMAKE_CURRENT_LIST_DIR}/../Data")

# --- Structs in namespaces ---

cerial_get_structs("${data_dir}/StructsInNamespaces.hpp" structs)
list(LENGTH structs n_structs)
check("${n_structs}" EQUAL 5)

list(GET structs 0 struct)
check("${struct}" STREQUAL "GlobalStruct")
check("${structs_members_0}" STREQUAL "b")

list(GET structs 1 struct)
check("${struct}" STREQUAL "n::NamespacedStruct")
check("${structs_members_1}" STREQUAL "l")

list(GET structs 2 struct)
check("${struct}" STREQUAL "n::m::NestedNamespaceStruct")
check("${structs_members_2}" STREQUAL "c;i;f")

list(GET structs 3 struct)
check("${struct}" STREQUAL "n::a::b::InlineNamespaceStruct")
check("${structs_members_3}" STREQUAL "s")

list(GET structs 4 struct)
check("${struct}" STREQUAL "AnonymousNamespaceStruct")
check("${structs_members_4}" STREQUAL "d")

# --- Ignored declarations ---

cerial_get_structs("${data_dir}/IgnoredDeclarations.hpp" structs)
list(LENGTH structs n_structs)
check("${n_structs}" EQUAL 1)

list(GET structs 0 struct)
check("${struct}" STREQUAL "ParentStruct")
check("${structs_members_0}" STREQUAL "j")

# --- Code generation ---

set(expected_dir "${data_dir}/ExpectedOutput")

cerial_get_structs("${data_dir}/StructsInNamespaces.hpp" structs)
cerial_generate_code(structs StructsInNamespaces.hpp code)
file(READ "${expected_dir}/StructsInNamespaces.hpp" expected)
string(REPLACE "\r\n" "\n" expected "${expected}")
check("${code}" STREQUAL "${expected}")

cerial_get_structs("${data_dir}/IgnoredDeclarations.hpp" structs)
cerial_generate_code(structs IgnoredDeclarations.hpp code)
file(READ "${expected_dir}/IgnoredDeclarations.hpp" expected)
string(REPLACE "\r\n" "\n" expected "${expected}")
check("${code}" STREQUAL "${expected}")

print_test_report()
