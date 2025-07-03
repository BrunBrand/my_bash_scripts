
#!/bin/bash

# Script to decompress files into their respective named folders.
# Each compressed file found in the target directory will be extracted
# into a new sub-folder named after the compressed file (without its extension).

# --- Helper function to check for command existence ---
# Arguments:
#   $1: The command name to check (e.g., "unzip")
# Returns:
#   0 if the command is found, 1 otherwise.
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "  Error: Required command '$1' not found."
        # Provide hints for common package managers
        case "$1" in
            unzip) echo "  Try: sudo apt install unzip  OR  sudo yum install unzip  OR  brew install unzip";;
            tar)   echo "  'tar' is usually pre-installed. If not, check your distribution's package manager.";;
            unrar) echo "  Try: sudo apt install unrar  OR  sudo yum install unrar  OR  brew install unrar (non-free)";;
            unar)  echo "  Try: sudo apt install unar   OR  sudo yum install unar   OR  brew install unar (free alternative to unrar)";;
        esac
        return 1
    fi
    return 0
}

# --- Main Script ---

# Check if a directory argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <directory_path>"
  echo "Example: $0 /path/to/your/archives"
  echo "Or:      $0 ./my_compressed_files"
  exit 1
fi

TARGET_DIR_ARG="$1"

# Check if the provided argument is a directory
if [ ! -d "$TARGET_DIR_ARG" ]; then
  echo "Error: '$TARGET_DIR_ARG' is not a valid directory."
  exit 1
fi

# Attempt to resolve to an absolute path for robustness
# 'cd' into the directory and 'pwd' to get its absolute path.
# This handles relative paths (e.g., ".", "..", "myfolder") correctly.
TARGET_DIR_ABS="$(cd "$TARGET_DIR_ARG" && pwd)"
if [ $? -ne 0 ] || [ -z "$TARGET_DIR_ABS" ]; then
    echo "Error: Could not resolve absolute path for '$TARGET_DIR_ARG'."
    exit 1
fi

echo "Scanning directory: '$TARGET_DIR_ABS'"
echo "----------------------------------------"

found_compressed_files=false # Flag to track if any compressed files are processed

# Find and process compressed files directly within the target directory.
# -maxdepth 1: Prevents find from descending into subdirectories of TARGET_DIR_ABS.
# -type f:     Ensures only regular files are processed (not directories, links, etc.).
# -name "*.ext": Matches files with the specified extensions.
# -print0:     Prints filenames separated by a null character.
# while IFS= read -r -d $'\0': Reads null-separated filenames safely,
#                               handling spaces, newlines, or other special characters in filenames.
find "$TARGET_DIR_ABS" -maxdepth 1 -type f \( \
    -name "*.zip" -o \
    -name "*.tar.gz" -o \
    -name "*.tgz" -o \
    -name "*.tar.bz2" -o \
    -name "*.tbz2" -o \
    -name "*.tar" -o \
    -name "*.rar" \
\) -print0 | while IFS= read -r -d $'\0' file_path; do
    found_compressed_files=true
    filename=$(basename -- "$file_path") # Extracts filename from full path (e.g., "archive.zip")
    
    # Determine the folder name from the filename, removing the compression extension.
    # Handles simple extensions (e.g., .zip) and compound extensions (e.g., .tar.gz).
    if [[ "$filename" == *.tar.gz ]]; then
        foldername="${filename%.tar.gz}"
    elif [[ "$filename" == *.tar.bz2 ]]; then
        foldername="${filename%.tar.bz2}"
    elif [[ "$filename" == *.tgz ]]; then # .tgz is a common shorthand for .tar.gz
        foldername="${filename%.tgz}"
    elif [[ "$filename" == *.tbz2 ]]; then # .tbz2 is a common shorthand for .tar.bz2
        foldername="${filename%.tbz2}"
    else
        # For single extensions like .zip, .tar, .rar
        foldername="${filename%.*}"
    fi

    # Define the full path for the new directory where files will be extracted.
    extraction_folder="$TARGET_DIR_ABS/$foldername"

    echo "Processing: $filename"

    # Create the extraction folder if it doesn't already exist.
    # mkdir -p creates parent directories as needed and doesn't error if the directory exists.
    if [ -d "$extraction_folder" ]; then
        echo "  Info: Extraction folder '$extraction_folder' already exists."
        # Current behavior: Will attempt to extract into the existing folder.
        # Extraction tools (unzip, tar) might overwrite files or skip, depending on their defaults.
    else
        echo "  Creating extraction folder: $extraction_folder"
        mkdir -p "$extraction_folder"
        if [ $? -ne 0 ]; then
            echo "  Error: Could not create folder '$extraction_folder'. Skipping '$filename'."
            continue # Move to the next compressed file
        fi
    fi

    echo "  Extracting '$filename' into '$extraction_folder'..."
    extraction_successful=false # Flag for the current file's extraction status

    # Determine the type of archive and use the appropriate command to extract.
    case "$filename" in
        *.zip)
            if check_command "unzip"; then
                unzip -q "$file_path" -d "$extraction_folder" && extraction_successful=true
                # -q: quiet mode
                # -d: specify output directory
            fi
            ;;
        *.tar.gz|*.tgz)
            if check_command "tar"; then
                tar -xzf "$file_path" -C "$extraction_folder" && extraction_successful=true
                # -x: extract
                # -z: filter through gzip (for .gz)
                # -f: use archive file
                # -C: change to directory before extracting
            fi
            ;;
        *.tar.bz2|*.tbz2)
            if check_command "tar"; then
                tar -xjf "$file_path" -C "$extraction_folder" && extraction_successful=true
                # -j: filter through bzip2 (for .bz2)
            fi
            ;;
        *.tar)
            if check_command "tar"; then
                tar -xf "$file_path" -C "$extraction_folder" && extraction_successful=true
            fi
            ;;
        *.rar)
            # Try 'unrar' first, then 'unar' as a free alternative.
            if check_command "unrar"; then
                unrar x -o+ "$file_path" "$extraction_folder/" && extraction_successful=true
                # x: extract with full paths
                # -o+: overwrite existing files without prompting
                # Trailing slash on destination is good practice for unrar.
            elif check_command "unar"; then
                echo "  Info: 'unrar' not found. Using 'unar' for '$filename'."
                unar -q -o "$extraction_folder" "$file_path" && extraction_successful=true
                # -q: quiet mode
                # -o: specify output directory
            else
                # Error message already printed by check_command if both are missing.
                # We simply don't set extraction_successful to true.
                : # No operation, error already handled by check_command
            fi
            ;;
        *)
            # This case should ideally not be reached due to the 'find' command's specific -name patterns.
            # It's a fallback for any unexpected matches.
            echo "  Warning: Unknown or unhandled compression type for '$filename'. Skipping."
            continue # Move to the next file
            ;;
    esac

    if $extraction_successful; then
        echo "  Successfully extracted '$filename'."
    else
        # An error message would have been printed by the failing command or check_command.
        echo "  Error: Failed to extract '$filename'."
        # Optional: Clean up the created folder if extraction failed and the folder is empty.
        # if [ -d "$extraction_folder" ] && [ ! "$(ls -A "$extraction_folder")" ]; then
        #     echo "  Cleaning up empty or partially created extraction folder: $extraction_folder"
        #     rm -r "$extraction_folder"
        # fi
    fi
    echo "----------------------------------------"
done

# After the loop, check if any compressed files were found and processed.
if ! $found_compressed_files; then
    echo "No compressed files found in '$TARGET_DIR_ABS' matching the recognized patterns (.zip, .tar.gz, .tgz, .tar.bz2, .tbz2, .tar, .rar)."
fi

echo "Decompression process finished."
