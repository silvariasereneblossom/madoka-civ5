# WFTW Lekmod port (clang-cl build compatibility): conversion helpers.
#
# The prebuilt FireWorks objects (FireWorksWin32.obj from the Community-Patch
# checkout, linked in place of Lekmod's /GL bytecode archives; see
# scripts/build_lekmod_dll.py) reference two legacy MSVC x86 helper functions
# that no shipped CRT provides. Calling conventions were recovered from the
# actual call sites in the prebuilt objects (FString.obj: FStringA::Decrypt,
# FRandom::Roll; FTimer.obj: FTimer::Read):
#
#   __ftol3 : single-precision float in the low 32 bits of xmm0 -> int in eax,
#            cdecl, no stack arguments (verified at all 3 call sites; every
#            site passes the result of a mulss). (int)float truncates.
#   __ltod3 : 64-bit integer, low half in ecx, high half in edx (edx:ecx pair;
#            consistent at both FTimer::Read sites) -> double in xmm0.
#
# Assembled by scripts/build_lekmod_dll.py with clang (i686 windows-msvc COFF)
# and linked into CvGameCore_Expansion2.dll.
	.text
	# @feat.00, value bit 0 set: object is SAFESEH-compatible (this is what
	# every MSVC-built object in FireWorksWin32.obj defines; lld-link checks it
	# before accepting the object under its default /SAFESEH).
	.set	"@feat.00", 1
	.def	__ftol3; .scl 2; .type 32; .endef
	.globl	__ftol3
	.safeseh __ftol3
__ftol3:
	cvttss2si	%xmm0, %eax
	ret

	.def	__ltod3; .scl 2; .type 32; .endef
	.globl	__ltod3
	.safeseh __ltod3
__ltod3:
	pushl	%ecx
	pushl	%edx
	fildll	(%esp)
	fstpl	(%esp)
	movsd	(%esp), %xmm0
	addl	$8, %esp
	ret