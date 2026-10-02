#!/usr/bin/env bash
# Streams each new Plannotator comment as one JSON line while the user is still annotating.
# Usage: watch.sh <ready-file>   (the PLANNOTATOR_READY_FILE the session was started with)
rf=$1
until [[ -s $rf ]]; do sleep 0.5; done
url=$(head -1 "$rf" | jq -r .url)
echo "{\"event\":\"ready\",\"url\":\"$url\"}"

# A re-armed watch continues from the seen-list; a new session (newer ready file) starts empty.
sf=$rf.seen fails=0
{ [[ $sf -nt $rf ]] && seen=$(jq -c . "$sf" 2>/dev/null); } || seen='[]'
while :; do
  # 404 = no draft saved yet; only a refused connection (curl 7) means the session is gone, a loaded machine times out.
  d=$(curl -s -m 5 -w '\n%{http_code}' "$url/api/draft") rc=$?
  if (( rc == 0 )) && [[ ${d##*$'\n'} =~ ^(200|404)$ ]]; then
    fails=0
    [[ ${d##*$'\n'} == 404 ]] && { sleep 1; continue; }
    # One jq pass per poll: new user comments (Claude's own replies skipped), then the updated seen-list.
    out=$(jq -c --argjson seen "$seen" '
      [(.annotations // []) + (.codeAnnotations // []) | .[] | select(.source != "claude")] as $all
      | ($all | map(select(.id as $i | $seen | index($i) | not)) | .[] | {id, type, text, originalText}),
        {seen: ($seen + ($all | map(.id)) | unique)}' <<<"${d%$'\n'*}")
    next=$(tail -1 <<<"$out" | jq -c .seen 2>/dev/null) && [[ -n $next ]] || { sleep 1; continue; }
    seen=$next
    sed '$d' <<<"$out" | grep -v '^$'
    echo "$seen" >"$sf"
  elif (( rc == 7 )) && (( ++fails >= 3 )); then
    echo '{"event":"session-ended"}'
    exit 0
  fi
  sleep 1
done
