#!/bin/bash

# Define paths
BASE_DIR="EXC-004"
RAW_DATA="$BASE_DIR/RAW-DATA"
COMBINED_DATA="$BASE_DIR/COMBINED-DATA"

mkdir -p "$COMBINED_DATA"

echo "Checking RAW-DATA path: $RAW_DATA"

# Loop through each DNA sample directory
for DNA_PATH in "$RAW_DATA"/*/; do
    
    # Skip if no folders are found
    [ -e "$DNA_PATH" ] || { echo "No folders found in $RAW_DATA"; break; }

    SAMPLE_ID=$(basename "$DNA_PATH")
    echo "--- Processing Sample: $SAMPLE_ID ---"

    # Find the translation file (looking for any case)
    TRANS_FILE=$(find "$DNA_PATH" -maxdepth 1 -iname "sample-translation.txt" | head -n 1)
    
    if [ -z "$TRANS_FILE" ]; then
        echo "  (!) Error: sample-translation.txt not found in $DNA_PATH"
        continue
    fi

    # Extract culture name
    CULTURE_NAME=$(awk -v id="$SAMPLE_ID" '$1 == id {print $2}' "$TRANS_FILE")
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
        [ -e "$BIN_FILE" ] || continue
        [[ "$BIN_FILE" == *"bin-unbinned.fasta" ]] && continue
        
        BIN_ID=$(basename "$BIN_FILE" .fasta)
        
        # Checkm stats
        CHECKM_FILE="${DNA_PATH}checkm.txt"
        STATS=$(awk -v bin="$BIN_ID" '$1 == bin {printf "%d %d", $12, $13}' "$CHECKM_FILE" 2>/dev/null)
        
        COMPLETION=$(echo ${STATS:-0 0} | cut -d' ' -f1)
        CONTAMINATION=$(echo ${STATS:-0 0} | cut -d' ' -f2)

        if [ "$COMPLETION" -ge 50 ] && [ "$CONTAMINATION" -lt 5 ]; then
            TYPE="MAG"
        else
            TYPE="BIN"
        fi

        SEQ_NUM=$(printf "%03d" $COUNTER)
        NEW_NAME="${CULTURE_NAME}_${TYPE}_${SEQ_NUM}.fa"
        
        cp "$BIN_FILE" "$COMBINED_DATA/$NEW_NAME"
        echo "  Copied: $NEW_NAME"
        
        ((COUNTER++))
    done
done

echo "Script Complete. Check $COMBINED_DATA now."

