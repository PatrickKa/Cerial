#pragma once


// @Cerial
struct UnsupportedMembers
{
    int supported;
    // clang-format off
    int* pointer1;
    int *pointer2;
    int * pointer3;
    int& reference1;
    int &reference2;
    int & reference3;
    // clang-format on
    [[maybe_unused]] int attributed;
    int flags : 4;
    int alsoSupported;
};
