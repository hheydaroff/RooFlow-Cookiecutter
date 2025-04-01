#!/bin/bash

echo "RooFlow Environment Setup Script (Unix/Mac)"
echo "=========================================="
echo

echo "This script will update system prompt files with your local environment details."
echo

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
WORKSPACE=$(pwd)

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
    echo "Created .roo directory"
fi

# --- Function to escape strings for sed ---
escape_for_sed() {
    echo "$1" | sed 's/[\/&]/\\&/g'
}

# Check if roo_config/.roo directory exists with system prompt files
if [ -d "roo_config/.roo" ] && [ "$(ls -A roo_config/.roo 2>/dev/null)" ]; then
    echo "Found system prompt files in roo_config/.roo"
    
    # Copy files from roo_config/.roo to .roo
    cp -r roo_config/.roo/* "$ROO_DIR/"
    echo "Copied system prompt files to $ROO_DIR"
    
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
        
        echo "Completed: $file"
    done
else
    echo "No system prompt files found in roo_config/.roo"
    
    # Check if default-system-prompt.md exists
    if [ -f "default-system-prompt.md" ]; then
        echo "Found default-system-prompt.md"
        
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
                "default-system-prompt.md" > "$output_file"
                
            echo "Created $output_file"
        done
    else
        echo "No default system prompt found. Please create system prompt files manually."
    fi
fi

echo
echo "Setup complete!"
echo "You can now use RooFlow with your local environment settings."
echo