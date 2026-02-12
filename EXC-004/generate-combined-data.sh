#!/bin/bash
# ==============================================================================
# SCRIPT: generated-combined-data.sh
# DESCRIPTION: Processes DNA bins from RAW-DATA, renames them using a 
#              translation file, and classifies them as MAG or BIN based 
#              on CheckM stats.
#
# USAGE: 
#   1. Place this script in the directory containing the 'RAW-DATA' folder.
#   2. Ensure 'RAW-DATA' contains 'sample-translation.txt' and sample folders.
#   3. Make executable: chmod +x process_dna.sh
#   4. Run: ./process_dna.sh
# ==============================================================================

shopt -s nullglob

# --- HELP FLAG ---
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    sed -n '3,14p' "$0" # Prints the header lines above
    exit 0
fi

# --- CONFIGURATION ---
RAW_DATA="RAW-DATA"
COMBINED_DATA="COMBINED-DATA"

# 1. Validation
if [ ! -d "$RAW_DATA" ]; then
    echo "ERROR: Directory '$RAW_DATA' not found. Please run this script in the parent folder of RAW-DATA."
    exit 1
fi

TRANS_FILE=$(find "$RAW_DATA" -maxdepth 1 -iname "sample-translation.txt" | head -n 1)

if [ -z "$TRANS_FILE" ]; then
    echo "ERROR: Could not find 'sample-translation.txt' in $RAW_DATA"
    exit 1
fi

mkdir -p "$COMBINED_DATA"
echo "Starting processing at $(date)"
echo "Translation file: $TRANS_FILE"

# 2. Processing Loop
for DNA_PATH in "$RAW_DATA"/*/; do
    SAMPLE_ID=$(basename "$DNA_PATH")
    
    # Skip non-sample folders if necessary
    [[ "$SAMPLE_ID" == "EXC-004" ]] && continue

    CULTURE_NAME=$(awk -v id="$SAMPLE_ID" '$1 == id {print $2}' "$TRANS_FILE")
    
    if [ -z "$CULTURE_NAME" ]; then
        echo "  (!) Skipping $SAMPLE_ID: No entry in translation file."
        continue
    fi

    echo "--- Processing Sample: $SAMPLE_ID ($CULTURE_NAME) ---"

    BINS_DIR="${DNA_PATH}bins"
    if [ ! -d "$BINS_DIR" ]; then
        echo "  (!) Error: 'bins' directory not found in $DNA_PATH"
        continue
    fi

    # Handle UNBINNED file
    UNBINNED_FILE="$BINS_DIR/bin-unbinned.fasta"
    if [ -f "$UNBINNED_FILE" ]; then
        cp "$UNBINNED_FILE" "$COMBINED_DATA/${CULTURE_NAME}_UNBINNED.fa"
    fi

    # Process Bins (FASTA/FA)
    COUNTER=1
    for BIN_FILE in "$BINS_DIR"/*.{fasta,fa}; do
        [[ "$BIN_FILE" == *"bin-unbinned.fasta" ]] && continue
        
        BIN_ID=$(basename "$BIN_FILE" .fasta)
        BIN_ID=$(basename "$BIN_ID" .fa)
        
        CHECKM_FILE="${DNA_PATH}checkm.txt"
        
        # Checkm extraction
        STATS=$(awk -v bin="$BIN_ID" '$1 == bin {printf "%d %d", $12, $13}' "$CHECKM_FILE" 2>/dev/null)
        COMPLETION=$(echo ${STATS:-0 0} | cut -d' ' -f1)
        CONTAMINATION=$(echo ${STATS:-0 0} | cut -d' ' -f2)

        # MAG vs BIN classification
        if [ "$COMPLETION" -ge 50 ] && [ "$CONTAMINATION" -lt 5 ]; then
            TYPE="MAG"
        else
            TYPE="BIN"
        fi

        NEW_NAME="${CULTURE_NAME}_${TYPE}_$(printf "%03d" $COUNTER).fa"
        cp "$BIN_FILE" "$COMBINED_DATA/$NEW_NAME"
        ((COUNTER++))
    done
    echo "  Completed $SAMPLE_ID: $((COUNTER-1)) bins processed."
done

echo "------------------------------------------"
echo "Script Complete. Files are in: [$(pwd)/$COMBINED_DATA]"
