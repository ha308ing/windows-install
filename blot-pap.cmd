:: install preconfigured windows to vhdx
:: blotting paper
@echo off & chcp 65001 >NUL & setlocal enabledelayedexpansion

@REM :start
@REM :askTargetDir
@REM @REM targetDir - directory to store modified image, extracted iso
@REM set /p targetDir=Enter target directory (No new folder): || goto :askTargetDir
@REM set targetDir="%targetDir:"=%"
@REM :checkTargetDir
@REM if not exist %targetDir% (
@REM     set /p askCreateTargetDir="Target dir does not exist. Create? (y/N) "
@REM     if /i "%askCreateTargetDir%" equ "y" (
@REM         mkdir %targetDir%
@REM         if errorlevel 1 (
@REM           echo Failed to create target dir..
@REM           goto askTargetDir
@REM         )
@REM         goto checkTargetDir
@REM     ) else goto askTargetDir
@REM )
@REM echo Ok..
@REM set imageModified="%targetDir:"=%\images\modified\install.wim"
@REM set mountDir="%targetDir:"=%\mount"
@REM echo imageModified: %imageModified%
@REM echo mountDir: %mountDir%
@REM goto :start

@REM :askInputPath
@REM set /p inputPath=Enter path to iso or wim:  || goto :askInputPath
@REM set inputPath="%inputPath:"=%"
@REM set inputType=
@REM echo %inputPath%| findstr \.wim\"$
@REM if %errorlevel% equ 0 (
@REM   echo Entered: .wim
@REM   set inputType=wim
@REM ) else (
@REM   echo %inputPath%| findstr \.iso\"$
@REM   if !errorlevel! equ 0 (
@REM     echo Entered: .iso
@REM     set inputType=iso
@REM   ) else (
@REM     echo Enter iso or wim
@REM     goto :askInputPath
@REM   )
@REM )
@REM echo inputType: %inputType%
@REM if not exist %inputPath% (
@REM   echo File not found. Try another path..
@REM   goto :askInputPath
@REM )

@REM set name=Petr
@REM if 5 gtr 3 (
@REM   set name=Nick
@REM   echo Nick?: !name!
@REM   if 5 lss 3 (
@REM     set name=John
@REM     echo John?: !name!
@REM   ) else (
@REM     set name=Kate
@REM     echo Kate?: !name!
@REM   )
@REM ) else (
@REM   set name=Patsy
@REM   echo Patsy?: !name!
@REM )

@REM echo %name%


@REM :inputImageIndex
@REM set /p imageIndex=Select image index: || goto :inputImageIndex
@REM echo %imageIndex%| findstr /r "^[1-9][0-9]*$" >NUL
@REM if errorlevel 1 goto :inputImageIndex

@REM dism /online /get-features /format:table 1>image-features-list.txt
@REM type image-features-list.txt

@REM echo Enter features to enable (see "image-features-list.txt"). Divide with spaces: 
@REM set /p inputFeatures=

@REM for /d %%i in (%inputFeatures%) do (
@REM   echo %%i
@REM )

@REM set n=
@REM if "%n%" equ "" (
@REM   echo no enabled features
@REM ) else (
@REM   for /d %%i in (%n%) do (
@REM     echo %%i
@REM   )
@REM )

@REM :enableFeatures
@REM @REM set failEnableFeatures=
@REM set failEnableFeatures=abc,def,ghi,jkl
@REM if "%failEnableFeatures%" neq "" (
@REM   echo Failed to enable features:
@REM   for /d %%i in (%failEnableFeatures%) do (
@REM     echo %%i
@REM   )
@REM )

@REM :askReEnable
@REM set /p reEnable=Try enable features again ^(y/n^)? 
@REM if /i "!reEnable!" equ "y" (
@REM   goto :enableFeatures
@REM )
@REM if /i "!reEnable!" neq "n" goto :askReEnable
@REM echo exit


@REM echo %0


@REM call :modifyRegistry HIVE_TYPE PATH_TO_HIVE PATH_TO_REG
@REM echo.
@REM call :modifyRegistry SOFTWARE G:\Windows\system32\config\SOFTWARE C:\custom-soft.reg
@REM call :modifyRegistry USER G:\Windows\system32\config\USER C:\custom-user.reg
@REM echo.
@REM call :modifyRegistry USER G:\USERS\DEFAULT\NTUSER.DAT C:\custom-user.reg

@REM exit /b

@REM :modifyRegistry
@REM @REM call :modifyRegistry HIVE_TYPE PATH_TO_HIVE PATH_TO_REG
@REM @REM %1 - HIVE TYPE (USER, SOFTWARE)
@REM @REM %2 - path to hive
@REM @REM %3 - reg file to import
@REM echo reg load HKLM\OFFLINE %2 ^>NUL
@REM if errorlevel 0 (
@REM   echo Failed to load %1 registry..
@REM   goto :exitModifyRegistry
@REM )

@REM echo reg import %3 ^>NUL
@REM if errorlevel 1 echo Failed to import %1 registry modification..

@REM echo reg unload HKLM\OFFLINE ^>NUL
@REM if errorlevel 1 echo Failed to unload %1 registry..

@REM if %errorlevel% equ 0 echo %1 registry modification imported successfully..
@REM :exitModifyRegistry
@REM exit /b



@REM powershell -command "& {Get-AppxProvisionedPackage -Path %mountDir% | ForEach-Object { $name = '\"'+$_.DisplayName+'\"'; Write-Host $name } }"

@REM powershell -command "& {ni -path pp.txt -value \"\" -force; Get-AppxProvisionedPackage -online | ForEach-Object { $name = '\"'+$_.DisplayName+'\"'; Write-Host $name; ac -path pp.txt -value $name -encoding unicode }  ; gci}"

@REM for /f "delims=" %%x in (pp.txt) do echo %%x

@REM echo List of Provisined Packages:
@REM powershell -command "& {New-Item -Path pp.txt -Value \"\" -Force | Out-Null; Get-AppxProvisionedPackage -Online | ForEach-Object { Write-Host $_.DisplayName; Add-Content -Path pp.txt -Value $_.DisplayName -Encoding oem } }"

@REM set pp=
@REM for /f "tokens=* delims=" %%i in (pp.txt) do set pp=!pp!;"%%i"
@REM set pp=%pp:~1%
@REM echo %pp%

:start
echo Enter name:
set /p name=
set name="%name:"=%"
echo %name%
goto :start
