BEGIN { OFS="\t"; print "chrom","pos","ref","alt" }

{
  line=$0
  gsub(/[[:space:]]+/, "", line)   # remove any spaces just in case

  # Match: chr...:g.<pos><ref>><alt>
  if (match(line, /^(chr[^:]+):g\.([0-9]+)([ACGTN]+)>([ACGTN]+)$/, m)) {
    print m[1], m[2], m[3], m[4]
  }
}
