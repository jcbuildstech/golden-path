@echo off
setlocal

set "TEMPLATE=C:\Users\jcdel\Root\03_RESOURCES\06_GOLDEN_PATH\template"
set "TARGET=%~dp0."

for %%I in ("%TARGET%") do set "PROJECT_NAME=%%~nxI"

echo.
echo ========================================
echo      Juan's Python Golden Path
echo ========================================
echo.
echo Project: %PROJECT_NAME%
echo.

echo Creating development environment files...

robocopy "%TEMPLATE%" "%TARGET%" /E /NFL /NDL /NJH /NJS /NP >nul

if %ERRORLEVEL% GEQ 8 (
    echo.
    echo ERROR: Golden Path setup failed.
    pause
    exit /b %ERRORLEVEL%
)

echo Creating local Git repository...

if not exist "%TARGET%\.git" (
    git -C "%TARGET%" init -b main
)

git -C "%TARGET%" config user.name "Juan Delgado Vivas"
git -C "%TARGET%" config user.email "jcbuildstech@gmail.com"
git -C "%TARGET%" config push.autoSetupRemote true

echo Creating private GitHub repository...

gh repo view "jcbuildstech/%PROJECT_NAME%" >nul 2>&1

if ERRORLEVEL 1 (
    gh repo create "jcbuildstech/%PROJECT_NAME%" --private
)

git -C "%TARGET%" remote get-url origin >nul 2>&1

if ERRORLEVEL 1 (
    git -C "%TARGET%" remote add origin "https://github.com/jcbuildstech/%PROJECT_NAME%.git"
)

echo.
echo Project ready.
echo.
echo Next:
echo   1. Start Docker Desktop
echo   2. Open this folder in VS Code
echo   3. Reopen in Container
echo   4. Start coding
echo.
pause