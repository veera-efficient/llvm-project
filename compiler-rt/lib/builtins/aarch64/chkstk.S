// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "../assembly.h"

// __chkstk routine
// This routine is windows specific.
// http://msdn.microsoft.com/en-us/library/ms648426.aspx

// This clobbers registers x16 and x17.
// Does not modify any memory or the stack pointer.

//      mov     x15, #256 // Number of bytes of stack, in units of 16 byte
//      bl      __chkstk
//      sub     sp, sp, x15, lsl #4

#if defined(__aarch64__) || defined(__arm64ec__)

#ifdef __arm64ec__
#define CHKSTK_FUNC __chkstk_arm64ec
#else
#define CHKSTK_FUNC __chkstk
#endif

#define PAGE_SIZE 4096

        .p2align 2
DEFINE_COMPILERRT_FUNCTION(CHKSTK_FUNC)
        lsl    x16, x15, #4
        mov    x17, sp
1:
        sub    x17, x17, #PAGE_SIZE
        subs   x16, x16, #PAGE_SIZE
        ldr    xzr, [x17]
        b.gt   1b

        ret
END_COMPILERRT_FUNCTION(CHKSTK_FUNC)

#endif // defined(__aarch64__) || defined(__arm64ec__)
