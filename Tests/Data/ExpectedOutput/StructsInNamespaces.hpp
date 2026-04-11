#include <StructsInNamespaces.hpp>

#include <Cerial/Cerial.hpp>


template<>
constexpr auto cerial::SerialSize<GlobalStruct>() -> std::size_t
{
    return SerialSize<decltype(GlobalStruct::b)>();
}


template<>
constexpr auto cerial::SerialSize<n::NamespacedStruct>() -> std::size_t
{
    return SerialSize<decltype(n::NamespacedStruct::l)>();
}


template<>
constexpr auto cerial::SerialSize<n::m::NestedNamespaceStruct>() -> std::size_t
{
    return SerialSize<decltype(n::m::NestedNamespaceStruct::c)>()
         + SerialSize<decltype(n::m::NestedNamespaceStruct::i)>()
         + SerialSize<decltype(n::m::NestedNamespaceStruct::f)>();
}


template<>
constexpr auto cerial::SerialSize<n::a::b::InlineNamespaceStruct>() -> std::size_t
{
    return SerialSize<decltype(n::a::b::InlineNamespaceStruct::s)>();
}


template<>
constexpr auto cerial::SerialSize<AnonymousNamespaceStruct>() -> std::size_t
{
    return SerialSize<decltype(AnonymousNamespaceStruct::d)>();
}
