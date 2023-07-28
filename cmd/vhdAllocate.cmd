setlocal enabledelayedexpansion
@REM %1 - vhd
@REM %2 - script save path

set "_scriptPath=%2"
if "%_scriptPath%" equ "" (
  set _scriptPath=%~dp0diskpart-script-allocate.txt
)
set "_vhd=%1"
set "_size="
if "%_vhd%" equ "" call :inputVHD
echo vhd: %_vhd%
call :vhdAllocate %_vhd%
exit /b

:inputVHD
:askVHD
set /p "_vhd=Enter path to vhd: " || goto :askVHD
call :checkVHD %_vhd%
if errorlevel 3 goto :askVHD
if errorlevel 2 (
  choice /c yn /m "VHD not found. Create?"
  if errorlevel 2 goto :askVHD
  if errorlevel 1 (
    call :createVHD %_vhd% %_size%
    exit /b
  )
)
if errorlevel 1 goto :askVHD
exit /b

:checkVHD
@REM %1 - vhd
set "_vhd=%1"
set "_vhd="%_vhd:"=%""
echo %_vhd%| findstr /ir "\.vhdx""$"
if errorlevel 1 (
  echo File should have vhdx extension. Try again..
  exit /b 3
)
dir /b /a:-d %_vhd%
if errorlevel 1 (
  @REM vhd not found ask to create
  exit /b 2
)
exit /b

:createVHD
@REM %1 - vhd
@REM %2 - size in MB
set "_size=%2"
if "%_size%" equ "" call :inputSize
echo %_size%| findstr /r "^[1-9][0-9]*$"
if errorlevel 1 (
  echo Size should be number. Try another..
  call :inputSize
)
(
  echo create vdisk file=%1 maximum=%_size%
  echo exit
) | diskpart
if not exist %_vhd% (
  set "_size="
  echo Failed to create VHD..
  call :inputVHD
  exit /b
)
exit /b

:inputSize
:askSize
set /p "_size=Enter vhd size: " || goto :askSize
exit /b

:vhdAllocate
@REM %1 - vhd
set "_vhd=%1"
:setNumberOfPartitions
set /p "_numberOfPartitions=Enter number of partitions: "
echo %_numberOfPartitions%| findstr /r "^[1-9][0-9]*$" >NUL
if errorlevel 1 (
  echo Use only numbers. Try another..
  goto :setNumberOfPartitions
)

:set vhdLabelPrefix
set /p "_labelPrefix=Enter vhd labels prefix: " || goto :vhdLabelPrefix

@REM get partitions labels and sizes
for /l %%i in (1,1,%_numberOfPartitions%) do (
  set /p "_partitionLabel%%i=Enter partition %%i label: "
  if %%i lss %_numberOfPartitions% (
    call :getPartitionSize %%i %_numberOfPartitions%
  ) else (
    set _partitionSize%%i=0
  )
)

@REM get available letters
set "_letters=C D E F G H I J K L M N O P Q R S T U V W X Y Z"
set "_partitionCounter=0"

:changeLetter
for /l %%i in (!_partitionCounter!,1,%_numberOfPartitions%) do (
  for %%j in ( !_letters! ) do (
    @REM dir "%%j:\" 2>NUL >NUL
    @REM if errorlevel 1 (
    if not exist "%%j:\" (
      set _partitionLetter%%i=%%j
      set /a _partitionCounter+=1
    )
    set _letters=!_letters:~2!
    goto :changeLetter
  )
)

echo User defined partitions:
for /l %%i in (1,1,%_numberOfPartitions%) do (
  echo Partition %%i. !_partitionLetter%%i!:\ %_labelPrefix%-!_partitionLabel%%i! - !_partitionSize%%i!
)
echo off
(
echo sel vdisk file=%_vhd%
echo attach vdisk
echo clean
echo convert gpt
echo sel part 1
echo delete part override
echo create part efi size=100
echo format quick fs=fat32 label="%_labelPrefix%-efi"
echo assign letter=%_partitionLetter0%
echo create part msr size=16
if %_numberOfPartitions% equ 1 (
  echo create part pri
) else (
  set /a _partitionSize1+=500
  echo create part pri size=!_partitionSize1!
)
if "%_partitionLabel1%" equ "" (
  echo format quick fs=ntfs
) else (
  echo format quick fs=ntfs label="%_labelPrefix%-%_partitionLabel1%"
)
echo assign letter=%_partitionLetter1%
echo shrink desired=450
echo create part pri size=450
echo format quick fs=ntfs label="%_labelPrefix%-recovery"
echo set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
if %_numberOfPartitions% equ 1 goto :endPartitions
for /l %%i in (2,1,%_numberOfPartitions%) do (
  if !_partitionSize%%i! equ 0 (
    echo create part pri
  ) else (
    echo create part pri size=!_partitionSize%%i!
  )
  if "!_partitionLabel%%i!" equ "" (
    echo format quick fs=ntfs
  ) else (
    echo format quick fs=ntfs label="%_labelPrefix%-!_partitionLabel%%i!"
  )
  echo assign letter=!_partitionLetter%%i!
)
:endPartitions
echo exit
) > %_scriptPath%
echo on

@REM diskpart /s "diskpart-script.txt"

@REM if %errorlevel% equ 0 (
@REM   echo Diskpart script completed successfully..
@REM   @REM del "diskpart-script.txt"
@REM ) else (
@REM   echo Diskpart script failed..
@REM   @REM goto ?
@REM )

exit /b

:getPartitionSize
@REM %1 - %%i
@REM %2 - %numberOfPartitions%
@REM implement size requirements
:getNewSize
set /p "_partitionSize%1=Enter parition %1 size in GB: "
@REM set currentSize=!size%1!
@REM echo currentSize: %currentSize%
if %1 equ %2 (
  if "!_partitionSize%1!" equ "" set _partitionSize%1=0
) else (
  echo !_partitionSize%1!| findstr /r "^[1-9][0-9]*$"
  if errorlevel 1 (
    echo Use only numbers. Try another partition size..
    goto :getNewSize
  )
)
set /a _partitionSize%1*=1024
exit /b


@REM dism /apply-image /imagefile:%imageModified% /index:%imageIndex% /applydir:%partitionLetter1%:\
