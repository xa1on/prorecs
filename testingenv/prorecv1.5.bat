@echo off
    REM ffmpeg batch program for prores, xvid, and h264 encoding for entire prerec folders/indivdual rec files
    
    REM C# WPF overrated. batch vscript on top
    REM expect full ui in windowsforms or UWP when I get time to learn it

setlocal enabledelayedexpansion
pushd %~dp0
goto start

:start

echo. & echo filetype: 
call :confirm "Are you converting a folder? Select No if you just want to convert a single file." "Confirm"
if %responseconfirm% == 1 ( echo folder & echo. & goto folderconvert)

echo file & echo.
goto singlefile

:singlefile
call :msgbox "Press OK then drag your file into command prompt and press enter"
set /p path = Drag file here: 
cd %~dp0
echo file path: %cd%

:folderconvert
call :folderselect

:end
echo Done.
call :msgbox "Finished"
exit






    REM --------------------------FUNCTIONS--------------------------

    REM temp msgbox in Wscript
:msgbox
echo msgbox "%~1" > %tmp%\tmp.vbs
wscript %tmp%\tmp.vbs
del %tmp%\tmp.vbs
exit /b


    REM Vscript yes no popup that sets responseconfirm to 1 or 0 based off response. usage - set :confirm [message] [title]
:confirm
echo set WshShell = WScript.CreateObject("WScript.Shell") > %tmp%\tmp.vbs
echo WScript.Quit (WshShell.Popup( "%~1" ,0 ,"%~2", vbYesNo)) >> %tmp%\tmp.vbs
cscript /nologo %tmp%\tmp.vbs
if %errorlevel%==6 (set "responseconfirm=1")
if %errorlevel%==7 (set "responseconfirm=0")
exit /b


    REM scuffed folder selector using shellapp and sets selectedfolder to path. usage - set :folderselect [message]
:folderselect
set folderSelector="(new-object -COM 'Shell.Application').BrowseForFolder(0, '%~1:',1, '::{20D04FE0-3AEA-1069-A2D8-08002B30309D}').self.path;"
for /f "usebackq delims=" %%i in (`powershell %folderSelector%`) do set "selectedfolder=%%i"
exit /b


    REM used to create converted folder and to create converted files within same directory (basically gmzorz thing)
:convertdirectory
for %%a in (*.mp4, *.avi, *.wmv, *.mov, *.m4v) do(
	set file=%%a
	set name=%%~na
	goto skip
	call:convertsettings
	if not exist "converted_!format!" ( mkdir "converted_!format!")
	!%format%!
	:skip
)
exit /b






    REM --------------------------FFMPEG CONFIG--------------------------

    REM apart from the h264 config, this is pretty much the same as gmzorz's prorec config
:convertsettings
set "xvid=ffmpeg -r ^"!fps!^" -i ^"!file!^" -c:v mpeg4 -vtag xvid -qscale:v 1 -qscale:a 1 -g 32 -vsync 1 -y ^"converted_!format!^"/^"!name!^".avi"
	REM for fast editing during hcs or editing contests (slower playback speed+worse quality but really speedy encode time)
set "prores=ffmpeg -r ^"!fps!^" -i ^"!file!^" -c:v prores_ks -profile:v 3 -c:a pcm_s16le -y ^"converted_!format!^"/^"!name!^".mov"
	REM general use codec for regular prerecs or cinematics (better playback speed+quality but 10x slower encode time)
set "h264=ffmpeg -r ^"!fps!^" -i ^"!file!^" -c:v libx264 -crf 4 -y ^"converted_!format!^"/^"!name!^".mp4"
	REM good for creating prerecs but vegas incompatible (relatively small file size) im pretty sure you can vdub these
exit /b

rem best girl