#pragma once

#include <cstdint>


// @Cerial
struct Color
{
    std::uint8_t r;
    std::uint8_t g;
    std::uint8_t b;

    friend constexpr auto operator==(Color const &, Color const &) -> bool = default;
};
