
@REM %1 - input install.wim
echo Available images:
dism /get-imageinfo /imagefile:%1
exit /b
