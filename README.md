# RooFlow Cookiecutter Template

A [Cookiecutter](https://github.com/cookiecutter/cookiecutter) template for creating new RooFlow projects. RooFlow helps maintain context across AI assistant sessions, making development more efficient and consistent.

## Features

- Configurable project structure with RooFlow integration
- System prompts for different AI assistant modes (code, architect, ask, debug, test)
- Environment variable setup scripts for Windows and Unix/Mac
- Optional default mode configuration
- Optional memory bank templates
- UVX integration support for modern Python package management

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
cookiecutter gh:username/rooflow-cookiecutter
# or from local template
cookiecutter path/to/rooflow-cookiecutter
```

### With UVX (recommended)

```bash
# Install UVX if you haven't already
pip install uv

# Install cookiecutter using UVX
uv pip install cookiecutter

# Create a new project from this template
cookiecutter gh:username/rooflow-cookiecutter
# or from local template
cookiecutter path/to/rooflow-cookiecutter
```

## Configuration Options

When you run the template, you'll be prompted for these values:

- `project_name`: Your project name (default: "My RooFlow Project")
- `project_slug`: URL-friendly name, auto-generated from project_name
- `project_description`: A short description of your project
- `author_name`: Your name
- `author_email`: Your email address
- `license`: Choose a license (MIT, Apache-2.0, GPL-3.0, BSD-3-Clause)
- `include_default_mode`: Include default mode configuration (yes/no)
- `include_memory_bank_templates`: Include memory bank templates (yes/no)
- `use_uv`: Use UVX for Python package management (yes/no)

### Benefits of Using UVX

UVX offers several advantages over traditional pip:

1. **Faster Installation**: UVX is significantly faster than pip for package installation and dependency resolution.
2. **Improved Dependency Resolution**: UVX provides more reliable dependency resolution, reducing conflicts.
3. **Isolated Environments**: Better isolation between project environments to prevent package conflicts.
4. **Reproducible Builds**: Enhanced reproducibility for consistent development environments.
5. **Modern Features**: Access to modern Python packaging features and improvements.

## Project Structure

The generated project will have this structure:

```
my-rooflow-project/
├── .roo/                  # System prompt files for different modes
├── .rooignore             # Files to ignore in context
├── .roomodes              # Mode configuration
├── config/                # Configuration files
│   ├── insert-variables.cmd  # Windows script to set environment variables
│   ├── insert-variables.sh   # Unix script to set environment variables
│   └── default-mode/      # Default mode configuration (if enabled)
├── memory-bank/           # Memory bank templates (if enabled)
├── LICENSE                # Project license
└── README.md              # Project README
```

## Post-Generation

After generating the project:

1. Navigate to your new project directory
2. Run the appropriate script to set up your environment:
   - Windows: `config/insert-variables.cmd`
   - Unix/Mac: `config/insert-variables.sh`

This will configure the system prompts with your local environment details.

## Customization

You can customize the generated project by:

1. Editing the system prompt files in `.roo/`
2. Modifying the `.rooignore` file to control what files are included in context
3. Updating the `.roomodes` file to add or remove modes
4. Customizing the default mode configuration in `config/default-mode/`

## License

This cookiecutter template is licensed under the MIT License.