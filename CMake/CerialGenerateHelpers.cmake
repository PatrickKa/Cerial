# cerial_compute_source_include(<source_file> <include_dirs> <out_var>)
#
# Finds the most specific include directory that is a prefix of <source_file> and returns the
# relative path from that directory. Used by the build-time driver script to determine the correct
# #include path for the source header inside generated files.
function(cerial_compute_source_include source_file include_dirs out_var)
    set(best_include "")
    set(best_length -1)
    foreach(dir IN LISTS include_dirs)
        if(dir STREQUAL "")
            continue()
        endif()
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
# list of member variable names in declaration order. Static members are excluded, since they are
# not per-instance data.
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
# Takes the variable name prefix from cerial_get_structs() and generates a cerial::Reflection<T>
# specialization for each struct. <source_include> is the include path for the header containing the
# struct definitions. <out_var> is set to the generated code string.
function(cerial_generate_code structs_var source_include out_var)
    set(structs "${${structs_var}}")
    set(code "#pragma once\n")
    string(APPEND code "\n")
    string(APPEND code "#include <${source_include}>\n")
    string(APPEND code "\n")
    string(APPEND code "#include <Cerial/Cerial.hpp>\n")
    string(APPEND code "\n")
    string(APPEND code "#include <tuple>\n")
    list(LENGTH structs n_structs)
    if(n_structs GREATER 0)
        math(EXPR last "${n_structs} - 1")
        foreach(index RANGE 0 ${last})
            list(GET structs ${index} struct_name)
            set(members "${${structs_var}_members_${index}}")
            string(APPEND code "\n\n")
            _cerial_generate_reflection("${struct_name}" "${members}" snippet)
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
# BRACE_OPEN and BRACE_CLOSE are emitted for every "{" and "}" respectively, whatever the brace
# delimits: a namespace or struct body, a function body, or a member's brace initializer. This is a
# regex tokenizer, not a C++ parser, so it does not distinguish them here; the consumer in
# _cerial_process_events() relies on braces being balanced to skip over anything that is not a
# direct data member.
#
# Events: ANNOTATED_STRUCT_TEMPLATE:<name>, STRUCT_TEMPLATE:<name>, ANNOTATED_STRUCT:<name>,
#         NAMESPACE:<name>, STRUCT:<name>, BRACE_OPEN, BRACE_CLOSE
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

    # Every remaining brace becomes an event. At this point struct/namespace bodies still have their
    # opening brace, so those are captured here too, alongside function bodies and brace
    # initializers.
    string(REPLACE "{" "${separator}BRACE_OPEN${separator}" content "${content}")
    string(REPLACE "}" "${separator}BRACE_CLOSE${separator}" content "${content}")

    # Escape semicolons so that C++ statement terminators do not split list elements
    string(REPLACE ";" "\\;" content "${content}")
    string(REPLACE "${separator}" ";" events "${content}")
    set(${out_var} "${events}" PARENT_SCOPE)
endfunction()

# Consumes the event list from _cerial_build_event_stream() and produces, in <out_var>, the list of
# annotated top-level (non-nested, non-template) struct names, plus each struct's member names in
# <out_var>_members_<i>.
#
# Two pieces of state drive this:
#   - brace_names / brace_kinds: a stack of the currently-open braces. Each entry records what
#     opened the brace ("namespace", "struct", or "other" for function bodies, blocks, and brace
#     initializers) and its name. Only namespace and struct entries carry meaning; "other" entries
#     exist only to keep the stack balanced. Used to build qualified names and to reject nested
#     structs.
#   - nested_brace_depth: while collecting a struct's members, how many braces deep we are below
#     that struct's own body. Member text is only read at depth 0; anything deeper (a brace
#     initializer, a function body, a nested type) is skipped.
function(_cerial_process_events events out_var)
    set(brace_names "")
    set(brace_kinds "")
    set(result "")
    set(collecting FALSE)
    set(nested_brace_depth 0)
    set(current_struct_index -1)
    set(current_members "")

    foreach(event IN LISTS events)
        string(STRIP "${event}" event)
        if(event STREQUAL "")
            continue()
        elseif(event STREQUAL "BRACE_OPEN")
            list(APPEND brace_names "")
            list(APPEND brace_kinds "other")
            if(collecting)
                math(EXPR nested_brace_depth "${nested_brace_depth} + 1")
            endif()
        elseif(event STREQUAL "BRACE_CLOSE")
            list(LENGTH brace_names depth)
            if(depth GREATER 0)
                list(POP_BACK brace_names)
                list(POP_BACK brace_kinds)
            endif()
            if(collecting)
                if(nested_brace_depth GREATER 0)
                    math(EXPR nested_brace_depth "${nested_brace_depth} - 1")
                else()
                    set(collecting FALSE)
                    set(${out_var}_members_${current_struct_index}
                        "${current_members}"
                        PARENT_SCOPE
                    )
                endif()
            endif()
        elseif(event MATCHES "^NAMESPACE:(.*)$")
            list(APPEND brace_names "${CMAKE_MATCH_1}")
            list(APPEND brace_kinds "namespace")
        elseif(
            event
                MATCHES
                "^(STRUCT_TEMPLATE|ANNOTATED_STRUCT_TEMPLATE|ANNOTATED_STRUCT|STRUCT):(.+)$"
        )
            set(event_kind "${CMAKE_MATCH_1}")
            set(struct_name "${CMAKE_MATCH_2}")
            set(started_collecting FALSE)

            if(event_kind STREQUAL "ANNOTATED_STRUCT_TEMPLATE")
                message(
                    WARNING
                    "cerial: struct template '${struct_name}' is annotated with @Cerial but "
                    "struct templates are not supported"
                )
            elseif(event_kind STREQUAL "ANNOTATED_STRUCT")
                list(LENGTH brace_kinds depth)
                set(parent_is_struct FALSE)
                if(depth GREATER 0)
                    math(EXPR top "${depth} - 1")
                    list(GET brace_kinds ${top} parent_kind)
                    if(parent_kind STREQUAL "struct")
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
                        "${brace_names}"
                        "${brace_kinds}"
                        "${struct_name}"
                        qualified_name
                    )
                    list(APPEND result "${qualified_name}")
                    set(collecting TRUE)
                    set(nested_brace_depth 0)
                    set(current_members "")
                    set(started_collecting TRUE)
                endif()
            endif()

            list(APPEND brace_names "${struct_name}")
            list(APPEND brace_kinds "struct")
            # A struct's opening brace is absorbed into its STRUCT event rather than emitted as a
            # BRACE_OPEN, so a nested struct must bump the nested brace depth by hand. The struct we
            # just started collecting for is the exception: its body is depth 0.
            if(collecting AND NOT started_collecting)
                math(EXPR nested_brace_depth "${nested_brace_depth} + 1")
            endif()
        else()
            if(collecting AND nested_brace_depth EQUAL 0)
                _cerial_parse_member_names("${event}" new_members)
                list(APPEND current_members ${new_members})
            endif()
        endif()
    endforeach()

    set(${out_var} "${result}" PARENT_SCOPE)
endfunction()

function(_cerial_generate_reflection struct_name members out_var)
    set(member_pointers "")
    foreach(member IN LISTS members)
        list(APPEND member_pointers "&${struct_name}::${member}")
    endforeach()

    list(LENGTH member_pointers n_members)
    if(n_members EQUAL 0)
        set(initializer " std::tuple<>{}")
    elseif(n_members EQUAL 1)
        set(initializer " std::tuple{${member_pointers}}")
    else()
        # One member per line, aligned after "std::tuple{" (8 spaces indentation +
        # strlen("std::tuple{") = 19)
        string(REPEAT " " 19 alignment)
        list(JOIN member_pointers ",\n${alignment}" aligned_pointers)
        set(initializer "\n        std::tuple{${aligned_pointers}}")
    endif()
    set(members_declaration "    static constexpr auto members =${initializer};")

    set(code "template<>\n")
    string(APPEND code "struct cerial::Reflection<${struct_name}>\n")
    string(APPEND code "{\n")
    string(APPEND code "${members_declaration}\n")
    string(APPEND code "};\n")
    set(${out_var} "${code}" PARENT_SCOPE)
endfunction()

function(_cerial_join_qualified_name brace_names brace_kinds struct_name out_var)
    set(name_parts "")
    list(LENGTH brace_names depth)
    if(depth GREATER 0)
        math(EXPR last "${depth} - 1")
        foreach(index RANGE 0 ${last})
            list(GET brace_kinds ${index} brace_kind)
            if(brace_kind STREQUAL "namespace")
                list(GET brace_names ${index} namespace_name)
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
        # Skip static members. We only care about per-instance data.
        if(declaration MATCHES "^static[ \t\n]")
            continue()
        endif()
        # Strip a default member initializer so only "<type> <name>" is left for the name match
        # below. In both regexes the character class before "=" excludes the compound assignment and
        # comparison operators ("==", "<=", ">=", "!="), so operator overloads like operator==() are
        # not mangled; the captured character before "=" is preserved via \1.
        #
        # Two forms have to be handled because a brace initializer is torn apart upstream: its
        # braces become BRACE_OPEN/BRACE_CLOSE events (see _cerial_build_event_stream()), so the
        # "{...}" never reaches this point.
        #   - "int x = 5"                -> the value follows "=" on this line; strip "= <value>".
        #   - "std::array<char, 7> a ="  -> "= {}" left a dangling "="; strip the trailing "=".
        # A direct-brace initializer ("std::array<char, 7> a{}") needs no stripping here: its braces
        # are likewise gone, leaving just "<type> <name>".
        string(REGEX REPLACE "([^!<>=])=[^=].*$" "\\1" declaration "${declaration}")
        string(REGEX REPLACE "([^!<>=])=[ \t]*$" "\\1" declaration "${declaration}")
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
