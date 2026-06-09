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
auto SerializeTo(std::span<cerial::Byte> destination, ParentStruct const & value)
    -> std::span<cerial::Byte>
{
    using cerial::SerializeTo;
    destination = SerializeTo<endianness>(destination, value.j);
    return destination;
}


template<std::endian endianness>
auto DeserializeFrom(std::span<cerial::Byte const> source, ParentStruct & value)
    -> std::span<cerial::Byte const>
{
    using cerial::DeserializeFrom;
    source = DeserializeFrom<endianness>(source, value.j);
    return source;
}
