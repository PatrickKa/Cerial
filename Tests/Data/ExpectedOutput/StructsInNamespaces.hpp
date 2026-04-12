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
auto Serialize(GlobalStruct const & value, std::span<cerial::Byte> destination)
    -> std::span<cerial::Byte>
{
    using cerial::Serialize;
    destination = Serialize<endianness>(value.b, destination);
    return destination;
}


template<std::endian endianness>
auto Deserialize(GlobalStruct * value, std::span<cerial::Byte const> source)
    -> std::span<cerial::Byte const>
{
    using cerial::Deserialize;
    source = Deserialize<endianness>(&value->b, source);
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
auto Serialize(NamespacedStruct const & value, std::span<cerial::Byte> destination)
    -> std::span<cerial::Byte>
{
    using cerial::Serialize;
    destination = Serialize<endianness>(value.l, destination);
    return destination;
}


template<std::endian endianness>
auto Deserialize(NamespacedStruct * value, std::span<cerial::Byte const> source)
    -> std::span<cerial::Byte const>
{
    using cerial::Deserialize;
    source = Deserialize<endianness>(&value->l, source);
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
auto Serialize(NestedNamespaceStruct const & value, std::span<cerial::Byte> destination)
    -> std::span<cerial::Byte>
{
    using cerial::Serialize;
    destination = Serialize<endianness>(value.c, destination);
    destination = Serialize<endianness>(value.i, destination);
    destination = Serialize<endianness>(value.f, destination);
    return destination;
}


template<std::endian endianness>
auto Deserialize(NestedNamespaceStruct * value, std::span<cerial::Byte const> source)
    -> std::span<cerial::Byte const>
{
    using cerial::Deserialize;
    source = Deserialize<endianness>(&value->c, source);
    source = Deserialize<endianness>(&value->i, source);
    source = Deserialize<endianness>(&value->f, source);
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
auto Serialize(InlineNamespaceStruct const & value, std::span<cerial::Byte> destination)
    -> std::span<cerial::Byte>
{
    using cerial::Serialize;
    destination = Serialize<endianness>(value.s, destination);
    return destination;
}


template<std::endian endianness>
auto Deserialize(InlineNamespaceStruct * value, std::span<cerial::Byte const> source)
    -> std::span<cerial::Byte const>
{
    using cerial::Deserialize;
    source = Deserialize<endianness>(&value->s, source);
    return source;
}
}


template<>
constexpr auto cerial::SerialSize<AnonymousNamespaceStruct>() -> std::size_t
{
    return SerialSize<decltype(AnonymousNamespaceStruct::d)>();
}


template<std::endian endianness>
auto Serialize(AnonymousNamespaceStruct const & value, std::span<cerial::Byte> destination)
    -> std::span<cerial::Byte>
{
    using cerial::Serialize;
    destination = Serialize<endianness>(value.d, destination);
    return destination;
}


template<std::endian endianness>
auto Deserialize(AnonymousNamespaceStruct * value, std::span<cerial::Byte const> source)
    -> std::span<cerial::Byte const>
{
    using cerial::Deserialize;
    source = Deserialize<endianness>(&value->d, source);
    return source;
}
