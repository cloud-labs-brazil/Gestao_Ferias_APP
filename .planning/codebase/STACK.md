# Technology Stack

## Runtime & Languages

| Technology | Version | Purpose |
|------------|---------|---------|
| PowerShell | 5.1+ / 7+ | Deployment automation scripts |
| JSON | - | Power Automate flow definitions, Adaptive Cards |
| YAML | - | Copilot Studio agent template |
| Markdown | - | SOPs, documentation, checklists |
| XML | MSBuild 15.0 | Power Platform Solution project |

## Dependencies & Modules

### PowerShell Modules
| Module | Purpose | Status |
|--------|---------|--------|
| `PnP.PowerShell` (v2.12/3.x) | SharePoint Online management | ✅ Installed |
| `SharePointPnPPowerShellOnline` | Legacy PnP fallback (PS 5.1) | ✅ Available |
| `ImportExcel` | Excel file parsing (`.xlsx`) | ✅ Installed |

### NPM Dependencies (package.json)
| Package | Version | Purpose |
|---------|---------|---------|
| `@mcp-consultant-tools/powerplatform` | ^25.0.0 | MCP Power Platform tools |
| `@microsoft/agents-copilotstudio-client` | ^1.2.2 | Copilot Studio SDK client |
| `@modelcontextprotocol/sdk` | ^1.25.3 | MCP protocol SDK |
| `@pnp/cli-microsoft365-mcp-server` | ^0.1.17 | CLI M365 MCP server |
| `powerplatform-mcp` | ^1.0.1 | Power Platform MCP integration |

## External Services

| Service | URL/Endpoint | Purpose |
|---------|-------------|---------|
| SharePoint Online | `indra365.sharepoint.com` | Data storage (6 lists) |
| Power Automate | `make.powerautomate.com` | Business logic (10 flows) |
| Copilot Studio | Power Platform | Conversational AI agent |
| Microsoft Teams | Teams client | Delivery channel + notifications |
| Office 365 Outlook | Exchange Online | Email notifications |
| Dataverse | `colofertasbrasilpro.crm4.dynamics.com` | Platform environment |

## Build & Tooling

| Tool | Purpose |
|------|---------|
| `pac` CLI | Power Platform CLI for solution management |
| MSBuild (.cdsproj) | Power Platform solution packaging |
| Git | Version control |
| npm | Node.js dependency management for MCP tools |
