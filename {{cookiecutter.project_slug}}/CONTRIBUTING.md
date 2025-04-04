# Contributing to {{ cookiecutter.project_name }}

Thank you for considering contributing to {{ cookiecutter.project_name }}! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

Please be respectful and considerate of others when contributing to this project. We aim to foster an inclusive and welcoming community.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion for improvement:

1. Check if the issue already exists in the issue tracker
2. If not, create a new issue with a clear description including:
   - Steps to reproduce (for bugs)
   - Expected behavior
   - Actual behavior
   - Screenshots or code examples if applicable

### Submitting Changes

1. Fork the repository
2. Create a new branch for your changes
3. Make your changes
4. Test your changes thoroughly
5. Submit a pull request with a clear description of the changes

### Pull Request Process

1. Update the README.md or documentation with details of changes if needed
2. The pull request will be reviewed by maintainers
3. Once approved, your changes will be merged

## Development Setup

1. Clone the repository
2. Run the appropriate script to set up your environment:
   - Windows: `config/insert-variables.cmd`
   - Unix/Mac: `config/insert-variables.sh`

## Coding Standards

- Follow the existing code style in the project
- Write clear, readable, and maintainable code
- Include comments where necessary
- Write tests for new features

## RooFlow Specific Guidelines

When working with RooFlow:

1. Keep system prompts in the `.roo` directory
2. Update `.rooignore` when adding files that should be excluded from context
3. Document any changes to mode configurations in the `.roomodes` JSON file

Thank you for your contributions!