#pragma once


// Brief struct description
// @Cerial
struct GlobalStruct
{
    int x;
};


namespace n
{
// @Cerial
struct NamespacedStruct  // Trailing comment
{
    int x;
};


namespace m
{
// @Cerial
struct /* Nobody would place a comment here */ NestedNamespaceStruct
{
    char c;
    int i;
    float f;
};
}  // namespace m


namespace a::b
{
// @Cerial
struct InlineNamespaceStruct
{
    int /* comment in member declaration */ x;
};
} /* namespace a::b */
}  // namespace n


namespace  // NOLINT(google-build-namespaces)
{
// @Cerial
struct AnonymousNamespaceStruct
{
    int x;
};
}
