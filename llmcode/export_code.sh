#!/bin/bash

# Usage:
# ./export_code.sh ml-inferences-advanced/rag-ocr-pipeline/ output.txt __pycache__


SRC_DIR="$1"
OUTPUT_FILE="$2"
IGNORE_DIRS="$3"
SEPARATOR="###__FILE_SEPARATOR__###"

if [[ -z "$SRC_DIR" || -z "$OUTPUT_FILE" ]]; then
    echo "Usage: $0 <source_dir> <output_file> [ignore_dirs_comma_separated]"
    exit 1
fi

# Build find prune expression for ignored dirs
PRUNE_EXPR=""
if [[ -n "$IGNORE_DIRS" ]]; then
    IFS=',' read -ra DIRS <<< "$IGNORE_DIRS"
    for dir in "${DIRS[@]}"; do
        PRUNE_EXPR+=" -path */$dir/* -prune -o"
    done
fi

# Empty the output file
> "$OUTPUT_FILE"

# Use eval to allow dynamic prune expression
eval find "\"$SRC_DIR\"" \
    $PRUNE_EXPR \
    -type f -print | while read -r FILE; do

    echo "$SEPARATOR $FILE" >> "$OUTPUT_FILE"
    cat "$FILE" >> "$OUTPUT_FILE"
    echo -e "\n" >> "$OUTPUT_FILE"

done

# Footer instructions (NO separator used here)
cat <<EOF >> "$OUTPUT_FILE"

INSTRUCTIONS

- This file contains the full source code combined into a single file.
- Each source file is preceded by a separator line in the following format:

    $SEPARATOR <relative_file_path>

- You may modify the code freely, BUT:
    - Do NOT remove or alter any separator lines
    - Do NOT change file paths in the separator lines
    - Do NOT add extra text before or between separator blocks

- After making changes, return the file in the EXACT same format.
- This format is required so the import script can correctly reconstruct
  the original directory structure and files.

IMPORTANT: Return the entire content as a single continuous file.
Do not divide the output into multiple code blocks, messages, or segments.
Any splitting will break the import process.

EOF


echo "Exported all files from '$SRC_DIR' to '$OUTPUT_FILE'."
