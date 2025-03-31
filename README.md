# RooFlow Cookiecutter Template

<div align="center">

[![Python 3.6+](https://img.shields.io/badge/python-3.6+-blue.svg)](https://www.python.org/downloads/)
[![Cookiecutter](https://img.shields.io/badge/built%20with-Cookiecutter-ff69b4.svg)](https://github.com/cookiecutter/cookiecutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/hheydaroff/rooflow-cookiecutter/pulls)
[![UVX Compatible](https://img.shields.io/badge/UVX-compatible-blueviolet)](https://github.com/astral-sh/uv)

</div>

A [Cookiecutter](https://github.com/cookiecutter/cookiecutter) template for creating new RooFlow projects. RooFlow helps maintain context across AI assistant sessions, making development more efficient and consistent.

## Table of Contents

- [What is RooFlow?](#what-is-rooflow)
- [Features](#features)
- [Quick Start](#quick-start)
- [Requirements](#requirements)
- [Usage](#usage)
- [Configuration Options](#configuration-options)
- [Project Structure](#project-structure)
- [Post-Generation](#post-generation)
- [RooFlow Modes](#rooflow-modes)
  - [Adding or Updating Modes](#adding-or-updating-modes)
- [Default Mode Configuration](#default-mode-configuration)
- [Memory Bank Templates](#memory-bank-templates)
- [Advanced Customization](#advanced-customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Reporting Issues](#reporting-issues)
- [License](#license)

## What is RooFlow?

[RooFlow](https://github.com/GreatScottyMac/RooFlow) is a framework that enhances AI-assisted development by maintaining persistent context across sessions. It allows AI assistants to:

- Remember previous conversations and decisions
- Access project-specific knowledge and configurations
- Adapt to different development modes (coding, architecture planning, debugging, etc.)
- Provide more consistent and relevant assistance

This template provides everything you need to quickly set up a new project with RooFlow integration.

## Features

- **Configurable project structure** with RooFlow integration
- **System prompts** for different AI assistant modes (code, architect, ask, debug, test, and more)
- **Environment variable setup scripts** for Windows and Unix/Mac
- **Optional default mode configuration** for customized AI assistance
- **Optional memory bank templates** for persistent context
- **UVX integration support** for modern Python package management
- **Comprehensive documentation** for easy setup and customization

## Quick Start

```bash
# Install cookiecutter
pip install cookiecutter

# Create a new project
cookiecutter gh:hheydaroff/rooflow-cookiecutter

# Follow the prompts to configure your project
```

## Requirements

- Python 3.6+
- Cookiecutter (`pip install cookiecutter` or `uv pip install cookiecutter`)
- Optional: UVX (`pip install uv`) - A modern Python package installer and resolver

## Usage

### With pip (traditional)

```bash
# Install cookiecutter if you haven't already
pip install cookiecutter

# Create a new project from this template
cookiecutter gh:hheydaroff/rooflow-cookiecutter
# or from local template
cookiecutter path/to/rooflow-cookiecutter
```

### With UVX (recommended)

```bash
# Install UVX if you haven't already
pip install uv

# Create a new project from this template
uvx cookiecutter gh:hheydaroff/rooflow-cookiecutter
# or from local template
uvx cookiecutter path/to/rooflow-cookiecutter
```

## Configuration Options

When you run the template, you'll be prompted for these values:

| Option | Description | Default |
|--------|-------------|---------|
| `project_name` | Your project name | "My RooFlow Project" |
| `project_slug` | URL-friendly name | Auto-generated from project_name |
| `project_description` | A short description | "A project using RooFlow for persistent context and optimized AI-assisted development" |
| `author_name` | Your name | "Your Name" |
| `author_email` | Your email address | "your.email@example.com" |
| `license` | Choose a license | MIT, Apache-2.0, GPL-3.0, BSD-3-Clause |
| `include_default_mode` | Include default mode configuration | yes/no |
| `include_memory_bank_templates` | Include memory bank templates | yes/no |
| `use_uv` | Use UVX for Python package management | yes/no |


## Project Structure

The generated project will have this structure:

```
my-rooflow-project/
├── .rooignore             # Files to ignore in context
├── .roomodes              # Mode configuration
├── roo_config/            # Configuration files
│   ├── insert-variables.cmd  # Windows script to set environment variables
│   ├── insert-variables.sh   # Unix script to set environment variables
│   └── default-mode/      # Default mode configuration (if enabled)
│       ├── cline_custom_modes.json  # Custom modes configuration
│       ├── custom-instructions.yaml # Custom instructions
│       ├── README.md      # Documentation for default mode
│       └── role-definition.txt      # Role definition for default mode
├── memory-bank/           # Memory bank templates (if enabled)
│   └── README.md          # Documentation for memory bank
├── LICENSE                # Project license
├── CONTRIBUTING.md        # Contribution guidelines
└── README.md              # Project README
```

If you select UVX integration, these additional files will be created:

```
my-rooflow-project/
├── .uv/                   # UVX configuration directory
│   └── uv.toml            # UVX configuration file
├── uv-setup.cmd           # Windows UVX setup script
├── uv-setup.sh            # Unix/Mac UVX setup script
└── requirements.txt       # Python dependencies file
```

## Post-Generation

After generating the project:

1. Navigate to your new project directory
2. Run the appropriate script to set up your environment:
   - Windows: `roo_config/insert-variables.cmd`
   - Unix/Mac: `roo_config/insert-variables.sh`

This will configure the system prompts with your local environment details.

### UVX Setup (if selected)

If you chose to use UVX, you can set up your environment by running:
- Windows: `uv-setup.cmd`
- Unix/Mac: `./uv-setup.sh`

This will create a virtual environment and install any dependencies listed in `requirements.txt`.

## RooFlow Modes

RooFlow provides specialized modes for different development tasks. Each mode has a specific role and capabilities:

| Mode | Description | Capabilities |
|------|-------------|--------------|
| **Code** | Handles code creation and modification | Read, edit, execute commands, use MCP servers, browser |
| **Architect** | Focuses on system design and project organization | Read, edit, execute commands, use MCP servers |
| **Ask** | Answers questions and provides information | Read, execute commands, use MCP servers |
| **Debug** | Diagnoses and resolves problems | Read, execute commands, use MCP servers, browser |
| **Advanced Orchestrator** | Coordinates complex tasks across modes | Read, edit, execute commands, use MCP servers |
| **VibeMode** | Transforms natural language into code | Read, edit, execute commands, use MCP servers, browser |
| **Test** | Handles test-driven development and QA | Read, execute commands, use MCP servers, browser |

These modes are configured in the `.roomodes` file and can be customized to fit your project's needs.

### Adding or Updating Modes

To add or update RooFlow modes in your project, you need to modify two key components:

#### 1. Update the `.roomodes` file

The `.roomodes` file contains JSON configuration for all available modes. To add a new mode, add an entry like this:

```json
{
  "slug": "test",
  "name": "Test",
  "roleDefinition": "You are Roo, responsible for test-driven development, test execution, and quality assurance. You write test cases, validate code, analyze results, and coordinate with other modes to ensure software quality.",
  "groups": [
    "read",
    "command",
    "mcp",
    "browser"
  ],
  "source": "project"
}
```

Key components:
- `slug`: Unique identifier for the mode (used in file names and URLs)
- `name`: Display name for the mode
- `roleDefinition`: Description of the mode's role and responsibilities
- `groups`: Capabilities granted to this mode (read, edit, command, mcp, browser)
- `source`: Where the mode is defined (usually "project")

#### 2. Create a `.clinerules-[mode-slug]` file

For each mode, create a file named `.clinerules-[mode-slug]` (replacing `[mode-slug]` with your mode's slug) containing custom instructions for that mode. For example:

```
# .clinerules-test

You are a test specialist focused on ensuring code quality through comprehensive testing.

## Testing Approach
- Prioritize test-driven development
- Create unit, integration, and end-to-end tests
- Focus on edge cases and error handling
- Ensure good test coverage

## Best Practices
- Write clear test descriptions
- Use appropriate testing frameworks
- Separate test fixtures from test logic
- Mock external dependencies
```

This file defines the specific instructions and guidelines for the AI assistant when operating in this mode.

## Default Mode Configuration

If you selected to include default mode configuration, your project will include a `roo_config/default-mode` directory with:

- `cline_custom_modes.json`: Configuration for custom AI assistant modes
- `custom-instructions.yaml`: Custom instructions for the AI assistant
- `role-definition.txt`: Role definition for the default mode
- `README.md`: Documentation for the default mode configuration

These files allow you to customize how the AI assistant behaves when working with your project.

## Memory Bank Templates

If you selected to include memory bank templates, your project will include a `memory-bank` directory. The memory bank is a feature that allows you to store and retrieve information across AI assistant sessions, helping maintain context and knowledge about your project over time.

To use the memory bank:
1. Add files to the `memory-bank` directory containing important project information
2. These files will be loaded into the AI's context when you start a new session

Examples of information to store in the memory bank:
- Project architecture overview
- Design decisions and rationales
- Coding standards and conventions
- Common troubleshooting steps
- Frequently used commands

## Advanced Customization

### Adding Custom Modes

To add a custom mode:

1. Update the `.roomodes` file with your new mode configuration
2. Create a `.clinerules-[mode-slug]` file with custom instructions for the mode
3. If using default mode, update the `cline_custom_modes.json` file

### Extending the Memory Bank

The memory bank can be extended with additional files and directories to organize project knowledge. Consider creating subdirectories for different aspects of your project:

- `memory-bank/architecture/`
- `memory-bank/decisions/`
- `memory-bank/standards/`

### Customizing UVX Configuration

If you're using UVX, you can customize the configuration by editing the `.uv/uv.toml` file. This allows you to change Python versions, virtual environment locations, and other UVX settings.

## Troubleshooting

### Common Issues

#### Environment Variables Not Set

If the environment variables are not being set correctly:

1. Check that you've run the appropriate script for your operating system
2. Verify that the script has execution permissions (Unix/Mac)
3. Try running the script with administrator privileges

#### UVX Not Found

If you get a "UVX not found" error:

1. Ensure UVX is installed: `pip install uv`
2. Verify that UVX is in your system PATH
3. Try using the full path to the UVX executable

#### Cookiecutter Template Not Found

If Cookiecutter can't find the template:

1. Check your internet connection
2. Verify the repository URL
3. Try using the HTTPS URL instead of the SSH URL

### Getting Help

If you encounter issues not covered here, please:

1. Check the [GitHub Issues](https://github.com/hheydaroff/rooflow-cookiecutter/issues) for similar problems
2. Search the [RooFlow documentation](https://github.com/GreatScottyMac/RooFlow) for more information
3. Open a new issue with detailed information about your problem

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## Reporting Issues

If you encounter any problems or have suggestions for improvements, please open an issue on the [GitHub repository](https://github.com/hheydaroff/rooflow-cookiecutter/issues).

## License

This cookiecutter template is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.