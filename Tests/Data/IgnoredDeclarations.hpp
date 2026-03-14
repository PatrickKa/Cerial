#pragma once

#include <cstddef>


struct ParentStruct
{
    struct NestedStruct
    {
        int x;
    };

    int y;
};


template<typename T>
// This is an unusual place for a comment
struct SimpleTemplateStruct
{
    T value;
};


template<typename T, std::/* comment splitting a qualified type */ size_t size>
struct ArrayTemplateStruct
{
    // Normal comment inside struct body
    T data[size];
    int i;  // Trailing member comment
};


struct ForwardDeclared;
