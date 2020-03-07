#!/bin/bash

FILELIST=$(find . -type f -name "*.csv")

for file in $FILELIST
do
  iconv --from-code='ISO_8859-1' --to-code='UTF-8' "$file" | sponge "$file"
done

