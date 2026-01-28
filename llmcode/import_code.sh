#!/bin/bash

# Usage: ./import_code.sh output.txt ./ml-inferences-advanced/test

COMBINED_FILE="$1"
OUTPUT_DIR="$2"
SEPARATOR="###__FILE_SEPARATOR__###"

if [[ -z "$COMBINED_FILE" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <combined_file> <output_dir>"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Read combined file line by line
current_file=""
while IFS= read -r line; do
    if [[ "$line" == $SEPARATOR* ]]; then
        # New file, extract path
        if [[ -n "$current_file" ]]; then
            # Close previous file
            exec 3>&-
        fi
        # Extract relative path
        file_path="${line#$SEPARATOR }"
        current_file="$OUTPUT_DIR/$file_path"
        mkdir -p "$(dirname "$current_file")"
        # Open file for writing
        exec 3>"$current_file"
    else
        # Write line to current file
        if [[ -n "$current_file" ]]; then
            echo "$line" >&3
        fi
    fi
done < "$COMBINED_FILE"

# Close last file
exec 3>&-

echo "Imported files to '$OUTPUT_DIR'."
