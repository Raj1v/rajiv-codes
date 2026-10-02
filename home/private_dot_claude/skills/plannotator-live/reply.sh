#!/usr/bin/env bash
# Replies to one Plannotator comment, attached to the text the user commented on. Reply text on stdin.
# Usage: reply.sh <ready-file> <comment-id> <<<'reply'
set -euo pipefail
url=$(head -1 "$1" | jq -r .url) id=$2
text=$(cat)

comment=$(curl -sf -m 5 "$url/api/draft" | jq -c --arg id "$id" \
  '[(.annotations // []) + (.codeAnnotations // []) | .[] | select(.id == $id)][0] // empty')
[[ -n $comment ]] || { echo "no comment $id in $url" >&2; exit 1; }

# prints the reply's id, fails unless the server stored it
post() {
  curl -sf -m 5 "$url/api/external-annotations" -H 'Content-Type: application/json' -d "$1" |
    jq -er '.ids[0]'
}

if [[ -n $(jq -r '.originalText // ""' <<<"$comment") ]]; then
  body=$(jq -c --arg text "$text" \
    '{source: "claude", author: "Claude", type: "COMMENT", originalText, text: $text}' <<<"$comment")
  reply=$(post "$body") && { echo "attached to $id (reply $reply)"; exit 0; }
fi

body=$(jq -c --arg text "$text" '{source: "claude", author: "Claude", type: "GLOBAL_COMMENT",
  text: ("Re \"" + (.text | gsub("\\s+"; " ") | .[0:120]) + "\":\n\n" + $text)}' <<<"$comment")
reply=$(post "$body") || { echo "reply to $id failed" >&2; exit 1; }
echo "unattached: $id has no text to attach to, posted as a global comment (reply $reply)"
