.assembly extern mscorlib { auto }
.assembly privatector {}
.module privatector.exe

.typedef [mscorlib]System.Console as TTY

#define PRIV_DEFLT_CTOR 
 ".method private specialname void .ctor(){ldarg.0; call instance void .base::.ctor(); ret;}"

.class public NoCtor
{
    PRIV_DEFLT_CTOR
    .method public void DoSomething()
    {
        ldarg.0
        pop
        ldstr "NoCtor::DoSomething()"
        call void TTY::WriteLine(string)
        ret
    }
    .method public static class NoCtor New()
    {
        newobj instance void .this::.ctor()
        ret
    }
}

.method public static void Exec()
{
	.entrypoint
	.locals init(class NoCtor nc)
    
    // Create the instance
    call class NoCtor NoCtor::New()
    stloc.0
	
    // Use the instance
	ldloc.0
	call instance void NoCtor::DoSomething()

	ret
}


