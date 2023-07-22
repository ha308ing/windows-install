@REM %1 - source dir
@REM %2 - target dir
if "%1" equ "" (
    echo Image path is required..
    exit /b 1
)
if "%2" equ "" (
    echo Target dir is required..
    exit /b 1
)
set _sourceDir=%~dp1
set _sourceFile=%~nx1
robocopy  "%_sourceDir:~0,-1%" "%~2" "%_sourceFile%"
exit /b