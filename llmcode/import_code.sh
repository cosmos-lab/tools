#!/bin/bash

COMBINED_FILE="$1"
OUTPUT_DIR="$2"
SEPARATOR="###__FILE_SEPARATOR__###"

if [[ -z "$COMBINED_FILE" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <combined_file> <output_dir>"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

current_file=""

while IFS= read -r line || [[ -n "$line" ]]; do
    # Trim leading whitespace
    trimmed_line="$(echo "$line" | sed 's/^[[:space:]]*//')"

    if [[ "$trimmed_line" == $SEPARATOR* ]]; then
        # Close previous file descriptor
        if [[ -n "$current_file" ]]; then
            exec 3>&-
        fi

        file_path="${trimmed_line#$SEPARATOR }"
        current_file="$OUTPUT_DIR/$file_path"

        mkdir -p "$(dirname "$current_file")"
        exec 3>"$current_file"
    else
        if [[ -n "$current_file" ]]; then
            echo "$line" >&3
        fi
    fi
done < "$COMBINED_FILE"

# Close last file
if [[ -n "$current_file" ]]; then
    exec 3>&-
fi

echo "Imported files to '$OUTPUT_DIR'."
