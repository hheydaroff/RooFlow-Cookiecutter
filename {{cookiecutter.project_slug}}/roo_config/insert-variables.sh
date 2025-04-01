#!/usr/bin/env bash

echo "RooFlow Environment Setup Script (Unix/Mac)"
echo "=========================================="
echo

echo "This script will update system prompt files with your local environment details and MCP metadata."
echo

# --- Determine script location and project root ---
# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script directory: $SCRIPT_DIR"

# Determine project root and config directory
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
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

SHELL="bash"  # Hardcode to bash since we're explicitly using it
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

# --- Run MCP Checker to extract MCP metadata ---
echo "Running MCP Checker to extract MCP metadata..."

# Check if python3 is available
if command -v python3 &> /dev/null; then
    # Use the MCP settings path from the environment variables
    if python3 "$WORKSPACE/mcp_checker.py" "$MCP_SETTINGS" > /tmp/mcp_metadata.md 2>/tmp/mcp_error.log; then
        echo "MCP metadata extracted successfully"
        MCP_METADATA=$(cat /tmp/mcp_metadata.md)
    else
        echo "Warning: Failed to extract MCP metadata. Check /tmp/mcp_error.log for details."
        echo "The script will continue, but MCP metadata may not be updated."
        MCP_METADATA=$(cat /tmp/mcp_metadata.md 2>/dev/null || echo "")
    fi
else
    echo "Warning: Python 3 is not available. MCP metadata extraction will be skipped."
    echo "To extract MCP metadata, please install Python 3 and the required packages."
    MCP_METADATA=""
fi

# --- Function to update MCP section in system prompt files ---
update_mcp_section() {
    local file=$1
    local metadata="$2"
    
    if [ -n "$metadata" ]; then
        # Find the line with "connected_servers:" and replace everything after it until the next section
        awk -v metadata="$metadata" '
        BEGIN { in_mcp = 0; in_connected_servers = 0; }
        /^mcp:/ { in_mcp = 1; print; next; }
        /^[a-z]/ && in_mcp { in_mcp = 0; print; next; }
        /^    connected_servers:/ && in_mcp { print; print metadata; in_connected_servers = 1; next; }
        in_connected_servers && /^    [a-z]/ { in_connected_servers = 0; print; next; }
        in_connected_servers { next; } # Skip existing connected_servers content
        { print; }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
}

# Check for system prompt files in different possible locations
echo "Looking for system prompt files..."

# List of possible locations for system prompt files
POSSIBLE_LOCATIONS=(
    "$CONFIG_DIR/.roo"
    "$PROJECT_ROOT/roo_config/.roo"
    "$PROJECT_ROOT/{{cookiecutter.project_slug}}/roo_config/.roo"
    "$WORKSPACE/roo_config/.roo"
)

PROMPT_FILES_DIR=""
for location in "${POSSIBLE_LOCATIONS[@]}"; do
    echo "Checking $location"
    if [ -d "$location" ] && [ "$(ls -A "$location" 2>/dev/null)" ]; then
        PROMPT_FILES_DIR="$location"
        echo "Found system prompt files in $PROMPT_FILES_DIR"
        break
    fi
done

if [ -n "$PROMPT_FILES_DIR" ]; then
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
        
        # Update MCP section with metadata from mcp_checker.py
        if [ -n "$MCP_METADATA" ]; then
            echo "Updating MCP metadata in: $file"
            update_mcp_section "$file" "$MCP_METADATA"
        fi
        
        echo "Completed: $file"
    done
else
    echo "No system prompt files found in any of the expected locations."
    
    # List directories to help debug
    echo "Current directory structure:"
    find "$PROJECT_ROOT" -type d -name ".roo" -o -name "roo_config" | sort
    echo
    
    # Check for default template in different locations
    DEFAULT_TEMPLATE=""
    POSSIBLE_TEMPLATES=(
        "$PROJECT_ROOT/default-system-prompt.md"
        "$WORKSPACE/default-system-prompt.md"
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
        for mode in code architect ask debug test; do
            output_file="$ROO_DIR/system-prompt-$mode"
            
            sed -e "s/OS_PLACEHOLDER/$(escape_for_sed "$OS")/g" \
                -e "s/SHELL_PLACEHOLDER/$(escape_for_sed "$SHELL")/g" \
                -e "s|HOME_PLACEHOLDER|$(escape_for_sed "$HOME")|g" \
                -e "s|WORKSPACE_PLACEHOLDER|$(escape_for_sed "$WORKSPACE")|g" \
                -e "s|GLOBAL_SETTINGS_PLACEHOLDER|$(escape_for_sed "$GLOBAL_SETTINGS")|g" \
                -e "s|MCP_LOCATION_PLACEHOLDER|$(escape_for_sed "$MCP_LOCATION")|g" \
                -e "s|MCP_SETTINGS_PLACEHOLDER|$(escape_for_sed "$MCP_SETTINGS")|g" \
                "$DEFAULT_TEMPLATE" > "$output_file"
                
            # Update MCP section with metadata from mcp_checker.py
            if [ -n "$MCP_METADATA" ]; then
                echo "Updating MCP metadata in: $output_file"
                update_mcp_section "$output_file" "$MCP_METADATA"
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
echo "You can now use RooFlow with your local environment settings and updated MCP metadata."
echo