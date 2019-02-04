//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// <ios>

// template <class charT, class traits> class basic_ios

// char narrow(char_type c, char dfault) const;

#include <ios>
#include <cassert>

int main()
{
    const std::wios ios(0);
    assert(ios.narrow(L'c', '*') == 'c');
    assert(ios.narrow(L'\u203C', '*') == '*');
}
