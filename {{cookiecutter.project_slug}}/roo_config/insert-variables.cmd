@echo off
setlocal enabledelayedexpansion

echo RooFlow Environment Setup Script (Windows)
echo =========================================
echo.
echo This script will update system prompt files with your local environment details.
echo.

REM Get system information
for /f "tokens=*" %%a in ('ver') do set OS_INFO=%%a
for /f "tokens=*" %%a in ('echo %COMSPEC%') do set SHELL_INFO=%%a
set HOME_DIR=%USERPROFILE%
set WORKSPACE_DIR=%CD%

echo Detected Environment:
echo - OS: %OS_INFO%
echo - Shell: %SHELL_INFO%
echo - Home Directory: %HOME_DIR%
echo - Workspace Directory: %WORKSPACE_DIR%
echo.

REM Process system prompt files
echo Processing system prompt files...

REM Check if roo_config\clinerules directory exists with system prompt files
if exist "roo_config\clinerules\.clinerules-*" (
    echo Found system prompt files in roo_config/clinerules
    for %%f in (roo_config\clinerules\.clinerules-*) do (
        set "filename=%%~nxf"
        echo Processing !filename!
        echo Copying !filename! to workspace directory
        copy "%%f" "!filename!" > nul

        REM Read file content
        set "content="
        for /f "tokens=* delims=" %%l in (%%f) do (
            set "line=%%l"
            set "line=!line:OS_PLACEHOLDER=%OS_INFO%!"
            set "line=!line:SHELL_PLACEHOLDER=%SHELL_INFO%!"
            set "line=!line:HOME_PLACEHOLDER=%HOME_DIR%!"
            set "line=!line:WORKSPACE_PLACEHOLDER=%WORKSPACE_DIR%!"
            set "content=!content!!line!^

"
        )
        echo Updated !filename!
    )
) else (
    echo No system prompt files found in roo_config/clinerules
    
    REM Check if default-system-prompt.md exists
    if exist "default-system-prompt.md" (
        echo Found default-system-prompt.md
        
        REM Read file content
        set "content="
        for /f "tokens=* delims=" %%l in (default-system-prompt.md) do (
            set "line=%%l"
            set "line=!line:OS_PLACEHOLDER=%OS_INFO%!"
            set "line=!line:SHELL_PLACEHOLDER=%SHELL_INFO%!"
            set "line=!line:HOME_PLACEHOLDER=%HOME_DIR%!"
            set "line=!line:WORKSPACE_PLACEHOLDER=%WORKSPACE_DIR%!"
            set "content=!content!!line!^

"
        )
        
        REM Create system prompt files for each mode
        for %%m in (code architect ask debug test vibemode advanced-orchestrator) do (
            echo !content! > "%WORKSPACE_DIR%\.clinerules-%%m"
            echo Created .clinerules-%%m
        )
    ) else (
        echo No default system prompt found. Please create system prompt files manually.
    )
)

echo.
echo Setup complete!
echo You can now use RooFlow with your local environment settings.
echo.

endlocal