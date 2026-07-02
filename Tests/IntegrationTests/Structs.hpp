#pragma once

#include <cstdint>
#include <vector>


// @Cerial
struct Point
{
    std::int16_t x;
    std::int16_t y;

    friend constexpr auto operator==(Point const &, Point const &) -> bool = default;
};


// @Cerial
struct Packet
{
    std::uint8_t id;
    std::vector<std::int16_t> payload;

    friend auto operator==(Packet const &, Packet const &) -> bool = default;
};
