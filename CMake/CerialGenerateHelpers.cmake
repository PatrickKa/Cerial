# cerial_compute_source_include(<source_file> <include_dirs> <out_var>)
#
# Finds the most specific include directory that is a prefix of <source_file> and returns the
# relative path from that directory. Used by the build-time driver script to determine the correct
# #include path for the source header inside generated files.
function(cerial_compute_source_include source_file include_dirs out_var)
    set(best_include "")
    set(best_length -1)
    foreach(dir IN LISTS include_dirs)
        cmake_path(IS_PREFIX dir "${source_file}" is_prefix)
        if(is_prefix)
            cmake_path(RELATIVE_PATH source_file BASE_DIRECTORY "${dir}" OUTPUT_VARIABLE candidate)
            string(LENGTH "${dir}" dir_length)
            if(dir_length GREATER best_length)
                set(best_include "${candidate}")
                set(best_length ${dir_length})
            endif()
        endif()
    endforeach()
    if(best_include STREQUAL "")
        message(
            FATAL_ERROR
            "cerial: Could not determine include path for '${source_file}'. "
            "None of the target's include directories is a prefix of this file."
        )
    endif()
    set(${out_var} "${best_include}" PARENT_SCOPE)
endfunction()

# cerial_get_structs(<source_file> <out_var>)
#
# Parses a C++ source file and returns a list of all struct definitions annotated with "// @Cerial",
# with their fully qualified, namespace-scoped names. Template structs and structs nested inside
# other structs are excluded.
#
# For each struct at index <i> in the returned list, also sets <out_var>_members_<i> to contain the
# list of member variable names in declaration order
function(cerial_get_structs source_file out_var)
    _cerial_read_file("${source_file}" content)
    _cerial_strip_literals("${content}" content)
    _cerial_mark_annotations("${content}" content)
    _cerial_strip_comments("${content}" content)
    _cerial_strip_using_namespace("${content}" content)
    _cerial_build_event_stream("${content}" events)
    _cerial_process_events("${events}" result)
    set(${out_var} "${result}" PARENT_SCOPE)
    list(LENGTH result n_structs)
    if(n_structs GREATER 0)
        math(EXPR last "${n_structs} - 1")
        foreach(index RANGE 0 ${last})
            set(${out_var}_members_${index} "${result_members_${index}}" PARENT_SCOPE)
        endforeach()
    endif()
endfunction()

# cerial_generate_code(<structs_var> <source_include> <out_var>)
#
# Takes the variable name prefix from cerial_get_structs and generates C++ serialization code.
# Generates SerialSize, Serialize, and Deserialize for each struct, grouped by struct.
# <source_include> is the include path for the header containing the struct definitions. Sets
# <out_var> to the generated code string.
function(cerial_generate_code structs_var source_include out_var)
    set(structs "${${structs_var}}")
    set(code "#pragma once\n")
    string(APPEND code "\n")
    string(APPEND code "#include <${source_include}>\n")
    string(APPEND code "\n")
    string(APPEND code "#include <Cerial/Byte.hpp>\n")
    string(APPEND code "#include <Cerial/Cerial.hpp>\n")
    string(APPEND code "\n")
    string(APPEND code "#include <bit>\n")
    string(APPEND code "#include <cstddef>\n")
    string(APPEND code "#include <span>\n")
    list(LENGTH structs n_structs)
    if(n_structs GREATER 0)
        math(EXPR last "${n_structs} - 1")
        foreach(index RANGE 0 ${last})
            list(GET structs ${index} struct_name)
            set(members "${${structs_var}_members_${index}}")
            string(APPEND code "\n\n")
            _cerial_generate_struct_serialization("${struct_name}" "${members}" snippet)
            string(APPEND code "${snippet}")
        endforeach()
    endif()
    set(${out_var} "${code}" PARENT_SCOPE)
endfunction()

# --- Private variables ---

set(_CERIAL_IDENTIFIER_PATTERN "[A-Za-z_][A-Za-z0-9_]*")
set(_CERIAL_WHITESPACE_PATTERN "[ \t\n]")

# --- Private functions ---

function(_cerial_read_file source_file out_var)
    if(NOT EXISTS "${source_file}")
        message(FATAL_ERROR "get_structs: file does not exist: ${source_file}")
    endif()
    file(READ "${source_file}" content)
    string(REPLACE "\r\n" "\n" content "${content}")
    string(REPLACE "\r" "\n" content "${content}")
    set(${out_var} "${content}" PARENT_SCOPE)
endfunction()

function(_cerial_strip_literals content out_var)
    # Character literals must be stripped before string literals and comments to prevent e.g. '/' or
    # '*' from interfering with comment detection
    string(REGEX REPLACE "'(\\\\.|[^\\\\'])'" "" content "${content}")
    string(REGEX REPLACE "\"([^\"\n\\\\]|\\\\.)*\"" "" content "${content}")
    set(${out_var} "${content}" PARENT_SCOPE)
endfunction()

function(_cerial_mark_annotations content out_var)
    # Replace "// @Cerial" annotation comments with a marker that survives comment stripping. The @
    # character does not appear in valid C++ outside of literals (already stripped).
    string(REGEX REPLACE "//[ \t]*@Cerial[ \t]*\n" "@CERIAL\n" content "${content}")
    set(${out_var} "${content}" PARENT_SCOPE)
endfunction()

function(_cerial_strip_comments content out_var)
    string(REGEX REPLACE "//[^\n]*" "" content "${content}")
    # The block-comment pattern /\*[^*]*\*+([^/*][^*]*\*+)*/ matches one comment at a time without
    # crossing comment boundaries
    string(REGEX REPLACE "/\\*[^*]*\\*+([^/*][^*]*\\*+)*/" "" content "${content}")
    set(${out_var} "${content}" PARENT_SCOPE)
endfunction()

function(_cerial_strip_using_namespace content out_var)
    set(whitespace "${_CERIAL_WHITESPACE_PATTERN}")
    string(REGEX REPLACE "using${whitespace}+namespace[^;]*;" "" content "${content}")
    set(${out_var} "${content}" PARENT_SCOPE)
endfunction()

# Replaces syntactically meaningful tokens with delimited markers and splits the result into an
# ordered event list.
#
# Events: ANNOTATED_STRUCT_TEMPLATE:<name>, STRUCT_TEMPLATE:<name>, ANNOTATED_STRUCT:<name>,
#         NAMESPACE:<name>, STRUCT:<name>, OPEN, CLOSE
function(_cerial_build_event_stream content out_var)
    set(separator "|||")
    set(identifier "${_CERIAL_IDENTIFIER_PATTERN}")
    set(whitespace "${_CERIAL_WHITESPACE_PATTERN}")

    # Annotated struct templates before plain struct templates so we can warn the user that they
    # are not supported
    string(
        REGEX REPLACE
            "@CERIAL${whitespace}*template${whitespace}*<[^;{]*>${whitespace}*struct${whitespace}+(${identifier})[^;{]*\\{"
        "${separator}ANNOTATED_STRUCT_TEMPLATE:\\1${separator}"
        content
        "${content}"
    )

    # Struct templates before plain structs so the plain struct pattern never matches them
    string(
        REGEX REPLACE
            "template${whitespace}*<[^;{]*>${whitespace}*struct${whitespace}+(${identifier})[^;{]*\\{"
        "${separator}STRUCT_TEMPLATE:\\1${separator}"
        content
        "${content}"
    )

    # Annotated structs before plain structs so the plain pattern does not consume them
    string(
        REGEX REPLACE "@CERIAL${whitespace}*struct${whitespace}+(${identifier})[^;{]*\\{"
        "${separator}ANNOTATED_STRUCT:\\1${separator}"
        content
        "${content}"
    )

    string(
        REGEX REPLACE "namespace${whitespace}+(${identifier}(::${identifier})*)${whitespace}*\\{"
        "${separator}NAMESPACE:\\1${separator}"
        content
        "${content}"
    )

    string(
        REGEX REPLACE "namespace${whitespace}*\\{"
        "${separator}NAMESPACE:${separator}"
        content
        "${content}"
    )

    string(
        REGEX REPLACE "struct${whitespace}+(${identifier})[^;{]*\\{"
        "${separator}STRUCT:\\1${separator}"
        content
        "${content}"
    )

    string(REPLACE "{" "${separator}OPEN${separator}" content "${content}")
    string(REPLACE "}" "${separator}CLOSE${separator}" content "${content}")

    # Escape semicolons so that C++ statement terminators do not split list elements
    string(REPLACE ";" "\\;" content "${content}")
    string(REPLACE "${separator}" ";" events "${content}")
    set(${out_var} "${events}" PARENT_SCOPE)
endfunction()

function(_cerial_process_events events out_var)
    set(scope_names "")
    set(scope_types "")
    set(result "")
    set(collecting FALSE)
    set(member_depth 0)
    set(current_struct_index -1)
    set(current_members "")

    foreach(event IN LISTS events)
        string(STRIP "${event}" event)
        if(event STREQUAL "")
            continue()
        elseif(event STREQUAL "OPEN")
            list(APPEND scope_names "")
            list(APPEND scope_types "other")
            if(collecting)
                math(EXPR member_depth "${member_depth} + 1")
            endif()
        elseif(event STREQUAL "CLOSE")
            list(LENGTH scope_names depth)
            if(depth GREATER 0)
                list(POP_BACK scope_names)
                list(POP_BACK scope_types)
            endif()
            if(collecting)
                if(member_depth GREATER 0)
                    math(EXPR member_depth "${member_depth} - 1")
                else()
                    set(collecting FALSE)
                    set(${out_var}_members_${current_struct_index}
                        "${current_members}"
                        PARENT_SCOPE
                    )
                endif()
            endif()
        elseif(event MATCHES "^NAMESPACE:(.*)$")
            list(APPEND scope_names "${CMAKE_MATCH_1}")
            list(APPEND scope_types "namespace")
        elseif(
            event
                MATCHES
                "^(STRUCT_TEMPLATE|ANNOTATED_STRUCT_TEMPLATE|ANNOTATED_STRUCT|STRUCT):(.+)$"
        )
            set(kind "${CMAKE_MATCH_1}")
            set(struct_name "${CMAKE_MATCH_2}")
            set(started_collecting FALSE)

            if(kind STREQUAL "ANNOTATED_STRUCT_TEMPLATE")
                message(
                    WARNING
                    "cerial: struct template '${struct_name}' is annotated with @Cerial but "
                    "struct templates are not supported"
                )
            elseif(kind STREQUAL "ANNOTATED_STRUCT")
                list(LENGTH scope_types depth)
                set(parent_is_struct FALSE)
                if(depth GREATER 0)
                    math(EXPR top "${depth} - 1")
                    list(GET scope_types ${top} parent_type)
                    if(parent_type STREQUAL "struct")
                        set(parent_is_struct TRUE)
                    endif()
                endif()

                if(parent_is_struct)
                    message(
                        WARNING
                        "cerial: nested struct '${struct_name}' is annotated with @Cerial but "
                        "nested structs are not supported"
                    )
                else()
                    list(LENGTH result current_struct_index)
                    _cerial_join_qualified_name(
                        "${scope_names}"
                        "${scope_types}"
                        "${struct_name}"
                        qualified_name
                    )
                    list(APPEND result "${qualified_name}")
                    set(collecting TRUE)
                    set(member_depth 0)
                    set(current_members "")
                    set(started_collecting TRUE)
                endif()
            endif()

            list(APPEND scope_names "${struct_name}")
            list(APPEND scope_types "struct")
            # Nested structs consume their opening brace, so they increase member depth.
            # But the struct we just started collecting for does not.
            if(collecting AND NOT started_collecting)
                math(EXPR member_depth "${member_depth} + 1")
            endif()
        else()
            if(collecting AND member_depth EQUAL 0)
                _cerial_parse_member_names("${event}" new_members)
                list(APPEND current_members ${new_members})
            endif()
        endif()
    endforeach()

    set(${out_var} "${result}" PARENT_SCOPE)
endfunction()

function(_cerial_generate_struct_serialization struct_name members out_var)
    _cerial_split_qualified_name("${struct_name}" namespace_part bare_name)

    _cerial_generate_serial_size("${struct_name}" "${members}" code)
    _cerial_generate_serialize("${bare_name}" "${members}" serialize_code)
    _cerial_generate_deserialize("${bare_name}" "${members}" deserialize_code)

    string(APPEND code "\n\n")
    if(NOT namespace_part STREQUAL "")
        string(APPEND code "namespace ${namespace_part}\n")
        string(APPEND code "{\n")
        string(APPEND code "${serialize_code}\n\n")
        string(APPEND code "${deserialize_code}")
        string(APPEND code "}\n")
    else()
        string(APPEND code "${serialize_code}\n\n")
        string(APPEND code "${deserialize_code}")
    endif()

    set(${out_var} "${code}" PARENT_SCOPE)
endfunction()

function(_cerial_split_qualified_name qualified_name out_namespace out_name)
    string(FIND "${qualified_name}" "::" last_separator REVERSE)
    if(last_separator EQUAL -1)
        set(${out_namespace} "" PARENT_SCOPE)
        set(${out_name} "${qualified_name}" PARENT_SCOPE)
    else()
        string(SUBSTRING "${qualified_name}" 0 ${last_separator} namespace_part)
        math(EXPR name_start "${last_separator} + 2")
        string(SUBSTRING "${qualified_name}" ${name_start} -1 bare_name)
        set(${out_namespace} "${namespace_part}" PARENT_SCOPE)
        set(${out_name} "${bare_name}" PARENT_SCOPE)
    endif()
endfunction()

function(_cerial_generate_serial_size struct_name members out_var)
    set(terms "")
    foreach(member IN LISTS members)
        list(APPEND terms "SerialSize<decltype(${struct_name}::${member})>()")
    endforeach()
    if(terms)
        list(JOIN terms "\n         + " return_expression)
    else()
        set(return_expression "0")
    endif()
    set(code "template<>\n")
    string(APPEND code "constexpr auto cerial::SerialSize<${struct_name}>() -> std::size_t\n")
    string(APPEND code "{\n")
    string(APPEND code "    return ${return_expression};\n")
    string(APPEND code "}\n")
    set(${out_var} "${code}" PARENT_SCOPE)
endfunction()

function(_cerial_generate_serialize bare_name members out_var)
    set(code "template<std::endian endianness>\n")
    string(
        APPEND code
        "auto Serialize(${bare_name} const & value, std::span<cerial::Byte> destination)\n"
    )
    string(APPEND code "    -> std::span<cerial::Byte>\n")
    string(APPEND code "{\n")
    string(APPEND code "    using cerial::Serialize;\n")
    foreach(member IN LISTS members)
        string(
            APPEND code
            "    destination = Serialize<endianness>(value.${member}, destination);\n"
        )
    endforeach()
    string(APPEND code "    return destination;\n")
    string(APPEND code "}\n")
    set(${out_var} "${code}" PARENT_SCOPE)
endfunction()

function(_cerial_generate_deserialize bare_name members out_var)
    set(code "template<std::endian endianness>\n")
    string(
        APPEND code
        "auto Deserialize(${bare_name} * value, std::span<cerial::Byte const> source)\n"
    )
    string(APPEND code "    -> std::span<cerial::Byte const>\n")
    string(APPEND code "{\n")
    string(APPEND code "    using cerial::Deserialize;\n")
    foreach(member IN LISTS members)
        string(APPEND code "    source = Deserialize<endianness>(&value->${member}, source);\n")
    endforeach()
    string(APPEND code "    return source;\n")
    string(APPEND code "}\n")
    set(${out_var} "${code}" PARENT_SCOPE)
endfunction()

function(_cerial_join_qualified_name scope_names scope_types struct_name out_var)
    set(name_parts "")
    list(LENGTH scope_names depth)
    if(depth GREATER 0)
        math(EXPR last "${depth} - 1")
        foreach(index RANGE 0 ${last})
            list(GET scope_types ${index} scope_type)
            if(scope_type STREQUAL "namespace")
                list(GET scope_names ${index} namespace_name)
                if(NOT namespace_name STREQUAL "") # Skip anonymous namespaces
                    # Handle inline namespace declarations (e.g. namespace a::b::c)
                    string(REPLACE "::" ";" namespace_parts "${namespace_name}")
                    foreach(part IN LISTS namespace_parts)
                        list(APPEND name_parts "${part}")
                    endforeach()
                endif()
            endif()
        endforeach()
    endif()
    list(APPEND name_parts "${struct_name}")
    list(JOIN name_parts "::" qualified_name)
    set(${out_var} "${qualified_name}" PARENT_SCOPE)
endfunction()

function(_cerial_parse_member_names text out_var)
    set(identifier "${_CERIAL_IDENTIFIER_PATTERN}")
    set(names "")
    # The text contains literal semicolons (preserved by escaping in the event stream).
    # Treating it as a list splits by semicolons to get individual declarations.
    foreach(declaration IN LISTS text)
        string(STRIP "${declaration}" declaration)
        if(declaration STREQUAL "")
            continue()
        endif()
        # Strip default value initializers (e.g. "int x = 5" -> "int x"). The character classes
        # around `=` exclude assignment operators that are part of `==`, `<=`, `>=`, `!=` so that
        # operator overloads like operator==() are not mangled. The captured character before `=`
        # is preserved via \1.
        string(REGEX REPLACE "([^!<>=])=[^=].*$" "\\1" declaration "${declaration}")
        string(STRIP "${declaration}" declaration)
        # Skip declarations containing parentheses. These are member or friend function
        # declarations, not data members. Function pointers happen to be skipped too, but those
        # are not directly serializable anyway.
        if(declaration MATCHES "\\(")
            continue()
        endif()
        # The greedy .+ matches the type, then backtracks to leave the last identifier as the name
        if(declaration MATCHES "^.+[ \t]+(${identifier})$")
            list(APPEND names "${CMAKE_MATCH_1}")
        endif()
    endforeach()
    set(${out_var} "${names}" PARENT_SCOPE)
endfunction()
