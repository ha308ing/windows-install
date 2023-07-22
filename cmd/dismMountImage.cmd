setlocal enabledelayedexpansion
@REM %1 - image file
@REM %2 - mount dir
@REM %3 - index
if "%1" equ "" (
    call :inputImage
) else (
    set _image=%1
)
if "%2" equ "" (
    call :inputMountDir
) else (
    set _mountDir=%2
)
call %~dp0dismShowImages %_image%
:askIndex
set /p "_index=Enter target index: "
echo "%_index%" | findstr /r "^"[1-9][0-9]" $"
if errorlevel 1 goto :askIndex
dism /mount-image /imagefile:%_image% /index:%_index% /mountdir:%_mountDir%
if %errorlevel% neq 0 (
    echo Failed to mount image. Try another index..
    goto :askIndex
)
exit /b

:inputImage
:askImage
set /p "_image=Enter path to wim file: "
set "_image="%_image:"=%""
call %~dp0checkFile %_image%
if errorlevel 1 (
    echo File not found. Try another..
    goto :askImage
)
exit /b

:inputMountDir
:askMountDir
set /p "_mountDir=Enter path mount dir: "
set "_mountDir="%_mountDir:"=%""
:checkMountDir
call %~dp0checkDir %_mountDir%
if errorlevel 1 (
    choice /c yn /m "Directory not found. Create?"
    if errorlevel 2 goto :askMountDir
    if errorlevel 1 (
        mkdir %_mountDir%
        goto :checkMountDir
    )
)
exit /b