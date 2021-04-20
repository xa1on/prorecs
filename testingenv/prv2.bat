@echo off
setlocal enabledelayedexpansion
pushd %~dp0





:end
echo Done.
exit

:convertdirectory
for %%a in (*.mp4, *.avi, *.wmv, *.mov, *.m4v) do(
	set file=%%a
	set name=%%~na
	call:convertsettings
	if not exist "converted_!format!" ( mkdir "converted_!format!")
	!%format%!
)
exit /b 0

:convertsettings
set "xvid=ffmpeg -r ^"!fps!^" -i ^"!file!^" -c:v mpeg4 -vtag xvid -qscale:v 1 -qscale:a 1 -g 32 -vsync 1 -y ^"converted_!format!^"/^"!name!^".avi"
	REM for fast editing during hcs or editing contests (slower playback speed+worse quality but really speedy encode time)
set "prores=ffmpeg -r ^"!fps!^" -i ^"!file!^" -c:v prores_ks -profile:v 3 -c:a pcm_s16le -y ^"converted_!format!^"/^"!name!^".mov"
	REM general use codec for regular prerecs or cinematics (better playback speed+quality but 10x slower encode time)
set "h264=ffmpeg -r ^"!fps!^" -i ^"!file!^" -c:v libx264 -crf 1 -y ^"converted_!format!^"/^"!name!^".mp4"
	REM good for creating prerecs but vegas incompatible (relatively small file size)