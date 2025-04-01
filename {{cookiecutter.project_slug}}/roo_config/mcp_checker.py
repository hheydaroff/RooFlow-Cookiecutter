import json
import asyncio
import os
import sys
from typing import Dict, Any, List
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

class MCPMetadataExtractor:
    def __init__(self, settings_path: str):
        """Initialize with the path to the MCP settings file."""
        self.settings_path = settings_path
        self.settings = self._load_settings()
        
    def _load_settings(self) -> Dict[str, Any]:
        """Load and parse the MCP settings file."""
        with open(self.settings_path, 'r') as f:
            return json.load(f)
    
    async def extract_server_metadata(self, server_name: str) -> Dict[str, Any]:
        """Connect to an MCP server and extract its metadata."""
        if server_name not in self.settings.get('mcpServers', {}):
            raise ValueError(f"Server '{server_name}' not found in settings")
        
        server_config = self.settings['mcpServers'][server_name]
        
        if server_config.get('disabled', False):
            print(f"Server '{server_name}' is disabled, skipping")
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
            async with stdio_client(server_params) as (read, write):
                async with ClientSession(read, write) as session:
                    # Initialize the connection
                    await session.initialize()
                    
                    # Get tools
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
                    except Exception as e:
                        metadata["tools_error"] = str(e)
                    
                    # Get resources
                    try:
                        resources_response = await session.list_resources()
                        metadata["resources"] = [
                            {
                                "uriTemplate": resource.uriTemplate,
                                "description": resource.description
                            }
                            for resource in resources_response.resources
                        ]
                    except Exception as e:
                        metadata["resources_error"] = str(e)
                        
        except Exception as e:
            metadata["status"] = "error"
            metadata["error"] = str(e)
            
        return metadata
    
    async def extract_all_metadata(self) -> Dict[str, Any]:
        """Extract metadata from all servers in the settings file."""
        results = {}
        for server_name in self.settings.get('mcpServers', {}):
            results[server_name] = await self.extract_server_metadata(server_name)
        return results
    
    def format_markdown(self, metadata: Dict[str, Any]) -> str:
        """Format the metadata as Markdown."""
        output = []
        
        for server_name, server_data in metadata.items():
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

async def main():
    # Path to your MCP settings file
    if len(sys.argv) > 1:
        settings_path = sys.argv[1]
    else:
        # Use the home directory dynamically
        home_dir = os.path.expanduser("~")
        
        # Determine the platform-specific path
        if sys.platform == "darwin":  # macOS
            settings_path = os.path.join(home_dir, "Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json")
        elif sys.platform == "win32":  # Windows
            settings_path = os.path.join(home_dir, "AppData/Roaming/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json")
        else:  # Linux and others
            settings_path = os.path.join(home_dir, ".config/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json")
    
    extractor = MCPMetadataExtractor(settings_path)
    
    # Extract metadata for all servers
    all_metadata = await extractor.extract_all_metadata()
    
    # Format as Markdown
    markdown_output = extractor.format_markdown(all_metadata)
    
    # Print to console
    print(markdown_output)
    
    # Save to file
    with open("mcp_metadata.md", "w") as f:
        f.write(markdown_output)
    
    print(f"\nMetadata saved to mcp_metadata.md")

if __name__ == "__main__":
    asyncio.run(main())
