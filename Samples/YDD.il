.assembly extern mscorlib { auto }
.assembly YDD { }
.module YDD.dll
.corflags 0x00000002
.vtfixup [1] int32 fromunmanaged at VT_01	// 1st VTFixup
.vtfixup [1] int32 fromunmanaged at VT_02	// 2nd VTFixup
.vtfixup [1] int32 fromunmanaged at VT_03	// 3rd VTFixup
.data VT_01 = int32(0)			// 1st v-table entry
.data VT_02 = int32(0)			// 2nd v-table entry
.data VT_03 = int32(0)			// 3rd v-table entry
.method public static void Yabba()
{
	.vtentry 1:1
	.export [1]
	ldstr "Yabba"
	call void [mscorlib]System.Console::WriteLine(string)
	ret
}
.method public static void Dabba()
{
	.vtentry 2:1
	.export [2]
	ldstr "Dabba"
	call void [mscorlib]System.Console::WriteLine(string)
	ret
}
.method public static void Doo()
{
	.vtentry 3:1
	.export [3]
	ldstr "Doo!"
	call void [mscorlib]System.Console::WriteLine(string)
	ret
}
