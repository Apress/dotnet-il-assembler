.assembly extern mscorlib { }
.assembly override { }
.module override.exe
#define DEFLT_CTOR ".method public specialname void .ctor(){ ldarg.0; call instance void .base::.ctor(); ret}"
.class public A
{
	DEFLT_CTOR
	.method public void Foo()
	{
		ldstr "A::Foo"
		call void [mscorlib]System.Console::WriteLine(string)
		ret
	}
	.method public virtual void Bar()
	{
		ldstr "A::Bar"
		call void [mscorlib]System.Console::WriteLine(string)
		ret
	}
	.method public virtual void Baz()
	{
		ldstr "A::Baz"
		call void [mscorlib]System.Console::WriteLine(string)
		ret
	}

}

.class public B extends A
{
	DEFLT_CTOR
	.method public void Foo()
	{
		ldstr "B::Foo"
		call void [mscorlib]System.Console::WriteLine(string)
		ret
	}
	.method public virtual void BarBaz()
	{
		.override A::Bar
		.override A::Baz
		ldstr "B::BarBaz"
		call void [mscorlib]System.Console::WriteLine(string)
		ret
	}
}

.class public C extends B
{
	DEFLT_CTOR
	// no overrides, let's inherit everything from B
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

	//-------------------------------------------------------------------
	
	newobj instance void C::.ctor() // create instance of derived class
	castclass class A			  // cast it to "grandparent"

	dup					  // we need 3 instance pointers
	dup					  // on stack for 3 calls

	call instance void A::Foo()
	callvirt instance void A::Bar()
	callvirt instance void A::Baz()

	ret
}



