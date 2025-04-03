#!/usr/bin/env python
import os
import platform
import subprocess
import shutil
import sys
import logging
import glob

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

def run_command(cmd, error_msg=None):
    """Run a command and handle errors.
    
    Args:
        cmd (list): Command to run as a list of arguments
        error_msg (str, optional): Custom error message to display on failure
        
    Returns:
        tuple: (success, output) where success is a boolean and output is the command output
    """
    try:
        result = subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return True, result.stdout.decode('utf-8').strip()
    except subprocess.CalledProcessError as e:
        if error_msg:
            logger.error(f"Error: {error_msg}")
            logger.error(f"Command output: {e.stderr.decode('utf-8')}")
        return False, e.stderr.decode('utf-8').strip()
    except Exception as e:
        if error_msg:
            logger.error(f"Error: {error_msg}")
            logger.error(f"Exception: {str(e)}")
        return False, str(e)

def check_uv_installed():
    """
    Check if UV/UVX is installed on the system and return details.
    
    Returns:
        dict: Dictionary containing information about UV availability:
            - uv_available: Whether the 'uv' command is available
            - uvx_available: Whether the 'uvx' command is available
            - version: The version of UV if available
            - any_available: Whether either 'uv' or 'uvx' is available
    """
    uv_available = False
    uvx_available = False
    version = None
    
    try:
        # Check for uv
        result = subprocess.run(['uv', '--version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.returncode == 0:
            uv_available = True
            version = result.stdout.decode('utf-8').strip()
            logger.debug(f"UV detected: {version}")
    except (FileNotFoundError, subprocess.SubprocessError) as e:
        logger.debug(f"UV not found: {e}")
        
    try:
        # Check for uvx
        result = subprocess.run(['uvx', '--version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.returncode == 0:
            uvx_available = True
            if not version:
                version = result.stdout.decode('utf-8').strip()
            logger.debug(f"UVX detected: {version}")
    except (FileNotFoundError, subprocess.SubprocessError) as e:
        logger.debug(f"UVX not found: {e}")
        
    return {
        'uv_available': uv_available,
        'uvx_available': uvx_available,
        'version': version,
        'any_available': uv_available or uvx_available
    }

def run_with_uv(cmd, error_msg=None, fallback=True):
    """
    Run a command with UV if available, with fallback to direct execution.
    
    Args:
        cmd (list): Command to run as a list of arguments
        error_msg (str, optional): Custom error message to display on failure
        fallback (bool): Whether to fall back to direct execution if UV fails
        
    Returns:
        tuple: (success, output) where success is a boolean and output is the command output
    """
    uv_info = check_uv_installed()
    
    if uv_info['uv_available']:
        logger.info(f"Running with UV: {' '.join(cmd)}")
        try:
            uv_cmd = ['uv', 'run'] + cmd
            result = subprocess.run(uv_cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            return True, result.stdout.decode('utf-8').strip()
        except subprocess.CalledProcessError as e:
            logger.warning(f"Failed to run with UV: {e.stderr.decode('utf-8')}")
            if not fallback:
                if error_msg:
                    logger.error(f"Error: {error_msg}")
                return False, e.stderr.decode('utf-8').strip()
        except Exception as e:
            logger.warning(f"Exception running with UV: {str(e)}")
            if not fallback:
                if error_msg:
                    logger.error(f"Error: {error_msg}")
                return False, str(e)
    
    # Fall back to direct execution
    if fallback:
        logger.info(f"Falling back to direct execution: {' '.join(cmd)}")
        return run_command(cmd, error_msg)
    
    return False, "UV execution failed and fallback disabled"

def create_uv_config():
    """Create UVX configuration files."""
    # Create .uv directory if it doesn't exist
    try:
        if not os.path.exists('.uv'):
            os.makedirs('.uv')
            logger.info("Created .uv directory")
        
        # Validate that the directory was created
        if not os.path.exists('.uv'):
            logger.error("Failed to create .uv directory")
            return False
    except Exception as e:
        logger.error(f"Error creating .uv directory: {e}")
        return False
    
    # Create uv.toml configuration file with enhanced settings
    try:
        with open('.uv/uv.toml', 'w') as f:
            f.write("""# UVX Configuration for RooFlow project
[tool]
# Use isolated environments by default
isolated = true

[python]
# Default Python version
default-version = "3.10"

[venv]
# Use .venv directory for virtual environments
venv-dir = ".venv"

[cache]
# Cache directory for downloaded packages
dir = ".uv/cache"

[http]
# Number of concurrent downloads
concurrency = 4
""")
        logger.info("Created .uv/uv.toml configuration file")
    except Exception as e:
        logger.error(f"Error creating .uv/uv.toml file: {e}")
        return False
    
    # Create helper scripts for UVX with enhanced functionality
    try:
        if platform.system() == 'Windows':
            with open('uv-setup.cmd', 'w') as f:
                f.write("""@echo off
echo Setting up UVX environment...

REM Create a virtual environment
echo Creating virtual environment...
uv venv

REM Install dependencies
echo Installing dependencies...
uv pip install -r requirements.txt

REM Install development dependencies if available
if exist requirements-dev.txt (
    echo Installing development dependencies...
    uv pip install -r requirements-dev.txt
)

echo UVX environment setup complete!
echo.
echo To activate the environment, run:
echo   .venv\\Scripts\\activate
""")
            logger.info("Created uv-setup.cmd")
        else:
            with open('uv-setup.sh', 'w') as f:
                f.write("""#!/bin/bash
echo "Setting up UVX environment..."

# Create a virtual environment
echo "Creating virtual environment..."
uv venv

# Install dependencies
echo "Installing dependencies..."
uv pip install -r requirements.txt

# Install development dependencies if available
if [ -f "requirements-dev.txt" ]; then
    echo "Installing development dependencies..."
    uv pip install -r requirements-dev.txt
fi

echo "UVX environment setup complete!"
echo
echo "To activate the environment, run:"
echo "  source .venv/bin/activate"
""")
            try:
                os.chmod('uv-setup.sh', 0o755)
                logger.info("Created uv-setup.sh with execute permissions")
            except Exception as e:
                logger.warning(f"Created uv-setup.sh but could not set execute permissions: {e}")
    except Exception as e:
        logger.error(f"Error creating setup scripts: {e}")
        return False
    
    # Create a basic requirements.txt file if it doesn't exist
    try:
        if not os.path.exists('requirements.txt'):
            with open('requirements.txt', 'w') as f:
                f.write("""# Project dependencies
# Add your dependencies here
mcp>=0.1.0
""")
            logger.info("Created requirements.txt with mcp dependency")
    except Exception as e:
        logger.error(f"Error creating requirements.txt: {e}")
        return False
    
    return True

def create_default_system_prompts():
    """Create default system prompt files if none are found."""
    logger.info("Creating default system prompt files...")
    
    # Create .roo directory if it doesn't exist
    if not os.path.exists('.roo'):
        os.makedirs('.roo')
        logger.info("Created .roo directory")
    
    # Basic template for system prompts
    template = """system_information:
  os: "OS_PLACEHOLDER"
  shell: "SHELL_PLACEHOLDER"
  home_directory: "HOME_PLACEHOLDER"
  working_directory: "WORKSPACE_PLACEHOLDER"

rules:
  environment:
    working_directory: "WORKSPACE_PLACEHOLDER"
  mcp_operations:
    server_management:
      location: "MCP_LOCATION_PLACEHOLDER"
      config_path: "MCP_SETTINGS_PLACEHOLDER"
  custom_modes:
    config_paths:
      global: "GLOBAL_SETTINGS_PLACEHOLDER"

mcp:
  overview:
    - "The Model Context Protocol (MCP) enables communication with external servers"
    - "MCP servers provide additional tools and resources to extend capabilities"
    - "Servers can be local (Stdio-based) or remote (SSE-based)"
  usage:
    - "Use server tools via the `use_mcp_tool` tool"
    - "Access server resources via the `access_mcp_resource` tool"
    - "Wait for server responses before proceeding with additional operations"
  connected_servers:
"""
    
    # Default mode names to create if no files are found
    default_modes = []
    
    # Try to read modes from .roomodes file if it exists
    if os.path.exists('.roomodes'):
        try:
            with open('.roomodes', 'r') as f:
                for line in f:
                    mode = line.strip()
                    if mode and not mode.startswith('#'):
                        default_modes.append(mode)
            logger.info(f"Read {len(default_modes)} modes from .roomodes file")
        except Exception as e:
            logger.warning(f"Error reading .roomodes file: {e}")
    
    # If no modes found in .roomodes, use minimal default set
    if not default_modes:
        default_modes = ["code", "ask"]  # Minimal default set
    
    # Create a system prompt file for each default mode
    for mode in default_modes:
        file_path = os.path.join('.roo', f'system-prompt-{mode}')
        try:
            with open(file_path, 'w') as f:
                f.write(template)
            logger.info(f"Created default system prompt file: {file_path}")
        except Exception as e:
            logger.error(f"Error creating system prompt file {file_path}: {e}")
    
    return True

def copy_system_prompt_files():
    """Copy system prompt files from template to project."""
    logger.info("Attempting to copy system prompt files...")
    
    # Create .roo directory if it doesn't exist
    if not os.path.exists('.roo'):
        os.makedirs('.roo')
        logger.info("Created .roo directory")
    
    # Only look in the project's roo_config/.roo directory
    template_roo_dir = 'roo_config/.roo'
    
    logger.info(f"Looking for system prompt files in: {template_roo_dir}")
    
    if os.path.exists(template_roo_dir) and os.path.isdir(template_roo_dir):
        logger.info(f"Found system prompt files in: {template_roo_dir}")
        
        # List all files in the directory
        files = os.listdir(template_roo_dir)
        logger.info(f"Files found: {files}")
        
        # Copy all files from template .roo directory to project .roo directory
        for filename in files:
            src_file = os.path.join(template_roo_dir, filename)
            dst_file = os.path.join('.roo', filename)
            
            if os.path.isfile(src_file):
                try:
                    shutil.copy2(src_file, dst_file)
                    logger.info(f"Copied system prompt file: {filename}")
                except Exception as e:
                    logger.error(f"Error copying {src_file} to {dst_file}: {e}")
        
        # Verify files were copied
        copied_files = os.listdir('.roo')
        logger.info(f"Files in .roo after copying: {copied_files}")
        
        if copied_files:
            return True
        else:
            logger.warning("No files were copied to .roo directory.")
    else:
        logger.warning(f"No system prompt files found in: {template_roo_dir}")
    
    # If we couldn't find any system prompt files, create default ones
    logger.warning("Could not find system prompt files. Creating default ones.")
    return create_default_system_prompts()

def main():
    logger.info("Running post-generation hook...")
    
    # First, try to copy system prompt files from the template
    copy_success = copy_system_prompt_files()
    if not copy_success:
        logger.warning("Failed to copy or create system prompt files.")
    
    # Check for UV
    uv_info = check_uv_installed()
    use_uv = uv_info['any_available']
    
    # Create .roo directory if it doesn't exist (should already be created by copy_system_prompt_files)
    try:
        if not os.path.exists('.roo'):
            os.makedirs('.roo')
            logger.info("Created .roo directory")
        
        # Validate that the directory was created
        if not os.path.exists('.roo'):
            logger.error("Failed to create .roo directory")
    except Exception as e:
        logger.error(f"Error creating .roo directory: {e}")

    # Move .rooignore and .roomodes to project root
    if os.path.exists('roo_config/.rooignore'):
        try:
            shutil.copy2('roo_config/.rooignore', '.rooignore')
            logger.info("Copied roo_config/.rooignore to .rooignore")
        except Exception as e:
            logger.error(f"Error copying .rooignore file: {e}")

    if os.path.exists('roo_config/.roomodes'):
        try:
            shutil.copy2('roo_config/.roomodes', '.roomodes')
            logger.info("Copied roo_config/.roomodes to .roomodes")
        except Exception as e:
            logger.error(f"Error copying .roomodes file: {e}")

    # Run the appropriate insert-variables script with UV if available
    if platform.system() == 'Windows':
        # Try the cross-platform script first
        # Use only the cross-platform Python script
        if os.path.exists('roo_config/insert_variables.py'):
            logger.info("Running insert_variables.py...")
            if use_uv:
                success, output = run_with_uv(['python', 'roo_config/insert_variables.py'], 
                                           "Failed to execute insert_variables.py with UV",
                                           fallback=True)
            else:
                success, output = run_command(['python', 'roo_config/insert_variables.py'], 
                                           "Failed to execute insert_variables.py")
            
            if not success:
                logger.error("Failed to execute insert_variables.py. Environment variables may not be set correctly.")
                logger.error(f"Error details: {output}")
            else:
                logger.info("insert_variables.py completed successfully.")
        else:
            logger.error("insert_variables.py not found. Environment variables will not be set.")
            logger.info("Please ensure the cross-platform script exists at 'roo_config/insert_variables.py'.")
    else:
        # Use only the cross-platform Python script for non-Windows platforms
        if os.path.exists('roo_config/insert_variables.py'):
            logger.info("Running insert_variables.py...")
            # Set execute permissions on the script
            try:
                os.chmod('roo_config/insert_variables.py', 0o755)
            except Exception as e:
                logger.warning(f"Could not set execute permissions on insert_variables.py: {e}")
                logger.warning("Attempting to run the script anyway...")
            
            if use_uv:
                success, output = run_with_uv(['python3', 'roo_config/insert_variables.py'], 
                                           "Failed to execute insert_variables.py with UV",
                                           fallback=True)
            else:
                success, output = run_command(['python3', 'roo_config/insert_variables.py'], 
                                           "Failed to execute insert_variables.py")
            
            if not success:
                logger.error("Failed to execute insert_variables.py. Environment variables may not be set correctly.")
                logger.error(f"Error details: {output}")
            else:
                logger.info("insert_variables.py completed successfully.")
        else:
            logger.error("insert_variables.py not found. Environment variables will not be set.")
            logger.info("Please ensure the cross-platform script exists at 'roo_config/insert_variables.py'.")

    # Create memory-bank directory and templates if selected
    include_memory_bank = '{{ cookiecutter.include_memory_bank_templates }}' == 'yes'
    if include_memory_bank:
        try:
            os.makedirs('memory-bank', exist_ok=True)
            logger.info("Created memory-bank directory")
            
            # Create template files for memory bank
            try:
                with open('memory-bank/README.md', 'w') as f:
                    f.write("""# Memory Bank

This directory contains memory bank templates for your RooFlow project.

## What is Memory Bank?

Memory Bank is a feature that allows you to store and retrieve information across sessions.
It helps maintain context and knowledge about your project over time.

## How to Use

Add files to this directory that contain important information about your project that you want
to persist across sessions. These files will be loaded into the AI's context when you start a new session.
""")
                logger.info("Created memory-bank/README.md")
            except Exception as e:
                logger.error(f"Error creating memory-bank/README.md: {e}")
        except Exception as e:
            logger.error(f"Error creating memory-bank directory: {e}")

    # Remove default-mode if not selected
    include_default_mode = '{{ cookiecutter.include_default_mode }}' == 'yes'
    if not include_default_mode:
        if os.path.exists('roo_config/default-mode'):
            try:
                shutil.rmtree('roo_config/default-mode', ignore_errors=True)
                logger.info("Removed roo_config/default-mode directory")
            except Exception as e:
                logger.error(f"Error removing roo_config/default-mode directory: {e}")
    
    # Always set up UV configuration (not just when selected)
    logger.info("\n=== UVX Integration ===")
    if uv_info['any_available']:
        logger.info(f"UV detected on your system! Version: {uv_info['version']}")
        if create_uv_config():
            logger.info("\nUVX configuration has been set up for this project.")
            logger.info("To initialize your UVX environment, run:")
            if platform.system() == 'Windows':
                logger.info("  uv-setup.cmd")
            else:
                logger.info("  ./uv-setup.sh")
        else:
            logger.error("Failed to set up UVX configuration.")
    else:
        logger.warning("UV was not detected on your system.")
        logger.info("To use UV with this project, please install it first:")
        logger.info("  pip install uv")
        logger.info("\nAfter installation, you can set up your UVX environment by running:")
        if platform.system() == 'Windows':
            logger.info("  uv-setup.cmd")
        else:
            logger.info("  ./uv-setup.sh")

    # Final check to ensure .roo directory has system prompt files
    if os.path.exists('.roo'):
        files = os.listdir('.roo')
        if not files:
            logger.warning(".roo directory is empty. Creating default system prompt files...")
            create_default_system_prompts()
    
    logger.info("\nPost-generation hook completed successfully!")

if __name__ == '__main__':
    main()