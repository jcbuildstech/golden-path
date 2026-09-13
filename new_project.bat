@echo off
setlocal EnableExtensions

set "TEMPLATE=C:\Users\jcdel\Root\03_RESOURCES\06_GOLDEN_PATH\template"
set "TARGET=%~dp0."

set "GITHUB_OWNER=jcbuildstech"
set "COOLIFY_SERVER_UUID=ew0ckwcs444o4c0s4s0000so"
set "COOLIFY_GITHUB_APP_UUID=ugwgsgowsgskc4w40ws4s0sc"

for %%I in ("%TARGET%") do set "PROJECT_NAME=%%~nxI"

set "REPO=%GITHUB_OWNER%/%PROJECT_NAME%"

set "JSON_FILE=%TEMP%\golden_path_%RANDOM%_data.json"
set "RESULT_FILE=%TEMP%\golden_path_%RANDOM%_result.txt"

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
    echo ERROR: Golden Path setup failed while copying template.
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

gh repo view "%REPO%" >nul 2>&1

if ERRORLEVEL 1 (
    gh repo create "%REPO%" --private

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: GitHub repository setup failed.
        pause
        exit /b 1
    )
)

git -C "%TARGET%" remote get-url origin >nul 2>&1

if ERRORLEVEL 1 (
    git -C "%TARGET%" remote add origin "https://github.com/%REPO%.git"
)

echo Connecting project to Coolify...

rem --------------------------------------------------
rem Find or create Coolify project
rem --------------------------------------------------

coolify project list --format json > "%JSON_FILE%"

if ERRORLEVEL 1 (
    echo.
    echo ERROR: Could not read Coolify projects.
    pause
    exit /b 1
)

powershell -NoProfile -Command "$projects = Get-Content -Raw $env:JSON_FILE | ConvertFrom-Json; $match = $projects | Where-Object { $_.name -eq $env:PROJECT_NAME } | Select-Object -First 1; if ($match) { [IO.File]::WriteAllText($env:RESULT_FILE,[string]$match.uuid) } else { [IO.File]::WriteAllText($env:RESULT_FILE,'NONE') }"

if ERRORLEVEL 1 (
    echo.
    echo ERROR: Could not inspect Coolify projects.
    pause
    exit /b 1
)

set /p COOLIFY_PROJECT_UUID=<"%RESULT_FILE%"

if "%COOLIFY_PROJECT_UUID%"=="NONE" (
    coolify project create --name "%PROJECT_NAME%" --format json > "%JSON_FILE%"

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: Coolify project creation failed.
        pause
        exit /b 1
    )

    powershell -NoProfile -Command "$data = Get-Content -Raw $env:JSON_FILE | ConvertFrom-Json; [IO.File]::WriteAllText($env:RESULT_FILE,[string]$data.uuid)"

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: Could not read new Coolify project UUID.
        pause
        exit /b 1
    )

    set /p COOLIFY_PROJECT_UUID=<"%RESULT_FILE%"
)

if not defined COOLIFY_PROJECT_UUID (
    echo.
    echo ERROR: Could not determine Coolify project UUID.
    pause
    exit /b 1
)

rem --------------------------------------------------
rem Find or create Coolify application
rem --------------------------------------------------

coolify app list --format json > "%JSON_FILE%"

if ERRORLEVEL 1 (
    echo.
    echo ERROR: Could not read Coolify applications.
    pause
    exit /b 1
)

powershell -NoProfile -Command "$apps = Get-Content -Raw $env:JSON_FILE | ConvertFrom-Json; $match = $apps | Where-Object { $_.git_repository -eq $env:REPO } | Select-Object -First 1; if ($match) { [IO.File]::WriteAllText($env:RESULT_FILE,[string]$match.uuid) } else { [IO.File]::WriteAllText($env:RESULT_FILE,'NONE') }"

if ERRORLEVEL 1 (
    echo.
    echo ERROR: Could not inspect Coolify applications.
    pause
    exit /b 1
)

set /p COOLIFY_APP_UUID=<"%RESULT_FILE%"

if "%COOLIFY_APP_UUID%"=="NONE" (
    coolify app create github ^
        --server-uuid "%COOLIFY_SERVER_UUID%" ^
        --project-uuid "%COOLIFY_PROJECT_UUID%" ^
        --environment-name production ^
        --github-app-uuid "%COOLIFY_GITHUB_APP_UUID%" ^
        --git-repository "%REPO%" ^
        --git-branch main ^
        --build-pack nixpacks ^
        --ports-exposes 8000 ^
        --start-command "python main.py" ^
        --name "%PROJECT_NAME%" ^
        --format json > "%JSON_FILE%"

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: Coolify application creation failed.
        pause
        exit /b 1
    )

    powershell -NoProfile -Command "$data = Get-Content -Raw $env:JSON_FILE | ConvertFrom-Json; [IO.File]::WriteAllText($env:RESULT_FILE,[string]$data.uuid)"

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: Could not read new Coolify application UUID.
        pause
        exit /b 1
    )

    set /p COOLIFY_APP_UUID=<"%RESULT_FILE%"
)

if not defined COOLIFY_APP_UUID (
    echo.
    echo ERROR: Could not determine Coolify application UUID.
    pause
    exit /b 1
)

del "%JSON_FILE%" >nul 2>&1
del "%RESULT_FILE%" >nul 2>&1

echo.
echo Project ready.
echo.
echo GitHub:  https://github.com/%REPO%
echo Coolify: connected
echo.
echo Next:
echo   1. Start Docker Desktop
echo   2. Open this folder in VS Code
echo   3. Reopen in Container
echo   4. Start coding
echo   5. First git push deploys automatically
echo.
pause