# Default Mode Configuration

This directory contains configuration files for a custom default mode in RooFlow.

## Files

- `role-definition.txt`: Defines the role and capabilities of the default mode
- `custom-instructions.yaml`: Contains custom instructions for the default mode
- `cline_custom_modes.json`: Configuration for custom modes in Cline

## Usage

To use the default mode:

1. Make sure the `.roomodes` file in the project root includes a reference to this mode
2. Customize the role definition and instructions as needed
3. Run the appropriate insert-variables script to update environment variables

## Customization

You can customize the default mode by editing the files in this directory. The role definition should describe the primary purpose and capabilities of the mode, while the custom instructions should provide specific guidance on how the mode should operate.