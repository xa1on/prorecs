@echo off
          REM Comments

    REM EXPERIMENTAL PRORECS v1.5.2

    REM ffmpeg batch program for prores, xvid, and h264 encoding for entire prerec folders/indivdual rec files w/basic ui
    REM currently WIP

    REM Been experiementing with windowsforms and UWP so expect full single page ui when I get time to work on it (something like avifrate or vdub, not sure yet)

    REM second time doing anything in batch so bear with me.
    REM message me on discord if you have any questions: something#7597
    REM or dm me on twitter @xalondzn


          REM program env variables (change these to whatever you want) CONFIG FILES BYPASS THESE

       REM --------------------------FFMPEG SETTINGS--------------------------

REM apart from the h264 config, this is pretty much the same as gmzorz's prerec config but with less verbose output (may add more options in the future)
set "xvid=ffmpeg -loglevel error -stats -r ^"-fps-^" -i ^"-inputdirectory-^" -c:v mpeg4 -vtag xvid -qscale:v 1 -qscale:a 1 -g 32 -vsync 1 -y ^"-outputdirectory-^".avi"
    REM for fast editing during hcs or editing contests (slower playback speed+worse quality but really speedy encode time)
set "prores=ffmpeg -loglevel error -stats  -r ^"-fps-^" -i ^"-inputdirectory-^" -c:v prores_ks -profile:v 3 -c:a pcm_s16le -y ^"-outputdirectory-^".mov"
    REM general use codec for regular prerecs or cinematics (better playback speed+quality but 10x slower encode time)
set "h264=ffmpeg -loglevel error -stats  -r ^"-fps-^" -i ^"-inputdirectory-^" -c:v libx264 -crf 4 -y ^"-outputdirectory-^".mp4"
    REM good for creating prerecs but vegas incompatible (relatively small file size) im pretty sure you can vdub these



set noUI=0
    REM L Fully automates things without any dialog, only relying on default values set. This bypasses dontconfirm, alwaysencodeall, and dontaskinputs when set to 1. (1=on 0=off) default - 0

set alwayscreatecopy=1
    REM L always creates encoded copy of the files/folders rather than creating a folder within selected folders for encoded files. basically 0 for old prerec folder being created or 1 for copy of folder/file (1=on 0=off) default - 1
set dontconfirm=0
    REM L Confirm encode type dialog toggle. (1=on 0=off) default - 0
set alwaysencodeall=0
    REM L Select exclude file/folder dialog toggle and encodes all. (1=on 0=off) default - 0
set dontaskinputs=0
    REM L Asking for fps and codec toggle. (1=on, 0=off) default - 0


set foldername=e_
    REM L set this to whatever you want as the prefix for the created folder/file. default - "e_" 
set tempfiledir=%tmp%
    REM L this is where the program puts the temp vbs files. Don't edit this if the program works as intended with its default value "%tmp%\"


    REM DEFAULT FPS AND DEFAULT CODEC IS EXCLUSIVELY FOR WHEN noUI OR dontaskinputs ARE SET TO 1
       REM In order to switch default codec and fps when dontaskinputs is off, go to line #placeholder and change the third parameter in the code for either option
set defaultfps=600
set defaultcodec=xvid
    REM L self explainitory, read above comment. defaults fps-600, codec-xvid

       

          REM vvvv code(please dont mess with this if you have no idea what you're doing) vvvv




setlocal enabledelayedexpansion
goto init

:init
call :reloadconfig
pushd %~dp0
echo.
if !noUI!==1 ( set dontconfirm=1 & set alwaysencodeall=1 & set dontaskinputs=1)
if !alwayscreatecopy!==0 call :confirm "Create copy of folder/files? (The folder will always have a duplicate encoded version in itself, but it will be in the parent directory rather than inside the folder. You can disable this popup by setting alwayscreatecopy = 1 in the batch file)" "Create Copy - prorecs1.5"
set createcopy=1
if !responseconfirm!==0 ( set createcopy=0)
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
for /f "delims=" %%D in ('dir /a:d /b') do ( goto batchfolderencode)
if exist *.mp4 ( goto folderencode)
if exist *.avi ( goto folderencode)
if exist *.wmv ( goto folderencode)
if exist *.mov ( goto folderencode)
if exist *.m4v ( goto folderencode)
goto empty


:singlefileencode
set responseconfirm=1
if %dontconfirm%==0 call :confirm "Single file encode? Open batch file in notepad for more info. (You can disable this popup by changing dontconfirm to 1 in the batch file)" "Single File - prorecs1.5"
if !responseconfirm!==0 ( exit)
call :askinfo
set file=%~n1%~x1
set name=%~n1
if !createcopy!==1 ( set inputdirectory=!file!& set "outputdirectory=!foldername!!format!_!name!") else ( if not exist "!foldername!!format!" ( mkdir "!foldername!!format!")
set inputdirectory=!file!& set "outputdirectory=!foldername!!format!\!name!")
call :encodefile
goto end

:batchfolderencode:
set startfolder=%cd%
set responseconfirm=1
if %dontconfirm%==0 call :confirm "Batch Folder encode? Open batch file in notepad for more info. (You can disable this popup by changing dontconfirm to 1 in the batch file)" "Batch Folder - prorecs1.5"
if !responseconfirm!==0 ( call :msgbox "Make sure to move/remove all folders within the target folder if you only want to encode the target folder files." & exit)
set allfolders=
call :askinfo
if !createcopy!==1 ( for %%* in (.) do set prevdirname=%%~nx*& pushd ..& if not exist "!foldername!!format!_!prevdirname!" ( mkdir "!foldername!!format!_!prevdirname!")
set "output=!cd!\!foldername!!format!_!prevdirname!" & popd )
set i=0
for /f "delims=" %%D in ('dir /a:d /b') do (
    set "allfolders=!allfolders! ^"%%~nxD^""
    set /a i+=1
    set "currentfolder!i!=%%~nxD"
)
call :selectionlist !allfolders!
if !para1!==null ( exit)
set /a i=0
set /a j=1
:checkexcludebatch
set /a i+=1
if "!para1!"=="ENCODE ALL" ( goto finishexludebatch)
if !para%i%!==!currentfolder%j%! goto endexludebatchinstance
if [!para%i%!]==[] goto finishexludebatch
if !i!==100 exit
goto checkexcludebatch
:finishexludebatch
pushd !startfolder!\!currentfolder%j%!
set "folderprefix=!foldername!!format!"
set /a prefixlength=0
:prefixcalcbatch
if not "!folderprefix:~%prefixlength%,1!"=="" ( set /a prefixlength+=1 & goto prefixcalcbatch)
:endprefixcalcbatch
if "!currentfolder%j%:~0,%prefixlength%!"=="!folderprefix!" ( goto endexludebatchinstance)
if exist *.mp4 ( goto startbatch)
if exist *.avi ( goto startbatch)
if exist *.wmv ( goto startbatch)
if exist *.mov ( goto startbatch)
if exist *.m4v ( goto startbatch)
goto endexludebatchinstance

:startbatch
if !createcopy!==0 ( if not exist "!foldername!!format!" ( mkdir "!foldername!!format!")
set "output=!cd!\!foldername!!format!")
if !createcopy!==1 ( for %%* in (.) do set prevnewdirname=%%~nx*& pushd .. & pushd .. & pushd !cd!\!foldername!!format!_!prevdirname! & if not exist "!prevnewdirname!" ( mkdir "!prevnewdirname!")
set "output=!cd!\!prevnewdirname!"& popd & popd & popd )

call :encodedirectory

cd !startfolder!
:endexludebatchinstance
set /a j+=1
set i=0
if [!currentfolder%j%!]==[] goto end
goto checkexcludebatch

:folderencode
set responseconfirm=1
if %dontconfirm%==0 call :confirm "Single directory encode? Open batch file in notepad for more info. (You can disable this popup by changing dontconfirm to 1 in the batch file)" "Single Directory - prorecs1.5"
if !responseconfirm!==0 ( exit)
call :askinfo
for %%* in (.) do set prevdirname=%%~nx*
if !createcopy!==0 ( if not exist "!foldername!!format!" ( mkdir "!foldername!!format!") & set "output=!cd!\!foldername!!format!")
if !createcopy!==1 ( pushd .. & if not exist "!foldername!!format!_!prevdirname!" ( mkdir "!foldername!!format!_!prevdirname!")
set "output=!cd!\!foldername!!format!_!prevdirname!" & popd )

call :encodedirectory
goto end

:empty
call :msgbox "There is nothing to encode. Try dragging a file/folder onto the batch file or try copy pasting this batch file into a directory with files/folders."
exit

:end
echo. & echo Finished
call :msgbox "Finished"
exit





       REM functions/methods

:reloadconfig
pushd %~dp0
if exist *.cfg ( for %%i in (*.cfg) do ( set "configfile=%%~nxi"& for /f "delims=" %%x in (!configfile!) do ( set currentline=%%x& call :processline) & echo Loaded !configfile! ) )
popd
exit /b

:processline
if not "%currentline:~0,1%"=="#" ( set !currentline!)
exit /b

:encodefile
echo "!inputdirectory!" with !format! to "!outputdirectory!"
set inputdirectory=!inputdirectory:%%=[hash]!
set outputdirectory=!outputdirectory:%%=[hash]!
set currentformat=!%format%!
call set currentformat=%%currentformat:-fps-=!fps!%%& call set currentformat=%%currentformat:-inputdirectory-=!inputdirectory!%%& call set currentformat=%%currentformat:-outputdirectory-=!outputdirectory!%%
set currentformat=!currentformat:[hash]=%%!
!currentformat!
exit /b

    REM used to create encoded folder and to create encoded files within same directory (basically gmzorz thing). usage - call :encodedirectory
:encodedirectory
for %%a in (*.mp4, *.avi, *.wmv, *.mov, *.m4v) do (
    set file=%%a
    set name=%%~na
    set inputdirectory=!file!& set "outputdirectory=!output!\!name!"
    call :encodefile
    echo.
)
exit /b

    REM msgbox in Wscript. usage - call :msgbox "[message]"
:msgbox
echo msgbox "%~1" > !tempfiledir!\tmp.vbs
wscript !tempfiledir!\tmp.vbs
del !tempfiledir!\tmp.vbs
exit /b

    REM inputbox in wscript to ask for codec and fps.(could have maybe just used a function for ask and used it twice but hybrid has limitations) usage - call :askinfo
:askinfo
if !dontaskinputs!==1 ( set fps=!defaultfps!& set format=!defaultcodec!
exit /b)
:wscript.echo InputBox("What codec would you like to use? [xvid recommended]","Codec - prorecs1.5","")
:wscript.echo InputBox("What fps would you like to use?","FPS - prorecs1.5","600")
findstr "^:wscript" "%~sf0">!tempfiledir!\tmp.vbs
set i=0 & for /f "delims=" %%n in ('cscript //nologo !tempfiledir!\tmp.vbs') do ( set /a i+=1 & set param!i!=%%n)
set format=!param1!
set fps=!param2!
del !tempfiledir!\tmp.vbs
exit /b

    REM Wscript yes no popup that sets responseconfirm to 1 or 0 based off response. usage - call :confirm "[message]" "[title]"
:confirm
echo set WshShell = WScript.CreateObject("WScript.Shell") > !tempfiledir!\tmp.vbs
echo WScript.Quit (WshShell.Popup( "%~1" ,0 ,"%~2", vbYesNo)) >> !tempfiledir!\tmp.vbs
cscript /nologo !tempfiledir!\tmp.vbs
if !errorlevel!==6 ( set responseconfirm=1) else ( set responseconfirm=0)
exit /b


    REM [UNUSED] scuffed folder selector using shellapp and sets selectedfolder to path. usage - call :folderselect "[message]"
:folderselect
set folderSelector="(new-object -COM 'Shell.Application').BrowseForFolder(0, '%~1:',1, '::{20D04FE0-3AEA-1069-A2D8-08002B30309D}').self.path;"
for /f "usebackq delims=" %%i in (`powershell %folderSelector%`) do set "selectedfolder=%%i"
exit /b

    REM selection list for selecting items using wscript and a handful of other stuff. usage - call :selectionlist "[option1] [option2] [option3] ..."
:selectionlist
if !alwaysencodeall!==1 ( set "para1=ENCODE ALL" & exit /b)
set allselectargs =
:checkselectionargs
if [%1]==[] goto endselectionargs
set "allselectargs=!allselectargs! %1"
shift /1
goto checkselectionargs
:endselectionargs
set i=0
findstr /e "'VBS" "%~f0">!tempfiledir!\tmp.vbs & for /f "delims=" %%n in ('cscript //nologo !tempfiledir!\tmp.vbs "ENCODE ALL"!allselectargs!') do ( set /a i+=1 & set para!i!=%%n)
del !tempfiledir!\tmp.vbs
if !para1!==null ( call :msgbox "Cancelled")
exit /b


    REM temp vbs script for selection lists (source:https://stackoverflow.com/questions/47100085/creating-multi-select-list-box-in-vbscript) Used for call :selectionlist ...

Option Explicit 'VBS
 'VBS
' Base64-encoded background image of the archaic logo 'VBS
Const BGI = "data:image/png;base64,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" 'VBS
 'VBS
Dim i 'VBS
 'VBS
' Array containing items for ListBox 'VBS

Dim aItems 'VBS
ReDim aItems(WScript.Arguments.Count-1) 'VBS
Dim ind 'VBS
for ind = 0 to WScript.Arguments.Count-1 'VBS
    aItems(ind) = WScript.Arguments(ind) 'VBS
Next 'VBS

 'VBS
' Create HTA window wrapper 'VBS
With New clsSmallWrapperForm 'VBS
    ' Setup window 'VBS
    .ShowInTaskbar = "yes" 'VBS
    .Title = "Select Folders/Files to Exclude - prorecs1.5" 'VBS
    .BackgroundImage = BGI 'VBS
    .Width = 354 'VBS
    .Height = 118 'VBS
    .Visible = False 'VBS
    ' Create window 'VBS
    .Create 'VBS
    ' Assign handlers 'VBS
    Set .Handlers = New clsSmallWrapperHandlers 'VBS
    ' Add ListBox 'VBS
    With .AddElement("ListBox1", "SELECT") 'VBS
        .size = 6 'VBS
        .multiple = True 'VBS
        .style.left = "15px" 'VBS
        .style.top = "10px" 'VBS
        .style.width = "250px" 'VBS
    End With 'VBS
    .AppendTo "Form" 'VBS
    ' Add ListBox items 'VBS
    For i = 0 To UBound(aItems) 'VBS
        .AddElement , "OPTION" 'VBS
        .AddText aItems(i) 'VBS
        .AppendTo "ListBox1" 'VBS
    Next 'VBS
    ' Add OK Button 'VBS
    With .AddElement("Button1", "INPUT") 'VBS
        .type = "button" 'VBS
        .value = "OK" 'VBS
        .style.left = "285px" 'VBS
        .style.top = "10px" 'VBS
        .style.width = "50px" 'VBS
        .style.height = "20px" 'VBS
    End With 'VBS
    .AppendTo "Form" 'VBS
    ' Add Cancel Button 'VBS
    With .AddElement("Button2", "INPUT") 'VBS
        .type = "button" 'VBS
        .value = "Cancel" 'VBS
        .style.left = "285px" 'VBS
        .style.top = "40px" 'VBS
        .style.width = "50px" 'VBS
        .style.height = "20px" 'VBS
    End With 'VBS
    .AppendTo "Form" 'VBS
    ' Add Label 'VBS
    With .AddElement("Label1", "SPAN") 'VBS
        .style.left = "15px" 'VBS
        .style.top = "98px" 'VBS
        .style.width = "350px" 'VBS
    End With 'VBS
    .AddText "Choose excluded folders/files or select 'ENCODE ALL'." 'VBS
    .AppendTo "Form" 'VBS
    ' Show window 'VBS
    .Visible = True 'VBS
    ' Wait window closing or user choise 'VBS
    Do While .ChkDoc And Not .Handlers.Selected 'VBS
        WScript.Sleep 100 'VBS
    Loop 'VBS
    ' Read results from array .Handlers.SelectedItems 'VBS
    If .Handlers.Selected Then 'VBS
        MsgBox "Selected " & (UBound(.Handlers.SelectedItems) + 1) & " Item(s)" & vbCrLf & Join(.Handlers.SelectedItems, vbCrLf)
        wscript.echo vbCrLf&Join(.Handlers.SelectedItems, vbCrLf) 'VBS
    Else 'VBS
        MsgBox "Cancelled"
        wscript.echo "null" 'VBS
    End If 'VBS
    ' The rest part of code ... 'VBS
 'VBS
End With 'VBS
 'VBS
Class clsSmallWrapperHandlers 'VBS
 'VBS
    ' Handlers class implements events processing 'VBS
    ' Edit code to provide the necessary behavior 'VBS
    ' Keep conventional VB handlers names: Public Sub <ElementID>_<EventName>() 'VBS
 'VBS
    Public oswForm ' mandatory property 'VBS
 'VBS
    Public Selected 'VBS
    Public SelectedItems 'VBS
 'VBS
    Private Sub Class_Initialize() 'VBS
        Selected = False 'VBS
        SelectedItems = Array() 'VBS
    End Sub 'VBS
 'VBS
    Public Sub ListBox1_Click() 'VBS
        Dim vItem 'VBS
        With CreateObject("Scripting.Dictionary") 'VBS
            For Each vItem In oswForm.Window.ListBox1.childNodes 'VBS
                If vItem.Selected Then .Item(vItem.innerText) = "" 'VBS
            Next 'VBS
            SelectedItems = .Keys() 'VBS
        End With 'VBS
        oswForm.Window.Label1.style.color = "buttontext" 'VBS
        oswForm.Window.Label1.innerText = (UBound(SelectedItems) + 1) & " selected" 'VBS
    End Sub 'VBS
 'VBS
    Public Sub Button1_Click() 'VBS
        Selected = UBound(SelectedItems) >= 0 'VBS
        If Selected Then 'VBS
            oswForm.Window.close 'VBS
        Else 'VBS
            oswForm.Window.Label1.style.color = "darkred" 'VBS
            oswForm.Window.Label1.innerText = "Choose at least 1 item" 'VBS
        End If 'VBS
    End Sub 'VBS
 'VBS
    Public Sub Button2_Click() 'VBS
        oswForm.Window.close 'VBS
    End Sub 'VBS
 'VBS
End Class 'VBS
 'VBS
Class clsSmallWrapperForm 'VBS
 'VBS
    ' Utility class for HTA window functionality 'VBS
    ' Do not modify 'VBS
 'VBS
    ' HTA tag properties 'VBS
    Public Border ' thick | dialog | none | thin 'VBS
    Public BorderStyle ' normal | complex | raised | static | sunken 'VBS
    Public Caption ' yes | no 'VBS
    Public ContextMenu ' yes | no 'VBS
    Public Icon ' path 'VBS
    Public InnerBorder ' yes | no 'VBS
    Public MinimizeButton ' yes | no 'VBS
    Public MaximizeButton ' yes | no 'VBS
    Public Scroll ' yes | no | auto 'VBS
    Public Selection ' yes | no 'VBS
    Public ShowInTaskbar ' yes | no 'VBS
    Public SysMenu ' yes | no 'VBS
    Public WindowState ' normal | minimize | maximize 'VBS
 'VBS
    ' Form properties 'VBS
    Public Title 'VBS
    Public BackgroundImage 'VBS
    Public Width 'VBS
    Public Height 'VBS
    Public Left 'VBS
    Public Top 'VBS
    Public Self 'VBS
 'VBS
    Dim oWnd 'VBS
    Dim oDoc 'VBS
    Dim bVisible 'VBS
    Dim oswHandlers 'VBS
    Dim oLastCreated 'VBS
 'VBS
    Private Sub Class_Initialize() 'VBS
        Set Self = Me 'VBS
        Set oswHandlers = Nothing 'VBS
        Border = "thin" 'VBS
        ContextMenu = "no" 'VBS
        InnerBorder = "no" 'VBS
        MaximizeButton = "no" 'VBS
        Scroll = "no" 'VBS
        Selection = "no" 'VBS
    End Sub 'VBS
 'VBS
    Private Sub Class_Terminate() 'VBS
        On Error Resume Next 'VBS
        oWnd.Close 'VBS
    End Sub 'VBS
 'VBS
    Public Sub Create() 'VBS
        ' source http://forum.script-coding.com/viewtopic.php?pid=75356#p75356 'VBS
        Dim sName, sAttrs, sSignature, oShellWnd, oProc 'VBS
        sAttrs = "" 'VBS
        For Each sName In Array("Border", "Caption", "ContextMenu", "MaximizeButton", "Scroll", "Selection", "ShowInTaskbar", "Icon", "InnerBorder", "BorderStyle", "SysMenu", "WindowState", "MinimizeButton") 'VBS
            If Eval(sName) <> "" Then sAttrs = sAttrs & " " & sName & "=" & Eval(sName) 'VBS
        Next 'VBS
        If Len(sAttrs) >= 240 Then Err.Raise 450, "<HTA:APPLICATION" & sAttrs & " />" 'VBS
        sSignature = Mid(Replace(CreateObject("Scriptlet.TypeLib").Guid, "-", ""), 2, 16) 'VBS
        Set oProc = CreateObject("WScript.Shell").Exec("mshta ""about:<script>moveTo(-32000,-32000);document.title='*'</script><hta:application" & sAttrs & " /><object id='s' classid='clsid:8856F961-340A-11D0-A96B-00C04FD705A2'><param name=RegisterAsBrowser value=1></object><script>s.putProperty('" & sSignature & "',document.parentWindow);</script>""") 'VBS
        Do 'VBS
            If oProc.Status > 0 Then Err.Raise 507, "mshta.exe" 'VBS
            For Each oShellWnd In CreateObject("Shell.Application").Windows 'VBS
                On Error Resume Next 'VBS
                Set oWnd = oShellWnd.GetProperty(sSignature) 'VBS
                If Err.Number = 0 Then 'VBS
                    On Error Goto 0 'VBS
                    With oWnd 'VBS
                        Set oDoc = .document 'VBS
                        With .document 'VBS
                            .open 'VBS
                            .close 'VBS
                            .title = Title 'VBS
                            .getElementsByTagName("head")(0).appendChild .createElement("style") 'VBS
                            .styleSheets(0).cssText = "* {font:8pt tahoma;position:absolute;}" 'VBS
                            .getElementsByTagName("body")(0).id = "Form" 'VBS
                        End With 'VBS
                        .Form.style.background = "buttonface" 'VBS
                        If BackgroundImage <> "" Then 'VBS
                            .Form.style.backgroundRepeat = "no-repeat" 'VBS
                            .Form.style.backgroundImage = "url(" & BackgroundImage & ")" 'VBS
                        End If 'VBS
                        If IsEmpty(Width) Then Width = .Form.offsetWidth 'VBS
                        If IsEmpty(Height) Then Height = .Form.offsetHeight 'VBS
                        .resizeTo .screen.availWidth, .screen.availHeight 'VBS
                        .resizeTo Width + .screen.availWidth - .Form.offsetWidth, Height + .screen.availHeight - .Form.offsetHeight 'VBS
                        If IsEmpty(Left) Then Left = CInt((.screen.availWidth - Width) / 2) 'VBS
                        If IsEmpty(Top) Then Top = CInt((.screen.availHeight - Height) / 2) 'VBS
                        bVisible = IsEmpty(bVisible) Or bVisible 'VBS
                        Visible = bVisible 'VBS
                        .execScript "var smallWrapperThunks = (function(){" & "var thunks,elements={};return {" & "parseHandlers:function(h){" & "thunks=h;for(var key in thunks){var p=key.toLowerCase().split('_');if(p.length==2){elements[p[0]]=elements[p[0]]||{};elements[p[0]][p[1]]=key;}}}," & "forwardEvents:function(e){" & "if(elements[e.id.toLowerCase()]){for(var key in e){if(key.search('on')==0){var q=elements[e.id.toLowerCase()][key.slice(2)];if(q){eval(e.id+'.'+key+'=function(){thunks.'+q+'()}')}}}}}}})()" 'VBS
                        If Not oswHandlers Is Nothing Then 'VBS
                            .smallWrapperThunks.parseHandlers oswHandlers 'VBS
                            .smallWrapperThunks.forwardEvents .Form 'VBS
                        End If 'VBS
                    End With 'VBS
                    Exit Sub 'VBS
                End If 'VBS
                On Error Goto 0 'VBS
            Next 'VBS
            WScript.Sleep 100 'VBS
        Loop 'VBS
    End Sub 'VBS
 'VBS
    Public Property Get Handlers() 'VBS
        Set Handlers = oswHandlers 'VBS
    End Property 'VBS
 'VBS
    Public Property Set Handlers(oHandlers) 'VBS
        Dim oElement 'VBS
        If Not oswHandlers Is Nothing Then Set oswHandlers.oswForm = Nothing 'VBS
        Set oswHandlers = oHandlers 'VBS
        Set oswHandlers.oswForm = Me 'VBS
        If ChkDoc Then 'VBS
            oWnd.smallWrapperThunks.parseHandlers oswHandlers 'VBS
            For Each oElement In oDoc.all 'VBS
                If oElement.id <> "" Then oWnd.smallWrapperThunks.forwardEvents oElement 'VBS
            Next 'VBS
        End If 'VBS
    End Property 'VBS
 'VBS
    Public Sub ForwardEvents(oElement) 'VBS
        If ChkDoc Then oWnd.smallWrapperThunks.forwardEvents oElement 'VBS
    End Sub 'VBS
 'VBS
    Public Function AddElement(sId, sTagName) 'VBS
        Set oLastCreated = oDoc.createElement(sTagName) 'VBS
        If VarType(sId) <> vbError Then 'VBS
            If Not(IsNull(sId) Or IsEmpty(sId)) Then oLastCreated.id = sId 'VBS
        End If 'VBS
        oLastCreated.style.position = "absolute" 'VBS
        Set AddElement = oLastCreated 'VBS
    End Function 'VBS
 'VBS
    Public Function AppendTo(vNode) 'VBS
        If Not IsObject(vNode) Then Set vNode = oDoc.getElementById(vNode) 'VBS
        vNode.appendChild oLastCreated 'VBS
        ForwardEvents oLastCreated 'VBS
        Set AppendTo = oLastCreated 'VBS
    End Function 'VBS
 'VBS
    Public Function AddText(sText) 'VBS
        oLastCreated.appendChild oDoc.createTextNode(sText) 'VBS
    End Function 'VBS
 'VBS
    Public Property Get Window() 'VBS
        Set Window = oWnd 'VBS
    End Property 'VBS
 'VBS
    Public Property Get Document() 'VBS
        Set Document = oDoc 'VBS
    End Property 'VBS
 'VBS
    Public Property Get Visible() 'VBS
        Visible = bVisible 'VBS
    End Property 'VBS
 'VBS
    Public Property Let Visible(bWindowVisible) 'VBS
        bVisible = bWindowVisible 'VBS
        If ChkDoc Then 'VBS
            If bVisible Then 'VBS
                oWnd.moveTo Left, Top 'VBS
            Else 'VBS
                oWnd.moveTo -32000, -32000 'VBS
            End If 'VBS
        End If 'VBS
    End Property 'VBS
 'VBS
    Public Function ChkDoc() 'VBS
        On Error Resume Next 'VBS
        ChkDoc = CBool(TypeName(oDoc) = "HTMLDocument") 'VBS
    End Function 'VBS
 'VBS
End Class 'VBS
)

rem best girl