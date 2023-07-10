@echo off & chcp 65001 > NUL & setlocal enabledelayedexpansion

set "script="

set "script=%script% hello"

(
  echo "hello"
  echo "hi"
) > test.txt

type test.txt
