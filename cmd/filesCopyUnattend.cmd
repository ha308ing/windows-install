@REM %1 - source
@REM %2 - target
setlocal enabledelayedexpansion
set "_source=%1"
set "_sourceDir=%~dp1
if "%_source%" equ "" (
  call :inputSource
) else (
  set "_source="%_source:"=%""
  if not exist %_source% (
    echo File is not found. Try another..
    call :inputSource
  )
)
set "_target=%2"
if "%_target%" equ "" call :inputTarget
set "_target="%_target:"=%""
copy /y %_source% %_target%
exit /b

:inputSource
:askSource
set /p "_source=Enter source path to copy: " || goto :askSource
set "_source="%_source:"=%""
if not exist %_source% (
  echo File is not found. Try another..
  goto :askSource
)
exit /b

:inputTarget
:askTarget
set /p "_target=Enter target path for extraction: " || goto :askTarget
exit /b

:checkFile 
dir /b /a:-d %1
exit /b
