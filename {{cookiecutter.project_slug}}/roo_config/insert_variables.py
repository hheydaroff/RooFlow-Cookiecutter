#!/usr/bin/env python3
"""
RooFlow Environment Setup Script (Cross-Platform)

This script updates system prompt files with local environment details and MCP metadata.
It replaces both insert-variables.cmd (Windows) and insert-variables.sh (Unix/Linux/macOS)
with a single cross-platform solution.

Usage:
    python insert_variables.py [--verbose]

Arguments:
    --verbose       Enable verbose output

Dependencies:
    - Python 3.6+
    - mcp (for MCP metadata extraction)
"""

import os
import sys
import json
import shutil
import argparse
import platform
import subprocess
import tempfile
import logging
from pathlib import Path
import re


def setup_logging(verbose=False):
    """Configure logging based on verbosity level."""
    log_level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format='%(levelname)s: %(message)s'
    )


def get_script_dir():
    """Get the directory where this script is located."""
    return Path(os.path.dirname(os.path.abspath(__file__)))


def get_project_root(script_dir):
    """Get the project root directory."""
    return script_dir.parent


def get_system_info():
    """Get system information based on the current platform."""
    system_info = {
        "os": "",
        "shell": "",
        "home_dir": "",
        "workspace_dir": "",
        "global_settings": "",
        "mcp_location": "",
        "mcp_settings": ""
    }
    
    # Get OS information
    if platform.system() == "Windows":
        system_info["os"] = f"Windows {platform.release()} {platform.version()}"
    elif platform.system() == "Darwin":
        system_info["os"] = f"macOS {platform.mac_ver()[0]}"
    else:
        system_info["os"] = f"{platform.system()} {platform.release()}"
    
    # Get shell information
    if "SHELL" in os.environ:
        system_info["shell"] = os.path.basename(os.environ["SHELL"])
    elif platform.system() == "Windows":
        system_info["shell"] = os.path.basename(os.environ.get("COMSPEC", "cmd.exe"))
    else:
        system_info["shell"] = "bash"  # Default fallback
    
    # Get home directory
    system_info["home_dir"] = str(Path.home())
    
    # Get workspace directory (project root)
    script_dir = get_script_dir()
    project_root = get_project_root(script_dir)
    system_info["workspace_dir"] = str(project_root)
    
    # Platform-specific paths
    if platform.system() == "Windows":
        # Windows paths
        system_info["global_settings"] = str(Path(system_info["home_dir"]) / "AppData" / "Roaming" / "Code" / "User" / "globalStorage" / "rooveterinaryinc.roo-cline" / "settings" / "cline_custom_modes.json")
        system_info["mcp_location"] = str(Path(system_info["home_dir"]) / ".local" / "share" / "Roo-Code" / "MCP")
        system_info["mcp_settings"] = str(Path(system_info["home_dir"]) / "AppData" / "Roaming" / "Code" / "User" / "globalStorage" / "rooveterinaryinc.roo-cline" / "settings" / "cline_mcp_settings.json")
    elif platform.system() == "Darwin":
        # macOS paths
        system_info["global_settings"] = str(Path(system_info["home_dir"]) / "Library" / "Application Support" / "Code" / "User" / "globalStorage" / "rooveterinaryinc.roo-cline" / "settings" / "cline_custom_modes.json")
        system_info["mcp_location"] = str(Path(system_info["home_dir"]) / ".local" / "share" / "Roo-Code" / "MCP")
        system_info["mcp_settings"] = str(Path(system_info["home_dir"]) / "Library" / "Application Support" / "Code" / "User" / "globalStorage" / "rooveterinaryinc.roo-cline" / "settings" / "cline_mcp_settings.json")
    else:
        # Linux paths
        system_info["global_settings"] = str(Path(system_info["home_dir"]) / ".config" / "Code" / "User" / "globalStorage" / "rooveterinaryinc.roo-cline" / "settings" / "cline_custom_modes.json")
        system_info["mcp_location"] = str(Path(system_info["home_dir"]) / ".local" / "share" / "Roo-Code" / "MCP")
        system_info["mcp_settings"] = str(Path(system_info["home_dir"]) / ".config" / "Code" / "User" / "globalStorage" / "rooveterinaryinc.roo-cline" / "settings" / "cline_mcp_settings.json")
    
    return system_info


def check_dependencies():
    """Check for required dependencies and install them if needed."""
    logging.info("Checking dependencies...")
    
    # Check for UV first (preferred)
    uv_available = False
    try:
        subprocess.run(["uv", "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        logging.info("UV detected! Using UV for package management.")
        uv_available = True
        
        # Check for mcp package with UV
        result = subprocess.run(["uv", "pip", "list"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if "mcp" not in result.stdout:
            logging.info("Installing mcp package using UV...")
            subprocess.run(["uv", "pip", "install", "mcp"], check=True)
            
            # Verify installation
            result = subprocess.run(["uv", "pip", "list"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            if "mcp" not in result.stdout:
                logging.error("Failed to install mcp package with UV.")
                uv_available = False
            else:
                logging.info("Successfully installed mcp package with UV.")
                return True
        else:
            logging.info("MCP package already installed with UV.")
            return True
    except (subprocess.SubprocessError, FileNotFoundError):
        logging.info("UV not detected. Checking for traditional Python tools...")
        uv_available = False
    
    # Check for Python if UV is not available
    python_cmd = None
    for cmd in ["python3", "python"]:
        try:
            result = subprocess.run([cmd, "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if result.returncode == 0:
                python_cmd = cmd
                logging.info(f"Using Python command: {python_cmd}")
                break
        except (subprocess.SubprocessError, FileNotFoundError):
            continue
    
    if not python_cmd:
        logging.error("Error: Python is required but not installed.")
        logging.error("Please install Python 3.x to continue.")
        return False
    
    # Check Python version
    try:
        version_check = subprocess.run(
            [python_cmd, "-c", "import sys; sys.exit(0 if sys.version_info.major >= 3 else 1)"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        if version_check.returncode != 0:
            logging.warning("Warning: Python 3.x is recommended. You may encounter issues with older versions.")
    except subprocess.SubprocessError:
        logging.warning("Warning: Could not verify Python version.")
    
    # Check for mcp package
    try:
        import_check = subprocess.run(
            [python_cmd, "-c", "import mcp"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        if import_check.returncode != 0:
            logging.warning("Warning: 'mcp' package is not installed. Will attempt to install it.")
            
            # Try with pip
            for pip_cmd in ["pip3", "pip", f"{python_cmd} -m pip"]:
                try:
                    if " " in pip_cmd:
                        # Handle commands with arguments
                        cmd_parts = pip_cmd.split()
                        cmd_parts.extend(["install", "mcp"])
                        subprocess.run(cmd_parts, check=True)
                    else:
                        subprocess.run([pip_cmd, "install", "mcp"], check=True)
                    
                    # Verify installation
                    import_check = subprocess.run(
                        [python_cmd, "-c", "import mcp"],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE
                    )
                    if import_check.returncode == 0:
                        logging.info("Successfully installed mcp package.")
                        return True
                    
                except (subprocess.SubprocessError, FileNotFoundError):
                    continue
            
            logging.error("Error: Failed to install mcp package.")
            logging.error("Please install it manually: pip install mcp")
            return False
    except subprocess.SubprocessError:
        logging.error("Error: Failed to check for mcp package.")
        return False
    
    return True


def run_mcp_checker(script_path, output_file, error_log):
    """Run the MCP checker script to extract MCP metadata."""
    logging.info("Running MCP Checker to extract MCP metadata...")
    
    # Try with UV first (preferred method)
    try:
        subprocess.run(["uv", "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        logging.info("Using UV to run MCP checker...")
        
        # Try different UV execution methods
        try:
            subprocess.run(
                ["uv", "run", "--with", "mcp", str(script_path), "--output", str(output_file)],
                stdout=subprocess.PIPE, stderr=open(error_log, "w"),
                check=True
            )
            logging.info("Successfully ran MCP checker with UV.")
            return True
        except subprocess.SubprocessError:
            logging.info("Trying alternative UV execution method...")
            try:
                subprocess.run(
                    ["uv", "run", str(script_path), "--output", str(output_file)],
                    stdout=subprocess.PIPE, stderr=open(error_log, "a"),
                    check=True
                )
                logging.info("Successfully ran MCP checker with alternative UV method.")
                return True
            except subprocess.SubprocessError:
                logging.warning("Warning: Failed to run MCP checker with UV. Falling back to direct Python execution.")
    except (subprocess.SubprocessError, FileNotFoundError):
        logging.info("UV not available. Using direct Python execution...")
    
    # Fallback to direct Python execution
    for python_cmd in ["python3", "python"]:
        try:
            subprocess.run(
                [python_cmd, str(script_path), "--output", str(output_file)],
                stdout=subprocess.PIPE, stderr=open(error_log, "a"),
                check=True
            )
            logging.info(f"Successfully ran MCP checker with {python_cmd}.")
            return True
        except (subprocess.SubprocessError, FileNotFoundError):
            continue
    
    # If we got here, all methods failed
    logging.error("Error: Failed to run MCP checker with all available methods.")
    logging.error(f"Check {error_log} for details.")
    return False


def replace_placeholders(file_path, replacements):
    """Replace placeholders in a file with actual values."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        # Perform all replacements
        for placeholder, value in replacements.items():
            content = content.replace(placeholder, value)
        
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(content)
        
        return True
    except Exception as e:
        logging.error(f"Error replacing placeholders in {file_path}: {e}")
        return False


def update_mcp_section(file_path, mcp_metadata):
    """Update the MCP section in a system prompt file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
        
        # Define the formatted MCP section
        formatted_mcp = """mcp:
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
        
        # Process the file content
        new_content = []
        in_mcp = False
        in_connected_servers = False
        
        for line in lines:
            if line.startswith('mcp:'):
                in_mcp = True
                new_content.append(line)
            elif in_mcp and line.strip().startswith('connected_servers:'):
                in_connected_servers = True
                new_content.append(line)
                # Add the MCP metadata with proper indentation
                for metadata_line in mcp_metadata.splitlines():
                    new_content.append(f"    {metadata_line}\n")
            elif in_mcp and re.match(r'^[a-z]', line):
                in_mcp = False
                in_connected_servers = False
                new_content.append(line)
            elif in_connected_servers and line.strip().startswith('-'):
                # Skip existing connected_servers content
                pass
            elif in_connected_servers and re.match(r'^  [a-z]', line):
                in_connected_servers = False
                new_content.append(line)
            else:
                new_content.append(line)
        
        # If no MCP section was found, append it
        if not in_mcp:
            new_content.append("\n")  # Add a blank line for separation
            new_content.append(formatted_mcp)
            # Add the MCP metadata with proper indentation
            for metadata_line in mcp_metadata.splitlines():
                new_content.append(f"    {metadata_line}\n")
        
        # Write the updated content back to the file
        with open(file_path, 'w', encoding='utf-8') as file:
            file.writelines(new_content)
        
        return True
    except Exception as e:
        logging.error(f"Error updating MCP section in {file_path}: {e}")
        return False


def process_system_prompt_files(roo_dir, config_dir, system_info, mcp_metadata):
    """Process system prompt files by replacing placeholders and updating MCP sections."""
    logging.info("Looking for system prompt files...")
    
    # Define the replacements dictionary
    replacements = {
        "OS_PLACEHOLDER": system_info["os"],
        "SHELL_PLACEHOLDER": system_info["shell"],
        "HOME_PLACEHOLDER": system_info["home_dir"],
        "WORKSPACE_PLACEHOLDER": system_info["workspace_dir"],
        "GLOBAL_SETTINGS_PLACEHOLDER": system_info["global_settings"],
        "MCP_LOCATION_PLACEHOLDER": system_info["mcp_location"],
        "MCP_SETTINGS_PLACEHOLDER": system_info["mcp_settings"]
    }
    
    # Check for system prompt files in the project's roo_config/.roo directory
    prompt_files_dir = config_dir / ".roo"
    
    if prompt_files_dir.exists() and any(prompt_files_dir.iterdir()):
        logging.info(f"Found system prompt files in {prompt_files_dir}")
        
        # Copy files from found location to .roo
        for file_path in prompt_files_dir.glob("*"):
            dest_path = roo_dir / file_path.name
            shutil.copy2(file_path, dest_path)
            logging.info(f"Copied {file_path.name} to {dest_path}")
            
            # Replace placeholders
            if replace_placeholders(dest_path, replacements):
                logging.info(f"Replaced placeholders in {dest_path}")
            
            # Update MCP section
            if mcp_metadata and update_mcp_section(dest_path, mcp_metadata):
                logging.info(f"Updated MCP section in {dest_path}")
            
            logging.info(f"Completed: {dest_path}")
    else:
        logging.info(f"No system prompt files found in {prompt_files_dir}")
        
        # List directories to help debug
        logging.info("Current directory structure:")
        for path in [roo_dir, config_dir]:
            if path.exists():
                logging.info(f"- {path}")
        
        # Check for default template in the project
        default_template = None
        possible_templates = [
            Path(system_info["workspace_dir"]) / "default-system-prompt.md",
            config_dir / "default-system-prompt.md"
        ]
        
        for template_path in possible_templates:
            if template_path.exists():
                default_template = template_path
                logging.info(f"Found default template at {default_template}")
                break
        
        if default_template:
            # Define the list of supported modes
            supported_modes = []
            
            # Try to read modes from .roomodes file if it exists
            roomodes_path = Path(system_info["workspace_dir"]) / ".roomodes"
            if roomodes_path.exists():
                try:
                    with open(roomodes_path, 'r', encoding='utf-8') as f:
                        try:
                            # Try to parse as JSON first (new format)
                            roomodes_data = json.load(f)
                            if "customModes" in roomodes_data:
                                for mode in roomodes_data["customModes"]:
                                    if "slug" in mode:
                                        supported_modes.append(mode["slug"])
                            logging.info(f"Read {len(supported_modes)} modes from .roomodes JSON file")
                        except json.JSONDecodeError:
                            # Fallback to old format (one mode per line)
                            f.seek(0)  # Reset file pointer to beginning
                            for line in f:
                                mode = line.strip()
                                if mode and not mode.startswith('#'):
                                    supported_modes.append(mode)
                            logging.info(f"Read {len(supported_modes)} modes from .roomodes text file")
                except Exception as e:
                    logging.warning(f"Error reading .roomodes file: {e}")
            
            # If no modes found in .roomodes, use default set
            if not supported_modes:
                logging.info("No modes found in .roomodes file, using default set")
                # Read from default modes file or use a minimal set
                supported_modes = ["code", "ask", "architect", "debug"]  # Minimal default set
                
            # Create system prompt files for each mode
            for mode in supported_modes:
                output_file = roo_dir / f"system-prompt-{mode}"
                
                # Copy the template
                shutil.copy2(default_template, output_file)
                
                # Replace placeholders
                if replace_placeholders(output_file, replacements):
                    logging.info(f"Replaced placeholders in {output_file}")
                
                # Update MCP section
                if mcp_metadata and update_mcp_section(output_file, mcp_metadata):
                    logging.info(f"Updated MCP section in {output_file}")
                
                logging.info(f"Created {output_file}")
        else:
            logging.warning("No default system prompt template found.")
            logging.warning("Please create system prompt files manually or provide a default template.")


def main():
    """Main entry point for the script."""
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='RooFlow Environment Setup Script (Cross-Platform)')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose output')
    args = parser.parse_args()
    
    # Setup logging
    setup_logging(args.verbose)
    
    # Print header
    print("RooFlow Environment Setup Script (Cross-Platform)")
    print("==============================================")
    print()
    print("This script will update system prompt files with your local environment details and MCP metadata.")
    print()
    
    # Determine script location and project root
    script_dir = get_script_dir()
    project_root = get_project_root(script_dir)
    config_dir = script_dir
    
    print(f"Script directory: {script_dir}")
    print(f"- Project Root: {project_root}")
    print(f"- Config Directory: {config_dir}")
    
    # Get system information
    system_info = get_system_info()
    
    print("Detected Environment:")
    print(f"- OS: {system_info['os']}")
    print(f"- Shell: {system_info['shell']}")
    print(f"- Home Directory: {system_info['home_dir']}")
    print(f"- Workspace Directory: {system_info['workspace_dir']}")
    print()
    
    # Directory setup
    roo_dir = Path(system_info["workspace_dir"]) / ".roo"
    
    # Create .roo directory if it doesn't exist
    if not roo_dir.exists():
        roo_dir.mkdir(parents=True)
        print(f"Created .roo directory at {roo_dir}")
    
    # Check dependencies
    if not check_dependencies():
        logging.warning("Warning: Dependency check failed. Some features may not work correctly.")
    
    # Set up paths for MCP checker
    mcp_checker_script = config_dir / "mcp_checker.py"
    
    # Use tempfile module for cross-platform temporary files
    with tempfile.NamedTemporaryFile(suffix='.md', delete=False) as temp_output_file, \
         tempfile.NamedTemporaryFile(suffix='.log', delete=False) as temp_error_log:
        
        mcp_output_file = Path(temp_output_file.name)
        mcp_error_log = Path(temp_error_log.name)
    
    # Run MCP checker
    mcp_metadata = None
    if run_mcp_checker(mcp_checker_script, mcp_output_file, mcp_error_log):
        print(f"MCP metadata extracted successfully and saved to {mcp_output_file}")
        
        # Display file size and first few lines
        file_size = os.path.getsize(mcp_output_file)
        print(f"File size: {file_size} bytes")
        
        print("First few lines of MCP metadata:")
        with open(mcp_output_file, 'r', encoding='utf-8') as f:
            for i, line in enumerate(f):
                if i >= 5:
                    break
                print(line.rstrip())
        
        # Store the content in a variable for later use
        with open(mcp_output_file, 'r', encoding='utf-8') as f:
            mcp_metadata = f.read()
    else:
        print(f"Warning: Failed to extract MCP metadata. Check {mcp_error_log} for details.")
        print("The script will continue, but MCP metadata may not be updated.")
        mcp_metadata = "No MCP metadata available"
    
    # Process system prompt files
    process_system_prompt_files(roo_dir, config_dir, system_info, mcp_metadata)
    
    # Clean up temporary files
    try:
        os.unlink(mcp_output_file)
        os.unlink(mcp_error_log)
    except (OSError, FileNotFoundError):
        pass
    
    print()
    print("Setup complete!")
    print("You can now use RooFlow with your local environment settings and updated MCP metadata.")
    print()


if __name__ == "__main__":
    main()