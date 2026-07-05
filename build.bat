@echo off
setlocal

rem ============================================================
rem BeyondDimmer build script
rem Place this file in the BeyondDimmer project root folder.
rem ============================================================

cd /d "%~dp0"

set "ROOT=%~dp0"
set "AHK2EXE=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
set "BASE=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"

set "SRC=%ROOT%src\BeyondDim.ahk"
set "OUTDIR=%ROOT%release"
set "OUT=%OUTDIR%\BeyondDim.exe"
set "ICON=%ROOT%assets\icons\candidates\icon_01_gradient_square.ico"

echo.
echo [BeyondDimmer Build]
echo ROOT  : "%ROOT%"
echo SRC   : "%SRC%"
echo OUT   : "%OUT%"
echo ICON  : "%ICON%"
echo.

if not exist "%AHK2EXE%" (
    echo ERROR: Ahk2Exe.exe was not found.
    echo "%AHK2EXE%"
    echo.
    pause
    exit /b 1
)

if not exist "%BASE%" (
    echo ERROR: AutoHotkey v2 base executable was not found.
    echo "%BASE%"
    echo.
    pause
    exit /b 1
)

if not exist "%SRC%" (
    echo ERROR: Source file was not found.
    echo "%SRC%"
    echo.
    echo Check that BeyondDim.ahk exists in the src folder.
    echo.
    pause
    exit /b 1
)

if not exist "%ICON%" (
    echo ERROR: Icon file was not found.
    echo "%ICON%"
    echo.
    pause
    exit /b 1
)

if not exist "%OUTDIR%" (
    mkdir "%OUTDIR%"
)

"%AHK2EXE%" ^
  /in "%SRC%" ^
  /out "%OUT%" ^
  /base "%BASE%" ^
  /icon "%ICON%"

if errorlevel 1 (
    echo.
    echo ERROR: Build failed.
    echo.
    pause
    exit /b 1
)

echo.
echo Build completed successfully.
echo "%OUT%"
echo.
pause
exit /b 0
