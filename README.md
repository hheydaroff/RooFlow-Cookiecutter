# RooFlow Cookiecutter Template

[![Python 3.6+](https://img.shields.io/badge/python-3.6+-blue.svg)](https://www.python.org/downloads/)
[![Cookiecutter](https://img.shields.io/badge/built%20with-Cookiecutter-ff69b4.svg)](https://github.com/cookiecutter/cookiecutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![UV](https://img.shields.io/badge/UV-first-blueviolet.svg)](https://github.com/astral-sh/uv)

A [Cookiecutter](https://github.com/cookiecutter/cookiecutter) template for creating new RooFlow projects with seamless UV integration. RooFlow helps maintain context across AI assistant sessions, making development more efficient and consistent.

## What is RooFlow?

[RooFlow](https://github.com/GreatScottyMac/RooFlow) is a framework that enhances AI-assisted development by maintaining persistent context across sessions. It allows AI assistants to:

- Remember previous conversations and decisions
- Access project-specific knowledge and configurations
- Adapt to different development modes defined in your project
- Orchestrate complex tasks across specialized modes with Captain Roo
- Provide more consistent and relevant assistance

This template provides everything you need to quickly set up a new project with RooFlow integration and modern Python tooling via UV.

## Features
- **UV-first approach** with automatic fallbacks for compatibility
- **Configurable project structure** with RooFlow integration
- **Dynamic mode detection** from your project's .roomodes file
- **System prompts** for all your defined AI assistant modes
- **Captain Roo mode** for orchestrating complex tasks and managing workflows across modes
- **Cross-platform environment setup** with a single Python script
- **MCP metadata extraction** for enhanced AI capabilities
- **Optional default mode configuration** for customized AI assistance
- **Optional memory bank templates** for persistent context
- **Comprehensive documentation** for easy setup and customization
- **Comprehensive documentation** for easy setup and customization

## Requirements

- Python 3.6+
- UV (`pip install uv`) - A modern, fast Python package installer and resolver
- Cookiecutter is automatically installed via UV when using the recommended approach

## Usage

### With UV (recommended)

```bash
# Install UV if you haven't already
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
| `use_uv` | Use UV for Python package management | yes (default)/no |


## Project Structure

The generated project will have this structure:

```
my-rooflow-project/
├── .roo/                  # System prompt files for different modes
├── .rooignore             # Files to ignore in context
├── .roomodes              # Mode configuration (JSON format with detailed mode information)
├── roo_config/            # Configuration files
│   ├── insert_variables.py  # Cross-platform script to set environment variables
│   ├── mcp_checker.py     # Script to extract MCP metadata
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

By default, these UV-related files will be created:

```
my-rooflow-project/
├── .uv/                   # UV configuration directory
│   └── uv.toml            # UV configuration file
├── uv-setup.cmd           # Windows UV setup script
├── uv-setup.sh            # Unix/Mac UV setup script
└── requirements.txt       # Python dependencies file with mcp package
```

## Post-Generation

After generating the project:

1. Navigate to your new project directory
2. Run the cross-platform environment setup script:
   ```
   python roo_config/insert_variables.py
   ```
   
   You can add the `--verbose` flag for more detailed output:
   ```
   python roo_config/insert_variables.py --verbose
   ```

This script will:
- Configure the system prompts with your local environment details
- Install the MCP package if needed (using UV when available)
- Extract MCP metadata from connected servers
- Update system prompt files with the extracted metadata
- Dynamically detect modes from your .roomodes file

The script automatically detects your operating system and sets the appropriate paths, making it work seamlessly across Windows, macOS, and Linux.

### UV Setup

The project is configured to use UV by default. You can set up your environment by running:
- Windows: `uv-setup.cmd`
- Unix/Mac: `./uv-setup.sh`

This will create a virtual environment and install any dependencies listed in `requirements.txt`, including the MCP package required for RooFlow functionality.

## UV Integration Details

This template is designed with a UV-first approach:

- All scripts prioritize using UV when available
- The MCP checker script is optimized to run with UV (`uv run --with mcp`)
- Automatic fallbacks to traditional tools ensure compatibility
- Default configuration files are set up for optimal UV usage
- Requirements are automatically installed via UV when detected

## MCP Integration

The Model Context Protocol (MCP) enables communication with external servers that provide additional tools and resources. This template includes:

- `mcp_checker.py`: A script that connects to MCP servers, extracts metadata about their tools and resources, and formats this information for use in system prompts
- Automatic MCP metadata extraction during setup
- Integration of MCP server information into system prompts
- Support for both local (Stdio-based) and remote (SSE-based) MCP servers

The MCP integration enhances the AI assistant's capabilities by providing access to external tools and resources that can help with specific tasks.

## Mode Configuration and Customization

The template uses a dynamic approach to mode configuration:

1. The `.roomodes` file defines which modes are available in your project using a JSON format with detailed information about each mode
2. System prompt files are automatically generated for each mode defined in `.roomodes`
3. If no `.roomodes` file is found, a minimal set of modes is used (`code` and `ask`)

### Adding New Modes

To add new modes to your project:

1. **Edit the `.roomodes` file** which now uses a JSON format with detailed mode information:
   ```json
   {
     "customModes": [
       {
         "slug": "code",
         "name": "Code",
         "roleDefinition": "You are Roo, a highly skilled software engineer...",
         "groups": [
           "read",
           "edit",
           "browser",
           "command",
           "mcp"
         ],
         "source": "global"
       },
       {
         "slug": "captain-roo",
         "name": "Captain Roo",
         "roleDefinition": "You are Captain Roo, an AI assistant responsible for both setting up the initial Roo Code configuration and orchestrating complex tasks...",
         "groups": [
           "read",
           [
             "edit",
             {
               "fileRegex": "\\.roomodes$|cline_custom_modes\\.json$|\\.clinerules$|\\.rooignore$",
               "description": "Mode configuration files only"
             }
           ],
           "command"
         ]
       },
       {
         "slug": "my-custom-mode",
         "name": "My Custom Mode",
         "roleDefinition": "You are Roo, a specialized assistant that...",
         "groups": [
           "read",
           "edit",
           "browser",
           "command",
           "mcp"
         ]
       }
     ]
   }
   ```

2. **Create a system prompt file** for your new mode:
   - Create a file in the `.roo` directory named `system-prompt-my-custom-mode`
   - Use the template format from existing system prompt files
   - Customize the content for your specific mode's needs

3. **Run the environment setup script** to update all system prompts:
   ```
   python roo_config/insert_variables.py
   ```

### Customizing System Prompts
You can customize the system prompts for any mode by editing the corresponding file in the `.roo` directory. Each system prompt file follows a YAML-like format with sections for system information, rules, and MCP configuration. The environment setup script will automatically update these files with your local environment details and MCP metadata while preserving your customizations.

### Mode Permission Groups

Each mode in the `.roomodes` file can have specific permission groups that control what actions the AI assistant can perform:

- **read**: Allows reading files
- **edit**: Allows editing files (can be restricted to specific file patterns)
- **browser**: Allows browser interactions
- **command**: Allows executing commands
- **mcp**: Allows using MCP tools and resources

Example of restricted edit permissions:
```json
"groups": [
  "read",
  [
    "edit",
    {
      "fileRegex": ".*\\.md$|.*\\.txt$",
      "description": "Documentation files only"
    }
  ],
  "browser",
  "command",
  "mcp"
]

## Captain Roo Mode

The template includes a powerful "Captain Roo" mode that serves as a team lead for your project:

- **Role**: Captain Roo is responsible for both setting up the initial Roo Code configuration (`.rooignore`, `.roomodes`, `.clinerules`) for a project *and* subsequently orchestrating complex tasks by breaking them down and delegating them to specialized modes.

- **Capabilities**:
  - Creates and manages custom modes in the `.roomodes` file
  - Orchestrates workflows across different modes based on task requirements
  - Breaks down complex tasks into smaller, manageable pieces
  - Delegates specific tasks to the most appropriate specialized modes
  - Manages the entire workflow from initial setup through task execution

- **Permissions**: Captain Roo has restricted edit permissions, only allowing modifications to configuration files:
  ```json
  "groups": [
    "read",
    [
      "edit",
      {
        "fileRegex": "\\.roomodes$|cline_custom_modes\\.json$|\\.clinerules$|\\.rooignore$",
        "description": "Mode configuration files only"
      }
    ],
    "command"
  ]
  ```

- **Usage**: When you have a complex task that requires coordination across multiple modes or specialized expertise, switch to Captain Roo mode. It will help organize the work, create any necessary custom modes, and orchestrate the execution of the task across these modes.
```



## License Selection

The template supports multiple license options:

- **MIT**: A permissive license that allows for reuse with few restrictions
- **Apache-2.0**: A permissive license with patent protection provisions
- **GPL-3.0**: A copyleft license that requires derivative works to be open source
- **BSD-3-Clause**: A permissive license with minimal restrictions

When you create a project, you'll be prompted to choose one of these licenses. The appropriate license text will be automatically included in your project's LICENSE file, with your name and the current year inserted in the copyright notice.

## Why UV?

UV is a modern Python packaging tool that offers significant advantages:

- **Speed**: Up to 10-100x faster than pip for package installation
- **Reliability**: Better dependency resolution with fewer conflicts
- **Compatibility**: Works with existing Python packaging standards
- **Modern**: Built with Rust for performance and safety
- **Extensible**: Designed with a modular architecture

All scripts in this template are designed to use UV when available, with fallbacks to traditional tools for compatibility.

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

## Customization

You can customize the generated project by:

1. **Adding or removing modes** by updating the `.roomodes` JSON file (see [Mode Configuration and Customization](#mode-configuration-and-customization))
2. **Customizing system prompts** by editing files in the `.roo/` directory
3. **Controlling context** by modifying the `.rooignore` file to specify which files should be included or excluded
4. **Configuring default mode** by editing files in `roo_config/default-mode/` (if enabled)
5. **Maintaining persistent context** by adding project-specific information to the memory bank
6. **Running the setup script** (`python roo_config/insert_variables.py`) after making changes to update environment variables and MCP metadata

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## Reporting Issues

If you encounter any problems or have suggestions for improvements, please open an issue on the [GitHub repository](https://github.com/hheydaroff/rooflow-cookiecutter/issues).

## License

This cookiecutter template is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.