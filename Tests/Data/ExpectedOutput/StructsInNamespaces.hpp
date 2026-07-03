#pragma once

#include <StructsInNamespaces.hpp>

#include <Cerial/Cerial.hpp>

#include <tuple>


template<>
struct cerial::Reflection<GlobalStruct>
{
    static constexpr auto members = std::tuple{&GlobalStruct::b};
};


template<>
struct cerial::Reflection<n::NamespacedStruct>
{
    static constexpr auto members = std::tuple{&n::NamespacedStruct::l};
};


template<>
struct cerial::Reflection<n::m::NestedNamespaceStruct>
{
    static constexpr auto members =
        std::tuple{&n::m::NestedNamespaceStruct::c,
                   &n::m::NestedNamespaceStruct::i,
                   &n::m::NestedNamespaceStruct::f};
};


template<>
struct cerial::Reflection<n::a::b::InlineNamespaceStruct>
{
    static constexpr auto members = std::tuple{&n::a::b::InlineNamespaceStruct::s};
};


template<>
struct cerial::Reflection<AnonymousNamespaceStruct>
{
    static constexpr auto members = std::tuple{&AnonymousNamespaceStruct::d};
};
