#pragma once

#include <cstddef>


// @Cerial
struct ParentStruct
{
    // @Cerial
    struct NestedStruct
    {
        int i;
    };

    int j;

    [[nodiscard]] auto GetJ() const -> int
    {
        return j;
    }

    friend constexpr auto operator==(ParentStruct const &, ParentStruct const &) -> bool = default;
};


// @Cerial
template<typename T>
// This is an unusual place for a comment
struct SimpleStructTemplate
{
    T value;
};


// @Cerial
template<typename T, std::/* comment splitting a qualified type */ size_t size>
struct StructTemplateWithArray
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
