#pragma once

#include <cstddef>


// @Cerial
struct ParentStruct
{
    struct NestedStruct
    {
        int i;
    };

    int j;
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
    int k;  // Trailing member comment
};


struct UnannotatedStruct
{
    int l;
};


struct ForwardDeclared;
