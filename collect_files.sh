#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() {
  echo "Usage: $0 <input_dir> <output_dir> [--max_depth N]"
  exit 1
}

if [[ $# -eq 2 ]]; then
  INPUT_DIR=$1
  OUTPUT_DIR=$2
  MAX_DEPTH=
elif [[ $# -eq 4 && $3 == "--max_depth" && $4 =~ ^[0-9]+$ ]]; then
  INPUT_DIR=$1
  OUTPUT_DIR=$2
  MAX_DEPTH=$4
else
  usage
fi

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Error: input directory '$INPUT_DIR' not found"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

if [[ -n "${MAX_DEPTH:-}" ]]; then
  mapfile -t all_files < <(find "$INPUT_DIR" -maxdepth "$MAX_DEPTH" -type f)
else
  mapfile -t all_files < <(find "$INPUT_DIR" -type f)
fi

generate_unique_name() {
  local dest_dir="$1" base_name="$2"
  local name ext candidate counter=1
  name="${base_name%.*}"
  ext="${base_name##*.}"
  if [[ "$name" == "$ext" ]]; then
    ext=""
  else
    ext=".$ext"
  fi
  candidate="$name$ext"
  while [[ -e "$dest_dir/$candidate" ]]; do
    candidate="${name}(${counter})${ext}"
    ((counter++))
  done
  echo "$candidate"
}

for src in "${all_files[@]}"; do
  fname=$(basename -- "$src")
  uname=$(generate_unique_name "$OUTPUT_DIR" "$fname")
  cp -- "$src" "$OUTPUT_DIR/$uname"
done

echo "Copied ${#all_files[@]} files from '$INPUT_DIR' to '$OUTPUT_DIR'"
