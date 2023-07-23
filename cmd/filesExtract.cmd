@REM %1 - source archive
@REM %2 - target dir
setlocal enabledelayedexpansion
set "_file=%1"
if "%_file%" equ "" (
  call :inputFile
) else (
  set "_file="%_file:"=%""
  call :checkFile %_file%
  if errorlevel 1 (
    echo File is not found. Try another..
      call :inputFile
  )
)
set "_target=%2"
if "%_target%" equ "" call :inputTarget
set "_target="%_target:"=%""
@REM _file: Edge.zip\Edge\User Data
@REM _target: mount\Users\Default\AppData\Local\Microsoft
7z x %_file% -o%_target%
exit /b

:inputFile
:askInputFile
set /p "_file=Enter path to file to extract: " || goto :askInputFile
set "_file="%_file:"=%""
call :checkFile %_file%
if errorlevel 1 (
  echo File is not found. Try another..
  goto :askInputFile
)
exit /b

:inputTarget
:askTarget
set /p "_target=Enter target path for extraction: " || goto :askTarget
exit /b

:checkFile 
dir /b /a:-d %1
exit /b
