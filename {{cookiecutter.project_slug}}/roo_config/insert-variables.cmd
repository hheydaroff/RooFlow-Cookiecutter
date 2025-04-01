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

REM Run MCP Checker to extract MCP metadata
echo Running MCP Checker to extract MCP metadata...
set MCP_TEMP_FILE=%TEMP%\mcp_metadata.md
set MCP_ERROR_LOG=%TEMP%\mcp_error.log

REM Check if Python is available
where python >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    REM Python is available, run the MCP checker
    python "%WORKSPACE_DIR%\mcp_checker.py" "%MCP_SETTINGS%" > "%MCP_TEMP_FILE%" 2> "%MCP_ERROR_LOG%"
    if %ERRORLEVEL% EQU 0 (
        echo MCP metadata extracted successfully
    ) else (
        echo Warning: Failed to extract MCP metadata. Check %MCP_ERROR_LOG% for details.
        echo The script will continue, but MCP metadata may not be updated.
        type nul > "%MCP_TEMP_FILE%"
    )
) else (
    echo Warning: Python is not available. MCP metadata extraction will be skipped.
    echo To extract MCP metadata, please install Python and the required packages.
)

REM Process system prompt files
echo Looking for system prompt files...

REM Check for system prompt files in different possible locations
set "PROMPT_FILES_DIR="

REM List of possible locations for system prompt files
set "LOCATIONS=%CONFIG_DIR%\.roo %PROJECT_ROOT%\roo_config\.roo %PROJECT_ROOT%\{{cookiecutter.project_slug}}\roo_config\.roo %WORKSPACE_DIR%\roo_config\.roo"

for %%L in (%LOCATIONS%) do (
    echo Checking %%L
    if exist "%%L\*" (
        set "PROMPT_FILES_DIR=%%L"
        echo Found system prompt files in !PROMPT_FILES_DIR!
        goto :found_prompt_files
    )
)

:found_prompt_files
if defined PROMPT_FILES_DIR (
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
    echo No system prompt files found in any of the expected locations.
    
    REM List directories to help debug
    echo Current directory structure:
    dir /s /b "%PROJECT_ROOT%\.roo" "%PROJECT_ROOT%\roo_config" 2>nul
    echo.
    
    REM Check for default template in different locations
    set "DEFAULT_TEMPLATE="
    set "TEMPLATE_LOCATIONS=%PROJECT_ROOT%\default-system-prompt.md %WORKSPACE_DIR%\default-system-prompt.md %CONFIG_DIR%\default-system-prompt.md"
    
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
        for %%m in (code architect ask debug test) do (
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

endlocal