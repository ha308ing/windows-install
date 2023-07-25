setlocal enabledelayedexpansion
@REM %1 - image file
@REM %2 - mount dir
@REM %3 - index
set "_image=%1"
if "%_image%" equ "" call :inputImage
set "_image="%_image:"=%""
dir /b /a:-d %_image%
if errorlevel 1 (
    echo Image file not found. Try another..
    call :inputImage
)
set "_mountDir=%2"
if "%_mountDir%" equ "" call :inputMountDir
set "_mountDir="%_mountDir:"=%""

set "_index=%3"
if %_index% equ "" call :inputIndex
echo %_index%| findstr /r "^[1-9][0-9]*$"
if errorlevel 1 (
    echo Number is required for image index. Try another..
    call :inputIndex
)

:retryIndex
dism /get-wiminfo /wimfile:%_image%
if "%_index%" equ "" (
    set /p "_index=Enter target index: "
echo "%_index%" | findstr /r "^""[1-9][0-9]""$" $"
if errorlevel 1 goto :retryIndex
)
:mountImage
dism /unmount-image /mountdir:%_mountDir% /discard
rmdir /s /q %_mountDir%
mkdir %_mountDir%
dism /mount-image /imagefile:%_image% /index:%_index% /mountdir:%_mountDir%
if %errorlevel% neq 0 (
    echo Failed to mount image. Try another index..
    set "_index="
    goto :retryIndex
)
exit /b

:inputImage
:askImage
set /p "_image=Enter path to wim file: "
set "_image="%_image:"=%""
dir /b /a:-d %1 %_image%
if errorlevel 1 (
    echo File not found. Try another..
    goto :askImage
)
exit /b

:inputMountDir
:askMountDir
set /p "_mountDir=Enter path mount dir: " || goto :askMountDir
set "_mountDir="%_mountDir:"=%""
exit /b

:inputIndex
:askIndex
set /p "_index=Enter image index: " || goto :askIndex
echo %_index%| findstr /r "^[1-9][0-9]*$"
if errorlevel 1 (
    echo Number is required for image index. Try another..
    goto :askIndex
)
exit /b
