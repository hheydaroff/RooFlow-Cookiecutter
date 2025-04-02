#!/usr/bin/env bash

echo "RooFlow Environment Setup Script (Unix/Mac)"
echo "=========================================="
echo

echo "This script will update system prompt files with your local environment details and MCP section with connected servers."
echo

# --- Determine script location and project root ---
# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script directory: $SCRIPT_DIR"

# Determine project root and config directory
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$SCRIPT_DIR"

echo "- Project Root: $PROJECT_ROOT"
echo "- Config Directory: $CONFIG_DIR"

# --- Get Environment Variables Correctly ---
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS specific
    OS="macOS $(sw_vers -productVersion)"
    SED_IN_PLACE=(-i "")
else
    # Linux specific
    OS=$(uname -s -r)
    SED_IN_PLACE=(-i)
fi

# Get the current shell name (basename extracts just the shell name from the path)
SHELL=$(basename "$SHELL" 2>/dev/null || echo "bash")  # Fallback to bash if detection fails
HOME=$(echo "$HOME")  # Use existing $HOME, but quote it
WORKSPACE="$PROJECT_ROOT"

# --- Construct Paths ---
GLOBAL_SETTINGS="$HOME/.vscode-server/data/User/globalStorage/rooveterinaryinc.roo-cline/settings/cline_custom_modes.json"
MCP_LOCATION="$HOME/.local/share/Roo-Code/MCP"
MCP_SETTINGS="$HOME/.vscode-server/data/User/globalStorage/rooveterinaryinc.roo-cline/settings/cline_mcp_settings.json"

echo "Detected Environment:"
echo "- OS: $OS"
echo "- Shell: $SHELL"
echo "- Home Directory: $HOME"
echo "- Workspace Directory: $WORKSPACE"
echo

# --- Directory Setup ---
ROO_DIR="$WORKSPACE/.roo"

# Create .roo directory if it doesn't exist
if [ ! -d "$ROO_DIR" ]; then
    mkdir -p "$ROO_DIR"
    echo "Created .roo directory at $ROO_DIR"
fi

# --- Function to escape strings for sed ---
escape_for_sed() {
    echo "$1" | sed 's/[\/&]/\\&/g'
}

# --- Function to check dependencies ---
check_dependencies() {
  echo "Checking dependencies..."
  
  # Check for UV first (preferred)
  if command -v uv &> /dev/null; then
    echo "UV detected! Using UV for package management."
    UV_AVAILABLE=true
    
    # Check for mcp package with UV
    if ! uv pip list | grep -q "mcp"; then
      echo "Installing mcp package using UV..."
      uv pip install mcp
      
      # Verify installation
      if ! uv pip list | grep -q "mcp"; then
        echo "Error: Failed to install mcp package with UV."
        UV_AVAILABLE=false
      else
        echo "Successfully installed mcp package with UV."
        return 0
      fi
    else
      echo "MCP package already installed with UV."
      return 0
    fi
  else
    echo "UV not detected. Checking for traditional Python tools..."
    UV_AVAILABLE=false
  fi
  
  # Check for Python if UV is not available
  if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo "Error: Python is required but not installed."
    echo "Please install Python 3.x to continue."
    return 1
  fi
  
  # Determine Python command (python3 or python)
  if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
  else
    PYTHON_CMD="python"
  fi
  echo "Using Python command: $PYTHON_CMD"
  
  # Check for mcp package
  if ! $PYTHON_CMD -c "import mcp" &> /dev/null; then
    echo "Warning: 'mcp' package is not installed. Will attempt to install it."
    
    # Try different package managers
    if command -v pip3 &> /dev/null; then
      echo "Installing mcp package using pip3..."
      pip3 install mcp
    elif command -v pip &> /dev/null; then
      echo "Installing mcp package using pip..."
      pip install mcp
    else
      echo "Error: pip is not available. Cannot install mcp package."
      echo "Please install the mcp package manually: pip install mcp"
      return 1
    fi
    
    # Verify installation
    if ! $PYTHON_CMD -c "import mcp" &> /dev/null; then
      echo "Error: Failed to install mcp package."
      return 1
    fi
    
    echo "Successfully installed mcp package."
  fi
  
  return 0
}

# --- Function to run MCP checker with UV or fallbacks ---
run_mcp_checker() {
  local output_file="$1"
  local error_log="$2"
  local script_path="$3"
  
  echo "Running MCP Checker to extract MCP metadata..."
  
  # Try with UV first (preferred method)
  if [ "$UV_AVAILABLE" = true ]; then
    echo "Using UV to run MCP checker..."
    
    # Try different UV execution methods
    if uv run --with mcp "$script_path" --output "$output_file" > /dev/null 2>"$error_log"; then
      echo "Successfully ran MCP checker with UV."
      return 0
    fi
    
    echo "Trying alternative UV execution method..."
    if uv run "$script_path" --output "$output_file" > /dev/null 2>>"$error_log"; then
      echo "Successfully ran MCP checker with alternative UV method."
      return 0
    fi
    
    echo "Warning: Failed to run MCP checker with UV. Falling back to direct Python execution."
  fi
  
  # Fallback to direct Python execution
  echo "Using direct Python execution..."
  if $PYTHON_CMD "$script_path" --output "$output_file" > /dev/null 2>>"$error_log"; then
    echo "Successfully ran MCP checker with direct Python execution."
    return 0
  fi
  
  # If we got here, all methods failed
  echo "Error: Failed to run MCP checker with all available methods."
  echo "Check $error_log for details."
  return 1
}

# --- Call dependency check ---
check_dependencies
UV_AVAILABLE=$?

# --- Set up paths for MCP checker ---
MCP_CHECKER_SCRIPT="$CONFIG_DIR/mcp_checker.py"
MCP_OUTPUT_FILE="/tmp/mcp_metadata.md"
MCP_ERROR_LOG="/tmp/mcp_error.log"

# --- Run MCP checker with fallbacks ---
if run_mcp_checker "$MCP_OUTPUT_FILE" "$MCP_ERROR_LOG" "$MCP_CHECKER_SCRIPT"; then
  echo "MCP metadata extracted successfully and saved to $MCP_OUTPUT_FILE"
  # Display file size and first few lines
  ls -l "$MCP_OUTPUT_FILE"
  echo "First few lines of MCP metadata:"
  head -n 5 "$MCP_OUTPUT_FILE"
  
  # Store the content in a variable for later use
  MCP_CHECKER_OUTPUT=$(cat "$MCP_OUTPUT_FILE")
else
  echo "Warning: Failed to extract MCP metadata. Check $MCP_ERROR_LOG for details."
  echo "The script will continue, but MCP metadata may not be updated."
  MCP_CHECKER_OUTPUT=$(cat "$MCP_OUTPUT_FILE" 2>/dev/null || echo "No MCP metadata available")
fi

# Define the formatted MCP section
echo "Setting up MCP section template..."
FORMATTED_MCP="mcp:
  overview:
    - \"The Model Context Protocol (MCP) enables communication with external servers\"
    - \"MCP servers provide additional tools and resources to extend capabilities\"
    - \"Servers can be local (Stdio-based) or remote (SSE-based)\"
  usage:
    - \"Use server tools via the \`use_mcp_tool\` tool\"
    - \"Access server resources via the \`access_mcp_resource\` tool\"
    - \"Wait for server responses before proceeding with additional operations\"
  connected_servers:"

# --- Function to append MCP metadata to system prompt files ---
update_mcp_section() {
    local file=$1
    local metadata="$2"
    local checker_output="$3"
    
    if [ -n "$metadata" ]; then
        # Simply append the MCP metadata to the end of the file
        echo "" >> "$file"  # Add a blank line for separation
        echo "$metadata" >> "$file"
        
        # If we have MCP checker output, indent it with 4 spaces and append it under connected_servers
        if [ -n "$checker_output" ]; then
            checker_length=$(echo "$checker_output" | wc -c)
            echo "Appending MCP checker output to $file (length: $checker_length)"
            
            # Debug: Show the first few lines of the output
            echo "First 3 lines of MCP checker output:"
            echo "$checker_output" | head -n 3
            
            # Indent each line with 4 spaces and append
            echo "$checker_output" | sed 's/^/    /' >> "$file"
            echo "MCP checker output appended successfully"
        fi
    fi
}

# Check for system prompt files in the project's roo_config/.roo directory
echo "Looking for system prompt files..."

# Only look in the project's roo_config/.roo directory
PROMPT_FILES_DIR="$CONFIG_DIR/.roo"

echo "Checking $PROMPT_FILES_DIR"
if [ -d "$PROMPT_FILES_DIR" ] && [ "$(ls -A "$PROMPT_FILES_DIR" 2>/dev/null)" ]; then
    echo "Found system prompt files in $PROMPT_FILES_DIR"
    
    # Copy files from found location to .roo
    cp -r "$PROMPT_FILES_DIR"/* "$ROO_DIR/"
    echo "Copied system prompt files from $PROMPT_FILES_DIR to $ROO_DIR"
    
    # --- Perform Replacements using sed ---
    find "$ROO_DIR" -type f -name "system-prompt-*" -print0 | while IFS= read -r -d $'\0' file; do
        echo "Processing: $file"
        
        # Basic variables - using sed with escaped strings
        sed "${SED_IN_PLACE[@]}" "s/OS_PLACEHOLDER/$(escape_for_sed "$OS")/g" "$file"
        sed "${SED_IN_PLACE[@]}" "s/SHELL_PLACEHOLDER/$(escape_for_sed "$SHELL")/g" "$file"
        sed "${SED_IN_PLACE[@]}" "s|HOME_PLACEHOLDER|$(escape_for_sed "$HOME")|g" "$file"
        sed "${SED_IN_PLACE[@]}" "s|WORKSPACE_PLACEHOLDER|$(escape_for_sed "$WORKSPACE")|g" "$file"
        
        # Complex paths - using sed with escaped strings
        sed "${SED_IN_PLACE[@]}" "s|GLOBAL_SETTINGS_PLACEHOLDER|$(escape_for_sed "$GLOBAL_SETTINGS")|g" "$file"
        sed "${SED_IN_PLACE[@]}" "s|MCP_LOCATION_PLACEHOLDER|$(escape_for_sed "$MCP_LOCATION")|g" "$file"
        sed "${SED_IN_PLACE[@]}" "s|MCP_SETTINGS_PLACEHOLDER|$(escape_for_sed "$MCP_SETTINGS")|g" "$file"
        
        # Append formatted MCP section with MCP checker output as connected_servers
        if [ -n "$FORMATTED_MCP" ]; then
            echo "Updating MCP section in: $file"
            update_mcp_section "$file" "$FORMATTED_MCP" "$MCP_CHECKER_OUTPUT"
        fi
        
        echo "Completed: $file"
    done
else
    echo "No system prompt files found in $PROMPT_FILES_DIR"
    
    # List directories to help debug
    echo "Current directory structure:"
    find "$PROJECT_ROOT" -type d -name ".roo" -o -name "roo_config" | sort
    echo
    
    # Check for default template in the project
    DEFAULT_TEMPLATE=""
    POSSIBLE_TEMPLATES=(
        "$PROJECT_ROOT/default-system-prompt.md"
        "$CONFIG_DIR/default-system-prompt.md"
    )
    
    for template in "${POSSIBLE_TEMPLATES[@]}"; do
        if [ -f "$template" ]; then
            DEFAULT_TEMPLATE="$template"
            echo "Found default template at $DEFAULT_TEMPLATE"
            break
        fi
    done
    
    if [ -n "$DEFAULT_TEMPLATE" ]; then
        # Create system prompt files for each mode
        # Define the list of supported modes
SUPPORTED_MODES=(
    "advanced-orchestrator"
    "architect"
    "ask"
    "code"
    "debug"
    "test"
    "vibemode"
    "junior-reviewer"
    "senior-reviewer"
    "documentation-writer"
)

# Create system prompt files for each mode
for mode in "${SUPPORTED_MODES[@]}"; do
            output_file="$ROO_DIR/system-prompt-$mode"
            
            sed -e "s/OS_PLACEHOLDER/$(escape_for_sed "$OS")/g" \
                -e "s/SHELL_PLACEHOLDER/$(escape_for_sed "$SHELL")/g" \
                -e "s|HOME_PLACEHOLDER|$(escape_for_sed "$HOME")|g" \
                -e "s|WORKSPACE_PLACEHOLDER|$(escape_for_sed "$WORKSPACE")|g" \
                -e "s|GLOBAL_SETTINGS_PLACEHOLDER|$(escape_for_sed "$GLOBAL_SETTINGS")|g" \
                -e "s|MCP_LOCATION_PLACEHOLDER|$(escape_for_sed "$MCP_LOCATION")|g" \
                -e "s|MCP_SETTINGS_PLACEHOLDER|$(escape_for_sed "$MCP_SETTINGS")|g" \
                "$DEFAULT_TEMPLATE" > "$output_file"
                
            # Append formatted MCP section with MCP checker output as connected_servers
            if [ -n "$FORMATTED_MCP" ]; then
                echo "Updating MCP section in: $output_file"
                update_mcp_section "$output_file" "$FORMATTED_MCP" "$MCP_CHECKER_OUTPUT"
            fi
                
            echo "Created $output_file"
        done
    else
        echo "No default system prompt template found."
        echo "Please create system prompt files manually or provide a default template."
    fi
fi

echo
echo "Setup complete!"
echo "You can now use RooFlow with your local environment settings and MCP section with connected servers."
echo