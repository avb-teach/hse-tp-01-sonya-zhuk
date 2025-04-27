#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 [--max_depth N] INPUT_DIR OUTPUT_DIR" >&2
  exit 1
}

MAX_DEPTH=0

if [[ "${1:-}" == "--max_depth" ]]; then
  if [[ $# -lt 3 ]]; then
    echo "Error: --max_depth requires a numeric argument and two dirs" >&2
    usage
  fi
  shift
  if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Error: max_depth must be a non-negative integer" >&2
    usage
  fi
  MAX_DEPTH="$1"
  shift
fi

if [[ $# -ne 2 ]]; then
  usage
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Error: input dir '$INPUT_DIR' not found or not a directory" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

declare -A name_counts

while IFS= read -r -d '' FILE; do
  rel="${FILE#$INPUT_DIR/}"
  dirpath=$(dirname "$rel")
  base=$(basename "$rel")

  if (( MAX_DEPTH > 0 )); then
    IFS='/' read -r -a parts <<< "$dirpath"
    newpath=""
    for ((i=0; i<${#parts[@]} && i<MAX_DEPTH; i++)); do
      newpath="$newpath/${parts[i]}"
    done
    newpath="${newpath#/}"
    dest_dir="$OUTPUT_DIR/$newpath"
  else
    dest_dir="$OUTPUT_DIR"
  fi

  mkdir -p "$dest_dir"

  if [[ -n "${name_counts[$base]:-}" ]]; then
    count=$(( name_counts[$base] + 1 ))
    name_counts[$base]=$count
    ext="${base##*.}"
    name="${base%.*}"
    if [[ "$ext" == "$base" ]]; then
      newname="${name}_${count}"
    else
      newname="${name}_${count}.${ext}"
    fi
  else
    name_counts[$base]=1
    newname="$base"
  fi

  cp -p "$FILE" "$dest_dir/$newname"
done < <(find "$INPUT_DIR" -type f -print0)
