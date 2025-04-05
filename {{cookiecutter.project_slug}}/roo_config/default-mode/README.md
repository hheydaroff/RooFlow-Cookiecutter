# Default Mode Configuration

This directory contains configuration files for a custom default mode in RooFlow.

## Files

- `role-definition.txt`: Defines the role and capabilities of the default mode
- `custom-instructions.yaml`: Contains custom instructions for the default mode
- `cline_custom_modes.json`: Configuration for custom modes in Cline

## Usage

To use the default mode:

1. Make sure the `.roomodes` JSON file in the project root includes this mode in its `customModes` array
2. Customize the role definition and instructions as needed
3. Run the `insert_variables.py` script to update environment variables (or use the platform-specific scripts `insert-variables.cmd` or `insert-variables.sh` for backward compatibility)

## Customization

You can customize the default mode by editing the files in this directory. The role definition should describe the primary purpose and capabilities of the mode, while the custom instructions should provide specific guidance on how the mode should operate.

For more information about the environment setup scripts, see the README.md in the parent directory.