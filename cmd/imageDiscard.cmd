@REM %1 - mount dir
echo Clear mount dir..
dism /unmount-image /mountdir:%1 /discard
if exist %1 rd /s /q %1
mkdir %1
exit /b
