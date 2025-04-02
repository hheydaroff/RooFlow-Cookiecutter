"""
MCP Metadata Extractor

This script connects to MCP (Model Context Protocol) servers defined in the settings file,
extracts metadata about their tools and resources, and formats this information as Markdown
or JSON.

Usage:
    python mcp_checker.py [--settings SETTINGS_PATH] [--output OUTPUT_FILE] [--format {markdown,json}] [--verbose]
    
    With UV:
    uv run --with mcp mcp_checker.py [--settings SETTINGS_PATH] [--output OUTPUT_FILE] [--format {markdown,json}] [--verbose]
    
    Alternative UV method:
    uv run mcp_checker.py [--settings SETTINGS_PATH] [--output OUTPUT_FILE] [--format {markdown,json}] [--verbose]

Arguments:
    --settings      Path to the MCP settings file (default: platform-specific path)
    --output        Output file path (default: mcp_metadata.md)
    --format        Output format: markdown or json (default: markdown)
    --verbose       Enable verbose output

Examples:
    # Extract metadata using default settings with UV (recommended)
    uv run --with mcp mcp_checker.py
    
    # Extract metadata using default settings with traditional Python
    python mcp_checker.py
    
    # Extract metadata with custom settings file and output to JSON
    uv run --with mcp mcp_checker.py --settings /path/to/settings.json --format json --output metadata.json
    
    # Extract metadata with verbose logging
    uv run --with mcp mcp_checker.py --verbose

Dependencies:
    - mcp: The Model Context Protocol client library
    - asyncio: For asynchronous operations
    - json: For parsing and formatting JSON data
"""

import json
import asyncio
import os
import sys
import argparse
import logging
from typing import Dict, Any, List
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


def get_mcp_settings_path():
    """Get the platform-specific path to MCP settings.
    
    Determines the appropriate path to the MCP settings file based on the user's
    operating system (Windows, macOS, or Linux).
    
    Returns:
        str: The path to the MCP settings file based on the current platform.
    """
    home_dir = os.path.expanduser("~")
    
    # Platform-specific paths using a dictionary for cleaner code
    paths = {
        "darwin": os.path.join(home_dir, "Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json"),
        "win32": os.path.join(home_dir, "AppData/Roaming/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json"),
        # Default to Linux path
        "default": os.path.join(home_dir, ".config/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json")
    }
    
    return paths.get(sys.platform, paths["default"])


class MCPMetadataExtractor:
    """
    A class for extracting metadata from MCP servers.
    
    This class connects to MCP servers defined in the settings file, extracts metadata
    about their tools and resources, and formats this information as Markdown or JSON.
    
    Attributes:
        settings_path (str): Path to the MCP settings file
        settings (dict): Parsed settings from the MCP settings file
    """
    
    def __init__(self, settings_path: str):
        """
        Initialize the MCPMetadataExtractor with a settings file path.
        
        Args:
            settings_path (str): Path to the MCP settings file
            
        Raises:
            FileNotFoundError: If the settings file does not exist
        """
        self.settings_path = settings_path
        self.settings = self._load_settings()
        
    def _load_settings(self) -> Dict[str, Any]:
        """
        Load and parse the MCP settings file.
        
        Returns:
            Dict[str, Any]: The parsed settings as a dictionary
            
        Raises:
            FileNotFoundError: If the settings file does not exist
            json.JSONDecodeError: If the settings file is not valid JSON
        """
        with open(self.settings_path, 'r') as f:
            return json.load(f)
    
    async def extract_server_metadata(self, server_name: str) -> Dict[str, Any]:
        """
        Connect to an MCP server and extract its metadata.
        
        This function connects to the specified MCP server, retrieves information about
        its tools and resources, and returns this information as a dictionary.
        
        Args:
            server_name (str): The name of the MCP server to connect to
            
        Returns:
            Dict[str, Any]: A dictionary containing the server's metadata including:
                - name: Server name
                - command: Command used to start the server
                - args: Command arguments
                - status: Connection status (connected, disabled, error)
                - tools: List of available tools with their schemas
                - resources: List of available resources
                - error: Error message if connection failed
                
        Raises:
            ValueError: If the server is not found in the settings
            Exception: If there is an error connecting to the server
        """
        if server_name not in self.settings.get('mcpServers', {}):
            raise ValueError(f"Server '{server_name}' not found in settings")
        
        server_config = self.settings['mcpServers'][server_name]
        
        # Check if the server is disabled in settings
        if server_config.get('disabled', False):
            logging.info(f"Server '{server_name}' is disabled, skipping")
            return {"name": server_name, "status": "disabled"}
        
        command = server_config.get('command')
        args = server_config.get('args', [])
        env = server_config.get('env', {})
        
        # Merge environment variables with current environment
        full_env = os.environ.copy()
        full_env.update(env)
        
        server_params = StdioServerParameters(
            command=command,
            args=args,
            env=full_env
        )
        
        metadata = {
            "name": server_name,
            "command": command,
            "args": args,
            "status": "connected",
            "tools": [],
            "resources": []
        }
        
        try:
            logging.debug(f"Connecting to server '{server_name}'")
            async with stdio_client(server_params) as (read, write):
                async with ClientSession(read, write) as session:
                    # Initialize the connection with the MCP server
                    await session.initialize()
                    
                    # Get tools from the server
                    try:
                        tools_response = await session.list_tools()
                        metadata["tools"] = [
                            {
                                "name": tool.name,
                                "description": tool.description,
                                "inputSchema": tool.inputSchema
                            }
                            for tool in tools_response.tools
                        ]
                        logging.debug(f"Retrieved {len(metadata['tools'])} tools from '{server_name}'")
                    except Exception as e:
                        # Store the error message if tool retrieval fails
                        logging.error(f"Error retrieving tools from '{server_name}': {e}")
                        metadata["tools_error"] = str(e)
                    
                    # Get resources from the server
                    try:
                        resources_response = await session.list_resources()
                        metadata["resources"] = []
                        for resource in resources_response.resources:
                            resource_data = {"description": getattr(resource, "description", "No description available")}
                            # Safely access uriTemplate attribute which may not exist in all resources
                            if hasattr(resource, 'uriTemplate'):
                                resource_data["uriTemplate"] = resource.uriTemplate
                            else:
                                resource_data["uriTemplate"] = "No URI template available"
                            metadata["resources"].append(resource_data)
                        logging.debug(f"Retrieved {len(metadata['resources'])} resources from '{server_name}'")
                    except Exception as e:
                        # Store the error message if resource retrieval fails
                        logging.error(f"Error retrieving resources from '{server_name}': {e}")
                        metadata["resources_error"] = str(e)
                        
        except Exception as e:
            # Handle connection errors
            logging.error(f"Error connecting to server '{server_name}': {e}")
            metadata["status"] = "error"
            metadata["error"] = str(e)
            
        return metadata
    
    async def extract_all_metadata(self) -> Dict[str, Any]:
        """
        Extract metadata from all servers in the settings file.
        
        This function iterates through all MCP servers defined in the settings file
        and extracts metadata from each one.
        
        Returns:
            Dict[str, Any]: A dictionary mapping server names to their metadata
            
        Raises:
            Exception: If there is an error extracting metadata from any server
        """
        results = {}
        for server_name in self.settings.get('mcpServers', {}):
            logging.info(f"Extracting metadata from server '{server_name}'")
            results[server_name] = await self.extract_server_metadata(server_name)
        return results
    
    def format_markdown(self, metadata: Dict[str, Any]) -> str:
        """
        Format the metadata as Markdown.
        
        This function takes the metadata dictionary and formats it as a Markdown string
        with sections for each server, its tools, and resources.
        
        Args:
            metadata (Dict[str, Any]): The metadata dictionary to format
            
        Returns:
            str: The formatted Markdown string
        """
        output = []
        
        for server_name, server_data in metadata.items():
            # Skip disabled servers
            if server_data.get("status") == "disabled":
                continue
                
            # Format command string
            command_str = f"{server_data['command']} {' '.join(server_data['args'])}"
            
            # Server header
            output.append(f"## {server_name} (`{command_str}`)\n")
            
            # Error handling
            if server_data.get("status") == "error":
                output.append(f"**ERROR**: {server_data.get('error')}\n")
                continue
                
            # Tools section
            if server_data.get("tools"):
                output.append("### Available Tools")
                for tool in server_data["tools"]:
                    output.append(f"- {tool['name']}: {tool.get('description', 'No description')}")
                    
                    # Format input schema with proper indentation
                    if tool.get("inputSchema"):
                        output.append("    Input Schema:")
                        schema_json = json.dumps(tool["inputSchema"], indent=2)
                        # Add tab indentation to each line
                        indented_schema = "\t\t" + schema_json.replace("\n", "\n\t\t")
                        output.append(indented_schema)
                    output.append("")  # Empty line after each tool
            elif "tools_error" in server_data:
                output.append(f"**ERROR RETRIEVING TOOLS**: {server_data['tools_error']}\n")
            else:
                output.append("### No tools available\n")
                
            # Resources section
            if server_data.get("resources"):
                output.append("### Direct Resources")
                for resource in server_data["resources"]:
                    uri = resource.get("uriTemplate", "No URI")
                    desc = resource.get("description", "undefined")
                    output.append(f"- {uri} ({desc}): undefined")
                output.append("")
            elif "resources_error" in server_data:
                output.append(f"**ERROR RETRIEVING RESOURCES**: {server_data['resources_error']}\n")
            else:
                output.append("### No direct resources available\n")
                
        return "\n".join(output)

    def format_json(self, metadata: Dict[str, Any]) -> str:
        """
        Format the metadata as JSON.
        
        This function takes the metadata dictionary and formats it as a JSON string.
        
        Args:
            metadata (Dict[str, Any]): The metadata dictionary to format
            
        Returns:
            str: The formatted JSON string with indentation for readability
        """
        return json.dumps(metadata, indent=2)


async def main():
    """
    Main entry point for the script.
    
    This function parses command-line arguments, sets up logging, and runs the
    metadata extraction process.
    
    Returns:
        None
        
    Raises:
        SystemExit: If there is an error during execution
    """
    # Set up argument parser
    parser = argparse.ArgumentParser(description='Extract metadata from MCP servers.')
    parser.add_argument('--settings', help='Path to MCP settings file')
    parser.add_argument('--output', default="mcp_metadata.md", help='Output file path')
    parser.add_argument('--format', choices=['markdown', 'json'], default='markdown', help='Output format')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose output')
    args = parser.parse_args()
    
    # Configure logging
    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(level=log_level, format='%(levelname)s: %(message)s')
    
    # Determine settings path
    settings_path = args.settings if args.settings else get_mcp_settings_path()
    logging.info(f"Using MCP settings from: {settings_path}")
    
    # Check if settings file exists
    if not os.path.isfile(settings_path):
        logging.error(f"Settings file not found: {settings_path}")
        print(f"Error: Settings file not found: {settings_path}")
        sys.exit(1)
    
    try:
        # Create extractor instance
        extractor = MCPMetadataExtractor(settings_path)
        
        # Extract metadata for all servers
        all_metadata = await extractor.extract_all_metadata()
        
        # Format output based on selected format
        if args.format == 'json':
            output = extractor.format_json(all_metadata)
        else:  # markdown
            output = extractor.format_markdown(all_metadata)
        
        # Print to console
        print(output)
        
        # Save to file
        with open(args.output, "w") as f:
            f.write(output)
        
        logging.info(f"Metadata saved to {args.output}")
    except Exception as e:
        logging.error(f"Error: {e}")
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    """
    Script execution entry point.
    
    Example usage:
        # Extract metadata using default settings with UV (recommended)
        uv run --with mcp mcp_checker.py
        
        # Extract metadata using default settings with traditional Python
        python mcp_checker.py
        
        # Extract metadata with custom settings file and output to JSON
        uv run --with mcp mcp_checker.py --settings /path/to/settings.json --format json --output metadata.json
        
        # Extract metadata with verbose logging
        uv run --with mcp mcp_checker.py --verbose
    """
    asyncio.run(main())
