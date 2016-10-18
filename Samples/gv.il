.assembly extern mscorlib { auto }
.assembly gv {}
.module gv.exe

.class public interface IX<T>
{
	.method public abstract virtual void F(!T){}
}

.class public A<T> implements class IX<!T>
{
	.method public specialname void .ctor()
	{
		ldarg.0
		call instance void .base::.ctor()
		ret
	}
	.method public virtual void G(!T)
	{
		.override method instance void class IX<!T>::F(!0)
		ldstr "IX::F"
		call void [mscorlib]System.Console::WriteLine(string)
		ret
	}
}

.method public static void Exec()
{
	.entrypoint
	newobj instance void class A<string>::.ctor()
	ldstr "Hehe"
	callvirt instance void class IX<string>::F(!0)
	ret
}
