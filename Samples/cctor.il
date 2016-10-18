.assembly extern mscorlib { auto }
.assembly cctor {}
.module cctor.exe

.class public value V
{
	.field public static int32 v
	.method public static specialname void .cctor()
	{
		ldc.i4.3
		stsfld int32 V::v
		ret
	}
}

.method public static void Exec()
{
	.entrypoint
	.locals (valuetype V x)

	ldsfld int32 V::v
	call void [mscorlib]System.Console::WriteLine(int32)

	ret
}
