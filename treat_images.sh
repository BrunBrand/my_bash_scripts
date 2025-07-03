#!/bin/bash

# Convert all .webp files in the current directory to .png using ffmpeg
# and delete the original .webp file after successful conversion

for file in *.webp; do
  # Skip if no .webp files are found
  [ -e "$file" ] || continue

  # Get the filename without extension
  base="${file%.*}"
  output="${base}.png"

  # Convert using ffmpeg
  if ffmpeg -i "$file" "$output"; then
    echo "Converted: $file -> $output"
    rm "$file"
    echo "Deleted: $file"
  else
    echo "Failed to convert: $file"
  fi
done
