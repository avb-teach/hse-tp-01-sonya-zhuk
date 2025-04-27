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

# Collect files
mapfile -t all_files < <(find "$INPUT_DIR" -type f)

generate_unique_name() {
  local dir="$1" name ext base candidate counter=1
  base="$2"
  name="${base%.*}"
  ext="${base##*.}"
  if [[ "$name" == "$ext" ]]; then ext=""; else ext=".$ext"; fi
  candidate="$name$ext"
  while [[ -e "$dir/$candidate" ]]; do
    candidate="${name}(${counter})${ext}"
    ((counter++))
  done
  echo "$candidate"
}

count=0

for src in "${all_files[@]}"; do
  # relative path without leading slash
  rel="${src#${INPUT_DIR}/}"
  if [[ -n "${MAX_DEPTH:-}" ]]; then
    IFS='/' read -r -a parts <<< "$rel"
    n=${#parts[@]}
    if (( n <= MAX_DEPTH )); then
      dest_rel="$rel"
    else
      start=$((MAX_DEPTH-1))
      dest_rel="$(IFS=/; echo "${parts[@]:start}")"
    fi
    dest_dir="$OUTPUT_DIR/$(dirname "$dest_rel")"
    base_name="$(basename "$dest_rel")"
    mkdir -p "$dest_dir"
  else
    dest_dir="$OUTPUT_DIR"
    base_name="$(basename "$rel")"
  fi
  uniq_name=$(generate_unique_name "$dest_dir" "$base_name")
  cp -- "$src" "$dest_dir/$uniq_name"
  ((count++))
done

echo "Copied $count files from '$INPUT_DIR' to '$OUTPUT_DIR'"
