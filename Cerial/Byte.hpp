#pragma once

#include <cstddef>


namespace cerial
{
using Byte = std::byte;


namespace literals
{
constexpr auto operator""_b(unsigned long long number) -> Byte
{
    return static_cast<Byte>(number);
}
}
}
