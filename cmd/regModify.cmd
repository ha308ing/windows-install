@REM %1 - path to hive file to load
@REM %2 - path to reg file to import

set "__regLoad="%~dp0\regLoad.cmd""
set "__regImport="%~dp0\regImport.cmd""
set "__regUnload="%~dp0\regUnload.cmd""
set localHive=HKLM\OFFLINE
call %__regLoad% %localHive% %1
call %__regImport% %2
call %__regUnload% %localHive%
exit /b
