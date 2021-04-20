    REM simple script for deleting all v1 converted files
@echo off
setlocal enabledelayedexpansion
pushd %~dp0
echo folders:
echo .
for /f "delims=" %%D in ('dir /a:d /b') do (
    echo %%~nxD
    pushd %~dp0\%%~nxD
    for /d /r . %%d IN (converted_*) do @if exist "%%d" rd /s /q "%%d"\
    popd
)
echo complete.