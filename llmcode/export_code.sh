#!/bin/bash

# Usage:
# ./export_code.sh <input_dirs> <include_files> <ignore_dirs> <output_file>
#

INPUT_DIRS="$1"
INCLUDE_FILES="$2"
IGNORE_DIRS="$3"
OUTPUT_FILE="$4"
SEPARATOR="###__FILE_SEPARATOR__###"

if [[ -z "$INPUT_DIRS" || -z "$OUTPUT_FILE" ]]; then
    echo "Usage: $0 <input_dirs> <include_files> <ignore_dirs> <output_file>"
    exit 1
fi

# Parse input directories
IFS=',' read -ra SRC_DIRS <<< "$INPUT_DIRS"

# Parse manually included files
IFS=',' read -ra EXTRA_FILES <<< "$INCLUDE_FILES"

# Prepare ignore arguments safely
FIND_IGNORE_ARGS=()
if [[ -n "$IGNORE_DIRS" ]]; then
    IFS=',' read -ra DIRS <<< "$IGNORE_DIRS"
    for dir in "${DIRS[@]}"; do
        FIND_IGNORE_ARGS+=(-path "*/$dir" -o -path "*/$dir/*")
    done
fi

# Empty output file
> "$OUTPUT_FILE"

# Export files from input directories
for SRC_DIR in "${SRC_DIRS[@]}"; do
    if [[ ! -d "$SRC_DIR" ]]; then
        echo "Warning: '$SRC_DIR' is not a directory, skipping."
        continue
    fi

    if [[ ${#FIND_IGNORE_ARGS[@]} -gt 0 ]]; then
        find "$SRC_DIR" \( "${FIND_IGNORE_ARGS[@]}" \) -prune -o -type f -print
    else
        find "$SRC_DIR" -type f -print
    fi
done | sort -u | while read -r FILE; do
    echo "$SEPARATOR $FILE" >> "$OUTPUT_FILE"
    cat "$FILE" >> "$OUTPUT_FILE"
    echo -e "\n" >> "$OUTPUT_FILE"
done

# Export manually included files
for FILE in "${EXTRA_FILES[@]}"; do
    if [[ -f "$FILE" ]]; then
        echo "$SEPARATOR $FILE" >> "$OUTPUT_FILE"
        cat "$FILE" >> "$OUTPUT_FILE"
        echo -e "\n" >> "$OUTPUT_FILE"
    else
        echo "Warning: include file '$FILE' not found, skipping."
    fi
done

# Footer instructions (NO separator here)
cat <<EOF >> "$OUTPUT_FILE"

INSTRUCTIONS

- This file contains the full source code combined into a single file.
- Each source file is preceded by a separator line in the following format:

    $SEPARATOR <file_path>

- You may modify the code freely, BUT:
    - Do NOT remove or alter any separator lines
    - Do NOT change file paths in the separator lines
    - Do NOT add extra text before or between separator blocks

- After making changes, return the file in the EXACT same format.
- This format is required so the import script can correctly reconstruct
  the original directory structure and files.

IMPORTANT:
Return the entire content as a single continuous code block seprated by ###__FILE_SEPARATOR__### for a single copy 
Do NOT divide the output into multiple code blocks, messages, or segments.

EOF

echo "Export completed → '$OUTPUT_FILE'"
