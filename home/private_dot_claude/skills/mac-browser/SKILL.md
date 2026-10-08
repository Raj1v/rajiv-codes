---
name: mac-browser
description: Drive Rajiv's logged-in Chrome on his Mac from this devbox via the agent-browser CLI over CDP.
disable-model-invocation: true
allowed-tools: Bash
---

# Rajiv's Mac Chrome

Use the `agent-browser` CLI, not Playwright MCP. Before the first use in a session, load its version-matched guide:

```sh
agent-browser skills get core --full
```

Connect over CDP at `http://100.84.27.10:9222` (always the IP, not the hostname):

```sh
agent-browser connect http://100.84.27.10:9222
# or per command
agent-browser --cdp http://100.84.27.10:9222 open https://example.com
```

Only up while Rajiv runs `agent-chrome` on the Mac. If `curl -sf -m 3 http://100.84.27.10:9222/json/version` fails, ask him to start it.

## Rules

It has full control of every account in that profile. Read and navigate freely; ask before anything outward-facing or hard to undo — sending messages, posting, purchases, deleting, changing account settings.
