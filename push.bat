@echo off
chcp 65001 >nul

echo ========================================
echo Git Auto Push
echo ========================================

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy/MM/dd HH:mm\""') do set COMMIT_MSG=%%i

echo.
echo Commit Message: %COMMIT_MSG%
echo.

echo [1/3] git add .
git add .

echo.
echo [2/3] git commit
git commit -m "%COMMIT_MSG%"

echo.
echo [3/3] git push
git push

echo.
echo ========================================
echo Push Finished
echo ========================================
pause