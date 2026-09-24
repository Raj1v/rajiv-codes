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

2. Start the Monitor tool on `bash ~/.claude/skills/plannotator-live/watch.sh <scratchpad>/plannotator-ready`. The first line is `{"event":"ready","url":...}` — give the user that URL. Every following line is one new comment: `{id, type, text, originalText}`.

3. Per comment, right away: answer the question or make the edit to the file, then reply in the UI:

   ```sh
   curl -s "$URL/api/external-annotations" -H 'Content-Type: application/json' \
     -d '{"source":"claude","author":"Claude","type":"COMMENT","originalText":"<same originalText>","text":"<reply>"}'
   ```

   Keep replies short: the answer, or "Done: <what changed>". No `originalText` on the comment, or the POST returns 400 → post `"type":"GLOBAL_COMMENT"` and quote what it refers to. File edits show in the tab only in the next round; the reply is how the user learns it's handled.

4. `{"event":"session-ended"}` or the background task finishing ends the loop. The submitted feedback repeats every comment — act only on ones not already handled (edited comment text keeps its id and is not re-streamed, so diff against what you handled).
