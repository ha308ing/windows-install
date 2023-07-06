@echo off & chcp 65001 > NUL & setlocal enabledelayedexpansion

:setVHD
set stepTitle=vhdx allocation
set vhdSizeMin=65
set /p vhd="%stepTitle%: Enter path to vhdx: "
if "!vhd!" equ "" goto :setVHD
set vhd=^"!vhd:"=!^"
echo !vhd!
echo test dir:
for /f "delims=" %%i in ('dir /b /s !vhd!') do (
  echo "%%i"
)
echo test dir end.

if not exist !vhd! (
  echo %stepTitle%: vhdx not found. Select another..
  goto :setVHD
) else (
  dir /b /s ^"!vhd:"=!^" | findstr /ir .vhdx$ >NUL
  if !errorlevel! neq 0 (
    echo %stepTitle%: vhdx should have vhdx extension
    goto :setVHD
  )
)

for /f "usebackq delims=" %%i in (`dir /b /s !vhd!`) do (
  echo %%i
  set size=%%~zi
  echo B: !size!
  set sizeKB=!size:~0,-3!
  echo KB: !sizeKB!
  set sizeMB=!sizeKB:~0,-3!
  echo MB: !sizeMB!
  set sizeGB=!sizeMB:~0,-3!
  echo GB: !sizeGB!
)

echo %stepTitle%: VHD size: %sizeGB% GB
if %sizeGB% lss %vhdSizeMin% (
  echo %stepTitle%: Selected VHD is smaller than %vhdSizeMin% GB. Select another..
  goto :setVHD
)
set /p labelPrefix="%stepTitle%: Enter vhd labels prefix: "

set /p numberOfPartitions="%stepTitle%: Enter number of partitions: "

set partitionSizeSystem=all available

if %numberOfPartitions% gtr 1 (
  :setPartitionSizeSystem
  set /p partitionSizeSystem="%stepTitle%: Enter system partition size: "
  echo %stepTitle%: Partition should be less than %sizeGB% GB
  if !partitionSizeSystem! geq %sizeGB% goto :setPartitionSizeSystem
)

echo %stepTitle%: partitionSizeSystem: %partitionSizeSystem%

@REM (
@REM ECHO sel vdisk file=B:\win11-insider.vhdx
@REM ECHO attach vdisk
@REM ECHO clean
@REM ECHO convert gpt
@REM ECHO sel part 1
@REM ECHO delete part override
@REM ECHO create part efi size=100
@REM ECHO format quick fs=fat32 label="%labelPrefix%-efi"
@REM ECHO create part msr size=16
@REM if %numberOfPartitions% eq 1 (
@REM ECHO create part pri
@REM ) else (
@REM ECHO create part pri size=%partitionSizeSystem%
@REM )
@REM ECHO format quick fs=ntfs label="%labelPrefix%-system"
@REM ECHO assign letter=F
@REM ECHO shrink minimum=450
@REM ECHO create part pri size=450
@REM ECHO format quick fs=ntfs label="%labelPrefix%-recovery"
@REM ECHO set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
@REM ECHO create part pri
@REM ECHO format quick fs=ntfs label="%labelPrefix%-data"
@REM ECHO assign letter=G
@REM ECHO exit
@REM ) | diskpart

:exitVHD
