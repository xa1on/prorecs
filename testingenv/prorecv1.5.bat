@echo off
    REM ffmpeg batch program for prores, xvid, and h264 encoding for entire prerec folders/indivdual rec files w/basic ui
    REM currently WIP

    REM Been experiementing with windowsforms and UWP so expect full ui when I get time to work on it (something like avifrate or vdub not sure)

    REM second time doing anything in batch so bear with me.
    REM message me on discord if you have any questions: something#7597


setlocal enabledelayedexpansion
goto init

:init
if [%1]==[] (
    set isDragged=0
    pushd %~dp0
    for /f "delims=" %%D in ('dir /a:d /b') do ( set folderExist=1 & goto batchfolderencode)
    if exist *.mp4 goto folderencode
    if exist *.avi goto folderencode
    if exist *.wmv goto folderencode
    if exist *.mov goto folderencode
    if exist *.m4v goto folderencode
    goto empty
) else (
    set isDragged=1
    for %%i in (%~dp1) do ( if exist %%~si\nul ( pushd %1 & goto singlefileencode) else ( pushd %~dp1 & goto folderencode))
)

:singlefileencode
call :confirm "Single file encode?" "Confirmation"

goto end

:batchfolderencode:
call :confirm "Batch Folder encode?" "Confirmation"

goto end

:folderencode
call :confirm "Single directory encode?" "Confirmation"

goto end

:empty
call :msgbox "There is nothing to encode. Try dragging a file/folder onto the batch file or try copy pasting this batch file into a directory with files/folders"

exit

:end
echo Done.
call :msgbox "Finished"
exit






    REM --------------------------FUNCTIONS--------------------------

    REM temp msgbox in Wscript. usage - set :msgbox "[message]"
:msgbox
echo msgbox "%~1" > %tmp%\tmp.vbs
wscript %tmp%\tmp.vbs
del %tmp%\tmp.vbs
exit /b


    REM Vscript yes no popup that sets responseconfirm to 1 or 0 based off response. usage - set :confirm "[message]" "[title]"
:confirm
echo set WshShell = WScript.CreateObject("WScript.Shell") > %tmp%\tmp.vbs
echo WScript.Quit (WshShell.Popup( "%~1" ,0 ,"%~2", vbYesNo)) >> %tmp%\tmp.vbs
cscript /nologo %tmp%\tmp.vbs
if %errorlevel%==6 (set "responseconfirm=1")
if %errorlevel%==7 (set "responseconfirm=0")
exit /b


    REM scuffed folder selector using shellapp and sets selectedfolder to path. usage - set :folderselect "[message]"
:folderselect
set folderSelector="(new-object -COM 'Shell.Application').BrowseForFolder(0, '%~1:',1, '::{20D04FE0-3AEA-1069-A2D8-08002B30309D}').self.path;"
for /f "usebackq delims=" %%i in (`powershell %folderSelector%`) do set "selectedfolder=%%i"
exit /b


    REM used to create encoded folder and to create encoded files within same directory (basically gmzorz thing)
:encodedirectory
for %%a in (*.mp4, *.avi, *.wmv, *.mov, *.m4v) do(
	set file=%%a
	set name=%%~na
	goto skip
	call:encodesettings
	if not exist "encoded_!format!" ( mkdir "encoded_!format!")
	!%format%!
	:skip
)
exit /b






    REM --------------------------FFMPEG CONFIG--------------------------

    REM apart from the h264 config, this is pretty much the same as gmzorz's prorec config (may add more in the future)
:encodesettings
set "xvid=ffmpeg -r ^"!fps!^" -i ^"!file!^" -c:v mpeg4 -vtag xvid -qscale:v 1 -qscale:a 1 -g 32 -vsync 1 -y ^"encoded_!format!^"/^"!name!^".avi"
	REM for fast editing during hcs or editing contests (slower playback speed+worse quality but really speedy encode time)
set "prores=ffmpeg -r ^"!fps!^" -i ^"!file!^" -c:v prores_ks -profile:v 3 -c:a pcm_s16le -y ^"encoded_!format!^"/^"!name!^".mov"
	REM general use codec for regular prerecs or cinematics (better playback speed+quality but 10x slower encode time)
set "h264=ffmpeg -r ^"!fps!^" -i ^"!file!^" -c:v libx264 -crf 4 -y ^"encoded_!format!^"/^"!name!^".mp4"
	REM good for creating prerecs but vegas incompatible (relatively small file size) im pretty sure you can vdub these
exit /b

rem best girl