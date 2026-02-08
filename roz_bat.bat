@echo off
setlocal enabledelayedexpansion

:: Set work directory to script location
set "BASE_DIR=%~dp0"
cd /d "%BASE_DIR%"

:: --- [ TOOLCHAIN CONFIGURATION ] ---
:: Note: These paths are machine-specific. 
:: Users on GitHub will need to update these to their local environment.
set "NASM_PATH=D:\nasm-3.01-win64\nasm-3.01\nasm.exe"
set "VS_BIN=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64"
set "WIN_KITS=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64"

:: --- [ PROJECT FILES ] ---
set "SRC_FILE=roz_SysMem.asm"
set "OBJ_FILE=roz_SysMem.obj"
set "DLL_OUT=roz_asm.dll"

echo [*] Starting ROZ_ASM Build Process...

:: 1. Compile Assembly Source
echo [1/2] Compiling: %SRC_FILE%...
"%NASM_PATH%" -f win64 "%SRC_FILE%" -o "%OBJ_FILE%"
if %errorlevel% neq 0 (
    echo [!] NASM Compilation Error!
    pause
    exit /b
)

:: 2. Link DLL with Exports
echo [2/2] Linking: %DLL_OUT%...
"%VS_BIN%\link.exe" /DLL /NOENTRY /MACHINE:X64 ^
    /OUT:"%DLL_OUT%" ^
    "%OBJ_FILE%" ^
    /LIBPATH:"%WIN_KITS%" ^
    /EXPORT:Luna_WinMemset ^
    /EXPORT:Luna_WinMemcpy ^
    /EXPORT:Luna_MemMove ^
    /EXPORT:Luna_MemSwap64 ^
    /EXPORT:Luna_ZeroFill ^
    /EXPORT:Luna_GetTicks ^
    /EXPORT:Luna_AtomicAdd64 ^
    /EXPORT:Luna_AtomicXchg64 ^
    /EXPORT:Luna_Prefetch ^
    /EXPORT:Luna_CacheFlush ^
    /EXPORT:Luna_MemIsZero ^
    /EXPORT:Luna_BitScanForward ^
    /EXPORT:Luna_StrLen ^
    /EXPORT:Luna_StrChr ^
    /EXPORT:Luna_Alloc ^
    /EXPORT:Luna_Calloc ^
    /EXPORT:Luna_Free ^
    /EXPORT:Luna_Realloc ^
    kernel32.lib

if %errorlevel% neq 0 (
    echo [!] Linker Error!
    pause
    exit /b
)

echo.
echo [SUCCESS] Build Complete: %DLL_OUT%
echo [*] Cleaning up temporary files...

:: Delete object and linker auxiliary files
if exist "%OBJ_FILE%" del "%OBJ_FILE%"
if exist "roz_asm.exp" del "roz_asm.exp"
if exist "roz_asm.lib" del "roz_asm.lib"

pause