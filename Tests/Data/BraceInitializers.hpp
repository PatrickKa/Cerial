#pragma once

#include <array>


// @Cerial
struct BraceInitializers
{
    int scalar = 0;
    std::array<char, 7> assignEmptyBrace = {};
    std::array<char, 7> assignFilledBrace = {1, 2, 3, 4, 5, 6, 7};
    std::array<char, 7> directBrace{};
    std::array<char, 7> noInit;
    int trailing = 1;
};
