import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import { appendFile } from "node:fs/promises";

type PullRequest = {
  url: string;
  number: number;
  title?: string;
  state?: string;
  isDraft?: boolean;
  headRefName?: string;
  touchedAt: number;
};

type StoredPullRequest = Omit<PullRequest, "touchedAt"> & { touchedAt?: number };

const ENTRY_TYPE = "session-pr";
const DETACHED_ENTRY_TYPE = "session-pr-detached";
const WIDGET_ID = "session-prs";
const PR_URL = /https:\/\/github\.com\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\/pull\/(\d+)/g;
const RELEVANT_GH_PR_COMMAND =
  /(?:^|[;&|]\s*|\s)gh\s+pr\s+(?:create|view|edit|checkout|comment|close|reopen|merge|ready|checks)\b/;

function textFromContent(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .map((part) => {
      if (!part || typeof part !== "object") return "";
      const value = part as { type?: string; text?: unknown };
      return value.type === "text" && typeof value.text === "string" ? value.text : "";
    })
    .filter(Boolean)
    .join("\n");
}

function extractPullRequests(text: string): PullRequest[] {
  const found = new Map<string, PullRequest>();
  for (const match of text.matchAll(PR_URL)) {
    const url = match[0].replace(/[),.;]+$/, "");
    found.set(url, {
      url,
      number: Number(match[1]),
      touchedAt: Date.now(),
    });
  }
  return [...found.values()];
}

function isStoredPullRequest(value: unknown): value is StoredPullRequest {
  if (!value || typeof value !== "object") return false;
  const candidate = value as Partial<StoredPullRequest>;
  return (
    typeof candidate.url === "string" &&
    candidate.url.startsWith("https://github.com/") &&
    typeof candidate.number === "number"
  );
}

function hyperlink(url: string, label: string): string {
  const open = `\x1b]8;;${url}\x1b\\`;
  const close = "\x1b]8;;\x1b\\";
  return `${open}${label}${close}`;
}

async function openUrl(pi: ExtensionAPI, url: string): Promise<boolean> {
  // This machine's WezTerm config opens URLs delivered through the openurl
  // user variable. Pass the OSC sequence through tmux when connected remotely.
  if (process.env.SSH_CONNECTION) {
    // WezTerm only emits user-var-changed when the value changes. A throwaway
    // fragment keeps repeated opens distinct without requiring a config change;
    // fragments are not sent to GitHub.
    const target = `${url}#pi-open-${Date.now().toString(36)}`;
    const encoded = Buffer.from(target).toString("base64");
    const osc = `\x1b]1337;SetUserVar=openurl=${encoded}\x07`;
    const sequence = process.env.TMUX ? `\x1bPtmux;\x1b${osc}\x1b\\` : osc;
    try {
      await appendFile("/dev/tty", sequence);
      return true;
    } catch {
      return false;
    }
  }

  const command = process.platform === "darwin" ? "open" : "xdg-open";
  const result = await pi.exec(command, [url], { timeout: 5_000 });
  return result.code === 0;
}

export default function sessionPullRequests(pi: ExtensionAPI): void {
  const pullRequests = new Map<string, PullRequest>();
  let currentUrl: string | undefined;
  let currentPullRequest: PullRequest | undefined;
  let activeCwd: string | undefined;
  let refreshPromise: Promise<void> | undefined;
  let metadataPromise: Promise<void> | undefined;
  const metadataFetchedAt = new Map<string, number>();
  const METADATA_REFRESH_INTERVAL = 60_000;

  function sortedPullRequests(): PullRequest[] {
    return [...pullRequests.values()].sort((left, right) => {
      if (left.url === currentUrl) return -1;
      if (right.url === currentUrl) return 1;
      return right.touchedAt - left.touchedAt;
    });
  }

  function updateUi(ctx: { hasUI: boolean; ui: any }): void {
    if (!ctx.hasUI) return;
    const items = sortedPullRequests();
    if (items.length === 0) {
      ctx.ui.setWidget(WIDGET_ID, undefined);
      return;
    }

    ctx.ui.setWidget(
      WIDGET_ID,
      (_tui: unknown, theme: any) => ({
        render(width: number) {
          return items.map((pr) => {
            const state = pr.isDraft ? "draft" : pr.state?.toLowerCase();
            const stateColor = pr.isDraft
              ? "warning"
              : pr.state === "OPEN"
                ? "success"
                : pr.state === "MERGED"
                  ? "accent"
                  : "dim";
            const dot = theme.fg(stateColor, "●");
            const label = hyperlink(pr.url, theme.fg("accent", theme.bold(`PR #${pr.number}`)));
            const flags = [pr.url === currentUrl ? "current" : undefined, state].filter(Boolean);
            const metadata = flags.length ? theme.fg(stateColor, ` (${flags.join(" · ")})`) : "";
            const title = pr.title ? theme.fg("muted", ` — ${pr.title}`) : "";
            return truncateToWidth(`${dot} ${label}${metadata}${title}`, width);
          });
        },
        invalidate() {},
      }),
      { placement: "belowEditor" },
    );
  }

  function remember(pr: PullRequest, persist: boolean): boolean {
    const previous = pullRequests.get(pr.url);
    const next: PullRequest = {
      ...previous,
      ...pr,
      touchedAt: Math.max(previous?.touchedAt ?? 0, pr.touchedAt),
    };
    const changed =
      !previous ||
      previous.title !== next.title ||
      previous.state !== next.state ||
      previous.isDraft !== next.isDraft ||
      previous.headRefName !== next.headRefName;
    pullRequests.set(next.url, next);
    if (persist && changed) pi.appendEntry(ENTRY_TYPE, next);
    return changed;
  }

  function rememberText(text: string, ctx: { hasUI: boolean; ui: any }): void {
    let changed = false;
    for (const pr of extractPullRequests(text)) changed = remember(pr, true) || changed;
    if (changed) updateUi(ctx);
  }

  async function refreshCurrent(ctx: { cwd: string; hasUI: boolean; ui: any }): Promise<void> {
    if (refreshPromise) return refreshPromise;
    refreshPromise = (async () => {
      const result = await pi.exec(
        "gh",
        ["pr", "view", "--json", "number,title,url,state,isDraft,headRefName"],
        { cwd: ctx.cwd, timeout: 8_000 },
      );

      currentUrl = undefined;
      currentPullRequest = undefined;
      if (result.code === 0) {
        try {
          const value = JSON.parse(result.stdout) as StoredPullRequest;
          if (isStoredPullRequest(value)) {
            const pr: PullRequest = { ...value, touchedAt: Date.now() };
            currentPullRequest = pr;
            currentUrl = pr.url;

            // A matching branch only discovers a candidate PR. Refresh metadata
            // when the session already knows the PR, but do not associate it.
            if (pullRequests.has(pr.url)) remember(pr, true);
          }
        } catch {
          // A malformed gh response should not disrupt the session.
        }
      }
      updateUi(ctx);
    })().finally(() => {
      refreshPromise = undefined;
    });
    return refreshPromise;
  }

  // The current-branch probe above only covers the checked-out branch. Session
  // PRs discovered from message text start out as bare URLs, so fetch their
  // metadata by URL. Merged/closed PRs are final; open ones are re-polled.
  async function refreshMetadata(ctx: { cwd: string; hasUI: boolean; ui: any }, force = false): Promise<void> {
    if (metadataPromise) return metadataPromise;
    metadataPromise = (async () => {
      const now = Date.now();
      const stale = [...pullRequests.values()].filter((pr) => {
        if (force || !pr.title || !pr.state) return true;
        if (pr.state === "MERGED" || pr.state === "CLOSED") return false;
        return now - (metadataFetchedAt.get(pr.url) ?? 0) >= METADATA_REFRESH_INTERVAL;
      });

      let changed = false;
      for (const pr of stale) {
        const result = await pi.exec(
          "gh",
          ["pr", "view", pr.url, "--json", "number,title,url,state,isDraft,headRefName"],
          { cwd: ctx.cwd, timeout: 8_000 },
        );
        metadataFetchedAt.set(pr.url, Date.now());
        if (result.code !== 0) continue;
        try {
          const value = JSON.parse(result.stdout) as StoredPullRequest;
          if (!isStoredPullRequest(value)) continue;
          // Keep the original URL as the map key and preserve touch ordering.
          changed =
            remember({ ...value, url: pr.url, touchedAt: pr.touchedAt }, true) || changed;
        } catch {
          // A malformed gh response should not disrupt the session.
        }
      }
      if (changed) updateUi(ctx);
    })().finally(() => {
      metadataPromise = undefined;
    });
    return metadataPromise;
  }

  pi.on("session_start", async (_event, ctx) => {
    pullRequests.clear();
    currentUrl = undefined;
    currentPullRequest = undefined;
    activeCwd = ctx.cwd;

    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type === "custom" && entry.customType === ENTRY_TYPE && isStoredPullRequest(entry.data)) {
        remember({ ...entry.data, touchedAt: entry.data.touchedAt ?? 0 }, false);
        continue;
      }
      if (
        entry.type === "custom" &&
        entry.customType === DETACHED_ENTRY_TYPE &&
        entry.data &&
        typeof entry.data === "object" &&
        typeof (entry.data as { url?: unknown }).url === "string"
      ) {
        pullRequests.delete((entry.data as { url: string }).url);
        continue;
      }
      if (entry.type !== "message") continue;
      const message = entry.message as { role?: string; content?: unknown };
      if (message.role === "user" || message.role === "assistant") {
        for (const pr of extractPullRequests(textFromContent(message.content))) remember(pr, false);
      }
    }

    updateUi(ctx);
    await refreshCurrent(ctx);
    await refreshMetadata(ctx);
  });

  pi.on("message_end", (event, ctx) => {
    const message = event.message as { role?: string; content?: unknown };
    if (message.role === "user" || message.role === "assistant") {
      rememberText(textFromContent(message.content), ctx);
    }
  });

  pi.on("tool_result", (event, ctx) => {
    if (event.toolName !== "bash") return;
    const command = (event.input as { command?: unknown })?.command;
    if (typeof command !== "string" || !RELEVANT_GH_PR_COMMAND.test(command)) return;
    rememberText(textFromContent(event.content), ctx);
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (ctx.cwd !== activeCwd) return;
    await refreshCurrent(ctx);
    await refreshMetadata(ctx);
  });

  pi.on("session_shutdown", (_event, ctx) => {
    ctx.ui.setWidget(WIDGET_ID, undefined);
  });

  async function detachCurrent(ctx: { cwd: string; hasUI: boolean; ui: any }): Promise<void> {
    await refreshCurrent(ctx);
    if (!currentPullRequest) {
      ctx.ui.notify("The current branch does not have a pull request.", "info");
      return;
    }

    pullRequests.delete(currentPullRequest.url);
    pi.appendEntry(DETACHED_ENTRY_TYPE, { url: currentPullRequest.url });
    updateUi(ctx);
    ctx.ui.notify(`Detached PR #${currentPullRequest.number} from this session.`, "info");
  }

  pi.registerCommand("prs-detach-current", {
    description: "Detach the current branch PR from this session",
    handler: async (_args, ctx) => detachCurrent(ctx),
  });

  pi.registerCommand("prs", {
    description: "Show session PRs; supports current, attach-current, and detach-current", 
    handler: async (args, ctx) => {
      const action = args.trim();
      if (
        action === "refresh" ||
        action === "attach-current" ||
        action === "current"
      ) {
        await refreshCurrent(ctx);
        await refreshMetadata(ctx, action === "refresh");
      }

      if (action === "attach-current") {
        if (!currentPullRequest) {
          ctx.ui.notify("The current branch does not have a pull request.", "info");
          return;
        }
        remember(currentPullRequest, true);
        updateUi(ctx);
        ctx.ui.notify(`Attached PR #${currentPullRequest.number} to this session.`, "info");
        return;
      }

      if (action === "detach-current") {
        await detachCurrent(ctx);
        return;
      }

      if (action === "current") {
        if (!currentPullRequest) {
          ctx.ui.notify("The current branch does not have a pull request.", "info");
          return;
        }
        const associated = pullRequests.has(currentPullRequest.url) ? "attached" : "not attached";
        ctx.ui.notify(
          `Current branch: PR #${currentPullRequest.number} (${associated})${currentPullRequest.title ? ` — ${currentPullRequest.title}` : ""}`,
          "info",
        );
        return;
      }

      const items = sortedPullRequests();
      if (items.length === 0) {
        ctx.ui.notify("No pull requests touched by this session yet.", "info");
        return;
      }

      const choices = items.map((pr) => {
        const current = pr.url === currentUrl ? " • current" : "";
        const state = pr.isDraft ? "draft" : pr.state?.toLowerCase();
        return `#${pr.number}${current}${state ? ` • ${state}` : ""}${pr.title ? ` — ${pr.title}` : ""}`;
      });
      const selected = await ctx.ui.select("Session pull requests", choices);
      if (!selected) return;

      const index = choices.indexOf(selected);
      const pr = items[index];
      if (!pr) return;
      if (!(await openUrl(pi, pr.url))) {
        ctx.ui.notify(`Could not open ${pr.url}`, "error");
      }
    },
  });
}
