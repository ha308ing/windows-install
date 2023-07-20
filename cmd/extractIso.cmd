@REM %1 - _inputFile
@REM %2 - _isoDir
set "__removeDir="%~dp0\removeDir.cmd""
echo Extracting iso..
echo Clear previous iso dir..
call %__removeDir% %2
echo Extracting iso..
7z x %1 -o%2
exit /b
