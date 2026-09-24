#!/usr/bin/env bash
# Streams each new Plannotator comment as one JSON line while the user is still annotating.
# Usage: watch.sh <ready-file>   (the PLANNOTATOR_READY_FILE the session was started with)
rf=$1
until [[ -s $rf ]]; do sleep 0.5; done
url=$(head -1 "$rf" | jq -r .url)
echo "{\"event\":\"ready\",\"url\":\"$url\"}"

seen=" " fails=0
while :; do
  if d=$(curl -sf -m 2 "$url/api/draft"); then
    fails=0
    while IFS= read -r a; do
      id=$(jq -r .id <<<"$a")
      [[ $seen == *" $id "* ]] && continue
      seen+="$id "
      echo "$a"
    done < <(jq -c '(.annotations // []) + (.codeAnnotations // []) | .[] | {id, type, text, originalText}' <<<"$d")
  elif (( ++fails >= 3 )); then
    echo '{"event":"session-ended"}'
    exit 0
  fi
  sleep 2
done
