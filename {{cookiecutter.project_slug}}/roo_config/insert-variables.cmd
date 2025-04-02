@echo off
setlocal enabledelayedexpansion

echo RooFlow Environment Setup Script (Windows)
echo =========================================
echo.
echo This script will update system prompt files with your local environment details and MCP metadata.
echo.

REM --- Determine script location and project root ---
REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
echo Script directory: %SCRIPT_DIR%

REM Determine project root and config directory
for %%I in ("%SCRIPT_DIR%\..") do set "PROJECT_ROOT=%%~fI"
set "CONFIG_DIR=%SCRIPT_DIR%"

echo - Project Root: %PROJECT_ROOT%
echo - Config Directory: %CONFIG_DIR%

REM Get system information
for /f "tokens=*" %%a in ('ver') do set OS_INFO=%%a
for /f "tokens=*" %%a in ('echo %COMSPEC%') do set SHELL_INFO=%%a
set HOME_DIR=%USERPROFILE%
set WORKSPACE_DIR=%PROJECT_ROOT%
set GLOBAL_SETTINGS=%USERPROFILE%\AppData\Roaming\Code\User\globalStorage\rooveterinaryinc.roo-cline\settings\cline_custom_modes.json
set MCP_LOCATION=%USERPROFILE%\.local\share\Roo-Code\MCP
set MCP_SETTINGS=%USERPROFILE%\AppData\Roaming\Code\User\globalStorage\rooveterinaryinc.roo-cline\settings\cline_mcp_settings.json

echo Detected Environment:
echo - OS: %OS_INFO%
echo - Shell: %SHELL_INFO%
echo - Home Directory: %HOME_DIR%
echo - Workspace Directory: %WORKSPACE_DIR%
echo.

REM --- Directory Setup ---
set ROO_DIR=%WORKSPACE_DIR%\.roo

REM Create .roo directory if it doesn't exist
if not exist "%ROO_DIR%" (
    mkdir "%ROO_DIR%"
    echo Created .roo directory at %ROO_DIR%
)

REM --- Function to check dependencies ---
call :check_dependencies
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Dependency check failed. Some features may not work correctly.
)

REM --- Set up paths for MCP checker ---
set MCP_CHECKER_SCRIPT=%CONFIG_DIR%\mcp_checker.py
set MCP_TEMP_FILE=%TEMP%\mcp_metadata.md
set MCP_ERROR_LOG=%TEMP%\mcp_error.log

REM --- Run MCP checker with fallbacks ---
call :run_mcp_checker "%MCP_TEMP_FILE%" "%MCP_ERROR_LOG%" "%MCP_CHECKER_SCRIPT%"
if %ERRORLEVEL% EQU 0 (
    echo MCP metadata extracted successfully and saved to %MCP_TEMP_FILE%
    REM Display file size and first few lines
    dir "%MCP_TEMP_FILE%"
    echo First few lines of MCP metadata:
    type "%MCP_TEMP_FILE%" | findstr /N "^" | findstr /B "^[1-5]:" 
    
    REM Store the content in a variable for later use
    set /p MCP_CHECKER_OUTPUT=<"%MCP_TEMP_FILE%"
) else (
    echo Warning: Failed to extract MCP metadata. Check %MCP_ERROR_LOG% for details.
    echo The script will continue, but MCP metadata may not be updated.
    echo No MCP metadata available > "%MCP_TEMP_FILE%"
    set MCP_CHECKER_OUTPUT=No MCP metadata available
)

REM Process system prompt files
echo Looking for system prompt files...

REM Only look in the project's roo_config/.roo directory
set "PROMPT_FILES_DIR=%CONFIG_DIR%\.roo"

echo Checking %PROMPT_FILES_DIR%
if exist "%PROMPT_FILES_DIR%\*" (
    echo Found system prompt files in %PROMPT_FILES_DIR%
    
    REM Copy files from found location to .roo
    for %%f in ("%PROMPT_FILES_DIR%\*") do (
        REM Get filename without path
        for %%i in (%%f) do set "filename=%%~nxi"
        echo Processing %%f to %ROO_DIR%\!filename!

        REM Copy file to .roo directory
        copy "%%f" "%ROO_DIR%\!filename!" > nul
        
        REM Replace placeholders
        powershell -Command "(Get-Content '%ROO_DIR%\!filename!') -replace 'OS_PLACEHOLDER', '%OS_INFO%' | Set-Content '%ROO_DIR%\!filename!'"
        powershell -Command "(Get-Content '%ROO_DIR%\!filename!') -replace 'SHELL_PLACEHOLDER', '%SHELL_INFO%' | Set-Content '%ROO_DIR%\!filename!'"
        powershell -Command "(Get-Content '%ROO_DIR%\!filename!') -replace 'HOME_PLACEHOLDER', '%HOME_DIR%' | Set-Content '%ROO_DIR%\!filename!'"
        powershell -Command "(Get-Content '%ROO_DIR%\!filename!') -replace 'WORKSPACE_PLACEHOLDER', '%WORKSPACE_DIR%' | Set-Content '%ROO_DIR%\!filename!'"
        powershell -Command "(Get-Content '%ROO_DIR%\!filename!') -replace 'GLOBAL_SETTINGS_PLACEHOLDER', '%GLOBAL_SETTINGS%' | Set-Content '%ROO_DIR%\!filename!'"
        powershell -Command "(Get-Content '%ROO_DIR%\!filename!') -replace 'MCP_LOCATION_PLACEHOLDER', '%MCP_LOCATION%' | Set-Content '%ROO_DIR%\!filename!'"
        powershell -Command "(Get-Content '%ROO_DIR%\!filename!') -replace 'MCP_SETTINGS_PLACEHOLDER', '%MCP_SETTINGS%' | Set-Content '%ROO_DIR%\!filename!'"
        
        REM Update MCP section if we have metadata
        if exist "%MCP_TEMP_FILE%" (
            echo Updating MCP metadata in: %ROO_DIR%\!filename!
            
            REM Create a PowerShell script to update the MCP section
            echo $file = '%ROO_DIR%\!filename!' > "%TEMP%\update_mcp.ps1"
            echo $metadata = Get-Content -Raw '%MCP_TEMP_FILE%' >> "%TEMP%\update_mcp.ps1"
            echo $content = Get-Content $file >> "%TEMP%\update_mcp.ps1"
            echo $inMcp = $false >> "%TEMP%\update_mcp.ps1"
            echo $inConnectedServers = $false >> "%TEMP%\update_mcp.ps1"
            echo $newContent = @() >> "%TEMP%\update_mcp.ps1"
            echo foreach ($line in $content) { >> "%TEMP%\update_mcp.ps1"
            echo     if ($line -match '^mcp:') { >> "%TEMP%\update_mcp.ps1"
            echo         $inMcp = $true >> "%TEMP%\update_mcp.ps1"
            echo         $newContent += $line >> "%TEMP%\update_mcp.ps1"
            echo     } elseif ($inMcp -and $line -match '^    connected_servers:') { >> "%TEMP%\update_mcp.ps1"
            echo         $inConnectedServers = $true >> "%TEMP%\update_mcp.ps1"
            echo         $newContent += $line >> "%TEMP%\update_mcp.ps1"
            echo         $newContent += $metadata.Split([Environment]::NewLine) >> "%TEMP%\update_mcp.ps1"
            echo     } elseif ($inMcp -and $line -match '^[a-z]') { >> "%TEMP%\update_mcp.ps1"
            echo         $inMcp = $false >> "%TEMP%\update_mcp.ps1"
            echo         $inConnectedServers = $false >> "%TEMP%\update_mcp.ps1"
            echo         $newContent += $line >> "%TEMP%\update_mcp.ps1"
            echo     } elseif ($inConnectedServers -and $line -match '^      -') { >> "%TEMP%\update_mcp.ps1"
            echo         # Skip existing connected_servers content >> "%TEMP%\update_mcp.ps1"
            echo     } elseif ($inConnectedServers -and $line -match '^    [a-z]') { >> "%TEMP%\update_mcp.ps1"
            echo         $inConnectedServers = $false >> "%TEMP%\update_mcp.ps1"
            echo         $newContent += $line >> "%TEMP%\update_mcp.ps1"
            echo     } else { >> "%TEMP%\update_mcp.ps1"
            echo         $newContent += $line >> "%TEMP%\update_mcp.ps1"
            echo     } >> "%TEMP%\update_mcp.ps1"
            echo } >> "%TEMP%\update_mcp.ps1"
            echo $newContent | Set-Content $file >> "%TEMP%\update_mcp.ps1"
            
            REM Execute the PowerShell script
            powershell -ExecutionPolicy Bypass -File "%TEMP%\update_mcp.ps1"
            
            REM Clean up
            del "%TEMP%\update_mcp.ps1"
        )
        
        echo Completed: %ROO_DIR%\!filename!
    )
) else (
    echo No system prompt files found in %PROMPT_FILES_DIR%
    
    REM List directories to help debug
    echo Current directory structure:
    dir /s /b "%PROJECT_ROOT%\.roo" "%PROJECT_ROOT%\roo_config" 2>nul
    echo.
    
    REM Check for default template in the project
    set "DEFAULT_TEMPLATE="
    set "TEMPLATE_LOCATIONS=%PROJECT_ROOT%\default-system-prompt.md %CONFIG_DIR%\default-system-prompt.md"
    
    for %%T in (%TEMPLATE_LOCATIONS%) do (
        if exist "%%T" (
            set "DEFAULT_TEMPLATE=%%T"
            echo Found default template at !DEFAULT_TEMPLATE!
            goto :found_template
        )
    )
    
    :found_template
    if defined DEFAULT_TEMPLATE (
        REM Create system prompt files for each mode
        REM Define the list of supported modes
set "SUPPORTED_MODES=advanced-orchestrator architect ask code debug test vibemode junior-reviewer senior-reviewer documentation-writer"

REM Create system prompt files for each mode
for %%m in (%SUPPORTED_MODES%) do (
            REM Copy default template
            copy "%DEFAULT_TEMPLATE%" "%ROO_DIR%\system-prompt-%%m" > nul
            
            REM Replace placeholders
            powershell -Command "(Get-Content '%ROO_DIR%\system-prompt-%%m') -replace 'OS_PLACEHOLDER', '%OS_INFO%' | Set-Content '%ROO_DIR%\system-prompt-%%m'"
            powershell -Command "(Get-Content '%ROO_DIR%\system-prompt-%%m') -replace 'SHELL_PLACEHOLDER', '%SHELL_INFO%' | Set-Content '%ROO_DIR%\system-prompt-%%m'"
            powershell -Command "(Get-Content '%ROO_DIR%\system-prompt-%%m') -replace 'HOME_PLACEHOLDER', '%HOME_DIR%' | Set-Content '%ROO_DIR%\system-prompt-%%m'"
            powershell -Command "(Get-Content '%ROO_DIR%\system-prompt-%%m') -replace 'WORKSPACE_PLACEHOLDER', '%WORKSPACE_DIR%' | Set-Content '%ROO_DIR%\system-prompt-%%m'"
            powershell -Command "(Get-Content '%ROO_DIR%\system-prompt-%%m') -replace 'GLOBAL_SETTINGS_PLACEHOLDER', '%GLOBAL_SETTINGS%' | Set-Content '%ROO_DIR%\system-prompt-%%m'"
            powershell -Command "(Get-Content '%ROO_DIR%\system-prompt-%%m') -replace 'MCP_LOCATION_PLACEHOLDER', '%MCP_LOCATION%' | Set-Content '%ROO_DIR%\system-prompt-%%m'"
            powershell -Command "(Get-Content '%ROO_DIR%\system-prompt-%%m') -replace 'MCP_SETTINGS_PLACEHOLDER', '%MCP_SETTINGS%' | Set-Content '%ROO_DIR%\system-prompt-%%m'"
            
            REM Update MCP section if we have metadata
            if exist "%MCP_TEMP_FILE%" (
                echo Updating MCP metadata in: %ROO_DIR%\system-prompt-%%m
                
                REM Create a PowerShell script to update the MCP section
                echo $file = '%ROO_DIR%\system-prompt-%%m' > "%TEMP%\update_mcp.ps1"
                echo $metadata = Get-Content -Raw '%MCP_TEMP_FILE%' >> "%TEMP%\update_mcp.ps1"
                echo $content = Get-Content $file >> "%TEMP%\update_mcp.ps1"
                echo $inMcp = $false >> "%TEMP%\update_mcp.ps1"
                echo $inConnectedServers = $false >> "%TEMP%\update_mcp.ps1"
                echo $newContent = @() >> "%TEMP%\update_mcp.ps1"
                echo foreach ($line in $content) { >> "%TEMP%\update_mcp.ps1"
                echo     if ($line -match '^mcp:') { >> "%TEMP%\update_mcp.ps1"
                echo         $inMcp = $true >> "%TEMP%\update_mcp.ps1"
                echo         $newContent += $line >> "%TEMP%\update_mcp.ps1"
                echo     } elseif ($inMcp -and $line -match '^    connected_servers:') { >> "%TEMP%\update_mcp.ps1"
                echo         $inConnectedServers = $true >> "%TEMP%\update_mcp.ps1"
                echo         $newContent += $line >> "%TEMP%\update_mcp.ps1"
                echo         $newContent += $metadata.Split([Environment]::NewLine) >> "%TEMP%\update_mcp.ps1"
                echo     } elseif ($inMcp -and $line -match '^[a-z]') { >> "%TEMP%\update_mcp.ps1"
                echo         $inMcp = $false >> "%TEMP%\update_mcp.ps1"
                echo         $inConnectedServers = $false >> "%TEMP%\update_mcp.ps1"
                echo         $newContent += $line >> "%TEMP%\update_mcp.ps1"
                echo     } elseif ($inConnectedServers -and $line -match '^      -') { >> "%TEMP%\update_mcp.ps1"
                echo         # Skip existing connected_servers content >> "%TEMP%\update_mcp.ps1"
                echo     } elseif ($inConnectedServers -and $line -match '^    [a-z]') { >> "%TEMP%\update_mcp.ps1"
                echo         $inConnectedServers = $false >> "%TEMP%\update_mcp.ps1"
                echo         $newContent += $line >> "%TEMP%\update_mcp.ps1"
                echo     } else { >> "%TEMP%\update_mcp.ps1"
                echo         $newContent += $line >> "%TEMP%\update_mcp.ps1"
                echo     } >> "%TEMP%\update_mcp.ps1"
                echo } >> "%TEMP%\update_mcp.ps1"
                echo $newContent | Set-Content $file >> "%TEMP%\update_mcp.ps1"
                
                REM Execute the PowerShell script
                powershell -ExecutionPolicy Bypass -File "%TEMP%\update_mcp.ps1"
                
                REM Clean up
                del "%TEMP%\update_mcp.ps1"
            )
            
            echo Created %ROO_DIR%\system-prompt-%%m
        )
    ) else (
        echo No default system prompt template found.
        echo Please create system prompt files manually or provide a default template.
    )
)

REM Clean up temporary files
if exist "%MCP_TEMP_FILE%" del "%MCP_TEMP_FILE%"

echo.
echo Setup complete!
echo You can now use RooFlow with your local environment settings and updated MCP metadata.
echo.

goto :eof

REM --- Function to check dependencies ---
:check_dependencies
echo Checking dependencies...

REM Check for UV first (preferred)
where uv >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo UV detected! Using UV for package management.
    set UV_AVAILABLE=true
    
    REM Check for mcp package with UV
    uv pip list | findstr "mcp" >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo Installing mcp package using UV...
        uv pip install mcp
        
        REM Verify installation
        uv pip list | findstr "mcp" >nul 2>nul
        if %ERRORLEVEL% NEQ 0 (
            echo Error: Failed to install mcp package with UV.
            set UV_AVAILABLE=false
        ) else (
            echo Successfully installed mcp package with UV.
            exit /b 0
        )
    ) else (
        echo MCP package already installed with UV.
        exit /b 0
    )
) else (
    echo UV not detected. Checking for traditional Python tools...
    set UV_AVAILABLE=false
)

REM Check for Python if UV is not available
where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    where py >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Python is required but not installed.
        echo Please install Python 3.x to continue.
        exit /b 1
    ) else (
        set PYTHON_CMD=py -3
        echo Using Python command: py -3
    )
) else (
    set PYTHON_CMD=python
    echo Using Python command: python
)

REM Check Python version
%PYTHON_CMD% -c "import sys; sys.exit(0 if sys.version_info.major >= 3 else 1)" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Python 3.x is recommended. You may encounter issues with older versions.
)

REM Check for mcp package
%PYTHON_CMD% -c "import mcp" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Warning: 'mcp' package is not installed. Will attempt to install it.
    
    REM Try with pip
    where pip >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo Installing mcp package using pip...
        pip install mcp
    ) else (
        REM Try with Python's pip module
        echo Installing mcp package using Python's pip module...
        %PYTHON_CMD% -m pip install mcp
    )
    
    REM Verify installation
    %PYTHON_CMD% -c "import mcp" >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Failed to install mcp package.
        echo Please install it manually: pip install mcp
        exit /b 1
    )
    
    echo Successfully installed mcp package.
)

exit /b 0

REM --- Function to run MCP checker with fallbacks ---
:run_mcp_checker
set output_file=%~1
set error_log=%~2
set script_path=%~3

echo Running MCP Checker to extract MCP metadata...

REM Try with UV first (preferred method)
if "%UV_AVAILABLE%"=="true" (
    echo Using UV to run MCP checker...
    
    REM Try different UV execution methods
    uv run --with mcp "%script_path%" --output "%output_file%" >nul 2>"%error_log%"
    if %ERRORLEVEL% EQU 0 (
        echo Successfully ran MCP checker with UV.
        exit /b 0
    )
    
    echo Trying alternative UV execution method...
    uv run "%script_path%" --output "%output_file%" >nul 2>>"%error_log%"
    if %ERRORLEVEL% EQU 0 (
        echo Successfully ran MCP checker with alternative UV method.
        exit /b 0
    )
    
    echo Warning: Failed to run MCP checker with UV. Falling back to direct Python execution.
)

REM Try direct Python execution
echo Using %PYTHON_CMD% to run MCP checker...
%PYTHON_CMD% "%script_path%" --output "%output_file%" >nul 2>>"%error_log%"
if %ERRORLEVEL% EQU 0 (
    echo Successfully ran MCP checker with direct Python execution.
    exit /b 0
)

REM If we got here, all methods failed
echo Error: Failed to run MCP checker with all available methods.
echo Check %error_log% for details.
exit /b 1

endlocal