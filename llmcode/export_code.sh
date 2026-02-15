#!/bin/bash

INPUT_DIRS="$1"
INCLUDE_FILES="$2"
IGNORE_DIRS="$3"
IGNORE_FILES="$4"
OUTPUT_FILE="$5"
SEPARATOR="###__FILE_SEPARATOR__###"

if [[ -z "$INPUT_DIRS" || -z "$OUTPUT_FILE" ]]; then
    echo "Usage: $0 <input_dirs> <include_files> <ignore_dirs> <ignore_files> <output_file>"
    exit 1
fi

IFS=',' read -ra SRC_DIRS <<< "$INPUT_DIRS"
IFS=',' read -ra EXTRA_FILES <<< "$INCLUDE_FILES"
IFS=',' read -ra DIRS <<< "$IGNORE_DIRS"
IFS=',' read -ra FILES <<< "$IGNORE_FILES"

# Empty output
> "$OUTPUT_FILE"

# Build prune args (dirs + files)
PRUNE_ARGS=()

# Ignore directories
for dir in "${DIRS[@]}"; do
    [[ -z "$dir" ]] && continue
    CLEAN_DIR=$(echo "$dir" | sed 's|^\./||')
    PRUNE_ARGS+=(-path "*/$CLEAN_DIR" -o -path "*/$CLEAN_DIR/*" -o)
done

# Ignore files (FULL PATH SUPPORT)
for file in "${FILES[@]}"; do
    [[ -z "$file" ]] && continue
    CLEAN_FILE=$(echo "$file" | sed 's|^\./||')
    PRUNE_ARGS+=(-path "*/$CLEAN_FILE" -o)
done

# Remove last -o
if [[ ${#PRUNE_ARGS[@]} -gt 0 ]]; then
    unset 'PRUNE_ARGS[${#PRUNE_ARGS[@]}-1]'
fi

# Export files
for SRC_DIR in "${SRC_DIRS[@]}"; do
    [[ ! -d "$SRC_DIR" ]] && continue

    if [[ ${#PRUNE_ARGS[@]} -gt 0 ]]; then
        find "$SRC_DIR" \
        \( "${PRUNE_ARGS[@]}" \) -prune -o \
        -type f -print
    else
        find "$SRC_DIR" -type f -print
    fi
done | sort -u | while read -r FILE; do
    echo "$SEPARATOR $FILE" >> "$OUTPUT_FILE"
    cat "$FILE" >> "$OUTPUT_FILE"
    echo -e "\n" >> "$OUTPUT_FILE"
done

# Include extra files
for FILE in "${EXTRA_FILES[@]}"; do
    if [[ -f "$FILE" ]]; then
        echo "$SEPARATOR $FILE" >> "$OUTPUT_FILE"
        cat "$FILE" >> "$OUTPUT_FILE"
        echo -e "\n" >> "$OUTPUT_FILE"
    fi
done

cat <<EOF >> "$OUTPUT_FILE"

INSTRUCTIONS

- Each file starts with:
  $SEPARATOR <file_path>

Do NOT modify separator lines.

EOF

echo "Export completed → '$OUTPUT_FILE'"
