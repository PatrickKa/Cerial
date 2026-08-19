#pragma once

#include <BraceInitializers.hpp>

#include <Cerial/Cerial.hpp>

#include <tuple>


template<>
struct cerial::Reflection<BraceInitializers>
{
    static constexpr auto members =
        std::tuple{&BraceInitializers::scalar,
                   &BraceInitializers::assignEmptyBrace,
                   &BraceInitializers::assignFilledBrace,
                   &BraceInitializers::directBrace,
                   &BraceInitializers::noInit,
                   &BraceInitializers::trailing};
};
