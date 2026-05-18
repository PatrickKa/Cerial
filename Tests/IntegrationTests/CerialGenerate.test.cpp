#include <Cerial/Cerial.hpp>

#include <catch2/catch_test_macros.hpp>
// TODO: Think about including Structs.cerial.hpp at the end of Structs.hpp
#include <Structs.cerial.hpp>  // IWYU pragma: keep
#include <Structs.hpp>

#include <bit>


TEST_CASE("Generated serialization round-trips correctly")
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
