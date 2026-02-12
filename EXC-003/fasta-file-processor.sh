#!/bin/bash
# USAGE: ./script.sh your_file.fasta

# Ensure a file was provided
[[ -z "$1" ]] && { echo "Usage: $0 <fasta_file>"; exit 1; }

echo "FASTA File Statistics for: $1"
echo "----------------------"

# 1. Number of sequences
num_seq=$(grep -c ">" "$1")
echo "Number of sequences: $num_seq"

# 2. Total length
total_len=$(awk '/^>/ {next} {sum+= length($0)} END {print sum}' "$1")
echo "Total length of sequences: $total_len"

# 3. Longest sequence
max_len=$(awk '/^>/ {if (seqlen > max) max = seqlen; seqlen = 0; next} {seqlen += length($0)} END {if (seqlen > max) max = seqlen; print max}' "$1")
echo "Length of the longest sequence: $max_len"

# 4. Shortest sequence (Fixing logic to handle first sequence)
min_len=$(awk '/^>/ {if (seqlen > 0 && (min == 0 || seqlen < min)) min = seqlen; seqlen = 0; next} {seqlen += length($0)} END {if (seqlen > 0 && (seqlen < min || min == 0)) min = seqlen; print min}' "$1")
echo "Length of the shortest sequence: $min_len"

# 5. Average sequence length
avg=$(awk -v n="$num_seq" '/^>/ {next} {sum += length($0)} END {if (n>0) print sum/n; else print 0}' "$1")
echo "Average sequence length: $avg"

# 6. GC Content (Fixed the pipe/parentheses error)
echo -n "GC Content (%): "
grep -v "^>" "$1" | awk '{total += length($0); gc += gsub(/[GCgc]/, "", $0)} END {if (total > 0) printf "%.2f%%\n", (gc / total) * 100}'
