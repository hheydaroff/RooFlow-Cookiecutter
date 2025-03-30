# {{ cookiecutter.project_name }}

{{ cookiecutter.project_description }}

## Overview

This project uses RooFlow for persistent project context and optimized mode interactions. RooFlow helps maintain context across AI assistant sessions, making development more efficient and consistent.

## Getting Started

### Prerequisites

- Python 3.6+
- Git
{% if cookiecutter.use_uv == 'yes' %}
- UVX (`pip install uv`) - A modern Python package installer and resolver
{% endif %}

### Setup

1. Clone this repository
2. Run the appropriate script to set up your environment:
   - Windows: `config/insert-variables.cmd`
   - Unix/Mac: `config/insert-variables.sh`

This will configure the system prompts with your local environment details.

{% if cookiecutter.use_uv == 'yes' %}
### UVX Setup

This project is configured to use UVX for Python package management. UVX offers faster installation, improved dependency resolution, and better isolation between project environments.

To set up your UVX environment:

1. Install UVX if you haven't already:
   ```bash
   pip install uv
   ```

2. Run the UVX setup script:
   - Windows: `uv-setup.cmd`
   - Unix/Mac: `./uv-setup.sh`

This will create a virtual environment and install the required dependencies.

#### UVX Commands

- Create a virtual environment: `uv venv`
- Install packages: `uv pip install <package>`
- Install from requirements.txt: `uv pip install -r requirements.txt`
- Run Python with the virtual environment: `uv run python <script.py>`
- Activate the virtual environment:
  - Windows: `.venv\Scripts\activate`
  - Unix/Mac: `source .venv/bin/activate`
{% endif %}

## Project Structure

```
{{ cookiecutter.project_slug }}/
├── .roo/                  # System prompt files for different modes
├── .rooignore             # Files to ignore in context
├── .roomodes              # Mode configuration
├── config/                # Configuration files
│   ├── insert-variables.cmd  # Windows script to set environment variables
│   ├── insert-variables.sh   # Unix script to set environment variables
│   └── default-mode/      # Default mode configuration (if enabled)
{% if cookiecutter.include_memory_bank_templates == 'yes' %}
├── memory-bank/           # Memory bank templates for persistent context
{% endif %}
{% if cookiecutter.use_uv == 'yes' %}
├── .uv/                   # UVX configuration directory
├── .venv/                 # Virtual environment (created by UVX)
├── requirements.txt       # Project dependencies
├── uv-setup.cmd           # Windows UVX setup script
├── uv-setup.sh            # Unix/Mac UVX setup script
{% endif %}
├── LICENSE                # Project license
└── README.md              # This file
```

## Usage

When working with this project using AI assistants like Claude, the assistant will have access to the project context defined in the system prompts and memory bank.

## License

This project is licensed under the {{ cookiecutter.license }} License - see the LICENSE file for details.

## Author

{{ cookiecutter.author_name }} <{{ cookiecutter.author_email }}>