.assembly extern mscorlib { }
.assembly overloads{ }
.module overloads.exe

#define DEFLT_CTOR 
	".method public specialname void .ctor(){ldarg.0; call instance void .base::.ctor(); ret}"

.typedef method void [mscorlib]System.Console::WriteLine(string) as PrintString


.class public A
{
   DEFLT_CTOR
   .method public void Foo()
   {
      ldstr "instance void Foo"
      call PrintString
      ret
   }
   .method public static void Foo()
   {
      ldstr "static void Foo"
      call PrintString
      ret
   }
   .method public vararg void Foo()
   {
      ldstr "instance vararg void Foo"
      call PrintString
      ret
   }
   .method public static vararg void Foo()
   {
      ldstr "static vararg void Foo"
      call PrintString
      ret
   }
   .method public int32 Foo()
   {
      ldstr "instance int32 Foo"
      call PrintString
      ldc.i4.1
      ret
   }
   .method public static int32 Foo()
   {
      ldstr "static int32 Foo"
      call PrintString
      ldc.i4.1
      ret
   }
}
.method public static void Exec()
{
   .entrypoint
   newobj instance void A::.ctor() //  Create instance of A

   dup                 // We need 3 instance pointers
   dup                 // On stack for 3 calls
   

   call instance void A::Foo()
   call instance vararg void A::Foo()
   call instance int32 A::Foo()
   pop
   call void A::Foo()
   call vararg void A::Foo()
   call int32 A::Foo()
   pop
   ret
}



