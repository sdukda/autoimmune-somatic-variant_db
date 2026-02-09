BEGIN {
  OFS = "\t"
  print "chrom","pos","ref","alt"
}

NF >= 2 {
  loc = $1          # e.g. chr4:3013742-3013743
  alle = $2         # e.g. CA>C

  split(loc, a, ":")
  chrom = a[1]
  pos   = a[2]      # keep as "3013742-3013743" if it's a range

  split(alle, b, ">")
  ref = b[1]
  alt = b[2]

  print chrom, pos, ref, alt
}
