#!/bin/bash

input_dir="$1"
output_dir="$2"
depth=""

if [[ "$1" == "--max_depth" ]]; then
  depth="-maxdepth $2"
  input_dir="$3"
  output_dir="$4"
fi

mkdir -p "$output_dir"

find "$input_dir" $depth -type f | while read file
do
  filename=$(basename "$file")
  name="${filename%.*}"
  ext="${filename##*.}"
  [[ "$name" == "$ext" ]] && ext=""

  new_name="$filename"
  count=1
  while [[ -e "$output_dir/$new_name" ]]
  do
    new_name="${name}${count}"
    [[ -n "$ext" ]] && new_name="$new_name.$ext"
    ((count++))
  done

  cp "$file" "$output_dir/$new_name"
done
