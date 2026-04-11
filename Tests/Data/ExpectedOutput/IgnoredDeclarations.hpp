#include <IgnoredDeclarations.hpp>

#include <Cerial/Cerial.hpp>


template<>
constexpr auto cerial::SerialSize<ParentStruct>() -> std::size_t
{
    return SerialSize<decltype(ParentStruct::j)>();
}
