#pragma once

#include <compare>


// Brief struct description
// @Cerial
struct GlobalStruct
{
    bool b = false;

    friend constexpr auto operator==(GlobalStruct const &, GlobalStruct const &) -> bool = default;
};


namespace n
{
// @Cerial
struct NamespacedStruct  // Trailing comment
{
    long l = 1;

    [[nodiscard]] auto Getl() const -> long;
    auto Setl(long value) -> void;

    friend constexpr auto operator<=>(NamespacedStruct const &, NamespacedStruct const &)
        -> std::strong_ordering = default;
};


namespace m
{
// @Cerial
struct /* Nobody would place a comment here */ NestedNamespaceStruct
{
    char c;
    int i;
    float f;

    auto GetC() -> char;
    int GetI();
    void SetI(int integer);

    auto operator==(NestedNamespaceStruct const &) const -> bool = default;
    bool operator!=(NestedNamespaceStruct const &) const = default;
};
}  // namespace m


namespace a::b
{
// @Cerial
struct InlineNamespaceStruct
{
    short /* comment in member declaration */ s;
};
} /* namespace a::b */
}  // namespace n


namespace  // NOLINT(google-build-namespaces)
{
// @Cerial
struct AnonymousNamespaceStruct
{
    double d;

    auto F() -> void;
    void G();
};
}
