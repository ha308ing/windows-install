@echo off & chcp 65001 > NUL & setlocal enabledelayedexpansion

:setName
set /p name=enter name^: || goto :setName

if 9 gtr 5 (
  echo You've entered: %name%
  :setSurname
  set /p surname=enter surname^: || goto :setSurname
)

echo %name% %surname%
