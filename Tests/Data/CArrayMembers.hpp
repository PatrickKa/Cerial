#pragma once


// @Cerial
struct CArrayMembers
{
    int scalar;
    char buffer[16];
    int matrix[2][3];
    float sizedByExpression[sizeof(double)];
    char initialized[4] = {};
    int trailing;
};
