#pragma once

#include <CArrayMembers.hpp>

#include <Cerial/Cerial.hpp>

#include <tuple>


template<>
struct cerial::Reflection<CArrayMembers>
{
    static constexpr auto members =
        std::tuple{&CArrayMembers::scalar,
                   &CArrayMembers::trailing};
};
