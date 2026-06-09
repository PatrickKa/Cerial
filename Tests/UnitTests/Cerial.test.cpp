#include <Cerial/Cerial.hpp>

#include <Cerial/Byte.hpp>

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <span>
#include <type_traits>


using cerial::Byte;
using cerial::Deserialize;
using cerial::Serialize;
using cerial::operator""_b;


// These compile-time checks are not in Cerial.hpp to prevent leaking the test enums and structs
TEST_CASE("TriviallySerializable and ByteOrderSensitive")
{
    using cerial::ByteOrderSensitive;
    using cerial::TriviallySerializable;

    enum ClassicEnum
    {
        one,
    };
    enum class ScopedEnum
    {
        one,
    };

    struct EmptyStruct
    {};
    struct SingleInt32
    {
        std::int32_t i = 0;
    };

    STATIC_CHECK(TriviallySerializable<ClassicEnum>);
    STATIC_CHECK(TriviallySerializable<ScopedEnum>);
    STATIC_CHECK(TriviallySerializable<EmptyStruct> == false);
    STATIC_CHECK(TriviallySerializable<SingleInt32> == false);

    STATIC_CHECK(ByteOrderSensitive<ClassicEnum>);
    STATIC_CHECK(ByteOrderSensitive<ScopedEnum>);
    STATIC_CHECK(ByteOrderSensitive<EmptyStruct> == false);
    STATIC_CHECK(ByteOrderSensitive<SingleInt32> == false);
}


TEST_CASE("Serialize TriviallySerializable types")
{
    SECTION("Little endian")
    {
        auto boolBuffer = Serialize<std::endian::little>(true);
        auto byteBuffer = Serialize<std::endian::little>(std::byte{0xAA});
        auto int8Buffer = Serialize<std::endian::little>(static_cast<std::int8_t>(-4));
        auto uint16Buffer = Serialize<std::endian::little>(static_cast<std::uint16_t>(11));
        auto int32Buffer = Serialize<std::endian::little>(static_cast<std::int32_t>(-2));
        auto uint64Buffer =
            Serialize<std::endian::little>(static_cast<std::uint64_t>(0x0102'0304'0506'0708));

        STATIC_CHECK(std::is_same_v<decltype(boolBuffer), std::array<Byte, sizeof(bool)>>);
        STATIC_CHECK(std::is_same_v<decltype(byteBuffer), std::array<Byte, sizeof(std::byte)>>);
        STATIC_CHECK(std::is_same_v<decltype(int8Buffer), std::array<Byte, sizeof(std::int8_t)>>);
        STATIC_CHECK(
            std::is_same_v<decltype(uint16Buffer), std::array<Byte, sizeof(std::uint16_t)>>);
        STATIC_CHECK(std::is_same_v<decltype(int32Buffer), std::array<Byte, sizeof(std::int32_t)>>);
        STATIC_CHECK(
            std::is_same_v<decltype(uint64Buffer), std::array<Byte, sizeof(std::uint64_t)>>);

        // CHECK magic can't handle std::byte, so we cast
        CHECK(int(boolBuffer[0]) == 0x01);
        CHECK(int(byteBuffer[0]) == 0xAA);
        CHECK(int(int8Buffer[0]) == 0xFC);

        CHECK(int(uint16Buffer[0]) == 0x0B);
        CHECK(int(uint16Buffer[1]) == 0x00);

        CHECK(int(int32Buffer[0]) == 0xFE);
        CHECK(int(int32Buffer[1]) == 0xFF);
        CHECK(int(int32Buffer[2]) == 0xFF);
        CHECK(int(int32Buffer[3]) == 0xFF);

        CHECK(int(uint64Buffer[0]) == 0x08);
        CHECK(int(uint64Buffer[1]) == 0x07);
        CHECK(int(uint64Buffer[2]) == 0x06);
        CHECK(int(uint64Buffer[3]) == 0x05);
        CHECK(int(uint64Buffer[4]) == 0x04);
        CHECK(int(uint64Buffer[5]) == 0x03);
        CHECK(int(uint64Buffer[6]) == 0x02);
        CHECK(int(uint64Buffer[7]) == 0x01);
    }

    SECTION("Big endian")
    {
        auto boolBuffer = Serialize<std::endian::big>(true);
        auto byteBuffer = Serialize<std::endian::big>(std::byte{0xAA});
        auto int8Buffer = Serialize<std::endian::big>(static_cast<std::int8_t>(-4));
        auto uint16Buffer = Serialize<std::endian::big>(static_cast<std::uint16_t>(11));
        auto int32Buffer = Serialize<std::endian::big>(static_cast<std::int32_t>(-2));
        auto uint64Buffer =
            Serialize<std::endian::big>(static_cast<std::uint64_t>(0x0102'0304'0506'0708));

        CHECK(int(boolBuffer[0]) == 0x01);
        CHECK(int(byteBuffer[0]) == 0xAA);
        CHECK(int(int8Buffer[0]) == 0xFC);

        CHECK(int(uint16Buffer[0]) == 0x00);
        CHECK(int(uint16Buffer[1]) == 0x0B);

        CHECK(int(int32Buffer[0]) == 0xFF);
        CHECK(int(int32Buffer[1]) == 0xFF);
        CHECK(int(int32Buffer[2]) == 0xFF);
        CHECK(int(int32Buffer[3]) == 0xFE);

        CHECK(int(uint64Buffer[0]) == 0x01);
        CHECK(int(uint64Buffer[1]) == 0x02);
        CHECK(int(uint64Buffer[2]) == 0x03);
        CHECK(int(uint64Buffer[3]) == 0x04);
        CHECK(int(uint64Buffer[4]) == 0x05);
        CHECK(int(uint64Buffer[5]) == 0x06);
        CHECK(int(uint64Buffer[6]) == 0x07);
        CHECK(int(uint64Buffer[7]) == 0x08);
    }
}


TEST_CASE("Deserialize TriviallySerializable types")
{
    auto buffer = std::array{0x01_b, 0x02_b, 0x03_b, 0x04_b};

    SECTION("Little endian")
    {
        auto int32 = Deserialize<std::endian::little, std::int32_t>(buffer);
        auto uint16 = Deserialize<std::endian::little, std::uint16_t>(
            std::span(buffer).first<sizeof(std::uint16_t)>());
        auto int8 = Deserialize<std::endian::little, std::int8_t>(
            std::span(buffer).subspan<2, sizeof(std::int8_t)>());

        CHECK(int32 == 0x0403'0201);
        CHECK(uint16 == 0x0201);
        CHECK(int8 == 3);
    }

    SECTION("Big endian")
    {
        auto int32 = Deserialize<std::endian::big, std::int32_t>(buffer);
        auto uint16 = Deserialize<std::endian::big, std::uint16_t>(
            std::span(buffer).first<sizeof(std::uint16_t)>());
        auto int8 = Deserialize<std::endian::big, std::int8_t>(
            std::span(buffer).subspan<2, sizeof(std::int8_t)>());

        CHECK(int32 == 0x0102'0304);
        CHECK(uint16 == 0x0102);
        CHECK(int8 == 3);
    }
}


TEST_CASE("Serialize std::array")
{
    auto array = std::to_array<std::uint16_t>({0x0102, 0x0304});

    SECTION("Little endian")
    {
        auto buffer = Serialize<std::endian::little>(array);
        CHECK(int(buffer[0]) == 0x02);
        CHECK(int(buffer[1]) == 0x01);
        CHECK(int(buffer[2]) == 0x04);
        CHECK(int(buffer[3]) == 0x03);
    }

    SECTION("Big endian")
    {
        auto buffer = Serialize<std::endian::big>(array);
        CHECK(int(buffer[0]) == 0x01);
        CHECK(int(buffer[1]) == 0x02);
        CHECK(int(buffer[2]) == 0x03);
        CHECK(int(buffer[3]) == 0x04);
    }
}


TEST_CASE("Deserialize std::array")
{
    auto buffer = std::array{0x01_b, 0x02_b, 0x03_b, 0x04_b};

    SECTION("Little endian")
    {
        auto array = Deserialize<std::endian::little, std::array<std::uint16_t, 2>>(buffer);
        CHECK(array[0] == 0x0201);
        CHECK(array[1] == 0x0403);
    }

    SECTION("Big endian")
    {
        auto array = Deserialize<std::endian::big, std::array<std::uint16_t, 2>>(buffer);
        CHECK(array[0] == 0x0102);
        CHECK(array[1] == 0x0304);
    }
}


// Example for serializing and deserializing a user-defined type

namespace
{
struct Point
{
    std::int16_t x;
    std::int16_t y;
};


template<std::endian endianness>
auto SerializeTo(std::span<Byte> destination, Point const & point) -> std::span<Byte>
{
    using cerial::SerializeTo;
    destination = SerializeTo<endianness>(destination, point.x);
    destination = SerializeTo<endianness>(destination, point.y);
    return destination;
}


template<std::endian endianness>
auto DeserializeFrom(std::span<Byte const> source, Point & point) -> std::span<Byte const>
{
    using cerial::DeserializeFrom;
    source = DeserializeFrom<endianness>(source, point.x);
    source = DeserializeFrom<endianness>(source, point.y);
    return source;
}
}


template<>
constexpr auto cerial::SerialSize<Point>() -> std::size_t  // NOLINT(*unneeded-internal-declaration)
{
    return SerialSize<decltype(Point::x)>() + SerialSize<decltype(Point::y)>();
}


TEST_CASE("Serialize user-defined type")
{
    auto point = Point{.x = 0x0102, .y = 0x0304};

    SECTION("Little endian")
    {
        auto buffer = Serialize<std::endian::little>(point);
        CHECK(int(buffer[0]) == 0x02);
        CHECK(int(buffer[1]) == 0x01);
        CHECK(int(buffer[2]) == 0x04);
        CHECK(int(buffer[3]) == 0x03);
    }

    SECTION("Big endian")
    {
        auto buffer = Serialize<std::endian::big>(point);
        CHECK(int(buffer[0]) == 0x01);
        CHECK(int(buffer[1]) == 0x02);
        CHECK(int(buffer[2]) == 0x03);
        CHECK(int(buffer[3]) == 0x04);
    }
}


TEST_CASE("Deserialize user-defined type")
{
    auto buffer = std::array{0x01_b, 0x02_b, 0x03_b, 0x04_b};

    SECTION("Little endian")
    {
        auto point = Deserialize<std::endian::little, Point>(buffer);
        CHECK(point.x == 0x0201);
        CHECK(point.y == 0x0403);
    }

    SECTION("Big endian")
    {
        auto point = Deserialize<std::endian::big, Point>(buffer);
        CHECK(point.x == 0x0102);
        CHECK(point.y == 0x0304);
    }
}
