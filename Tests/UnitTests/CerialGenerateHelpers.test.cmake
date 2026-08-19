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

# --- Brace initializers ---

# Regression test: a brace initializer (e.g. "= {}") has its braces consumed as scope events in the
# event stream, so the member declaration was left ending in a dangling "=" and silently dropped.
cerial_get_structs("${data_dir}/BraceInitializers.hpp" structs)
list(LENGTH structs n_structs)
check("${n_structs}" EQUAL 1)

list(GET structs 0 struct)
check("${struct}" STREQUAL "BraceInitializers")
check(
    "${structs_members_0}"
    STREQUAL
    "scalar;assignEmptyBrace;assignFilledBrace;directBrace;noInit;trailing"
)

# --- C-array members ---

# Regression test: C-style array members are not serializable, so each is excluded with a warning
# rather than reflected. Covers multiple dimensions, a size with parentheses, and a brace
# initializer; only the two plain members survive.
cerial_get_structs("${data_dir}/CArrayMembers.hpp" structs)
list(LENGTH structs n_structs)
check("${n_structs}" EQUAL 1)

list(GET structs 0 struct)
check("${struct}" STREQUAL "CArrayMembers")
check("${structs_members_0}" STREQUAL "scalar;trailing")

# --- Unsupported members ---

# Regression test: pointer, reference, and attributed members were recognized by the
# final-identifier match and reflected anyway, producing code that does not compile; they must be
# excluded instead. Bit-fields have no address and are excluded too. Only the two plain members
# survive.
cerial_get_structs("${data_dir}/UnsupportedMembers.hpp" structs)
list(LENGTH structs n_structs)
check("${n_structs}" EQUAL 1)

list(GET structs 0 struct)
check("${struct}" STREQUAL "UnsupportedMembers")
check("${structs_members_0}" STREQUAL "supported;alsoSupported")

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

cerial_get_structs("${data_dir}/BraceInitializers.hpp" structs)
cerial_generate_code(structs BraceInitializers.hpp code)
file(READ "${expected_dir}/BraceInitializers.hpp" expected)
string(REPLACE "\r\n" "\n" expected "${expected}")
check("${code}" STREQUAL "${expected}")

cerial_get_structs("${data_dir}/CArrayMembers.hpp" structs)
cerial_generate_code(structs CArrayMembers.hpp code)
file(READ "${expected_dir}/CArrayMembers.hpp" expected)
string(REPLACE "\r\n" "\n" expected "${expected}")
check("${code}" STREQUAL "${expected}")

cerial_get_structs("${data_dir}/UnsupportedMembers.hpp" structs)
cerial_generate_code(structs UnsupportedMembers.hpp code)
file(READ "${expected_dir}/UnsupportedMembers.hpp" expected)
string(REPLACE "\r\n" "\n" expected "${expected}")
check("${code}" STREQUAL "${expected}")

print_test_report()
