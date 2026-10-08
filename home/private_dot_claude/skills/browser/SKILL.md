---
name: browser
description: Browser automation on this devbox with the agent-browser CLI, including Rajiv's logged-in Mac Chrome. Use for anything that needs a real browser — open/click/fill pages, screenshots, scraping JS-rendered sites, testing web apps, or acting in his logged-in accounts. Use instead of Playwright MCP.
allowed-tools: Bash
---

# Browser automation

Use the `agent-browser` CLI, not Playwright MCP. Before the first use in a session, load its version-matched guide:

```sh
agent-browser skills get core --full
```

## Which browser

- **Default: headless on the devbox.** Fine for public pages, local dev servers, tests.
- **Logged-in sessions: Rajiv's Mac Chrome** over CDP at `http://100.84.27.10:9222` (always the IP, not the hostname). Use it when the task needs his accounts.

```sh
agent-browser connect http://100.84.27.10:9222
# or per command
agent-browser --cdp http://100.84.27.10:9222 open https://example.com
```

The Mac Chrome is only up while Rajiv runs `agent-chrome` on the Mac. If `curl -sf -m 3 http://100.84.27.10:9222/json/version` fails, ask him to start it.

## Mac Chrome rules

It has full control of every account in that profile. Read and navigate freely; ask before anything outward-facing or hard to undo — sending messages, posting, purchases, deleting, changing account settings.
