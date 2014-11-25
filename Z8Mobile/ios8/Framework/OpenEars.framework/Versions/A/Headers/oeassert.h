/*-
 * Copyright (c) 1992, 1993
 *	The Regents of the University of California.  All rights reserved.
 * (c) UNIX System Laboratories, Inc.
 * All or some portions of this file are derived from material licensed
 * to the University of California by American Telephone and Telegraph
 * Co. or Unix System Laboratories, Inc. and are reproduced herein with
 * the permission of UNIX System Laboratories, Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *	@(#)assert.h	8.2 (Berkeley) 1/21/94
 * $FreeBSD: src/include/assert.h,v 1.4 2002/03/23 17:24:53 imp Exp $
 */

#include <sys/cdefs.h>
#ifdef __cplusplus
#include <stdlib.h>
#endif /* __cplusplus */

#import <OpenEars/OpenEarsStaticAnalysisToggle.h>

#ifdef SHOW64BITCOMPLAINTS
#else
#if __LP64__ // This is only significant for 64-bit compilations -- prefer to keep it limited.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32" // We are turning off warnings about 64 bit shortening because it isn't harming behavior, but it's reversible for troubleshooting. 
#endif
#endif

#import "err.h"
/*
 * Unlike other ANSI header files, <assert.h> may usefully be included
 * multiple times, with and without NDEBUG defined.
 */

#undef oe_assert
#undef __oe_assert

#ifdef NDEBUG
// this isn't compiled
#define	oe_assert(e)	((void)0)
#else
// this is compiled
#ifndef __GNUC__
// this isn't compiled
__BEGIN_DECLS
#ifndef __cplusplus
// this isn't compiled
void abort(void) __dead2;
#endif /* !__cplusplus */
int  printf(const char * __restrict, ...);
__END_DECLS
// this isn't compiled
#define oe_assert(e)  \
((void) ((e) ? 0 : __oe_assert (#e, OELINEMACRO)))
#define __oe_assert(e, line) \
((void)printf ("%u: failed oe_assertion `%s'\n", line, e), (void)0))

#else /* __GNUC__ */
// this is compiled
__BEGIN_DECLS
// this is compiled
void __oe_assert_rtn(const char *, int, const char *) __dead2;
#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && ((__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__-0) < 1070)
// this is not compiled
void __eprintf(const char *, unsigned, const char *) __dead2;
#endif
__END_DECLS

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && ((__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__-0) < 1070)
// this isn't compiled
#define __oe_assert(e, line) \
__eprintf ("%u: failed oe_assertion `%s'\n", line, e)
#else
// this is compiled
/* 8462256: modified __assert_rtn() replaces deprecated __eprintf() */
#define __oe_assert(e, line) \
__oe_assert_rtn ((const char *)-1L, line, e)
#endif

#if __DARWIN_UNIX03
// this is compiled
#define oe_assert(e)  \
((void) ((e) ? 0 : __oe_assert (#e, OELINEMACRO)))
#undef __oe_assert
#define __oe_assert(e, line) \
((void)printf ("%u: failed oe_assertion `%s'\n", line, e), ((void)0))
#else /* !__DARWIN_UNIX03 */
// this isn't compiled
#define oe_assert(e)  \
(__builtin_expect(!(e), 0) ? __oe_assert (#e, OELINEMACRO) : (void)0)
#endif /* __DARWIN_UNIX03 */

#endif /* __GNUC__ */
#endif /* NDEBUG */
