//----------- Program header
.assembly extern mscorlib { auto }
.assembly OddOrEven { }
.module OddOrEven.exe
//----------- Class declaration
.namespace Odd.or {
  .class public auto ansi Even
          extends [mscorlib]System.Object {
//----------- Field declaration
    .field public static int32 val
//----------- Method declaration
    .method public static void check( ) cil managed {
      .entrypoint
      .locals init (int32 Retval)
    AskForNumber:
      ldstr "Enter a number"
      call void [mscorlib]System.Console::WriteLine(string)
      call string [mscorlib]System.Console::ReadLine()
      ldstr "%d" // CHANGE!
      ldsflda int32 Odd.or.Even::val
      call vararg int32 sscanf(string,string,...,int32*)
                         // CHANGE!
      stloc.0 // CHANGE!
      ldloc.0 // CHANGE!
      brfalse.s Error // CHANGE!
      ldsfld int32 Odd.or.Even::val
      ldc.i4.1 // CHANGE!
      and
      brfalse.s ItsEven // CHANGE!
      ldstr "odd!"
      br.s PrintAndReturn // CHANGE!
    ItsEven:
      ldstr "even!"
      br.s PrintAndReturn // CHANGE!
    Error:
      ldstr "How rude!"
    PrintAndReturn:
      call void [mscorlib]System.Console::WriteLine(string)
      ldloc.0 // CHANGE!
      brtrue.s AskForNumber // CHANGE!
      ret
    } // End of method
  } // End of class
} // End of namespace
//----------- Calling unmanaged code
.method public static pinvokeimpl("msvcrt.dll" cdecl) 
    vararg int32 sscanf(string,string) cil managed preservesig { }
