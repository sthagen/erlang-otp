/*
 * %CopyrightBegin%
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Copyright Ericsson AB 2026. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * %CopyrightEnd%
 */

#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif

#ifdef ERTS_USE_BUILTIN_RYU
# error "ERTS_USE_BUILTIN_RYU should not be defined here"
#endif

#include <charconv>
#include <string.h>
#include <math.h>

extern "C"
int sys_double_to_chars_short(double f, char* fbuf, int sizeof_fbuf)
{
    std::to_chars_result tcr;

    if (fabs(f) < 9007199254740992.0) {
        tcr = std::to_chars(fbuf, fbuf + sizeof_fbuf -1, f);
    }
    else {
        tcr = std::to_chars(fbuf, fbuf + sizeof_fbuf -1, f,
                            std::chars_format::scientific);
    }

    if (tcr.ec != std::errc()) {
        return 0;
    }

    char* end = tcr.ptr;
    bool add_dot0 = true;

    for (char *p = fbuf+1; p < end; p++) {
        if (*p == '.') {
            add_dot0 = false;
        }
        else if (*p == 'e') {
            if (add_dot0) {
                memmove(p+2, p, end - p);
                *p++ = '.';
                *p++ = '0';
                end += 2;
                add_dot0 = false;
            }
            p++;
            char* exp_dst = p;
            if (*p == '+') {
                p++;
            }
            else if (*p == '-') {
                p++;
                exp_dst++;
            }
            if (*p == '0') {
                p++;
            }
            if (p != exp_dst) {
                memmove(exp_dst, p, end - p);
                end -= p - exp_dst;
            }
            break;
        }
    }

    if (add_dot0) {
        *end++ = '.';
        *end++ = '0';
    }

    *end = '\0';
    return end - fbuf;
}
