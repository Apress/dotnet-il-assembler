.assembly extern mscorlib { }
.assembly virt_not { }
.module virt_not.exe

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
	.method public virtual void Bar()
	{
		ldstr "B::Bar"
		call void [mscorlib]System.Console::WriteLine(string)
		ret
	}
	.method public virtual newslot void Baz()
	{
		ldstr "B::Baz"
		call void [mscorlib]System.Console::WriteLine(string)
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



