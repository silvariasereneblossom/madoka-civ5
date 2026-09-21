/* Searched before the VC9 include folder by build_dll.py and build_lekmod_dll.py.
 *
 * VC9's vadefs.h implements va_start on x86 as pointer arithmetic on the address of the last named
 * parameter. clang does not keep parameters where that arithmetic expects them once a varargs function
 * is inlined (VC9's C++ sprintf_s(char (&)[N], fmt, ...) overload is the common case), so the argument
 * pointer lands on stack garbage: "(null)" in queries, or an access violation in printf. That crashed the
 * Lekmod DLL at database load on 2026-09-21 (CvDatabaseUtility::MaxRows); the CP DLL compiled the same
 * broken code and survived on stack luck. clang ships an identical override in its own resource folder,
 * but VC9's folder is searched first, so it never takes effect. This file restores it.
 */
#ifndef PMMM_CLANG_VADEFS_SHIM
#define PMMM_CLANG_VADEFS_SHIM

#include_next <vadefs.h>

#ifdef _crt_va_start
#undef _crt_va_start
#define _crt_va_start(ap, param) __builtin_va_start(ap, param)
#endif
#ifdef _crt_va_end
#undef _crt_va_end
#define _crt_va_end(ap) __builtin_va_end(ap)
#endif
#ifdef _crt_va_arg
#undef _crt_va_arg
#define _crt_va_arg(ap, type) __builtin_va_arg(ap, type)
#endif

#endif
