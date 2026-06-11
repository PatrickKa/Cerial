# Cerial <!-- omit in toc -->

A simple C++ serialization library plus a CMake code generator that writes the serialization
boilerplate for your structs.

The library serializes and deserializes trivially serializable types (arithmetic types and enums),
`std::array`, and dynamically sized contiguous ranges such as `std::vector`, `std::string`, and the
[ETL](https://www.etlcpp.com/) containers, to and from byte buffers. The target byte order is a
template argument. User-defined types are supported either by hand or via the generator.


**Contents**

- [Usage](#usage)
  - [Code generation](#code-generation)
- [Installation](#installation)
- [Licensing](#licensing)


## Usage

The simplest case is a round-trip through a byte buffer:

~~~cpp
#include <Cerial/Cerial.hpp>

#include <bit>
#include <cstdint>

auto buffer = cerial::Serialize<std::endian::big>(std::uint32_t{0x01020304});
auto value = cerial::Deserialize<std::endian::big, std::uint32_t>(buffer);  // == 0x01020304
~~~

The example below shows the full API for statically sized values and dynamically sized ranges, which
Cerial supports out of the box:

~~~cpp
#include <Cerial/Byte.hpp>
#include <Cerial/Cerial.hpp>

#include <array>
#include <bit>
#include <cassert>
#include <cstdint>
#include <vector>

using namespace cerial::literals;

int main()
{
    static constexpr auto size = cerial::SerialSize<std::uint32_t>();
    static_assert(size == 4);

    auto buffer = cerial::Serialize<std::endian::big>(std::uint32_t{0x01020304});
    assert(buffer == std::array<cerial::Byte, 4>{0x01_b, 0x02_b, 0x03_b, 0x04_b});

    auto value = cerial::Deserialize<std::endian::little, std::uint32_t>(buffer);
    assert(value == 0x04030201);

    // Dynamically sized ranges: the size depends on the runtime element count, so you must provide
    // your own buffer and use SerializeTo()/DeserializeFrom()
    auto numbers = std::vector<std::uint16_t>{1, 2, 3};
    auto bytes = std::vector<cerial::Byte>(cerial::SerialSize(numbers));
    cerial::SerializeTo<std::endian::big>(bytes, numbers);
    assert(bytes == std::vector<cerial::Byte>{0x00_b, 0x01_b, 0x00_b, 0x02_b, 0x00_b, 0x03_b});

    // The vector must be pre-sized to the number of elements you want to deserialize
    auto firstPart = std::vector<std::uint16_t>(2);
    auto remainingBytes = cerial::DeserializeFrom<std::endian::big>(bytes, firstPart);
    assert(firstPart == std::vector<std::uint16_t>{1, 2});
    assert(remainingBytes.size() == 2);

    auto secondPart = std::vector<std::uint16_t>(1);
    cerial::DeserializeFrom<std::endian::big>(remainingBytes, secondPart);
    assert(secondPart == std::vector<std::uint16_t>{3});
}
~~~

For more examples see the unit tests in
[`Tests/UnitTests/Cerial.test.cpp`](Tests/UnitTests/Cerial.test.cpp). They cover `std::array`,
nested ranges, ETL containers, and both byte orders.

To make a user-defined type serializable, you must provide a `cerial::SerialSize<T>()`
specialization and `SerializeTo()`/`DeserializeFrom()` overloads for it (found via
argument-dependent lookup). The worked example at the end of the unit test file shows the full
pattern.


### Code generation

Rather than writing `SerialSize()`, `SerializeTo()`, and `DeserializeFrom()` by hand, annotate a
struct with `// @Cerial`:

~~~cpp
// MyHeader.hpp

// @Cerial
struct MyType
{
    int i;
    double d;
};
~~~

Then invoke `cerial_generate()` in CMake to emit the code for those functions and write it to a
companion header `MyHeader.cerial.hpp`. Include the companion header alongside the original to
enable serialization.

The `cerial_generate()` function is documented in full at the top of
[`CMake/CerialGenerate.cmake`](CMake/CerialGenerate.cmake). For a complete example – the annotation,
the CMake wiring, and the consuming test – see the integration tests in
[`Tests/IntegrationTests/`](Tests/IntegrationTests/).


## Installation

Cerial has no dependencies beyond a **C++23** compiler and **CMake ≥ 3.31**. The dependencies listed
in [`vcpkg.json`](vcpkg.json) are only needed by developers running the test suite and live behind
the `test` feature.

Being a standard CMake package, Cerial is configured and installed with the canonical commands. Pass
`--prefix` to the install step to choose the destination:

~~~shell
cmake -S . -B build -G "Your preferred generator"
# No build step since Cerial is header-only
cmake --install build --prefix /your/install/prefix
~~~

Once installed, find the package and link against it from your own `CMakeLists.txt`. This also makes
the `cerial_generate()` function available, so the code generator needs no extra setup:

~~~cmake
find_package(Cerial CONFIG REQUIRED)
target_link_libraries(MyTarget PRIVATE Cerial::Cerial)
~~~


## Licensing

Copyright 2026 Patrick Kappl

This project is licensed under the Boost Software License 1.0. See the [`LICENSE`](LICENSE) document
for the full text.
