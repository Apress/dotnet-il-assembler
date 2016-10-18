.assembly extern mscorlib { auto }
.assembly gen_virt{}
.module gen_virt.exe

#define DEFLT_CTOR ".method public specialname void .ctor(){ldarg.0; call instance void .base::.ctor(); ret;}"

.typedef method void [mscorlib]System.Console::WriteLine(string) as PrintString
.typedef method void [mscorlib]System.Console::WriteLine(int32) as PrintInt
.typedef [mscorlib]System.Type as SysType

// Non-generic interface with generic method
.class public interface IX
{
	.method public virtual abstract int32 Do<T>(!!T theT){}
}

// Implicit override of generic virtual method
.class public A implements IX
{
	DEFLT_CTOR
	.method public virtual int32 Do<T>(!!T theT)
	{
		ldarga.s theT
		constrained. !!T
		callvirt instance string object::ToString()
		call PrintString
		ldc.i4.2
		ret
	}
}

// Explicit override of generic method, short form 
.class public B implements IX
{
	DEFLT_CTOR
	.method public virtual int32 DoIt<T>(!!T theT)
	{
		.override method instance int32 IX::Do<[1]>(!!0)
		ldarga.s theT
		constrained. !!T
		callvirt instance string object::ToString()
		call PrintString
		ldc.i4.3
		ret
	}
}

// Generic instance constructor and
// Explicit override of generic method, long form
.class public C implements IX
{
	.method public specialname void .ctor<U>(!!U u)
	{
		ldarg.0
		call instance void .base::.ctor()

		ldtoken !!U
		call class SysType SysType::GetTypeFromHandle(valuetype [mscorlib]System.RuntimeTypeHandle)		
		callvirt instance string SysType::ToString()
		call PrintString

		ldarga.s u
		constrained. !!U
		callvirt instance string object::ToString()
		call PrintString

		ret
	}		
	.override method instance int32 IX::Do<[1]>(!!0)
		with method instance int32 .this::DoIt<[1]>(!!0)
	.method public virtual int32 DoIt<T>(!!T theT)
	{
		ldarga.s theT
		constrained. !!T
		callvirt instance string object::ToString()
		call PrintString
		ldc.i4.4
		ret
	}
}

// Test executing method
.method public static void Exec()
{
	.entrypoint

	newobj instance void A::.ctor()
	ldstr "Hehe"
	callvirt instance int32 IX::Do<string>(!!0)
	call PrintInt

	newobj instance void B::.ctor()
	ldstr "Haha"
	callvirt instance int32 IX::Do<string>(!!0)
	call PrintInt

	ldstr "Huhu"
	newobj instance void C::.ctor<string>(!!0)
	ldstr "Hoho"
	callvirt instance int32 IX::Do<string>(!!0)
	call PrintInt

	ret
}



 
	