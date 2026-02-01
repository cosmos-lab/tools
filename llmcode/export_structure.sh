#!/bin/bash

# Usage:
# ./export_structure.sh <input_dirs> <ignore_dirs> <output_file>
#
# Example:
# ./export_structure.sh "src,config" "node_modules,.git" structure.txt

INPUT_DIRS="$1"
IGNORE_DIRS="$2"
OUTPUT_FILE="$3"

if [[ -z "$INPUT_DIRS" || -z "$OUTPUT_FILE" ]]; then
    echo "Usage: $0 <input_dirs> <ignore_dirs> <output_file>"
    exit 1
fi

# Parse input directories
IFS=',' read -ra SRC_DIRS <<< "$INPUT_DIRS"

# Parse ignore directories
IFS=',' read -ra IGNORES <<< "$IGNORE_DIRS"

should_ignore() {
    local path="$1"
    for ignore in "${IGNORES[@]}"; do
        [[ -n "$ignore" && "$path" == *"/$ignore"* ]] && return 0
    done
    return 1
}

print_tree() {
    local dir="$1"
    local indent="$2"

    should_ignore "$dir" && return

    local base
    base=$(basename "$dir")

    echo "${indent}${base}" >> "$OUTPUT_FILE"

    local item
    for item in "$dir"/*; do
        [[ ! -e "$item" ]] && continue
        should_ignore "$item" && continue

        if [[ -d "$item" ]]; then
            print_tree "$item" "  $indent"
        else
            echo "${indent}  $(basename "$item")" >> "$OUTPUT_FILE"
        fi
    done
}

# Empty output file
> "$OUTPUT_FILE"

for SRC_DIR in "${SRC_DIRS[@]}"; do
    if [[ -d "$SRC_DIR" ]]; then
        print_tree "$SRC_DIR" ""
    else
        echo "Warning: '$SRC_DIR' is not a directory, skipping."
    fi
done

echo "Directory structure exported → '$OUTPUT_FILE'"
