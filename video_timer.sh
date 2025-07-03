
#!/bin/bash

# A script to calculate the total duration of all video files in a directory.
#
# Usage: ./script_name.sh /path/to/your/videos
#
# Dependencies: ffmpeg (specifically the ffprobe utility)

# --- Configuration ---
# Set to "true" to see the duration of each individual file processed.
SHOW_INDIVIDUAL_DURATION=false

# --- Script Start ---

# 1. Check for Dependencies
# Verify that 'ffprobe' is installed and available in the system's PATH.
if ! command -v ffprobe &> /dev/null; then
    echo "Error: ffprobe is not installed or not in your PATH."
    echo "Please install ffmpeg (e.g., 'sudo apt install ffmpeg' or 'sudo dnf install ffmpeg')."
    exit 1
fi

# 2. Validate Input
# Check if a directory path was provided as an argument.
TARGET_DIR="$1"
if [ -z "$TARGET_DIR" ]; then
    echo "Error: No directory specified."
    echo "Usage: $0 <directory_path>"
    exit 1
fi

# Check if the provided path is a valid directory.
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: '$TARGET_DIR' is not a valid directory."
    exit 1
fi

echo "Scanning directory: $TARGET_DIR"
total_seconds=0

# 3. Process Files and Calculate Total Duration
# Use 'find' to locate all files in the target directory and its subdirectories.
# The 'while' loop reads each file path found.
while IFS= read -r file; do
    # Use ffprobe to get the duration of the file in seconds.
    # -v error: Suppresses all output except for errors.
    # -show_entries format=duration: Specifies that we only want the duration.
    # -of default=noprint_wrappers=1:nokey=1: Formats the output to be just the raw value.
    # 2>/dev/null: Redirects any errors (e.g., for non-video files) to /dev/null.
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)

    # Check if a valid duration was returned.
    if [[ -n "$duration" && "$duration" =~ ^[0-9.]+$ ]]; then
        if [ "$SHOW_INDIVIDUAL_DURATION" = "true" ]; then
            echo " - Found video: $(basename "$file") - Duration: ${duration}s"
        fi
        # Add the duration of the current file to the total.
        # 'bc' is used for floating-point arithmetic.
        total_seconds=$(echo "$total_seconds + $duration" | bc)
    fi
done < <(find "$TARGET_DIR" -type f)

# 4. Display the Result
if (( $(echo "$total_seconds > 0" | bc -l) )); then
    # Convert total seconds to minutes.
    total_minutes=$(echo "scale=2; $total_seconds / 60" | bc)
    echo "----------------------------------------"
    echo "Total duration (seconds): $total_seconds"
    echo "Total duration (minutes): $total_minutes"
    echo "----------------------------------------"
else
    echo "No video files with valid duration found in '$TARGET_DIR'."
fi
