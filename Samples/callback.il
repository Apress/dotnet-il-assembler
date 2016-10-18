// Necessary preliminaries
.assembly extern mscorlib { auto }
.assembly callback { }
.module callback.exe

// The unsorted data we want to sort. With minor improvements,
// I could make the data to be received from a file or the console,
// but it would not serve any illustrative purpose.
// Feel free to try modifying the code in this aspect.

.class private value explicit sealed SixtyBytes { .pack 1 .size 60 }
.field public static valuetype SixtyBytes DataToSort at D_0001
.data D_0001 = {int32(10), int32(32), int32(-1), int32(567),
  int32(3), int32(18), int32(1), int32(-51), int32(789), int32(2345),
  int32(-43), int32(788), int32(-345), int32(345), int32(0)}

// To show that the sorting really happens, I am going to print
// out data before and after the sorting. Rather than using the
// [mscorlib]System.Console::WriteLine, I will P/Invoke the C 
// function int printf(char* Format,...)

.method public static pinvokeimpl("msvcrt.dll" ansi cdecl) 
	vararg int32 printf(string) preservesig {}

// And this is a managed printing method, invoking the printf.

.method public static void printInt32(void* pBuff, int32 N)
{
  .locals init(int32 i, void* pb)
  // i = 1;
  ldc.i4.1
  stloc.0
  // pb = pBuff;
  ldarg.0
  stloc.1

  Next:    // if(i > N) goto Return;
  ldloc.0
  ldarg.1
  bgt Return

  // printf(“%2.2d : %d\n”,i,*(int*)pb);
  ldstr "%2.2d : %d\n"
  ldloc.0
  ldloc.1
  ldind.i4
  call vararg int32 printf(string,...,int32,int32)
  pop

  // i += 1;
  ldloc.0
  ldc.i4.1
  add
  stloc.0

  // pb += 4; In C, this would be an illegal operation, because 
  // pb is void*, and the absolute pointer increment could not be 
  // calculated. In IL, however, the pointer increment is always
  // absolute (in bytes).
  ldloc.1
  ldc.i4.4
  add
  stloc.1
  br Next

  Return:
  ret
}


// I can’t pass the managed method pointer to unmanaged function,
// and even ldftn instruction is not going to help me.
// This delegate shall serve as an appropriate vehicle.

.class sealed public CompareDelegate
           extends [mscorlib]System.MulticastDelegate
{
  .method public specialname rtspecialname 
              instance void  .ctor(object 'object',
                                   native unsigned int 'method') runtime {}

  // Note the modopt modifier of the Invoke signature – it’s very
  // important. Without it, the calling convention of the callback
  // function shall be marshaled as stdcall (callee cleans the stack). 
  // The qsort, however, expects the callback function to have cdecl
  // calling convention (caller clears the stack). If we supply the
  // callback with stdcall calling convention, qsort shall blow 
  // the stack away and cause Memory Access Violation. You are welcome
  // to comment out the modopt line and see what happens.
  // Note also that the modopt modifier is placed on the delegate’s
  // Invoke signature, not on the signature of the delegated method.

  .method public virtual instance int32 
              modopt([mscorlib]System.Runtime.CompilerServices.CallConvCdecl)
              Invoke(void*, void*) runtime {}

  // Well, I don’t really need asynchronous invocation here, 
  // but you know, dura lex sed lex.

  .method public newslot virtual 
              instance class [mscorlib]System.IAsyncResult 
              BeginInvoke(object,
                          class [mscorlib]System.AsyncCallback,
                          object) runtime {}

  .method public newslot virtual 
              instance void  EndInvoke(class [mscorlib]System.IAsyncResult result) runtime {}

}

// The cause of the celebration – the qsort function.
.method public static pinvokeimpl("msvcrt.dll" ansi cdecl) 
	void qsort(void*,int32,int32,class CompareDelegate) preservesig {}

// This is the comparator method I’m going to offer as 
// a callback to qsort. What can be simpler than comparing
// two integers?
.method public static int32 compInt32(void* arg1,void* arg2) 
{
  // return(*arg1 - *arg2);
  ldarg 0
  ldind.i4
  ldarg 1
  ldind.i4
  sub
  ret
}

  
  
// And now, let’s put this show on the road.
.method public static void Exec()
{
  .entrypoint
  .locals(class CompareDelegate 'compDel')

  // Print the unsorted values
  ldstr "Before Sorting:\n"
  call vararg int32 printf(string)
  pop
  ldsflda valuetype SixtyBytes DataToSort 
  ldc.i4.s 15
  call void printInt32(void*, int32)

  // Create the delegate. Null object ref indicates the global method.
  ldnull
  ldftn int32 compInt32(void*,void*)
  newobj instance void CompareDelegate::.ctor(object,native unsigned int)
  stloc.0

  // Invoke qsort
  ldsflda valuetype SixtyBytes DataToSort // Pointer to data
  ldc.i4.s 15				  // Number of items to sort
  ldc.i4.4				  // Size of an individual item
  ldloc.0				  // Callback function pointer
  call void qsort(void*,int32,int32,class CompareDelegate)


  // Print the sorted values
  ldstr "After Sorting:\n"
  call vararg int32 printf(string)
  pop
  ldsflda valuetype SixtyBytes DataToSort 
  ldc.i4.s 15
  call void printInt32(void*, int32)

  ret
}
