// ===============================================================
// 
//   ILLINK -- Microsoft (R) .NET Framework IL Linker
// 
//   Author: Serge Lidin (slidin@microsoft.com)
//
//   Version: 1.0 (April 05,2002)
//
//   This source code is provided "as is" without any warranties of any kind
//
// ===============================================================
#include "windows.h"
#include <stdio.h>
#include <process.h>
#include <stdlib.h>
#include <wchar.h>

// Used for parsing the command line arguments
WCHAR* EqualOrColon(WCHAR* szArg)
{
	WCHAR* pchE = wcschr(szArg,L'=');
	WCHAR* pchC = wcschr(szArg,L':');
	WCHAR* ret;
	if(pchE == NULL) ret = pchC;
	else if(pchC == NULL) ret = pchE;
	else ret = (pchE < pchC)? pchE : pchC;
	return ret;
}

// Used for eliminating the leading spaces of a text line
WCHAR* SkipBlanks(WCHAR* wz)
{
    WCHAR* wch;
    for(wch = wz; *wch == ' '; wch++); // ILDASM guarantees the strings are terminated
    return wch;
}

// Used in search for resolution scopes and data labels
BOOL NotCommentOrLiteral(WCHAR* wzString, WCHAR* wzPtr)
{
    BOOL fIsComment=FALSE;
    BOOL fIsLiteral=FALSE;
    for(WCHAR* wz=wzString; wz<wzPtr; wz++)
    {
        if(fIsLiteral)
        {
            if(*wz == '"') fIsLiteral = FALSE;
        }
        else
        {
            if(fIsComment)
            {
                if((*wz == '*')&&(*(wz+1)=='/')) {fIsComment = FALSE; wz++;}
            }
            else
            {
                if(*wz == '"') fIsLiteral = TRUE;
                else if(*wz == '/')
                {
                    if(*(wz+1)=='*') {fIsComment = TRUE; wz++;}
                    else if((*wz+1)=='/') {fIsComment = TRUE; break; }
                }
            }
        }
    }
    return !(fIsComment || fIsLiteral);
}

// Used for data label modification according to file number: radix 64
WCHAR* EncodeInt(unsigned i)
{
    static WCHAR* wzSymbol = L"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$";
    static WCHAR wzRet[3];
    i &= 0xFFF; // actually, 0 <= i < 1024, but just in case...
    wzRet[0] = wzSymbol[i >> 6];
    wzRet[1] = wzSymbol[i & 0x3F];
    wzRet[2] = 0;
    return wzRet;
}

extern "C" int _cdecl wmain(int argc, WCHAR *argv[])
{
    WCHAR       wzOutputFilename[512];
    WCHAR	*pwzInputFile[1024];
    WCHAR       *pwzModuleName[1024];
    unsigned    i, j;
    unsigned    NumFiles = 0;
    WCHAR	szOpt[4];
    int		exitval=1;
    bool	bLogo = TRUE;
    BOOL        fAutoResFile = FALSE;
    BOOL        fDeleteIntermediateFiles = TRUE;
    WCHAR       wz[4096];
    WCHAR       wzOther[4096];
    WCHAR       *wzSubsystem=NULL, *wzComImageFlags=NULL, *wzFileAlignment=NULL, *wzDebug=NULL,
                *wzBaseAddress=NULL,*wzKeySourceName=NULL,*wzResFile=NULL;
    DWORD       dwVTEntryBase=0,dwVTEntries,dwExportBase=0,dwExports;
    
    OSVERSIONINFO   osVerInfo;

    osVerInfo.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
    if (!(GetVersionEx(&osVerInfo) && osVerInfo.dwPlatformId == VER_PLATFORM_WIN32_NT))
    {
        fprintf(stderr,"The ILLINK utility is not intended for Windows 9x and ME systems\n");
        exit(1);
    }
    
	memset(wzOutputFilename,0,sizeof(wzOutputFilename));

    if (argc < 3 || ! wcscmp(argv[1], L"/?") || ! wcscmp(argv[1],L"-?"))
    { 
		printf("\nMicrosoft (R) .NET Framework IL Linker.  Version 1.0\n\n");
    ErrorExit:
        printf("\n\nUsage: illink <files_being_linked> /out=<linked_file> [<options>]");
        printf("\n\n  The names of files being linked must maintain casing of respective");
        printf("\n  modules or assemblies. For example, if you link assembly System.Windows.Forms,");
        printf("\n  specify it as System.Windows.Forms.dll");
        printf("\n\nOptions:");
        printf("\n/RESOURCE=<res_file>	Link the specified resource file (*.res) \n\t\t\tinto resulting .exe or .dll");
        printf("\n/DEBUG			Include debug information");
        printf("\n/PRESERVE		Don't delete the intermediate .IL files on exit");
        printf("\n/KEY=<keyfile>		Link with strong signature \n\t\t\t(<keyfile> contains private key)");
        printf("\n/KEY=@<keysource>	Link with strong signature \n\t\t\t(<keysource> is the private key source name)");
        printf("\n/SUBSYSTEM=<int>	Set Subsystem value in the NT Optional header");
        printf("\n/FLAGS=<int>		Set CLR ImageFlags value in the CLR header");
        printf("\n/ALIGNMENT=<int>	Set FileAlignment value in the NT Optional header");
        printf("\n/BASE=<int>		Set ImageBase value in the NT Optional header");
        printf("\n\nKey may be '-' or '/'\nOptions are recognized by first 3 characters\n'=' and ':' in options are interchangeable\n\n");
        if(argc >= 3) exitval = 0;
        exit(exitval);
    }

    //-------------------------------------------------
    for (i = 1; i < (unsigned)argc; i++)
    {
        if((argv[i][0] == L'/') || (argv[i][0] == L'-'))
        {
            wcsncpy(szOpt,&argv[i][1],3);
            szOpt[3] = 0;
            if (!_wcsicmp(szOpt, L"out"))
            {
                WCHAR *pStr = EqualOrColon(argv[i]);
                if(pStr == NULL) goto ErrorExit;
                for(pStr++; *pStr == L' '; pStr++); //skip the blanks
                if(wcslen(pStr)==0) goto ErrorExit; //if no file name
                wcscpy(wzOutputFilename,pStr);
            }
            else if (!_wcsicmp(szOpt, L"ali")) wzFileAlignment = argv[i];
            else if (!_wcsicmp(szOpt, L"fla")) wzComImageFlags = argv[i];
            else if (!_wcsicmp(szOpt, L"sub")) wzSubsystem = argv[i];
            else if (!_wcsicmp(szOpt, L"bas")) wzBaseAddress = argv[i];
            else if (!_wcsicmp(szOpt, L"deb")) wzDebug = argv[i];
            else if (!_wcsicmp(szOpt, L"key")) wzKeySourceName = argv[i];
            else if (!_wcsicmp(szOpt, L"res")) wzResFile = argv[i];
            else if (!_wcsicmp(szOpt, L"pre")) fDeleteIntermediateFiles = FALSE;
            else
            {
                fwprintf(stderr,L"Error : Invalid Option: %s", argv[i]);
                goto ErrorExit;
            }
        }                                              
        else
        {
            for(j = 0; j < NumFiles; j++)
            {
                if(!_wcsicmp(argv[i],pwzInputFile[j])) break;
            }
            if(j >= NumFiles)
            {
                WCHAR *wc = wcsrchr(argv[i],'\\');
                if(!wc) wc = wcsrchr(argv[i],':');
                if(!wc) wc = argv[i];
                else wc++;
                if(NumFiles >= 1024)
                {
                    fwprintf(stderr,L"Cannot link more than 1024 files.\n");
                    exit(1);
                }
                pwzModuleName[NumFiles] = wc;
                pwzInputFile[NumFiles++] = argv[i];
            }
            else
                fwprintf(stderr,L"Duplicate input file %s, ignored.\n",argv[i]);
        }
        
    }
    if((NumFiles == 0)||(wzOutputFilename[0] == 0)) goto ErrorExit;
    if(NumFiles == 1) // trivial case: nothing to link
    {
        wcscpy(wz,L"copy ");
        wcscat(wz,pwzInputFile[0]);
        wcscat(wz,L" ");
        wcscat(wz,wzOutputFilename);
        _wsystem(wz);
        exit(0);
    }

    BOOL fAssemblyDeclared = FALSE;
    BOOL fModuleDeclared = FALSE;
    FILE *pTempIL, *pOutIL,*pOutHeader, *pOut;
    system("mkdir illinktempdir");

    pOutHeader = fopen("illinktempdir\\illinktempoutheader.il","wb");
    if(pOutHeader==NULL)
    {
        fprintf(stderr,"Failed to open intermediate header file.\n");
        exit(1);
    }
    fwrite("\377\376",2,1,pOutHeader);  // UNICODE signature
    pOutIL = fopen("illinktempdir\\illinktempoutfile.il","wb");
    if(pOutIL==NULL)
    {
        fprintf(stderr,"Failed to open intermediate output file.\n");
        fclose(pOutHeader);
        DeleteFileA("illinktempoutheader.il");
        exit(1);
    }
    //fwrite("\377\376",2,1,pOutIL);  // UNICODE signature
    SetCurrentDirectoryA(".\\illinktempdir");
    for(i = 0; i < NumFiles; i++)
    {
        // 1. Disassemble the input file to temp. il file
        wcscpy(wz,L"ildasm /nob /uni /out:illinktempinfile.il ");
        if(wzDebug) wcscat(wz,L"/lin ");
        if(wcschr(pwzInputFile[i],'\\')==NULL) wcscat(wz,L"..\\");
        wcscat(wz,pwzInputFile[i]);
        _wsystem(wz);

        // 2. Pump temp. il file to output il file, editing as necessary
        pTempIL = fopen("illinktempinfile.il","rb");
        if(pTempIL == NULL)
        {
            fprintf(stderr,"Failed to open intermediate input file. Possible failure disassembling %s\n",pwzInputFile[i]);
            fclose(pOutIL);
            DeleteFileA("illinktempoutfile.il");
            fclose(pOutHeader);
            DeleteFileA("illinktempoutheader.il");
            goto CleanUpAndExit;
        }
        // If the /RESOURCE= option is not specified, try using the .res file of first linked module
        if((i==0)&&(wzResFile==NULL))
        {
            pOut = fopen("illinktempinfile.res","rb");
            if(pOut)
            {
                fclose(pOut);
                system("copy illinktempinfile.res illinkautores32.res");
                fAutoResFile = TRUE;
            }
        }
        DeleteFileA("illinktempinfile.res");

        dwVTEntries = 0;
        dwExports = 0;

        fgetws(wz,4095,pTempIL);
        fgetws(wz,4095,pTempIL);
        fgetws(wz,4095,pTempIL);

        pOut = pOutHeader;  // Manifest and forward class decls go to header file
        memset(wz,0,sizeof(wz));
        while(fgetws(wz,4095,pTempIL))
        {
            WCHAR* wch = SkipBlanks(wz);

            // 2.1. Skip the blank and comment lines
            if(*wch == '\r') continue;
            if((*wch == '/')&&(*(wch+1) == '/'))
            {
                if(wcsstr(wch,L"// =============== GLOBAL FIELDS AND METHODS")) pOut = pOutIL;
                // Globals, class members and data go to IL file
                continue;
            }

            // 2.2. Skip duplicate assembly decls
            if(!wcsncmp(wch,L".assembly ",10))
            {
                BOOL fSkipToClosingBraceAndContinue=FALSE;
                if(wcsncmp(wch,L".assembly extern",16))
                {
                    if(fAssemblyDeclared) fSkipToClosingBraceAndContinue = TRUE;
                    else fAssemblyDeclared = TRUE;
                }
                else
                {
                    WCHAR *wzAssemblyName = wzOther;
                    for(j = 0; j < NumFiles; j++)
                    {
                        wcscpy(wzAssemblyName,pwzModuleName[j]);
                        wch = wcsrchr(wzAssemblyName,'.');
                        if(wch) *wch = 0;
                        wch = wcsstr(wz,wzAssemblyName);
                        if(wch)
                        {
                            wch += wcslen(wzAssemblyName);
                            if((*wch == ' ')||(*wch == '\r')||(*wch == '\n'))
                            { 
                                fSkipToClosingBraceAndContinue = TRUE;
                                break;
                            }
                        }
                    }
                }
                if(fSkipToClosingBraceAndContinue)
                {
                    while(fgetws(wz,4095,pTempIL))
                    {
                        wch = SkipBlanks(wz);
                        if(*wch == '}') break;
                    }
                }
                else fputws(wz,pOut);

            }
            // 2.3. Skip module ref decls pertinent to linked files
            else if(!wcsncmp(wch,L".module ",8))
            {
                if(!wcsncmp(wch,L".module extern ",15))
                {
                    for(j = 0; j < NumFiles; j++)
                    {
                        wch = wcsstr(wz,pwzModuleName[j]);
                        if(wch) break;
                    }
                    if(j >= NumFiles) fputws(wz,pOut);
                }
                else
                {
                    if(!fModuleDeclared)
                    {
                        fModuleDeclared = TRUE;
                        fputws(wz,pOut);
                    }
                }
            }
            // 2.4. Skip file decls pertinent to linked files
            else if(!wcsncmp(wch,L".file ",6))
            {
                for(j = 0; j < NumFiles; j++)
                {
                    wch = wcsstr(wz,pwzModuleName[j]);
                    if(wch) break;
                }
                if(j < NumFiles)   // .file can be followed by .entrypoint and .hash = (<bytearray>)
                {
                    if(fgetws(wz,4095,pTempIL))
                    {
                        wch = SkipBlanks(wz);
                        if(!wcsncmp(wch,L".entrypoint",11))
                        { 
                            wch = fgetws(wz,4095,pTempIL);
                            if(wch) wch = SkipBlanks(wz);
                        }
                        if(!wcsncmp(wch,L".hash = (",9))
                        {
                            do
                            {
                                wch = wcsstr(wz,L"//");
                                if(wch) *wch = 0; // cut off the comments which may contain anything
                                if(wcschr(wz,')')) break;
                            } 
                            while(fgetws(wz,4095,pTempIL));
                        }
                        else fputws(wz,pOut);
                    }
                }
                else fputws(wz,pOut);
            }
            // 2.5. Skip exported type decls pertinent to linked files
            else if(!wcsncmp(wch,L".class extern ",14))
            {
                WCHAR *wzNext = &wzOther[4000]; // next line is only opening brace
                WCHAR *wzAfterNext = wzOther; // implementation
                BOOL fWriteLines = TRUE;
                if(!fgetws(wzNext,95,pTempIL)) continue;
                if(!fgetws(wzAfterNext,3999,pTempIL)) continue;
                wch = SkipBlanks(wzAfterNext);
                if(!wcsncmp(wch,L".file ",6))
                {
                    for(j = 0; j < NumFiles; j++)
                    {
                        wch = wcsstr(wz,pwzModuleName[j]);
                        if(wch) break;
                    }
                    if(j < NumFiles)
                    {
                        while(fgetws(wz,4095,pTempIL))
                        {
                            wch = SkipBlanks(wz);
                            if(*wch == '}') break;
                        }
                        fWriteLines = FALSE;
                    }
                }
                if(fWriteLines)
                {
                    fputws(wz,pOut);
                    fputws(wzNext,pOut);
                    fputws(wzAfterNext,pOut);
                }
            }
            else // No line skipping any more, in-line surgery
            {
                // 2.6. Shift .vtentry entry number, leave slot number as is
                if(!wcsncmp(wch,L".vtentry ",9))
                {
                    DWORD dwVTEntry;
                    WCHAR* wch1;
                    wch += 9;
                    wch1 = wcschr(wch,':');  // can't really be NULL -- it's ILDASM output
                    if(wch1)
                    {
                        *wch1 = 0;
                        swscanf(wch,L"%d",&dwVTEntry);
                        if(dwVTEntry > dwVTEntries) dwVTEntries = dwVTEntry;
                        if(dwVTEntryBase)
                        {
                            dwVTEntry += dwVTEntryBase;
                            wcscpy(wzOther,wch1+1);
                            swprintf(wch,L"%d :",dwVTEntry);
                            wcscat(wz,wzOther);
                        }
                        else *wch1 = ':';
                    }

                }
                // 2.7. Shift .export number
                else if(!wcsncmp(wch,L".export [",9))
                {
                    DWORD dwExport;
                    WCHAR* wch1;
                    wch += 9;
                    wch1 = wcschr(wch,']');  // can't really be NULL -- it's ILDASM output
                    if(wch1)
                    {
                        *wch1 = 0;
                        swscanf(wch,L"%d",&dwExport);
                        if(dwExport > dwExports) dwExports = dwExport;
                        if(dwExportBase)
                        {
                            dwExport += dwExportBase;
                            wcscpy(wzOther,wch1+1);
                            swprintf(wch,L"%d]",dwExport);
                            wcscat(wz,wzOther);
                        }
                        else *wch1 = ']';
                    }

                }

                // 2.8. Remove class ref res.scopes pertinent to linked files
                for(j = 0; j < NumFiles; j++)
                {
                    WCHAR *wzPattern = wzOther;
                    WCHAR *wcopen=NULL, *wcclose=wz;
                    wcscpy(wzPattern,pwzModuleName[j]);
                    wch = wcsrchr(wzPattern,'.');
                    if(wch) *wch = 0; // off with the extension
                    while((wcopen=wcschr(wcclose,'['))&&(wcclose=wcschr(wcopen,']')))
                    {
                        if(NotCommentOrLiteral(wz,wcopen))
                        {
                            if((wch = wcsstr(wcopen,wzPattern))&&(wch < wcclose))
                            {
                                wcclose++;
                                if(*wcclose == ':') wcclose+=2;
                                wcscpy(wcopen,wcclose);
                                wcclose = wcopen+1;
                            }
                        }
                    }
                }
                // 2.9. Modify data labels
                while((wch = wcsstr(wz,L" D_00"))||(wch = wcsstr(wz,L" T_00")))
                {
                    if(NotCommentOrLiteral(wz,wch))
                    {
                        wcscpy(wch+2,EncodeInt(i));
                        *(wch+4) = '0';
                    }
                }
                fputws(wz,pOut);
            }
            //
            memset(wz,0,sizeof(wz));
        } // end while(fgetws(wz,4095,pTempIL))
        fclose(pTempIL);
        DeleteFileA("illinktempinfile.il");
        dwVTEntryBase += dwVTEntries;
        dwExportBase  += dwExports;
    } // end for(i = 0; i < NumFiles; i++)

    // 3. Close the output il file and assemble it
    fclose(pOutHeader);
    fclose(pOutIL);
    _wsystem(L"copy /b illinktempoutheader.il+illinktempoutfile.il illinktemptotal.il");
    wcscpy(wz,L"ilasm illinktemptotal.il /qui /out:");
    if(wcschr(wzOutputFilename,'\\')==NULL) wcscat(wz,L"..\\");
    wcscat(wz,wzOutputFilename);
    if(wcsstr(wzOutputFilename,L".dll")||wcsstr(wzOutputFilename,L".DLL")) wcscat(wz,L" /dll");
    if(wzDebug)         { wcscat(wz,L" "); wcscat(wz,wzDebug); }
    if(wzSubsystem)     { wcscat(wz,L" "); wcscat(wz,wzSubsystem); }
    if(wzComImageFlags) { wcscat(wz,L" "); wcscat(wz,wzComImageFlags); }
    if(wzFileAlignment) { wcscat(wz,L" "); wcscat(wz,wzFileAlignment); }
    if(wzBaseAddress)   { wcscat(wz,L" "); wcscat(wz,wzBaseAddress); }
    if(wzKeySourceName) { wcscat(wz,L" "); wcscat(wz,wzKeySourceName); }
    if(wzResFile)       { wcscat(wz,L" "); wcscat(wz,wzResFile); }
    else if(fAutoResFile) wcscat(wz,L" /res:illinkautores32.res");

    wcscat(wz,L" > ilasm.log");
    
    _wsystem(wz);
    SetCurrentDirectoryA("..\\");

    exitval = 0;
  CleanUpAndExit:
    // Temporary files and directory removal
    if(fDeleteIntermediateFiles)
    {
        system("del illinktempdir\\*.* /Q");
        system("rmdir illinktempdir");
    }
    exit(exitval);
}
