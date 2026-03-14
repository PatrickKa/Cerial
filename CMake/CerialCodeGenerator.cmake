# TODO:
# - Read and try to understand the code

# cerial_get_structs(<source_file> <out_var>)
#
# Parses a C++ source file and returns a list of all non-template struct definitions with their
# fully qualified, namespace-scoped names. Structs nested inside other structs are excluded.
function(cerial_get_structs source_file out_var)
    _cerial_read_file("${source_file}" content)
    _cerial_strip_literals("${content}" content)
    _cerial_strip_comments("${content}" content)
    _cerial_strip_using_namespace("${content}" content)
    _cerial_build_event_stream("${content}" events)
    _cerial_process_events("${events}" result)
    set(${out_var} "${result}" PARENT_SCOPE)
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
    # Character literals must be stripped before string literals and comments
    # to prevent e.g. '/' or '*' from interfering with comment detection.
    string(REGEX REPLACE "'(\\\\.|[^\\\\'])'" "" content "${content}")
    string(REGEX REPLACE "\"([^\"\n\\\\]|\\\\.)*\"" "" content "${content}")
    set(${out_var} "${content}" PARENT_SCOPE)
endfunction()

function(_cerial_strip_comments content out_var)
    string(REGEX REPLACE "//[^\n]*" "" content "${content}")
    # The block-comment pattern /\*[^*]*\*+([^/*][^*]*\*+)*/ matches one
    # comment at a time without crossing comment boundaries.
    string(REGEX REPLACE "/\\*[^*]*\\*+([^/*][^*]*\\*+)*/" "" content "${content}")
    set(${out_var} "${content}" PARENT_SCOPE)
endfunction()

function(_cerial_strip_using_namespace content out_var)
    set(whitespace "${_CERIAL_WHITESPACE_PATTERN}")
    string(REGEX REPLACE "using${whitespace}+namespace[^;]*;" "" content "${content}")
    set(${out_var} "${content}" PARENT_SCOPE)
endfunction()

# Replaces syntactically meaningful tokens with delimited markers and splits
# the result into an ordered event list.
# Events: TEMPLATE_STRUCT:<name>, NAMESPACE:<name>, STRUCT:<name>, OPEN, CLOSE
function(_cerial_build_event_stream content out_var)
    set(separator "|||")
    set(identifier "${_CERIAL_IDENTIFIER_PATTERN}")
    set(whitespace "${_CERIAL_WHITESPACE_PATTERN}")

    # Template structs first so the plain struct pattern never matches them.
    string(
        REGEX REPLACE
            "template${whitespace}*<[^;{]*>${whitespace}*struct${whitespace}+(${identifier})[^;{]*\\{"
        "${separator}TEMPLATE_STRUCT:\\1${separator}"
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

    # Escape semicolons so that C++ statement terminators do not split list elements.
    string(REPLACE ";" "\\;" content "${content}")
    string(REPLACE "${separator}" ";" events "${content}")
    set(${out_var} "${events}" PARENT_SCOPE)
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
                if(NOT namespace_name STREQUAL "") # skip anonymous namespaces
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

function(_cerial_process_events events out_var)
    set(scope_names "")
    set(scope_types "")
    set(result "")

    foreach(event IN LISTS events)
        string(STRIP "${event}" event)
        if(event STREQUAL "")
            continue()
        elseif(event STREQUAL "OPEN")
            list(APPEND scope_names "")
            list(APPEND scope_types "other")
        elseif(event STREQUAL "CLOSE")
            list(LENGTH scope_names depth)
            if(depth GREATER 0)
                list(POP_BACK scope_names)
                list(POP_BACK scope_types)
            endif()
        elseif(event MATCHES "^NAMESPACE:(.*)$")
            list(APPEND scope_names "${CMAKE_MATCH_1}")
            list(APPEND scope_types "namespace")
        elseif(event MATCHES "^(TEMPLATE_STRUCT|STRUCT):(.+)$")
            set(kind "${CMAKE_MATCH_1}")
            set(struct_name "${CMAKE_MATCH_2}")

            if(kind STREQUAL "STRUCT")
                list(LENGTH scope_types depth)
                set(parent_is_struct FALSE)
                if(depth GREATER 0)
                    math(EXPR top "${depth} - 1")
                    list(GET scope_types ${top} parent_type)
                    if(parent_type STREQUAL "struct")
                        set(parent_is_struct TRUE)
                    endif()
                endif()

                if(NOT parent_is_struct)
                    _cerial_join_qualified_name(
                        "${scope_names}"
                        "${scope_types}"
                        "${struct_name}"
                        qualified_name
                    )
                    list(APPEND result "${qualified_name}")
                endif()
            endif()

            list(APPEND scope_names "${struct_name}")
            list(APPEND scope_types "struct")
        endif()
    endforeach()

    set(${out_var} "${result}" PARENT_SCOPE)
endfunction()
