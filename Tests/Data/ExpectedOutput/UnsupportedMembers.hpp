#pragma once

#include <UnsupportedMembers.hpp>

#include <Cerial/Cerial.hpp>

#include <tuple>


template<>
struct cerial::Reflection<UnsupportedMembers>
{
    static constexpr auto members =
        std::tuple{&UnsupportedMembers::supported,
                   &UnsupportedMembers::alsoSupported};
};
