#pragma once

#include <IgnoredDeclarations.hpp>

#include <Cerial/Byte.hpp>
#include <Cerial/Cerial.hpp>

#include <bit>
#include <cstddef>
#include <span>


template<>
constexpr auto cerial::SerialSize<ParentStruct>() -> std::size_t
{
    return SerialSize<decltype(ParentStruct::j)>();
}


template<std::endian endianness>
auto Serialize(ParentStruct const & value, std::span<cerial::Byte> destination)
    -> std::span<cerial::Byte>
{
    using cerial::Serialize;
    destination = Serialize<endianness>(value.j, destination);
    return destination;
}


template<std::endian endianness>
auto Deserialize(ParentStruct * value, std::span<cerial::Byte const> source)
    -> std::span<cerial::Byte const>
{
    using cerial::Deserialize;
    source = Deserialize<endianness>(&value->j, source);
    return source;
}
