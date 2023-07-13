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

@REM :start
@REM echo Enter name:
@REM set /p name=
@REM set name="%name:"=%"
@REM echo %name%
@REM goto :start

@REM set edgeTarget="\Users\Default\AppData\Local\Microsoft\"
@REM echo "%edgeTarget:"=%Edge\"

@REM :start
@REM echo Enter program:
@REM set /p p= || goto :start
@REM where %p% 2>NUL >NUL
@REM if errorlevel 1 (
@REM   echo program %p% is not found
@REM )
@REM goto :start


@REM dir "%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" 2>NUL >NUL

@REM if errorlevel 1 (
@REM   echo no
@REM ) else (
@REM   echo yes
@REM )

@REM set targetDir=drrr
@REM :askIsoName
@REM set /p target=Enter iso name: || goto :askIsoName
@REM echo %target%| findstr /ir "\.iso$" >NUL
@REM if errorlevel 1 set target=%target%.iso
@REM set target="%targetDir:"=%\%target%"
@REM echo %target%

@REM set vhdPath="%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64"
@REM echo VHD (%vhdPath%) not found. Select another..


@REM :setNumberOfPartitions
@REM set /p numberOfPartitions=Enter number of partitions: || goto :setNumberOfPartitions
@REM echo %numberOfPartitions%| findstr /r "^[1-9][0-9]*$"
@REM if %errorlevel% neq 0 (
@REM   echo Use only numbers. Try another..
@REM   goto :setNumberOfPartitions
@REM )

@REM set numberOfPartitions=3

@REM :getPartitionsInfo
@REM for /l %%i in (1,1,%numberOfPartitions%) do (
@REM   set /p partitionLabel%%i=Enter partition %%i label: 
@REM   call :getPartitionSize %%i %numberOfPartitions%
@REM )

@REM for /l %%i in (1,1,%numberOfPartitions%) do (
@REM   echo partition %%i: !partitionLabel%%i! - !partitionSize%%i!
@REM )

@REM exit /b

@REM :getPartitionSize
@REM @REM %1 - %%i
@REM @REM %2 - %numberOfPartitions%
@REM :getNewSize
@REM set /p partitionSize%1=Enter parition %1 size: 
@REM @REM set currentSize=!size%1!
@REM @REM echo currentSize: %currentSize%
@REM if %1 equ %2 (
@REM   if "!partitionSize%1!" equ "" set partitionSize%1=0
@REM ) else (
@REM   echo !partitionSize%1!| findstr /r "^[1-9][0-9]*$"
@REM   if errorlevel 1 (
@REM     echo Use only numbers. Try another partition size..
@REM     goto :getNewSize
@REM   )
@REM )
@REM set /a partitionSize%1*=1024
@REM exit /b

@REM set inputPath="E:\Distrib_p\OS\uupdump.net\25393\25393.1_amd64_en-us_professional_26b20909_convert\25393.1.230608-1158.ZN_RELEASE_CLIENTPRO_OEMRET_X64FRE_EN-US.ISO"
@REM echo %inputPath%| findstr /ir "\.iso""$" >NUL
@REM if %errorlevel% equ 0 (
@REM   echo found
@REM ) else (
@REM   echo not found
@REM )


@REM :getPacakgesToRemoveList
@REM echo Remove Provisioned Packages:
@REM set /p packagesToDeletePath="Enter path to file with packages to delete (blank to generate file): "
@REM if "%packagesToDeletePath%" equ "" goto :generatePacakgesToRemoveList
@REM set packagesToDeletePath="%packagesToDeletePath:"=%"
@REM if not exist %packagesToDeletePath% (
@REM   echo %packagesToDeletePath% not found. Try another..
@REM   goto :getPacakgesToRemoveList
@REM ) else (
@REM   goto :removeProvisionedPackages
@REM )

@REM :generatePacakgesToRemoveList
@REM echo Generating Packages List

@REM :removeProvisionedPackages
@REM echo Removing Packages

set vhdPath="B:\win11-temp.wim"
set vhdPath="%vhdPath:"=%"

echo %vhdPath%| findstr /ir "\.wim""$"
