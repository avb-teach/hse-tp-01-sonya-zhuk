#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [[ $# -ne 2 ]]; then
  echo "$0 <входная_директория> <выходная_директория>"
  exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR=$2

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Ошибка: входная директория '$INPUT_DIR' не найдена"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

mapfile -t all_files < <(find "$INPUT_DIR" -type f)

generate_unique_name() {
  local dest_dir=$1
  local base_name=$2
  local name ext
  name="${base_name%.*}"
  ext="${base_name##*.}"
  if [[ "$name" == "$ext" ]]; then
    ext=""
  else
    ext=".$ext"
  fi

  local candidate="$name$ext"
  local counter=1
  while [[ -e "$dest_dir/$candidate" ]]; do
    candidate="${name}(${counter})${ext}"
    ((counter++))
  done
  echo "$candidate"
}

for src_path in "${all_files[@]}"; do
  filename=$(basename -- "$src_path")
  unique_name=$(generate_unique_name "$OUTPUT_DIR" "$filename")
  cp -- "$src_path" "$OUTPUT_DIR/$unique_name"
done

echo "Скопировано ${#all_files[@]} файлов из '$INPUT_DIR' в '$OUTPUT_DIR'"
