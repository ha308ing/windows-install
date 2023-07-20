
@REM %1 - variable for input file path
@REM %2 - variable for input format
@REM ===========================================================================
@REM set "__quote="%~dp0\quote.cmd""
@REM set "__checkFile="%~dp0\checkFile.cmd""
@REM set _inputFileVar=_inputFileQQ
@REM set _inputFormatVar=_inputFormatQQ
@REM if "%1" neq "" set _inputFileVar=%1
@REM if "%2" neq "" set _inputFormatVar=%2
echo Set input file
:askInputFile
set /p "_inputFile=Enter path to iso or wim: " || goto :askInputFile
call %__quote% _inputFile
echo %_inputFile%| findstr /ir "\.wim""$"
if errorlevel 1 goto :setIso
:setWim
set "_inputFormat=wim"
set _wimSource=%_inputFile%
goto :setWimExit
:setIso
echo %_inputFile%| findstr /ir "\.iso""$"
if errorlevel 1 goto :askInputFile
set "_inputFormat=iso"
set _wimSource="%_targetDir:"=%\iso\sources\install.wim"
:setWimExit
call %__checkFile% %_inputFile%
if errorlevel 1 goto :askInputFile
echo.
echo Input file: %_inputFile%..
exit /b
