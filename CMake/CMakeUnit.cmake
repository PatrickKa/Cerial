set(_cmake_unit_n_total_assertions 0)
set(_cmake_unit_n_failed_assertions 0)

function(check lhs operator rhs)
    math(EXPR _cmake_unit_n_total_assertions "${_cmake_unit_n_total_assertions} + 1")
    set(_cmake_unit_n_total_assertions "${_cmake_unit_n_total_assertions}" PARENT_SCOPE)
    # IN_LIST is the only binary operator where the right-hand side must be a variable name and not
    # a string.
    if(operator STREQUAL "IN_LIST")
        if(NOT lhs IN_LIST ${rhs})
            math(EXPR _cmake_unit_n_failed_assertions "${_cmake_unit_n_failed_assertions} + 1")
            set(_cmake_unit_n_failed_assertions "${_cmake_unit_n_failed_assertions}" PARENT_SCOPE)
            message("FAILED: '${lhs}' ${operator} '${${rhs}}'")
        endif()
    else()
        if(NOT lhs ${operator} rhs)
            math(EXPR _cmake_unit_n_failed_assertions "${_cmake_unit_n_failed_assertions} + 1")
            set(_cmake_unit_n_failed_assertions "${_cmake_unit_n_failed_assertions}" PARENT_SCOPE)
            message("FAILED: '${lhs}' ${operator} '${rhs}'")
        endif()
    endif()
endfunction()

function(print_test_report)
    if(_cmake_unit_n_failed_assertions EQUAL 0)
        set(assertion_string "assertion")
        if(_cmake_unit_n_total_assertions GREATER 1)
            set(assertion_string "assertions")
        endif()
        message("All tests passed (${_cmake_unit_n_total_assertions} ${assertion_string})")
    else()
        math(
            EXPR
            n_passed_assertions
            "${_cmake_unit_n_total_assertions} - ${_cmake_unit_n_failed_assertions}"
        )
        message(
            "Assertions: ${_cmake_unit_n_total_assertions} | "
            "${n_passed_assertions} passed | ${_cmake_unit_n_failed_assertions} failed"
        )
        cmake_language(EXIT 1)
    endif()
endfunction()
