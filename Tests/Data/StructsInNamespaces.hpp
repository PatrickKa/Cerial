#pragma once


// Brief struct description
struct GlobalStruct
{
    int x;
};


namespace n
{
struct NamespacedStruct  // Trailing comment
{
    int x;
};


namespace m
{
struct /* Nobody would place a comment here */ NestedNamespaceStruct
{
    char c;
    int i;
    float f;
};
}  // namespace m


namespace a::b
{
struct InlineNamespaceStruct
{
    int /* comment in member declaration */ x;
};
}  /* namespace a::b */
}  // namespace n


namespace
{
struct AnonymousNamespaceStruct
{
    int x;
};
}
