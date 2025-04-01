#!/usr/bin/env python
import os
import platform
import subprocess
import shutil
import sys

def check_uv_installed():
    """Check if UVX is installed on the system."""
    try:
        subprocess.run(['uv', '--version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return True
    except (FileNotFoundError, subprocess.SubprocessError):
        return False

def create_uv_config():
    """Create UVX configuration files."""
    # Create .uv directory if it doesn't exist
    if not os.path.exists('.uv'):
        os.makedirs('.uv')
        print("Created .uv directory")
    
    # Create uv.toml configuration file
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
""")
    print("Created .uv/uv.toml configuration file")
    
    # Create helper scripts for UVX
    if platform.system() == 'Windows':
        with open('uv-setup.cmd', 'w') as f:
            f.write("""@echo off
echo Setting up UVX environment...
uv venv
uv pip install -r requirements.txt
echo UVX environment setup complete!
""")
        print("Created uv-setup.cmd")
    else:
        with open('uv-setup.sh', 'w') as f:
            f.write("""#!/bin/bash
echo "Setting up UVX environment..."
uv venv
uv pip install -r requirements.txt
echo "UVX environment setup complete!"
""")
        os.chmod('uv-setup.sh', 0o755)
        print("Created uv-setup.sh")
    
    # Create a basic requirements.txt file if it doesn't exist
    if not os.path.exists('requirements.txt'):
        with open('requirements.txt', 'w') as f:
            f.write("""# Project dependencies
# Add your dependencies here
""")
        print("Created requirements.txt")

def main():
    print("Running post-generation hook...")
    
    # Create .roo directory if it doesn't exist
    if not os.path.exists('.roo'):
        os.makedirs('.roo')
        print("Created .roo directory")

    # Move .rooignore and .roomodes to project root
    if os.path.exists('roo_config/.rooignore'):
        shutil.move('roo_config/.rooignore', '.rooignore')
        print("Moved roo_config/.rooignore to .rooignore")
    
    if os.path.exists('roo_config/.roomodes'):
        shutil.move('roo_config/.roomodes', '.roomodes')
        print("Moved roo_config/.roomodes to .roomodes")

    # Run the appropriate insert-variables script
    if platform.system() == 'Windows':
        if os.path.exists('roo_config/insert-variables.cmd'):
            print("Running insert-variables.cmd...")
            subprocess.call(['cmd', '/c', 'roo_config/insert-variables.cmd'])
    else:
        if os.path.exists('roo_config/insert-variables.sh'):
            print("Running insert-variables.sh...")
            os.chmod('roo_config/insert-variables.sh', 0o755)
            subprocess.call(['./roo_config/insert-variables.sh'])

    # Create memory-bank directory and templates if selected
    include_memory_bank = '{{ cookiecutter.include_memory_bank_templates }}' == 'yes'
    if include_memory_bank:
        os.makedirs('memory-bank', exist_ok=True)
        print("Created memory-bank directory")
        
        # Create template files for memory bank
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
        print("Created memory-bank/README.md")

    # Remove default-mode if not selected
    include_default_mode = '{{ cookiecutter.include_default_mode }}' == 'yes'
    if not include_default_mode:
        if os.path.exists('roo_config/default-mode'):
            shutil.rmtree('roo_config/default-mode', ignore_errors=True)
            print("Removed roo_config/default-mode directory")
    
    # Handle UVX integration if selected
    use_uv = '{{ cookiecutter.use_uv }}' == 'yes'
    if use_uv:
        print("\n=== UVX Integration ===")
        if check_uv_installed():
            print("UVX detected on your system!")
            create_uv_config()
            print("\nUVX configuration has been set up for this project.")
            print("To initialize your UVX environment, run:")
            if platform.system() == 'Windows':
                print("  uv-setup.cmd")
            else:
                print("  ./uv-setup.sh")
        else:
            print("UVX was not detected on your system.")
            print("To use UVX with this project, please install it first:")
            print("  pip install uv")
            print("\nAfter installation, you can set up your UVX environment by running:")
            if platform.system() == 'Windows':
                print("  uv-setup.cmd")
            else:
                print("  ./uv-setup.sh")

    print("\nPost-generation hook completed successfully!")

if __name__ == '__main__':
    main()