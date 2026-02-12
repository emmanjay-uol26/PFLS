#!/bin/bash
shopt -s nullglob

# Define paths
RAW_DATA="RAW-DATA"
COMBINED_DATA="COMBINED-DATA"

# 1. Check if RAW-DATA exists
if [ ! -d "$RAW_DATA" ]; then
    echo "ERROR: Directory '$RAW_DATA' not found."
    exit 1
fi

# 2. FIND MASTER TRANSLATION FILE (Look inside RAW-DATA)
# This finds the file once so we can use it for all samples
TRANS_FILE=$(find "$RAW_DATA" -maxdepth 1 -iname "sample-translation.txt" | head -n 1)

if [ -z "$TRANS_FILE" ]; then
    echo "ERROR: Could not find master sample-translation.txt in $RAW_DATA"
    exit 1
fi

echo "Using translation file: $TRANS_FILE"
mkdir -p "$COMBINED_DATA"

# 3. Loop through sample directories
for DNA_PATH in "$RAW_DATA"/*/; do
    SAMPLE_ID=$(basename "$DNA_PATH")
    
    # Skip the sample loop if it hits the RAW-DATA/EXC-004 folder (if it's just a subfolder)
    [[ "$SAMPLE_ID" == "EXC-004" ]] && continue

    echo "--- Processing Sample: $SAMPLE_ID ---"

    # Extract culture name from the master file
    CULTURE_NAME=$(awk -v id="$SAMPLE_ID" '$1 == id {print $2}' "$TRANS_FILE")
    
    if [ -z "$CULTURE_NAME" ]; then
        echo "  (!) Warning: $SAMPLE_ID not found in $TRANS_FILE. Skipping."
        continue
    fi
    echo "  Found Culture Name: $CULTURE_NAME"

    # Define bins directory
    BINS_DIR="${DNA_PATH}bins"
    if [ ! -d "$BINS_DIR" ]; then
        echo "  (!) Error: 'bins' directory not found in $DNA_PATH"
        continue
    fi

    # Handle UNBINNED file
    UNBINNED_FILE="$BINS_DIR/bin-unbinned.fasta"
    if [ -f "$UNBINNED_FILE" ]; then
        cp "$UNBINNED_FILE" "$COMBINED_DATA/${CULTURE_NAME}_UNBINNED.fa"
        echo "  Copied: ${CULTURE_NAME}_UNBINNED.fa"
    fi

    # Process other Bins
    COUNTER=1
    for BIN_FILE in "$BINS_DIR"/*.fasta; do
        [[ "$BIN_FILE" == *"bin-unbinned.fasta" ]] && continue
        
        BIN_ID=$(basename "$BIN_FILE" .fasta)
        CHECKM_FILE="${DNA_PATH}checkm.txt"
        
        # Checkm extraction
        STATS=$(awk -v bin="$BIN_ID" '$1 == bin {printf "%d %d", $12, $13}' "$CHECKM_FILE" 2>/dev/null)
        COMPLETION=$(echo ${STATS:-0 0} | cut -d' ' -f1)
        CONTAMINATION=$(echo ${STATS:-0 0} | cut -d' ' -f2)

        if [ "$COMPLETION" -ge 50 ] && [ "$CONTAMINATION" -lt 5 ]; then
            TYPE="MAG"
        else
            TYPE="BIN"
        fi

        NEW_NAME="${CULTURE_NAME}_${TYPE}_$(printf "%03d" $COUNTER).fa"
        cp "$BIN_FILE" "$COMBINED_DATA/$NEW_NAME"
        echo "  Copied: $NEW_NAME"
        ((COUNTER++))
    done
done

echo "Done! Check $COMBINED_DATA for your renamed files."
