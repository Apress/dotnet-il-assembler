.assembly extern mscorlib { .locale "fr-CA" auto }
.assembly virt_not2 { }
.module virt_not2.exe

#define DEFLT_CTOR ".method public specialname void .ctor(){ldarg.0; call instance void .base::.ctor(); ret;}"

.typedef method void [mscorlib]System.Console::WriteLine(string) as PrintString

.class public A
{
	DEFLT_CTOR
	.method public void Foo()
	{
		ldstr "A::Foo"
		call PrintString
		ret
	}
	.method public virtual void Bar()
	{
		ldstr "A::Bar"
		call PrintString
		ret
	}
	.method public virtual void Baz()
	{
		ldstr "A::Baz"
		call PrintString
		ret
	}

}

.class public B extends A
{
	DEFLT_CTOR
	.method public void Foo()
	{
		ldstr "B::Foo"
		call PrintString
		ret
	}
	.method public virtual void Bar()
	{
		ldstr "B::Bar"
		call PrintString
		ret
	}
	.method public virtual newslot void Baz()
	{
		ldstr "B::Baz"
		call PrintString
		ret
	}

}


.method public static void Exec()
{
	.entrypoint
	newobj instance void B::.ctor()	// create instance of derived class
	castclass class A		// cast it to base class

	dup				// we need 3 instance pointers
	dup				// on stack for 3 calls

	call instance void A::Foo()
	callvirt instance void A::Bar()
	callvirt instance void A::Baz()

	ret
}



