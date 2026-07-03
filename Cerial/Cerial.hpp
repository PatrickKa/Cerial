#pragma once

#include <Cerial/Byte.hpp>

#include <array>
#include <bit>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <span>
#include <tuple>
#include <type_traits>
#include <utility>


namespace cerial
{
// --- Reflection types ---

// Specializing Reflection<T> with a static constexpr tuple of pointers-to-members named "members"
// is all it takes for a user-defined type to get first-class Cerial support. The primary template
// is intentionally left undefined, so that unregistered types are detected via the Reflected
// concept.
template<typename T>
struct Reflection;


namespace internal
{
template<typename Member>
struct MemberTypeHelper;


template<typename Class, typename Value>
struct MemberTypeHelper<Value Class::*>
{
    using Type = Value;
};
}


template<typename T>
using MemberType = typename internal::MemberTypeHelper<std::remove_cvref_t<T>>::Type;


// --- Concepts and traits ---

template<typename T>
concept TriviallySerializable = std::is_arithmetic_v<T> || std::is_enum_v<T>;

template<typename T>
concept ByteOrderSensitive = (std::is_arithmetic_v<T> || std::is_enum_v<T>) && sizeof(T) > 1;

template<typename T>
inline constexpr auto isStdArray = false;

template<typename T, std::size_t size>
inline constexpr auto isStdArray<std::array<T, size>> = true;

template<typename T>
concept StdArray = isStdArray<T>;

template<typename T>
concept Reflected = requires { Reflection<T>::members; };

// Must be specialized for non-reflected user-defined types that appear in reflected user-defined
// types
template<typename T>
inline constexpr auto isStaticallySized = TriviallySerializable<T>;

template<typename T, std::size_t size>
inline constexpr auto isStaticallySized<std::array<T, size>> = isStaticallySized<T>;

template<Reflected T>
inline constexpr auto isStaticallySized<T> = []<typename... Members>(std::tuple<Members...> const &)
{ return (isStaticallySized<MemberType<Members>> && ... && true); }(Reflection<T>::members);

template<typename T>
concept StaticallySized = isStaticallySized<T>;

template<typename T>
concept DynamicContiguousRange = requires(T & t) {
    { t.data() };
    { t.size() } -> std::convertible_to<std::size_t>;
    t.begin();
    t.end();
    t.clear();  // Simplest test I could come up with to check if a range has dynamic or static size
};


// --- Function declarations and type aliases ---

// Must be specialized or overloaded for non-reflected user-defined types. The primary template is
// intentionally left undefined, so that a missing specialization is a compiler error.
template<typename T>
constexpr auto SerialSize() -> std::size_t;

template<TriviallySerializable T>
constexpr auto SerialSize() -> std::size_t;

template<StdArray T>
    requires StaticallySized<T>
constexpr auto SerialSize() -> std::size_t;

template<Reflected T>
    requires StaticallySized<T>
constexpr auto SerialSize() -> std::size_t;

// Runtime counterpart to SerialSize<T>(). Must be specialized for dynamically sized non-reflected
// user-defined types. The primary template forwards to SerialSize<T>().
template<typename T>
constexpr auto SerialSize(T const & t) -> std::size_t;

template<StdArray T>
    requires(!StaticallySized<T>)
constexpr auto SerialSize(T const & array) -> std::size_t;

template<DynamicContiguousRange T>
constexpr auto SerialSize(T const & range) -> std::size_t;

template<Reflected T>
    requires(!StaticallySized<T>)
constexpr auto SerialSize(T const & t) -> std::size_t;


template<typename T>
using Buffer = std::array<Byte, SerialSize<T>()>;

template<typename T>
using BufferView = std::span<Byte const, SerialSize<T>()>;


template<std::endian endianness, typename T>
[[nodiscard]] auto Serialize(T const & t) -> Buffer<T>;

template<std::endian endianness, std::default_initializable T>
[[nodiscard]] auto Deserialize(BufferView<T> bufferView) -> T;

// Must be overloaded for non-reflected user-defined types to be serializable
template<std::endian endianness, TriviallySerializable T>
auto SerializeTo(std::span<Byte> destination, T t) -> std::span<Byte>;

// Must be overloaded for non-reflected user-defined types to be deserializable
template<std::endian endianness, TriviallySerializable T>
auto DeserializeFrom(std::span<Byte const> source, T & t) -> std::span<Byte const>;

template<std::endian endianness, StdArray T>
auto SerializeTo(std::span<Byte> destination, T const & array) -> std::span<Byte>;

template<std::endian endianness, StdArray T>
auto DeserializeFrom(std::span<Byte const> source, T & array) -> std::span<Byte const>;

template<std::endian endianness, DynamicContiguousRange T>
auto SerializeTo(std::span<Byte> destination, T const & range) -> std::span<Byte>;

// Deserializes into the range's existing elements, so the caller must size the range beforehand
template<std::endian endianness, DynamicContiguousRange T>
auto DeserializeFrom(std::span<Byte const> source, T & range) -> std::span<Byte const>;

template<std::endian endianness, Reflected T>
auto SerializeTo(std::span<Byte> destination, T const & t) -> std::span<Byte>;

template<std::endian endianness, Reflected T>
auto DeserializeFrom(std::span<Byte const> source, T & t) -> std::span<Byte const>;


template<ByteOrderSensitive T>
constexpr auto ReverseBytes(T t) -> T;


// --- Function definitions ---

template<TriviallySerializable T>
constexpr auto SerialSize() -> std::size_t
{
    return sizeof(T);
}


template<StdArray T>
    requires StaticallySized<T>
constexpr auto SerialSize() -> std::size_t
{
    return SerialSize<typename T::value_type>() * std::tuple_size_v<T>;
}


template<Reflected T>
    requires StaticallySized<T>
constexpr auto SerialSize() -> std::size_t
{
    return []<typename... Members>(std::tuple<Members...> const &)
    { return (SerialSize<MemberType<Members>>() + ... + 0UZ); }(Reflection<T>::members);
}


template<typename T>
constexpr auto SerialSize(T const & /*t*/) -> std::size_t
{
    return SerialSize<T>();
}


template<StdArray T>
    requires(!StaticallySized<T>)
constexpr auto SerialSize(T const & array) -> std::size_t
{
    auto sum = 0UZ;
    for(auto && element : array)
    {
        sum += SerialSize(element);
    }
    return sum;
}


template<DynamicContiguousRange T>
constexpr auto SerialSize(T const & range) -> std::size_t
{
    using Element = std::remove_cvref_t<decltype(*range.data())>;
    if constexpr(StaticallySized<Element>)
    {
        return range.size() * SerialSize<Element>();
    }
    else  // Without this else branch MSVC emits warnings about unreachable code
    {
        auto sum = 0UZ;
        for(auto && element : range)
        {
            sum += SerialSize(element);
        }
        return sum;
    }
}


template<Reflected T>
    requires(!StaticallySized<T>)
constexpr auto SerialSize(T const & t) -> std::size_t
{
    return std::apply([&](auto... members) { return (SerialSize(t.*members) + ... + 0UZ); },
                      Reflection<T>::members);
}


template<std::endian endianness, typename T>
[[nodiscard]] auto Serialize(T const & t) -> Buffer<T>
{
    auto buffer = Buffer<T>{};
    SerializeTo<endianness>(std::span(buffer), t);
    return buffer;
}


template<std::endian endianness, std::default_initializable T>
[[nodiscard]] auto Deserialize(BufferView<T> bufferView) -> T
{
    auto t = T{};
    DeserializeFrom<endianness>(bufferView, t);
    return t;
}


template<std::endian endianness, TriviallySerializable T>
auto SerializeTo(std::span<Byte> destination, T t) -> std::span<Byte>
{
    if constexpr(ByteOrderSensitive<T> && endianness != std::endian::native)
    {
        t = ReverseBytes(t);
    }
    std::memcpy(destination.data(), &t, SerialSize<T>());
    return destination.subspan(SerialSize<T>());
}


template<std::endian endianness, TriviallySerializable T>
auto DeserializeFrom(std::span<Byte const> source, T & t) -> std::span<Byte const>
{
    std::memcpy(&t, source.data(), SerialSize<T>());
    if constexpr(ByteOrderSensitive<T> && endianness != std::endian::native)
    {
        t = ReverseBytes(t);
    }
    return source.subspan(SerialSize<T>());
}


template<std::endian endianness, StdArray T>
auto SerializeTo(std::span<Byte> destination, T const & array) -> std::span<Byte>
{
    for(auto && element : array)
    {
        destination = SerializeTo<endianness>(destination, element);
    }
    return destination;
}


template<std::endian endianness, StdArray T>
auto DeserializeFrom(std::span<Byte const> source, T & array) -> std::span<Byte const>
{
    for(auto && element : array)
    {
        source = DeserializeFrom<endianness>(source, element);
    }
    return source;
}


template<std::endian endianness, DynamicContiguousRange T>
auto SerializeTo(std::span<Byte> destination, T const & range) -> std::span<Byte>
{
    for(auto && element : range)
    {
        destination = SerializeTo<endianness>(destination, element);
    }
    return destination;
}


template<std::endian endianness, DynamicContiguousRange T>
auto DeserializeFrom(std::span<Byte const> source, T & range) -> std::span<Byte const>
{
    for(auto && element : range)
    {
        source = DeserializeFrom<endianness>(source, element);
    }
    return source;
}


template<std::endian endianness, Reflected T>
auto SerializeTo(std::span<Byte> destination, T const & t) -> std::span<Byte>
{
    std::apply([&](auto... members)
               { ((destination = SerializeTo<endianness>(destination, t.*members)), ...); },
               Reflection<T>::members);
    return destination;
}


template<std::endian endianness, Reflected T>
auto DeserializeFrom(std::span<Byte const> source, T & t) -> std::span<Byte const>
{
    std::apply([&](auto... members)
               { ((source = DeserializeFrom<endianness>(source, t.*members)), ...); },
               Reflection<T>::members);
    return source;
}


template<ByteOrderSensitive T>
constexpr auto ReverseBytes(T t) -> T
{
    if constexpr(std::integral<T>)
    {
        return std::byteswap(t);
    }
    else if constexpr(std::is_enum_v<T>)
    {
        return static_cast<T>(std::byteswap(std::to_underlying(t)));
    }
    else if constexpr(std::floating_point<T>)
    {
        using UnsignedInt = std::conditional_t<sizeof(T) == 4, std::uint32_t, std::uint64_t>;
        return std::bit_cast<T>(std::byteswap(std::bit_cast<UnsignedInt>(t)));
    }
    else
    {
        static_assert(false);
    }
}


// --- Compile time checks ---

static_assert(TriviallySerializable<bool>);
static_assert(TriviallySerializable<char>);
static_assert(TriviallySerializable<int>);
static_assert(TriviallySerializable<unsigned long long>);
static_assert(TriviallySerializable<float>);
static_assert(TriviallySerializable<double>);
static_assert(!TriviallySerializable<void *>);

static_assert(!ByteOrderSensitive<bool>);
static_assert(!ByteOrderSensitive<char>);
static_assert(ByteOrderSensitive<int>);
static_assert(ByteOrderSensitive<unsigned long long>);
static_assert(ByteOrderSensitive<float>);
static_assert(ByteOrderSensitive<double>);
static_assert(!ByteOrderSensitive<void *>);

static_assert(SerialSize<bool>() == 1);
static_assert(SerialSize<char>() == 1);
static_assert(SerialSize<int>() == sizeof(int));
static_assert(SerialSize<unsigned long long>() == sizeof(unsigned long long));
// static_assert(SerialSize<void *>() == 4);  // "Undefined function 'SerialSize<void *>' ..."

static_assert(SerialSize<std::array<char, 2>>() == 2);
static_assert(SerialSize<std::array<std::array<float, 2>, 3>>() == 4 * 3 * 2);

static_assert(StaticallySized<int>);
static_assert(StaticallySized<std::array<int, 4>>);
static_assert(StaticallySized<std::array<std::array<float, 2>, 3>>);
static_assert(!StaticallySized<void *>);

// The runtime SerialSize() is usable in a constant expression for statically sized types
static_assert(SerialSize(1) == sizeof(int));
static_assert(SerialSize(std::array<char, 2>{}) == 2);
}
