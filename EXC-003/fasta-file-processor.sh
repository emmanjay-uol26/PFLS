#for $1= .fasta (fna) file
echo $"FASTA File Statistics":
echo $"----------------------"
    num_seq=$(grep ">" $1 | wc -l)
echo $"Number of sequences":$num_seq

    total_len=$(awk '/^>/ {next} {sum+= length} END {print sum}' $1)
echo $"Total length of sequences":$total_len

    length_of_the_longest_sequence=$(awk '/^>/ {if (seqlen > max) {max = seqlen; name = prev}; seqlen = 0; prev = $0; next} {seqlen += length($0)} END {if (seqlen > max) {max = seqlen; name = prev}; print "\nLength:", max}' $1)
echo $"Length of the longest sequence":$length_of_the_longest_sequence

    length_of_the_shortest_sequence=$(awk '/^>/ {if (seqlen > 0 && (min == 0 || seqlen < min)) min = seqlen; seqlen = 0; next} {seqlen += length($0)} END {if (seqlen > 0 && (seqlen < min || min == 0)) min = seqlen; print min}' $1)
echo $"Length of the shortest sequence":$length_of_the_shortest_sequence

    avg=$(awk '/^>/ {count++} !/^>/ {sum += length($0)} END {print sum/count}' $1)
echo $"Average sequence length":$avg

    gc_perc=$(grep -v "^>" $1) | awk '{total += length($0); gc += gsub(/[GCgc]/, "", $0)} END {if (total > 0) printf "GC Content (%): %.2f%%\n", (gc / total) * 100}' $1
