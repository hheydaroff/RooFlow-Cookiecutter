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

REM Create .roo directory if it doesn't exist
if not exist ".roo" (
    mkdir .roo
    echo Created .roo directory
)

REM Process system prompt files
echo Processing system prompt files...

REM Check if roo_config\.roo directory exists with system prompt files
if exist "roo_config\.roo\*" (
    echo Found system prompt files in roo_config/.roo
    for %%f in (roo_config\.roo\*) do (
        echo Processing %%f
        
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
        
        REM Get filename without path
        for %%i in (%%f) do set "filename=%%~nxi"
        
        REM Write updated content to .roo directory
        echo !content! > .roo\!filename!
        echo Updated .roo\!filename!
    )
) else (
    echo No system prompt files found in roo_config/.roo
    
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
        for %%m in (code architect ask debug test) do (
            echo !content! > .roo\system-prompt-%%m
            echo Created .roo\system-prompt-%%m
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