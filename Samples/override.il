.assembly extern mscorlib { }
.assembly override { }
.module override.exe

.class public A
{
	.method public specialname void .ctor() 
	{
		ldarg.0
		call instance void [mscorlib]System.Object::.ctor() 
		ret 
	}
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
	.method public specialname void .ctor() 
	{
		ldarg.0
		call instance void A::.ctor() 
		ret 
	}
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
	.method public specialname void .ctor() 
	{
		ldarg.0
		call instance void B::.ctor() 
		ret 
	}
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



