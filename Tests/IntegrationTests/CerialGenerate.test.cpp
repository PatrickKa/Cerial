#include <Cerial/Byte.hpp>
#include <Cerial/Cerial.hpp>

#include <catch2/catch_test_macros.hpp>
#include <InterfaceStructs.cerial.hpp>  // IWYU pragma: keep
#include <InterfaceStructs.hpp>
#include <Structs.cerial.hpp>  // IWYU pragma: keep
#include <Structs.hpp>

#include <array>
#include <bit>
#include <cstdint>
#include <vector>


TEST_CASE("Generated serialization round-trips correctly")
{
    SECTION("Test target")
    {
        auto original = Point{.x = 0x0102, .y = 0x0304};

        SECTION("Little endian")
        {
            auto buffer = cerial::Serialize<std::endian::little>(original);
            auto result = cerial::Deserialize<std::endian::little, Point>(buffer);
            CHECK(result.x == original.x);
            CHECK(result.y == original.y);
        }

        SECTION("Big endian")
        {
            auto buffer = cerial::Serialize<std::endian::big>(original);
            auto result = cerial::Deserialize<std::endian::big, Point>(buffer);
            CHECK(result.x == original.x);
            CHECK(result.y == original.y);
        }
    }

    SECTION("Interface target")
    {
        auto original = Color{.r = 0x01, .g = 0x02, .b = 0x03};

        SECTION("Little endian")
        {
            auto buffer = cerial::Serialize<std::endian::little>(original);
            auto result = cerial::Deserialize<std::endian::little, Color>(buffer);
            CHECK(result.r == original.r);
            CHECK(result.g == original.g);
            CHECK(result.b == original.b);
        }

        SECTION("Big endian")
        {
            auto buffer = cerial::Serialize<std::endian::big>(original);
            auto result = cerial::Deserialize<std::endian::big, Color>(buffer);
            CHECK(result.r == original.r);
            CHECK(result.g == original.g);
            CHECK(result.b == original.b);
        }
    }
}


TEST_CASE("Generated serialization supports dynamically sized structs")
{
    auto original = Packet{
        .id = 0xAB, .payload = {0x0102, 0x0304}
    };
    auto buffer = std::array<cerial::Byte, 1 + 2 * sizeof(std::int16_t)>{};
    REQUIRE(cerial::SerialSize(original) == buffer.size());

    SECTION("Little endian")
    {
        auto remaining = cerial::SerializeTo<std::endian::little>(buffer, original);
        CHECK(remaining.empty());

        auto result = Packet{.id = 0, .payload = std::vector<std::int16_t>(2)};  // Pre-sized
        cerial::DeserializeFrom<std::endian::little>(buffer, result);
        CHECK(result.id == original.id);
        CHECK(result.payload == original.payload);
    }

    SECTION("Big endian")
    {
        auto remaining = cerial::SerializeTo<std::endian::big>(buffer, original);
        CHECK(remaining.empty());

        auto result = Packet{.id = 0, .payload = std::vector<std::int16_t>(2)};  // Pre-sized
        cerial::DeserializeFrom<std::endian::big>(buffer, result);
        CHECK(result.id == original.id);
        CHECK(result.payload == original.payload);
    }
}
