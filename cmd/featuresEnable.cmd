
@REM %1 - mountDir
@REM ===========================================================================
:getFeaturesList
echo Get file with features to enable..
:askFeaturesPath
echo Enter path to list with features to enable (blank to generate list):
set /p "_inputFeatures="
if "%_inputFeatures%" equ "" (
  set "_flPath="!%1:"=!\fl.txt""
  call :generateFeaturesList
  echo Edit %_flPath% so it has features to enable..
    set "_inputFeatures=%_flPath%"
)
call %__quote% _inputFeatures
call %__checkFile% %_inputFeatures%
if errorlevel 1 (
  echo File not found. Try another..
  goto :askFeaturesPath
)
echo File with features to enable: %_inputFeatures%
exit /b

@REM ===========================================================================
:generateFeaturesList
echo Generate features list..
powershell -noprofile -command "& {get-windowsoptionalfeature  -Path %_mountDir% | where-object -property state -value disabled -eq | sort-object -property featurename | select-object -property featurename} | format-table -hidetableheaders" > %_flPath%
type %_flPath%
exit /b

@REM ===========================================================================
:printFeaturesToEnable
echo Features to enable:
for /f "usebackq" %%i in (%_inputFeatures%) do (
  echo %%i
)
choice /c yn /m "Continue with current list?"
if errorlevel 2 (
  echo Update %_inputFeatures%..
    goto :printFeaturesToEnable
)
if errorlevel 1 echo Continue with current list
exit /b

@REM ===========================================================================
:enableFeatures
echo Enabling features..
set "_failEnableFeatures="
set "_successEnableFeatures="
for /f "usebackq" %%i in (%_inputFeatures%) do (
  @REM check if feature is present in image?
  dism /image:%_mountDir% /enable-feature /featurename:%%i
  if errorlevel 1 set "_successEnableFeatures=!_successEnableFeatures!;%%i"
  if errorlevel 0 set "_failEnableFeatures=!_failEnableFeatures!;%%i"
)
if "%_successEnableFeatures%" equ "" goto :enableFeaturesFail
echo Successfully enabled features:
for %%i in (%_successEnableFeatures%) do (
  echo %%i
)
:enableFeaturesFail
if "%_failEnableFeatures%" equ "" goto :enableFeaturesExit
echo Failed to enable features:
for %%i in (%_failEnableFeatures%) do (
  echo %%i
)
:askReEnableFeatures
choice /c yn /m "Try enable features again?"
if errorlevel 2 goto :enableFeaturesExit
if errorlevel 1 goto :enableFeatures
:enableFeaturesExit
exit /b
