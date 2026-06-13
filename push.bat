@echo off
chcp 65001 >nul

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy/MM/dd HH:mm\""') do set COMMIT_MSG=%%i

git add .
git commit -m "%COMMIT_MSG%"
git push

pause