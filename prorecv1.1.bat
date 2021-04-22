@echo off
          REM Comments

    REM ffmpeg batch program for prores, xvid, and h264 encoding for entire prerec folders/indivdual rec files w/basic ui
    REM currently WIP

    REM Been experiementing with windowsforms and UWP so expect full single page ui when I get time to work on it (something like avifrate or vdub, not sure yet)

    REM second time doing anything in batch so bear with me.
    REM message me on discord if you have any questions: something#7597


       REM vvvvv scroll to the bottom if you want to edit the ffmpeg config vvvvv

          REM program env variables
set foldername="e_"
    REM L set this to whatever you want as the prefix for the created folder/file. default - "e_" 
set dontconfirm=0
    REM L Confirm dialog toggle. (1=on 0=off) default - 0
set tempfiledir="%tmp%\"
    REM L this is where the program puts the temp vbs files. Don't edit this if the program works as intended with its default value "%tmp%\"

       REM to switch default codec and fps, go to line # and change the third parameter

          REM vvvv code vvvv


setlocal enabledelayedexpansion
goto init

:init
if [%1]==[] (
    set isDragged=0
    pushd %~dp0
) else (
    set isDragged=1
    if exist "%~1\*" (
       pushd %~1
    ) else (
       pushd %~dp1 & goto singlefileencode
    )
)
if exist *.mp4 goto folderencode & if exist *.avi goto folderencode & if exist *.wmv goto folderencode & if exist *.mov goto folderencode & if exist *.m4v goto folderencode
goto empty

:singlefileencode
set responseconfirm=1
if %dontconfirm%==0 call :confirm "Single file encode? Open batch file in notepad for more info. (You can disable this popup by changing dontconfirm to 1 in the batch file)" "Single File - prorecv1.5"
if !responseconfirm!==0 ( exit)
call :askinfo
set file=%~n1%~x1
set name=%~n1
if not exist "!foldername!!format!" ( mkdir "!foldername!!format!")
set inputdirectory=!file! & set "outputdirectory=!foldername!!format!\!name!" )
call :encodesettings
!%format%!
goto end

goto end

:folderencode
set responseconfirm=1
if %dontconfirm%==0 call :confirm "Single directory encode? Open batch file in notepad for more info. (You can disable this popup by changing dontconfirm to 1 in the batch file)" "Single Directory - prorecv1.5"
if !responseconfirm!==0 ( exit)
call :askinfo
set filename=%cd%~1
call :encodedirectory

goto end

:empty
call :msgbox "There is nothing to encode. Try dragging a file/folder onto the batch file or try copy pasting this batch file into a directory with files/folders."
exit

:end
call :msgbox "Finished"
exit

       REM functions/methods

    REM msgbox in Wscript. usage - call :msgbox "[message]"
:msgbox
echo msgbox "%~1" > !tempfiledir!tmp.vbs
wscript !tempfiledir!tmp.vbs
del !tempfiledir!tmp.vbs
exit /b

    REM inputbox in wscript to ask for codec and fps.(could have maybe just used a function for ask and used it twice but hybrid has limitations) usage - call :askinfo
:askinfo
:wscript.echo InputBox("What codec would you like to use? [xvid, prores, h264]","Codec - prorecv1.5","")
:wscript.echo InputBox("What fps would you like to use?","FPS - prorecv1.5","600")
findstr "^:wscript" "%~sf0">!tempfiledir!tmp.vbs
set i=0 & for /f "delims=" %%n in ('cscript //nologo !tempfiledir!tmp.vbs') do ( set /a i+=1 & set param!i!=%%n)
set format=%param1%& set fps=%param2%
del !tempfiledir!tmp.vbs
exit /b

    REM Wscript yes no popup that sets responseconfirm to 1 or 0 based off response. usage - call :confirm "[message]" "[title]"
:confirm
echo set WshShell = WScript.CreateObject("WScript.Shell") > !tempfiledir!tmp.vbs
echo WScript.Quit (WshShell.Popup( "%~1" ,0 ,"%~2", vbYesNo)) >> !tempfiledir!tmp.vbs
cscript /nologo !tempfiledir!tmp.vbs
if !errorlevel!==6 ( set responseconfirm=1) else ( set responseconfirm=0)
exit /b


    REM [UNUSED] scuffed folder selector using shellapp and sets selectedfolder to path. usage - call :folderselect "[message]"
:folderselect
set folderSelector="(new-object -COM 'Shell.Application').BrowseForFolder(0, '%~1:',1, '::{20D04FE0-3AEA-1069-A2D8-08002B30309D}').self.path;"
for /f "usebackq delims=" %%i in (`powershell %folderSelector%`) do set "selectedfolder=%%i"
exit /b

    REM selection list for selecting items using wscript and a handful of other stuff. usage - call :selectionlist "[option1] [option2] [option3] ..."
:selectionlist
set /a i=0
findstr /e "'VBS" "%~f0">!tempfiledir!tmp.vbs & for /f "delims=" %%n in ('cscript //nologo !tempfiledir!tmp.vbs %~1') do ( set /a i+=1 & set param!i!=%%n) & set /a i=0
:results
set /a i+=1
if [!param%i%!]==[] goto selectionend
del !tempfiledir!tmp.vbs
goto results
:selectionend
exit /b

    REM used to create encoded folder and to create encoded files within same directory (basically gmzorz thing). usage - call :encodedirectory
:encodedirectory
for %%a in (*.mp4, *.avi, *.wmv, *.mov, *.m4v) do (
    set file=%%a
    set name=%%~na
    echo !file!
    echo !name!
    if not exist "!foldername!!format!" ( mkdir "!foldername!!format!")
    set inputdirectory=!file! & set "outputdirectory=!foldername!!format!\!name!"
    call :encodesettings
    !%format%!
)
exit /b

       REM --------------------------FFMPEG CONFIG--------------------------

    REM apart from the h264 config, this is pretty much the same as gmzorz's prorec config (may add more in the future)
:encodesettings
set "xvid=ffmpeg -r ^"!fps!^" -i ^"!inputdirectory!^" -c:v mpeg4 -vtag xvid -qscale:v 1 -qscale:a 1 -g 32 -vsync 1 -y ^"!outputdirectory!^".avi"
    REM for fast editing during hcs or editing contests (slower playback speed+worse quality but really speedy encode time)
set "prores=ffmpeg -r ^"!fps!^" -i ^"!inputdirectory!^" -c:v prores_ks -profile:v 3 -c:a pcm_s16le -y ^"!outputdirectory!^".mov"
    REM general use codec for regular prerecs or cinematics (better playback speed+quality but 10x slower encode time)
set "h264=ffmpeg -r ^"!fps!^" -i ^"!inputdirectory!^" -c:v libx264 -crf 4 -y ^"!outputdirectory!^".mp4"
    REM good for creating prerecs but vegas incompatible (relatively small file size) im pretty sure you can vdub these
exit /b

    REM L used to set encode settings. usage - call :encodesettings & !%format%!

rem best girl