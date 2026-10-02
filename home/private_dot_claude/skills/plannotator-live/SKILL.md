---
name: plannotator-live
description: Annotate a file in Plannotator with live comments — each comment reaches the agent the moment it is saved and gets a reply in the UI, while the user keeps reading. Use when Rajiv says "live annotate", "plannotator live", or wants to comment without batching — and by default when delivering a plannotator-visual-explainer doc (use this flow instead of its blocking `plannotator annotate` step, keeping its `--gate` flag for plans).
---

# Plannotator live

Comments are processed one by one as the user saves them; never wait for the submit.

1. Start the session in the background (Bash `run_in_background: true`):

   ```sh
   PLANNOTATOR_READY_FILE=<scratchpad>/plannotator-ready plannotator annotate <target>
   ```

   Delete a stale ready file first. The background task completes only when the user submits or closes.

2. Start the Monitor tool on `bash ~/.claude/skills/plannotator-live/watch.sh <scratchpad>/plannotator-ready`. The first line is `{"event":"ready","url":...}` — give the user that URL. Every following line is one new comment: `{id, type, text, originalText}`. The Monitor expires after 30 minutes; re-arm it with the same command, handled comments are not replayed.

3. Per comment, right away: answer the question or make the edit to the file, then reply in the UI by comment `id`:

   ```sh
   bash ~/.claude/skills/plannotator-live/reply.sh <scratchpad>/plannotator-ready <id> <<'EOF'
   <reply>
   EOF
   ```

   It attaches the reply to the text the user commented on and prints `attached to <id>`. Always reply through it, never with a hand-written POST: long `originalText` arrives cut off in the event, and a reply only attaches with the full text. `unattached: …` means the comment has no text to attach to; tell the user that reply sits under global comments. A wrong reply is removed with `curl -X DELETE "$URL/api/external-annotations?id=<reply id>"`.

   Keep replies short: the answer, or "Done: <what changed>". File edits show in the tab only in the next round; the reply is how the user learns it's handled.

4. `{"event":"session-ended"}` or the background task finishing ends the loop. The submitted feedback repeats every comment — act only on ones not already handled (edited comment text keeps its id and is not re-streamed, so diff against what you handled).
