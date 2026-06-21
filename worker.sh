#!/bin/sh
DATA_DIR="/data"
JOBS_DIR="$DATA_DIR/jobs"
mkdir -p "$JOBS_DIR"

while true; do
  for jobfile in "$JOBS_DIR"/*.json; do
    [ -f "$jobfile" ] || continue
    job=$(cat "$jobfile")
    status=$(echo "$job" | jq -r '.status')
    if [ "$status" = "pending" ]; then
      echo "$job" | jq '.status = "running"' > "$jobfile"
      mode=$(echo "$job" | jq -r '.mode')
      target_file=$(echo "$job" | jq -r '.target_file')
      threads=$(echo "$job" | jq -r '.threads')
      job_id=$(echo "$job" | jq -r '.id')
      output_dir="/data/outputs/$job_id"
      mkdir -p "$output_dir"

      if [ "$mode" = "mass" ]; then
        /app/mass-scan.sh -t "$target_file" -o "$output_dir" -r > "$output_dir/log.txt" 2>&1
      else
        /app/batch-domains.sh -o "$output_dir" > "$output_dir/log.txt" 2>&1
      fi
      echo "$job" | jq '.status = "completed"' > "$jobfile"
    fi
  done
  sleep 5
done