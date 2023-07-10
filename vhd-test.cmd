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
  set /a "partitionSize%%i*=1024"
)
@REM )
@REM )

@REM get available letters
set partitionCounter=0

set lettersString="C D E F G H I J K L M N O P Q R S T U V W X Y Z"
set letters=!lettersString:"=!

:changeLetter
for /l %%i in (!partitionCounter!,1,%numberOfPartitions%) do (
  for %%j in ( !letters! ) do (
    dir "%%j:\" 2>NUL >NUL
    if errorlevel 1 (
      set "partitionLetter%%i=%%j"
      set /a partitionCounter+=1
    )
    set letters=!letters:~2!
    goto :changeLetter
  )
)

echo %stepTitle%: User defined partitions:
for /l %%i in (1,1,%numberOfPartitions%) do (
  echo Partition %%i. !partitionLetter%%i!:\ %labelPrefix%-!partitionLabel%%i! - !partitionSize%%i!
)

@REM echo %stepTitle%: partitionSizeSystem: %partitionSizeSystem%

(
ECHO sel vdisk file=%vhd%
ECHO attach vdisk
ECHO clean
ECHO convert gpt
ECHO sel part 1
ECHO delete part override
ECHO create part efi size=100
ECHO format quick fs=fat32 label="%labelPrefix%-efi"
ECHO assign letter=%partitionLetter0%
ECHO create part msr size=16
if %numberOfPartitions% equ 1 (
  ECHO create part pri
) else (
  ECHO create part pri size=%partitionSize1%
)
ECHO format quick fs=ntfs label="%labelPrefix%-%partitionLabel1%"
ECHO assign letter=%partitionLetter1%
ECHO shrink minimum=450
ECHO create part pri size=450
ECHO format quick fs=ntfs label="%labelPrefix%-recovery"
ECHO set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
if %numberOfPartitions% gtr 1 (
  for /l %%i in (2,1,%numberOfPartitions%) do (
    if !partitionSize%%i! equ 0 (
      ECHO create part pri
    ) else (
      ECHO create part pri size=!partitionSize%%i!
    )
    ECHO format quick fs=ntfs label="%labelPrefix%-!partitionLabel%%i!"
    ECHO assign letter=!partitionLetter%%i!
  )
)
ECHO exit
) > diskpart-script.txt

diskpart /s "diskpart-script.txt"

@REM if errorlevel 0 (
@REM   echo Diskpart script completed successfully. Removing script file..
@REM   del "diskpart-script.txt"
@REM )

@REM bcdboot %partitionLabel1%\Windows /s %partitionLetter0%: /f UEFI

@REM (
@REM   echo sel vol=%partitionLetter0%
@REM   echo remove letter=%partitionLetter0%
@REM   echo exit
@REM ) | diskpart

:exitVHD
