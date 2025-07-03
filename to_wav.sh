
#!/bin/bash

# Script to convert all MP3 files in a directory to WAV format using ffmpeg

# --- Configuration ---
# Set to 1 to enable verbose output from ffmpeg, 0 to keep it quieter
FFMPEG_VERBOSE=0

# --- Helper Functions ---
# Function to display usage instructions
usage() {
  echo "Usage: $0 [directory_path]"
  echo "Converts all .mp3 files in the specified directory (or current directory if none provided) to .wav format."
  echo "Requires ffmpeg to be installed and in your PATH."
  exit 1
}

# Function to check if ffmpeg is installed
check_ffmpeg() {
  if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed or not found in your PATH."
    echo "Please install ffmpeg to use this script."
    exit 1
  fi
}

# --- Main Script Logic ---

# Check if ffmpeg is installed
check_ffmpeg

# Determine the target directory
TARGET_DIR="." # Default to current directory
if [ -n "$1" ]; then
  if [ -d "$1" ]; then
    TARGET_DIR="$1"
    echo "Target directory set to: $TARGET_DIR"
  else
    echo "Error: Directory '$1' not found."
    usage
  fi
elif [ "$#" -gt 1 ]; then # Too many arguments
    echo "Error: Too many arguments."
    usage
fi

# Navigate to the target directory to handle relative paths correctly
# and avoid issues with spaces in directory names passed to find
cd "$TARGET_DIR" || { echo "Error: Could not change to directory '$TARGET_DIR'."; exit 1; }
# Get the absolute path for clearer messages
ABS_TARGET_DIR=$(pwd)
echo "Processing MP3 files in: $ABS_TARGET_DIR"

# Find and convert MP3 files
# Using find and a while loop to handle filenames with spaces or special characters
# -maxdepth 1 ensures we only process files in the immediate directory, not subdirectories.
# Remove -maxdepth 1 if you want to process subdirectories recursively.
find . -maxdepth 1 -type f -iname "*.mp3" -print0 | while IFS= read -r -d $'\0' mp3_file; do
  # Get the filename without the path and extension
  base_name_with_path="${mp3_file%.*}" # Removes .mp3 extension
  base_name="${base_name_with_path##*/}" # Removes path if any (should be just ./ here)

  # Construct the output WAV filename
  wav_file="./${base_name}.wav" # Output in the same directory

  echo "----------------------------------------"
  echo "Input MP3: $ABS_TARGET_DIR/${mp3_file#./}"
  echo "Output WAV: $ABS_TARGET_DIR/${wav_file#./}"

  # Check if WAV file already exists
  if [ -f "$wav_file" ]; then
    echo "Skipping: WAV file '$wav_file' already exists."
    continue # Skip to the next file
  fi

  # Perform the conversion
  echo "Converting '${mp3_file#./}' to '${wav_file#./}'..."
  if [ "$FFMPEG_VERBOSE" -eq 1 ]; then
    ffmpeg -i "$mp3_file" "$wav_file"
  else
    ffmpeg -i "$mp3_file" "$wav_file" -loglevel error -stats # Show progress but hide verbose logs unless error
  fi

  if [ $? -eq 0 ]; then
    echo "Successfully converted: ${wav_file#./}"
  else
    echo "Error converting: ${mp3_file#./}. Check ffmpeg output above."
  fi
done

echo "----------------------------------------"
echo "MP3 to WAV conversion process complete for directory: $ABS_TARGET_DIR"

# Optional: Navigate back to the original directory if needed
# cd - > /dev/null
