#pragma once

#include <StructsInNamespaces.hpp>

#include <Cerial/Byte.hpp>
#include <Cerial/Cerial.hpp>

#include <bit>
#include <cstddef>
#include <span>


template<>
constexpr auto cerial::SerialSize<GlobalStruct>() -> std::size_t
{
    return SerialSize<decltype(GlobalStruct::b)>();
}


template<std::endian endianness>
auto SerializeTo(std::span<cerial::Byte> destination, GlobalStruct const & value)
    -> std::span<cerial::Byte>
{
    using cerial::SerializeTo;
    destination = SerializeTo<endianness>(destination, value.b);
    return destination;
}


template<std::endian endianness>
auto DeserializeFrom(std::span<cerial::Byte const> source, GlobalStruct & value)
    -> std::span<cerial::Byte const>
{
    using cerial::DeserializeFrom;
    source = DeserializeFrom<endianness>(source, value.b);
    return source;
}


template<>
constexpr auto cerial::SerialSize<n::NamespacedStruct>() -> std::size_t
{
    return SerialSize<decltype(n::NamespacedStruct::l)>();
}


namespace n
{
template<std::endian endianness>
auto SerializeTo(std::span<cerial::Byte> destination, NamespacedStruct const & value)
    -> std::span<cerial::Byte>
{
    using cerial::SerializeTo;
    destination = SerializeTo<endianness>(destination, value.l);
    return destination;
}


template<std::endian endianness>
auto DeserializeFrom(std::span<cerial::Byte const> source, NamespacedStruct & value)
    -> std::span<cerial::Byte const>
{
    using cerial::DeserializeFrom;
    source = DeserializeFrom<endianness>(source, value.l);
    return source;
}
}


template<>
constexpr auto cerial::SerialSize<n::m::NestedNamespaceStruct>() -> std::size_t
{
    return SerialSize<decltype(n::m::NestedNamespaceStruct::c)>()
         + SerialSize<decltype(n::m::NestedNamespaceStruct::i)>()
         + SerialSize<decltype(n::m::NestedNamespaceStruct::f)>();
}


namespace n::m
{
template<std::endian endianness>
auto SerializeTo(std::span<cerial::Byte> destination, NestedNamespaceStruct const & value)
    -> std::span<cerial::Byte>
{
    using cerial::SerializeTo;
    destination = SerializeTo<endianness>(destination, value.c);
    destination = SerializeTo<endianness>(destination, value.i);
    destination = SerializeTo<endianness>(destination, value.f);
    return destination;
}


template<std::endian endianness>
auto DeserializeFrom(std::span<cerial::Byte const> source, NestedNamespaceStruct & value)
    -> std::span<cerial::Byte const>
{
    using cerial::DeserializeFrom;
    source = DeserializeFrom<endianness>(source, value.c);
    source = DeserializeFrom<endianness>(source, value.i);
    source = DeserializeFrom<endianness>(source, value.f);
    return source;
}
}


template<>
constexpr auto cerial::SerialSize<n::a::b::InlineNamespaceStruct>() -> std::size_t
{
    return SerialSize<decltype(n::a::b::InlineNamespaceStruct::s)>();
}


namespace n::a::b
{
template<std::endian endianness>
auto SerializeTo(std::span<cerial::Byte> destination, InlineNamespaceStruct const & value)
    -> std::span<cerial::Byte>
{
    using cerial::SerializeTo;
    destination = SerializeTo<endianness>(destination, value.s);
    return destination;
}


template<std::endian endianness>
auto DeserializeFrom(std::span<cerial::Byte const> source, InlineNamespaceStruct & value)
    -> std::span<cerial::Byte const>
{
    using cerial::DeserializeFrom;
    source = DeserializeFrom<endianness>(source, value.s);
    return source;
}
}


template<>
constexpr auto cerial::SerialSize<AnonymousNamespaceStruct>() -> std::size_t
{
    return SerialSize<decltype(AnonymousNamespaceStruct::d)>();
}


template<std::endian endianness>
auto SerializeTo(std::span<cerial::Byte> destination, AnonymousNamespaceStruct const & value)
    -> std::span<cerial::Byte>
{
    using cerial::SerializeTo;
    destination = SerializeTo<endianness>(destination, value.d);
    return destination;
}


template<std::endian endianness>
auto DeserializeFrom(std::span<cerial::Byte const> source, AnonymousNamespaceStruct & value)
    -> std::span<cerial::Byte const>
{
    using cerial::DeserializeFrom;
    source = DeserializeFrom<endianness>(source, value.d);
    return source;
}
