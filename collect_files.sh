#!/usr/bin/env bash
# Скрипт для копирования всех файлов из входной директории (рекурсивно) в выходную директорию без сохранения структуры папок
# Разрешает конфликты файлов с одинаковыми именами путём добавления порядкового суффикса

set -euo pipefail
IFS=$'\n\t'

# Проверка параметров
if [[ $# -ne 2 ]]; then
  echo "Использование: $0 <входная_директория> <выходная_директория>"
  exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR=$2

# Проверка существования входной директории
if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Ошибка: входная директория '$INPUT_DIR' не существует или не является директорией"
  exit 1
fi

# Создать выходную директорию, если её не существует
mkdir -p "$OUTPUT_DIR"

# 1) Получение списка файлов непосредственно в входной директории
mapfile -t direct_files < <(find "$INPUT_DIR" -maxdepth 1 -type f)
# 2) Получение списка поддиректорий непосредственно в входной директории
mapfile -t direct_dirs < <(find "$INPUT_DIR" -maxdepth 1 -mindepth 1 -type d)

# 3) Получение списка всех файлов во входной директории рекурсивно
mapfile -t all_files < <(find "$INPUT_DIR" -type f)

# Функция для генерации уникального имени в случае конфликта
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

# 4) Копирование файлов в выходную директорию без структуры папок
for src_path in "${all_files[@]}"; do
  filename=$(basename -- "$src_path")
  unique_name=$(generate_unique_name "$OUTPUT_DIR" "$filename")
  cp -- "$src_path" "$OUTPUT_DIR/$unique_name"
done

# Завершение
echo "Скопировано ${#all_files[@]} файлов из '$INPUT_DIR' в '$OUTPUT_DIR' (без иерархии)."
