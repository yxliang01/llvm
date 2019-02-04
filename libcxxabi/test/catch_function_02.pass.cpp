//===---------------------- catch_function_02.cpp -------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// Can you have a catch clause of array type that catches anything?
// UNSUPPORTED: libcxxabi-no-exceptions

#include <cassert>

void f() {}

int main()
{
    typedef void Function();
    try
    {
        throw f;     // converts to void (*)()
        assert(false);
    }
    catch (Function b)  // equivalent to void (*)()
    {
    }
    catch (...)
    {
        assert(false);
    }
}
