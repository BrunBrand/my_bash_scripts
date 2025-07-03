total_seconds=0
for f in *; do
  if file --mime-type "$f" | grep -q audio/; then
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f")
    total_seconds=$(echo "$total_seconds + $duration" | bc)
  fi
done

total_minutes=$(echo "scale=2; $total_seconds / 60" | bc)
echo "Total duration: $total_minutes minutes"
