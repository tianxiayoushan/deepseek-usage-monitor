@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1

:: ═══════════════════════════════════════════════════════════════════
:: start-windows.bat — DeepSeek Usage Monitor
:: Double-click this file to start the app on Windows.
::
:: This script will:
::   1. Check for Node.js and Python
::   2. Install npm dependencies if needed
::   3. Create a Python venv and install backend dependencies if needed
::   4. Open two separate windows: one for backend, one for frontend
::   5. Open http://localhost:5173 in your default browser
:: ═══════════════════════════════════════════════════════════════════

:: ── Resolve project root (handles spaces in path) ────────────────────
cd /d "%~dp0"
set "SCRIPT_DIR=%~dp0"
:: Remove trailing backslash
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo.
echo   DeepSeek Usage Monitor — Launcher
echo   v0.2.2 - Windows
echo   ------------------------------------------
echo.

:: ── 1. Check Node.js ─────────────────────────────────────────────────
echo [CHECK] Node.js...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   ERROR: Node.js is not installed or not in PATH.
    echo.
    echo   Please install Node.js 18+ from:
    echo     https://nodejs.org/
    echo.
    echo   After installing, restart this script.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('node --version 2^>nul') do set NODE_VER=%%v
echo [OK]    Node.js found: %NODE_VER%

:: ── 2. Check npm ─────────────────────────────────────────────────────
where npm >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   ERROR: npm is not installed or not in PATH.
    echo.
    echo   npm usually comes bundled with Node.js.
    echo   Please reinstall Node.js from: https://nodejs.org/
    echo.
    pause
    exit /b 1
)
echo [OK]    npm found.

:: ── 3. Check Python ──────────────────────────────────────────────────
echo [CHECK] Python...
set "PYTHON_CMD="

where python >nul 2>&1
if %errorlevel% equ 0 (
    python --version 2>&1 | findstr "3\." >nul
    if !errorlevel! equ 0 (
        set "PYTHON_CMD=python"
    )
)

if "%PYTHON_CMD%"=="" (
    where py >nul 2>&1
    if %errorlevel% equ 0 (
        py --version 2>&1 | findstr "3\." >nul
        if !errorlevel! equ 0 (
            set "PYTHON_CMD=py"
        )
    )
)

if "%PYTHON_CMD%"=="" (
    echo.
    echo   ERROR: Python 3 is not installed or not in PATH.
    echo.
    echo   Please install Python 3.10+ from:
    echo     https://www.python.org/downloads/
    echo.
    echo   Make sure to check "Add Python to PATH" during installation.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('%PYTHON_CMD% --version 2^>nul') do set PY_VER=%%v
echo [OK]    Python found: %PY_VER%

:: ── 4. Check package.json ────────────────────────────────────────────
if not exist "%SCRIPT_DIR%\package.json" (
    echo.
    echo   ERROR: package.json not found.
    echo   Are you running this script from the project root?
    echo.
    pause
    exit /b 1
)

:: ── 5. Frontend npm install ───────────────────────────────────────────
if not exist "%SCRIPT_DIR%\node_modules" (
    echo.
    echo [INFO]  node_modules not found. Running npm install...
    echo         This may take a minute on first run.
    echo.
    call npm install
    if !errorlevel! neq 0 (
        echo.
        echo   ERROR: npm install failed.
        echo   Check your internet connection and try again.
        echo.
        pause
        exit /b 1
    )
    echo [OK]    Frontend dependencies installed.
) else (
    echo [OK]    node_modules found, skipping npm install.
)

:: ── 6. Backend setup ──────────────────────────────────────────────────
set "BACKEND_DIR=%SCRIPT_DIR%\backend"

if not exist "%BACKEND_DIR%" (
    echo.
    echo   ERROR: backend\ directory not found.
    echo.
    pause
    exit /b 1
)

if not exist "%BACKEND_DIR%\requirements.txt" (
    echo.
    echo   ERROR: backend\requirements.txt not found.
    echo.
    pause
    exit /b 1
)

:: Create venv if needed
if not exist "%BACKEND_DIR%\.venv" (
    echo [INFO]  Creating Python virtual environment...
    %PYTHON_CMD% -m venv "%BACKEND_DIR%\.venv"
    if !errorlevel! neq 0 (
        echo.
        echo   ERROR: Failed to create Python virtual environment.
        echo.
        pause
        exit /b 1
    )
    echo [OK]    Virtual environment created.
)

:: Install backend dependencies
echo [INFO]  Installing backend dependencies...
call "%BACKEND_DIR%\.venv\Scripts\pip.exe" install -q -r "%BACKEND_DIR%\requirements.txt"
if %errorlevel% neq 0 (
    echo.
    echo   ERROR: pip install failed. Check requirements.txt and your internet connection.
    echo.
    pause
    exit /b 1
)
echo [OK]    Backend dependencies installed.

:: ── 7. .env setup ────────────────────────────────────────────────────
if not exist "%BACKEND_DIR%\.env" (
    if exist "%BACKEND_DIR%\.env.example" (
        copy "%BACKEND_DIR%\.env.example" "%BACKEND_DIR%\.env" >nul
        echo [WARN]  .env not found — copied from .env.example.
        echo         Use Dashboard Settings to enter your DeepSeek API Key.
    ) else (
        echo [WARN]  .env and .env.example both missing.
        echo         The backend will start without an API key.
        echo         Use Dashboard Settings to enter your API key after launch.
    )
) else (
    echo [OK]    .env file found.
)

:: ── 8. Launch backend in a new window ────────────────────────────────
echo.
echo [INFO]  Starting backend in a new window...
start "DeepSeek Backend — port 8789" cmd /k "cd /d "%BACKEND_DIR%" && call ".venv\Scripts\activate.bat" && uvicorn main:app --host 127.0.0.1 --port 8789 --reload"

:: Wait a moment for backend to start
echo [INFO]  Waiting 5s for backend to initialize...
timeout /t 5 /nobreak >nul

:: ── 9. Launch frontend in a new window ───────────────────────────────
echo [INFO]  Starting frontend in a new window...
start "DeepSeek Frontend — port 5173" cmd /k "cd /d "%SCRIPT_DIR%" && npm run dev -- --host 127.0.0.1"

:: Wait for Vite to compile
echo [INFO]  Waiting 5s for Vite to compile...
timeout /t 5 /nobreak >nul

:: ── 10. Open browser ─────────────────────────────────────────────────
echo [INFO]  Opening Dashboard in browser...
start "" "http://localhost:5173"

:: ── 11. Done ─────────────────────────────────────────────────────────
echo.
echo   ------------------------------------------
echo   DeepSeek Usage Monitor is starting!
echo.
echo   Dashboard: http://localhost:5173
echo   Backend:   http://127.0.0.1:8789/api/health
echo.
echo   Two windows have been opened:
echo     - "DeepSeek Backend"  (keep this running)
echo     - "DeepSeek Frontend" (keep this running)
echo.
echo   To stop: close both windows.
echo   ------------------------------------------
echo.
pause
