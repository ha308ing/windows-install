@echo off & chcp 65001 > NUL & setlocal enabledelayedexpansion

:setVHD
set stepTitle=vhdx allocation
set vhdSizeMinGB=65
: manually set %vhdSizeMinGB% * 1024 ^ 3
set vhdSizeMinB=000069793218560
: pasrtition size for system manually set 64 * 1024 ^ 3
set partitionSizeSystemMinGB=0000000064
set /p vhd="%stepTitle%: Enter path to vhdx: "
if ^"%vhd%^" equ "" goto :setVHD
: default path with quotes
set vhd=^"%vhd:"=%^"

echo %vhd:"=%| findstr /i /r "\.vhdx$" >NUL
if %errorlevel% neq 0 (
  echo %stepTitle%: vhdx should have vhdx extension. Select another..
  goto :setVHD
) else (
  if not exist %vhd% (
    echo %stepTitle%: vhdx ^(%vhd%^) not found. Select another..
    goto :setVHD
  )
)

for /f "delims=" %%i in ('dir /b /s %vhd%') do (
  set sizeB=00000%%~zi
  
  echo %stepTitle%: VHD size: !sizeB:~-15! B
  echo %stepTitle%: VHD min size: !vhdSizeMinB:~-15! B
  if !sizeB:~-15! lss !vhdSizeMinB:~-15! (
    echo %stepTitle%: Selected VHD is smaller than %vhdSizeMinGB% GB. Select another..
    goto :setVHD
  )
  echo B: !sizeB!
  set sizeKB=!sizeB:~0,-3!
  echo KB: !sizeKB!
  set sizeMB=!sizeKB:~0,-3!
  echo MB: !sizeMB!
  set sizeGB=!sizeMB:~0,-3!
  echo GB: !sizeGB!
)

:setNumberOfPartitions
set /p numberOfPartitions="%stepTitle%: Enter number of partitions: "
echo %numberOfPartitions%| findstr /r ^[1-9][0-9]*$ > NUL
if !errorlevel! neq 0 (
  echo Use only numbers. Try another..
  set /a partitionIndex-=1
  goto :setNumberOfPartitions
)

set /p labelPrefix="%stepTitle%: Enter vhd labels prefix: "

set partitionSizeSystem=all available

@REM if %numberOfPartitions% gtr 1 (
@REM :setPartitionSizeSystem
@REM set /p partitionSizeSystem="%stepTitle%: Enter system partition size: "
@REM echo %stepTitle%: Partition should be less than %sizeGB% GB
@REM if !partitionSizeSystem! geq %sizeGB% goto :setPartitionSizeSystem
@REM ask for sizes, first is system - check size
@REM create variables from 1, 0 for efi (e.g. 0-efi, 1-system,2-data)
@REM ask for labels?
@REM for last partition size=0 - which means all available space
@REM use sizes in GB?
:setPartitionSize
set partitionIndex=1
for /l %%i in (!partitionIndex!,1,%numberOfPartitions%) do (
  if "!partitionLabel%%i!" equ "" (
    if %%i equ 1 echo %stepTitle%: First partition for system:
    set /p "partitionLabel%%i=Enter partition %%i label: "
  )

  if %%i equ %numberOfPartitions% (
    set "partitionSize%%i=0"
  ) else (
    set /p "partitionSize%%i=Enter partition %%i size in GB: "
    echo !partitionSize%%i!| findstr /r ^[1-9][0-9]*$ > NUL
    if !errorlevel! neq 0 (
      echo Use only numbers. Try another..
      set /a partitionIndex-=1
      goto :setPartitionSize
    )
  )

  @REM prevent sizes larger than vhdx size
  @REM and other entered sizes

  if %%i equ 1 (
    if  %numberOfPartitions% gtr 1 (
      set "partitionSizeTemp=0000000000!partitionSize%%i!"
      if !partitionSizeTemp:~-10! lss !partitionSizeSystemMinGB! (
        @REM use number from variable instead of 64
        echo %stepTitle%: System partition must be larger than 64 GB. Enter another..
        set /a partitionIndex-=1
        goto :setPartitionSize
      ) else (
        set /a partitionIndex+=1
      )
    )
  )
)
@REM )
@REM )

echo %stepTitle%: User defined partitions:
for /l %%i in (1,1,%numberOfPartitions%) do (
  echo Partition %%i. %labelPrefix%-!partitionLabel%%i! - !partitionSize%%i!
)

@REM echo %stepTitle%: partitionSizeSystem: %partitionSizeSystem%

@REM (
@REM ECHO sel vdisk file=!vhd!
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
