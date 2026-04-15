# Global Preferences

## Package manager

NEVER use npm. Always use pnpm. No exceptions.

## Claude Code MCP servers

User-scope MCP servers MUST be defined in `~/.claude.json` under the top-level `mcpServers` key. They do NOT work in `~/.claude/settings.json`. See https://code.claude.com/docs/en/mcp#user-scope

MCP config is managed by chezmoi via `run_onchange_after_configure-claude-mcps.sh.tmpl`. To add/remove an MCP server, edit that script and run `chezmoi apply`. Secrets are sourced from `~/.secrets` at runtime.
