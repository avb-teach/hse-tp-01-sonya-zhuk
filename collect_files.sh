#!/usr/bin/env bash
set -euo pipefail

MAX_DEPTH=0
if [[ "${1:-}" == "--max_depth" ]]; then
  shift
  if (( $# < 3 )) || ! [[ "$1" =~ ^[0-9]+$ ]]; then
    exit 1
  fi
  MAX_DEPTH=$1
  shift
fi

if (( $# != 2 )); then
  exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR=$2

if [[ ! -d "$INPUT_DIR" ]]; then
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
declare -A seen

if (( MAX_DEPTH > 0 )); then
  FIND_OPTS=( -maxdepth "$MAX_DEPTH" )
else
  FIND_OPTS=()
fi

find "$INPUT_DIR" "${FIND_OPTS[@]}" -type f -print0 |
while IFS= read -r -d '' file; do
  rel="${file#$INPUT_DIR/}"
  dirpart=$(dirname "$rel")
  base=$(basename "$rel")

  if (( MAX_DEPTH > 0 )); then
    dest_subdir="$OUTPUT_DIR/$dirpart"
  else
    dest_subdir="$OUTPUT_DIR"
  fi
  mkdir -p "$dest_subdir"

  name="${base%.*}"
  ext="${base##*.}"
  if [[ "$name" == "$ext" ]]; then
    ext=""
  else
    ext=".$ext"
  fi

  newname="$name$ext"
  if [[ -n "${seen[$newname]:-}" ]]; then
    cnt=${seen[$newname]}
    (( cnt++ ))
    seen[$newname]=$cnt
    newname="${name}_${cnt}${ext}"
  else
    seen[$newname]=1
  fi

  cp -p -- "$file" "$dest_subdir/$newname"
done
