@echo off & chcp 65001 > NUL & setlocal enabledelayedexpansion

@REM set letter=a
@REM set k=1
@REM :defineLetterStart
@REM for %%i in ( c d e f g h i j k l m n o p q r s t u v w x y z ) do (
@REM   dir "%%i:\" 2>NUL >NUL
@REM   if errorlevel 1 (
@REM     if !k! leq %n%(
@REM       echo !k!
@REM       set letter=%%i
@REM       set /a k+=1
@REM     ) else goto :defineLetterEnd
@REM     goto :defineLetterEnd
@REM   )
@REM )
@REM :defineLetterEnd

@REM echo first available drive letter: %letter%:\
@REM for /f "tokens=1-%n% delims= " %%a in ( "!letters!" ) do (
@REM   set temp=%%a
@REM   if "!temp:~0,1!" neq "%%" echo !temp!
@REM   set temp=%%b
@REM   if "!temp:~0,1!" neq "%%" echo !temp!
@REM   set temp=%%c
@REM   if "!temp:~0,1!" neq "%%" echo !temp!
@REM   set temp=%%d
@REM   if "!temp:~0,1!" neq "%%" echo !temp!
@REM   set temp=%%e
@REM   if "!temp:~0,1!" neq "%%" echo !temp!
@REM   set temp=%%f
@REM   if "!temp:~0,1!" neq "%%" echo !temp!
@REM   set temp=%%g
@REM   if "!temp:~0,1!" neq "%%" echo !temp!
@REM   set temp=%%h
@REM   if "!temp:~0,1!" neq "%%" echo !temp!
@REM   set temp=%%i
@REM   if "!temp:~0,1!" neq "%%" echo !temp!
@REM )

set n=3
set k=0

set lettersString="c d e f g h i j k l m n o p q r s t u v w x y z"
set letters=!lettersString:"=!

echo !letters!

:changeLetter
for /l %%i in (!k!,1,%n%) do (
  for %%j in ( !letters! ) do (
    dir "%%j:\" 2>NUL >NUL
    if errorlevel 1 (
      echo assign letter %%i with %%j
      set "letter%%i=%%j"
      set /a k+=1
    )
    set letters=!letters:~2!
    goto :changeLetter
  )
)

echo %letter0%
echo %letter1%
echo %letter2%
echo %letter3%
echo %letter4%

echo !letters!
