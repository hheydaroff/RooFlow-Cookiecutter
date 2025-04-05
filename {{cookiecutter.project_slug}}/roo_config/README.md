# RooFlow Configuration Scripts

This directory contains configuration scripts for the RooFlow project.

## Environment Setup Scripts

### Cross-Platform Script (Recommended)

The `insert_variables.py` script is a cross-platform Python script that works on Windows, macOS, and Linux. It replaces the platform-specific scripts (`insert-variables.cmd` and `insert-variables.sh`).

#### Usage

```bash
# On Unix-like systems (macOS, Linux)
./insert_variables.py

# On Windows
python insert_variables.py

# With verbose output (for debugging)
python insert_variables.py --verbose
```

#### Features

- Automatically detects the operating system and adapts accordingly
- Updates system prompt files with local environment details
- Runs `mcp_checker.py` to extract MCP metadata
- Replaces placeholders in system prompt files
- Updates MCP sections with server information
- Handles platform-specific paths and commands

### Legacy Platform-Specific Scripts

These scripts are maintained for backward compatibility but are no longer recommended for use:

- `insert-variables.cmd`: Windows batch script
- `insert-variables.sh`: Unix/Linux/macOS bash script

## MCP Checker Script

The `mcp_checker.py` script connects to MCP (Model Context Protocol) servers defined in the settings file, extracts metadata about their tools and resources, and formats this information as Markdown or JSON.

### Usage

```bash
# With UV (recommended)
uv run --with mcp mcp_checker.py [--settings SETTINGS_PATH] [--output OUTPUT_FILE] [--format {markdown,json}] [--verbose]

# Alternative UV method
uv run mcp_checker.py [--settings SETTINGS_PATH] [--output OUTPUT_FILE] [--format {markdown,json}] [--verbose]

# With traditional Python
python mcp_checker.py [--settings SETTINGS_PATH] [--output OUTPUT_FILE] [--format {markdown,json}] [--verbose]
```

### Arguments

- `--settings`: Path to the MCP settings file (default: platform-specific path)
- `--output`: Output file path (default: mcp_metadata.md)
- `--format`: Output format: markdown or json (default: markdown)
- `--verbose`: Enable verbose output

## Other Configuration Files

- `.rooignore`: Specifies files and directories to be ignored by RooFlow
- `.roomodes`: Configures the available modes in RooFlow using a JSON format with detailed mode information
- `default-mode/`: Contains configuration files for the default mode