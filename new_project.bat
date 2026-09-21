@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "TEMPLATE=C:\Users\jcdel\Root\03_RESOURCES\06_GOLDEN_PATH\template"
set "OUTER_FOLDER=%~dp0"

set "GITHUB_OWNER=jcbuildstech"
set "COOLIFY_SERVER_UUID=ew0ckwcs444o4c0s4s0000so"
set "COOLIFY_GITHUB_APP_UUID=ugwgsgowsgskc4w40ws4s0sc"

:ASK_PROJECT_NAME
echo.
set "PROJECT_NAME="
set /p "PROJECT_NAME=Project name: "

powershell -NoProfile -Command "if ($env:PROJECT_NAME -match '^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$') { exit 0 } else { exit 1 }"

if ERRORLEVEL 1 (
    echo.
    echo Invalid project name.
    echo Use lowercase letters, numbers and hyphens only.
    echo Do not start or end with a hyphen.
    echo Maximum length: 63 characters.
    echo.
    echo Example: qld-traffic-monitor
    goto ASK_PROJECT_NAME
)

set "TARGET=%OUTER_FOLDER%%PROJECT_NAME%"

if not exist "%TARGET%" (
    mkdir "%TARGET%"
)

set "REPO=%GITHUB_OWNER%/%PROJECT_NAME%"
set "DATABASE_NAME=%PROJECT_NAME%-postgres"
set "WORKER_NAME=%PROJECT_NAME%-worker"
set "DATABASE_WAS_CREATED=0"
set "DB_PASSWORD="

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
rem Find or create Coolify PostgreSQL
rem --------------------------------------------------

echo Creating production PostgreSQL...

coolify database list --format json > "%JSON_FILE%"

if ERRORLEVEL 1 (
    echo.
    echo ERROR: Could not read Coolify databases.
    pause
    exit /b 1
)

powershell -NoProfile -Command "$databases = Get-Content -Raw $env:JSON_FILE | ConvertFrom-Json; $match = $databases | Where-Object { $_.name -eq $env:DATABASE_NAME -and $_.type -eq 'postgresql' } | Select-Object -First 1; if ($match) { [IO.File]::WriteAllText($env:RESULT_FILE,[string]$match.uuid) } else { [IO.File]::WriteAllText($env:RESULT_FILE,'NONE') }"

if ERRORLEVEL 1 (
    echo.
    echo ERROR: Could not inspect Coolify databases.
    pause
    exit /b 1
)

set /p COOLIFY_DB_UUID=<"%RESULT_FILE%"

if "%COOLIFY_DB_UUID%"=="NONE" (
    powershell -NoProfile -Command "[IO.File]::WriteAllText($env:RESULT_FILE,([guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')))"

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: Could not generate PostgreSQL password.
        pause
        exit /b 1
    )

    set /p DB_PASSWORD=<"%RESULT_FILE%"

    coolify database create postgresql ^
        --server-uuid "%COOLIFY_SERVER_UUID%" ^
        --project-uuid "%COOLIFY_PROJECT_UUID%" ^
        --environment-name production ^
        --name "%DATABASE_NAME%" ^
        --image "postgres:17-alpine" ^
        --postgres-user "app" ^
        --postgres-password "!DB_PASSWORD!" ^
        --postgres-db "app" ^
        --instant-deploy ^
        --format json > "%JSON_FILE%"

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: Production PostgreSQL creation failed.
        pause
        exit /b 1
    )

    powershell -NoProfile -Command "$data = Get-Content -Raw $env:JSON_FILE | ConvertFrom-Json; [IO.File]::WriteAllText($env:RESULT_FILE,[string]$data.uuid)"

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: Could not read new PostgreSQL UUID.
        pause
        exit /b 1
    )

    set /p COOLIFY_DB_UUID=<"%RESULT_FILE%"
    set "DATABASE_WAS_CREATED=1"
)

if not defined COOLIFY_DB_UUID (
    echo.
    echo ERROR: Could not determine PostgreSQL UUID.
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

powershell -NoProfile -Command "$apps = Get-Content -Raw $env:JSON_FILE | ConvertFrom-Json; $match = $apps | Where-Object { $_.git_repository -eq $env:REPO -and $_.name -eq $env:PROJECT_NAME } | Select-Object -First 1; if ($match) { [IO.File]::WriteAllText($env:RESULT_FILE,[string]$match.uuid) } else { [IO.File]::WriteAllText($env:RESULT_FILE,'NONE') }"

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

rem --------------------------------------------------
rem Wire production PostgreSQL to Web application
rem --------------------------------------------------

coolify app env list "%COOLIFY_APP_UUID%" --format json > "%JSON_FILE%"

if ERRORLEVEL 1 (
    echo.
    echo ERROR: Could not read Coolify application environment variables.
    pause
    exit /b 1
)

powershell -NoProfile -Command "$vars = Get-Content -Raw $env:JSON_FILE | ConvertFrom-Json; $match = $vars | Where-Object { $_.key -eq 'DATABASE_URL' } | Select-Object -First 1; if ($match) { [IO.File]::WriteAllText($env:RESULT_FILE,'EXISTS') } else { [IO.File]::WriteAllText($env:RESULT_FILE,'NONE') }"

if ERRORLEVEL 1 (
    echo.
    echo ERROR: Could not inspect Coolify application environment variables.
    pause
    exit /b 1
)

set /p DATABASE_URL_STATE=<"%RESULT_FILE%"

if "%DATABASE_URL_STATE%"=="NONE" (
    if "%DATABASE_WAS_CREATED%"=="0" (
        echo.
        echo ERROR: Existing PostgreSQL found but DATABASE_URL is missing.
        echo Cannot safely reconstruct its password automatically.
        pause
        exit /b 1
    )

    set "DATABASE_URL=postgresql://app:%DB_PASSWORD%@%COOLIFY_DB_UUID%:5432/app"

    coolify app env create "%COOLIFY_APP_UUID%" ^
        --key "DATABASE_URL" ^
        --value "!DATABASE_URL!" ^
        --is-literal ^
        --build-time=false ^
        --runtime=true >nul

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: Could not wire DATABASE_URL to Coolify application.
        pause
        exit /b 1
    )
)

rem --------------------------------------------------
rem Find or create Coolify Worker application
rem --------------------------------------------------

echo Creating worker application...

coolify app list --format json > "%JSON_FILE%"

if ERRORLEVEL 1 (
    echo.
    echo ERROR: Could not read Coolify applications for Worker.
    pause
    exit /b 1
)

powershell -NoProfile -Command "$apps = Get-Content -Raw $env:JSON_FILE | ConvertFrom-Json; $match = $apps | Where-Object { $_.git_repository -eq $env:REPO -and $_.name -eq $env:WORKER_NAME } | Select-Object -First 1; if ($match) { [IO.File]::WriteAllText($env:RESULT_FILE,[string]$match.uuid) } else { [IO.File]::WriteAllText($env:RESULT_FILE,'NONE') }"

if ERRORLEVEL 1 (
    echo.
    echo ERROR: Could not inspect Coolify Worker applications.
    pause
    exit /b 1
)

set /p COOLIFY_WORKER_UUID=<"%RESULT_FILE%"

if "%COOLIFY_WORKER_UUID%"=="NONE" (
    coolify app create github ^
        --server-uuid "%COOLIFY_SERVER_UUID%" ^
        --project-uuid "%COOLIFY_PROJECT_UUID%" ^
        --environment-name production ^
        --github-app-uuid "%COOLIFY_GITHUB_APP_UUID%" ^
        --git-repository "%REPO%" ^
        --git-branch main ^
        --build-pack nixpacks ^
        --ports-exposes 8001 ^
        --start-command "python worker.py" ^
        --name "%WORKER_NAME%" ^
        --format json > "%JSON_FILE%"

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: Coolify Worker creation failed.
        pause
        exit /b 1
    )

    powershell -NoProfile -Command "$data = Get-Content -Raw $env:JSON_FILE | ConvertFrom-Json; [IO.File]::WriteAllText($env:RESULT_FILE,[string]$data.uuid)"

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: Could not read Worker UUID.
        pause
        exit /b 1
    )

    set /p COOLIFY_WORKER_UUID=<"%RESULT_FILE%"
)

if not defined COOLIFY_WORKER_UUID (
    echo.
    echo ERROR: Could not determine Worker UUID.
    pause
    exit /b 1
)

rem --------------------------------------------------
rem Wire production PostgreSQL to Worker
rem --------------------------------------------------

coolify app env list "%COOLIFY_WORKER_UUID%" --format json > "%JSON_FILE%"

if ERRORLEVEL 1 (
    echo.
    echo ERROR: Could not read Worker environment variables.
    pause
    exit /b 1
)

powershell -NoProfile -Command "$vars = Get-Content -Raw $env:JSON_FILE | ConvertFrom-Json; $match = $vars | Where-Object { $_.key -eq 'DATABASE_URL' } | Select-Object -First 1; if ($match) { [IO.File]::WriteAllText($env:RESULT_FILE,'EXISTS') } else { [IO.File]::WriteAllText($env:RESULT_FILE,'NONE') }"

set /p WORKER_DATABASE_URL_STATE=<"%RESULT_FILE%"

if "%WORKER_DATABASE_URL_STATE%"=="NONE" (
    if "%DATABASE_WAS_CREATED%"=="0" (
        echo.
        echo ERROR: Existing PostgreSQL found but Worker DATABASE_URL is missing.
        pause
        exit /b 1
    )

    if not defined DATABASE_URL (
        set "DATABASE_URL=postgresql://app:!DB_PASSWORD!@!COOLIFY_DB_UUID!:5432/app"
    )

    coolify app env create "%COOLIFY_WORKER_UUID%" ^
        --key "DATABASE_URL" ^
        --value "!DATABASE_URL!" ^
        --is-literal ^
        --build-time=false ^
        --runtime=true >nul

    if ERRORLEVEL 1 (
        echo.
        echo ERROR: Could not wire DATABASE_URL to Worker.
        pause
        exit /b 1
    )
)

set "DB_PASSWORD="
set "DATABASE_URL="

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