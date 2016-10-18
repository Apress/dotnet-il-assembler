.assembly extern mscorlib { auto }
.assembly cctors {}
.module cctors.exe

.typedef [mscorlib]System.Console as TTY

#define DEFLT_CTOR 
 ".method public specialname void .ctor(){ldarg.0; call instance void .base::.ctor(); ret;}"

.class public Base
{
    DEFLT_CTOR
    .method public void DoSomething()
    {
        ldarg.0
        pop
        ldstr "Base::DoSomething()"
        call void TTY::WriteLine(string)
        ret
    }
}
.class public /*beforefieldinit*/ A extends Base
{
    DEFLT_CTOR
	.method public static specialname void .cctor()
	{
		ldstr "A::.cctor()"
		call void TTY::WriteLine(string)
		ret
	}
}
.class public /*beforefieldinit*/ B extends Base
{
    DEFLT_CTOR
	.method public static specialname void .cctor()
	{
		ldstr "B::.cctor()"
		call void TTY::WriteLine(string)
		ret
	}
}

.method public static specialname void .cctor()
{
        ldstr "<Module>::.cctor()"
        call void TTY::WriteLine(string)
        ret
}

.method public static void Exec()
{
	.entrypoint
	.locals init(class Base b1)
	
	ldstr "Enter string"
	call void TTY::WriteLine(string)
	call string TTY::ReadLine()
	call bool string::IsNullOrEmpty(string)
	brtrue L1 // use result of IsNullOrEmpty
	
	// Instantiate class A with .cctor
	newobj instance void A::.ctor()
	stloc.s b1
    br L2
L1:
	// Instantiate class B with .cctor
	newobj instance void B::.ctor()
	stloc.s b1
L2:
    // Use the instance
	ldloc.s b1
	call instance void Base::DoSomething()

	ret
}


