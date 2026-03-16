#pragma once


// Brief struct description
// @Cerial
struct GlobalStruct
{
    bool b;
};


namespace n
{
// @Cerial
struct NamespacedStruct  // Trailing comment
{
    long l;
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
};
}
