#pragma once

#include <cstdint>


// @Cerial
struct Point
{
    std::int16_t x;
    std::int16_t y;

    friend constexpr auto operator==(Point const &, Point const &) -> bool = default;
};
