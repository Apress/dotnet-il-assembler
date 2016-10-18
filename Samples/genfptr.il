.assembly extern mscorlib { auto }
.assembly genfptr {}
.module genfptr.exe

.typedef method void [mscorlib]System.Console::WriteLine(string) as PrintString
.method public static !!T GetMedian<T>(!!T[] tarray)
{
	ldstr "GetMedian<T> called"
	call PrintString
	ldarg.0
	dup
	ldlen
	ldc.i4.1
	shr
	ldelem !!T
	ret
}
.method public static !!T Invoke<T>(method !!T*(!!T[]) medFunc, !!T[] tarr)
{	
	ldstr "Invoke<T> called"
	call PrintString
	ldarg.1
	ldarg.0
        calli !!T (!!T[])
	ret
}

#define CALL_VIA_INVOKE

.method public static void Exec()
{
	.entrypoint
#ifdef CALL_VIA_INVOKE
	ldftn !!0 GetMedian<string>(!!0[])
#endif
	ldc.i4.3
	newarr string
	dup 
	dup 
	dup
	ldc.i4.0
	ldstr "One"
	stelem.ref
	ldc.i4.1
	ldstr "Two"
	stelem.ref
	ldc.i4.2
	ldstr "Three"
	stelem.ref
#ifdef CALL_VIA_INVOKE	
	call !!0 Invoke<string>(method !!0*(!!0[]), !!0[])
#else
	ldftn !!0 GetMedian<string>(!!0[])
	calli string(string[])
#endif
	call PrintString
	ret
}

