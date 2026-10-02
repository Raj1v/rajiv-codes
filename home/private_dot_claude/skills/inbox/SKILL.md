---
name: inbox
description: Inbox-zero for Rajiv's Slack and Outlook. Finds everything people are still waiting on Rajiv for, tracks it in a state file until it's handled, and can watch Slack on a timer and push-notify on new asks. Use for "/inbox", "who's waiting on me", "what do I still owe people", "monitor my slack", "done 3", "dismiss the Alicia one", "snooze 2 till tomorrow".
argument-hint: "[watch | stop | tick | done/dismiss/snooze <n>]"
---

# Slack inbox

Rajiv is Slack user `U07J66HP5RN`. Uses the `plugin:slack:slack` MCP tools. **Read-only: never send, react, draft, or mark anything read in Slack.**

Argument: $ARGUMENTS

## State

`~/.claude/state/inbox.json` (create with `{"last_checked": null, "items": []}` if missing):

```json
{
  "last_checked": 1789990000,
  "items": [
    {
      "id": "<channel_id>:<message_ts>",
      "who": "Kyle Fearne",
      "where": "DM",
      "ask": "needs your 2FA so Niko can give him YouTube access",
      "link": "<permalink>",
      "since": "2026-09-21T10:21",
      "status": "open | done | dismissed | snoozed | ignored",
      "snooze_until": null,
      "closed_by": "rajiv | auto-replied"
    }
  ]
}
```

`ignored` = evaluated, not actionable; kept only so it isn't re-evaluated. Drop closed/ignored items older than 30 days on every write.

## Check (default, no argument)

1. **Window**: from `last_checked` minus 1h (overlap; dedupe by `id`). First run: last 14 days.
2. **Collect** with `slack_search_public_and_private`, `sort: timestamp`, `include_context: false`, paginating until results predate the window:
   - `to:me after:<date>` — DMs and group DMs
   - keywords `["<@U07J66HP5RN>"]`, filters `after:<date> -from:<@U07J66HP5RN>` — @-mentions
   - Exclude these senders everywhere (own automation / covered elsewhere): GitHub, Linear, Sentry, Figma, Maximilian, Drift, Cloud Costs.
   - Exception: **Cursor** appsec reviews in DM — surface only *Critical* findings, as alerts.
   - **High-traffic DMs** (niko `D07HEFYAGTX`, group DM niko+Chris `C0BJ29268HY`): read the full history in the window with `slack_read_channel` instead of trusting search — asks get buried mid-conversation and search only surfaces a fraction. Use `response_format: detailed` — `concise` hides thread reply counts and exact `Message TS`, and Rajiv often answers in threads.
   - Links: always build from the exact `Message TS` returned by Slack (`/archives/<channel>/p<ts without dot>`), never from a displayed time.
3. **Classify** each new message: actionable only if a person expects something from Rajiv — a question, request, review ask, decision, access/2FA, a deadline. Not actionable: FYIs, banter, acks ("ok", "ahh okay"), answers to Rajiv's own questions. Collapse several messages from the same person on the same ask into one item.
4. **Resolve**: for every `open` item (new and old), check whether Rajiv replied after it — `slack_read_thread` for thread messages, else `slack_read_channel` with `oldest` = item ts. A reply that actually addresses the ask → `done`, `closed_by: auto-replied`. A mere "will look" doesn't close it. Snoozed items whose `snooze_until` has passed → `open`.
5. **Write** state (`last_checked` = now), then print:

```
Waiting on you (N)
 1. Kyle · DM · 3h — needs your 2FA for YouTube access  <link>
 ...
Alerts
 - Cursor appsec: unsigned RevenueCat webhook (critical)  <link>
Closed since last check: Ahmed (replied), ...
```

Oldest first, numbered (numbers are what `done 3` refers to). Nothing open → one line: "Inbox zero."

## Email pass (Outlook, via the `claude.ai Microsoft 365` connector)

Same Check, same state file; items get `where: "email"`, `id: "mail:<internetMessageId>"`, `link` = the message's `webLink`.

1. `outlook_email_search` with `folderName: Inbox`, `order: newest`, `afterDateTime` = window start, paginate by `offset` until `receivedDateTime` predates the window.
2. Drop automated senders by address: `noreply|no-reply|notifications?|alerts?|notify|hey@|team@|support\+|auth@|accounts@|metabase@|sentry@|azure-noreply|posthog|stripe.com|revenuecat.com|notion.com|cursor.com|globus|newsletter|marketing`. Everything else is a person: read the summary; if unclear, `read_resource` on the `uri`.
3. Actionable = a person asks Rajiv for something (a question, a review, a meeting, a signature, a form). CC-only threads where someone else is addressed are FYI. Verification codes, receipts, trials are noise.
4. Resolve: `outlook_email_search` with `recipient: <sender address>` and `sender: rajiv@studyflash.ch`, `afterDateTime` = the ask's date; any reply after the ask → `done`, `closed_by: auto-replied`.
5. Never send, draft, move, flag or delete mail. Read-only, like Slack.

## Directory (Slack IDs, verified 2026-09-22)

People: niko `U06C5M1QMS9` · Ahmed `U06CZMPNP63` · Nikola Grbovic "Grbson" `U06CZMPFNDV` · Kyle `U0B172TQT28` · Furkan `U08G01QH3QQ` · Chris `U0AP43K9B4P` · Zan `U0BC9HVHDGC` · Lazar `U09GHQ7D1MF` · Olivera `U09PYNN9P5Y` · Maximilian (bot) `U0BSGSHN221` · Cursor (bot) `U092NA5EBHS`.

DMs: niko `D07HEFYAGTX` · Ahmed `D07HKT28ZU4` · Grbson `D07HHCFHL3C` · Kyle `D0B102U3UKX` · Furkan `D08F8MDQM45` · Chris `D0AP43KJAGP` · Cursor `D092NA6DVQU`.
Group DMs: niko+Chris `C0BJ29268HY` · niko+Kyle `C0BN4AESXH8` · niko+Ahmed `C0A1D0S8F17` · Furkan+Chris `C0C2V58HD89`.
Channels: #devs `C06BU37LSG7` (everyone's EODs) · #learning_api `C08V1M58XJL` · #invoices `C09L63728LT` · #updates `C0A800X2XQT` (Niko's EODs, posted by a bot as user `U00`) · #cloud-costs `C0BK6LZQ50C`.

## Lessons (each one cost a wrong answer)

- **Never say "unanswered" without opening threads.** Rajiv answers inside threads constantly. `concise` reads hide reply counts. 4 of 9 "open" Niko asks on 21 Sep were already answered in threads.
- **Search returns a fraction.** For "what did X do / ask" questions, `slack_read_channel` the whole window (paginate with the cursor until "no more"), then open every message with replies. Search found 4 of Grbson's 4 EODs but only ~20% of Niko's asks.
- **🤝 / "will check" / "checking" are acks, not closure.** Keep the item open until the thing is done or a real answer lands.
- **One item per ask, across channels.** When the same ask arrives again (email + Slack, a re-flagged Cursor alert, Niko repeating himself), update the existing item's `ask`/`link`, don't add a second one.
- **Recurring bot alerts collapse into one item**; keep the link pointing at the latest occurrence.
- **"Tomorrow" asks → snooze to 09:00 next day**, they reopen on the first tick.
- **Links only from the exact `Message TS` / `webLink`.** Never build a link from a displayed time.
- **Rajiv's other addresses** (`rajivmanichand@gmail.com`, `rajiv+aws-learning-api@studyflash.ch`) land in the same Outlook inbox — GitHub/AWS-support mail, all noise.

## Web view

`index.html` (next to this file) renders `inbox.json` live. Served from `~/.claude/state/inbox-web/` (symlinks to both) with `python3 -m http.server 8787 --bind <tailscale ip>` → `http://<tailscale-ip>:8787/`. If it's not running and Rajiv asks for the page, start it in the background.

## Commands

Natural language is fine ("done 3", "drop the Alicia one", "snooze 2 till tomorrow 9am"). Update status in state, reprint the list.

## watch / stop / tick

- `watch`: `CronList` first; if an "/inbox tick" job exists, say so and stop. Otherwise `CronCreate` cron `"7-59/20 7-22 * * *"`, prompt `/inbox tick`. Then start the web view if port 8787 isn't listening (`ss -ltn | grep -q ':8787 '`), in the background. Tell Rajiv the page URL, and that it's session-only and expires after 7 days (re-run `/inbox watch`).
- `stop`: `CronDelete` the "/inbox tick" job.
- `tick`: run Check. If there are **new** open items since the previous tick, `PushNotification` (status `proactive`), one line, most important first, e.g. `Slack: Kyle needs YouTube 2FA; +2 more`, then print the list. No new items → output nothing but a single line "no new asks".
