#pragma once

#include <IgnoredDeclarations.hpp>

#include <Cerial/Cerial.hpp>

#include <tuple>


template<>
struct cerial::Reflection<ParentStruct>
{
    static constexpr auto members = std::tuple{&ParentStruct::j};
};
