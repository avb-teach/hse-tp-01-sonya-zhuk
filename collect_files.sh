#!/bin/bash

max_depth=""
pos=()

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --max_depth)
        if [[ "$2" =~ ^[0-9]+$ ]]; then
          max_depth="$2"
          shift 2
        else
          exit 1
        fi
        ;;
      *)
        pos+=("$1")
        shift
        ;;
    esac
  done

  if [ "${#pos[@]}" -ne 2 ]; then
    exit 1
  fi

  input_dir="${pos[0]}"
  output_dir="${pos[1]}"
}

compute_rel() {
  local rel="$1"
  if [ -n "$max_depth" ]; then
    local tmp="$rel" slash_count=0 comps
    while [ "${tmp#*/}" != "$tmp" ]; do
      slash_count=$((slash_count + 1))
      tmp="${tmp#*/}"
    done
    comps=$((slash_count + 1))
    while [ "$comps" -gt "$max_depth" ]; do
      rel="${rel#*/}"
      comps=$((comps - 1))
    done
  fi
  printf '%s' "$rel"
}

process_file() {
  local file="$1"
  local rel="${file#"$input_dir"/}"
  rel=$(compute_rel "$rel")

  local dest="$output_dir/$rel"
  local dir="${dest%/*}"
  local base="${dest##*/}"

  mkdir -p "$dir"

  local name="${base%.*}"
  local ext="${base##*.}"
  local new_base="$base"
  local count=1

  while [ -e "$dir/$new_base" ]; do
    if [ "$ext" != "$base" ]; then
      new_base="${name}_${count}.${ext}"
    else
      new_base="${name}_${count}"
    fi
    count=$((count + 1))
  done

  cp "$file" "$dir/$new_base"
}

main() {
  parse_args "$@"
  [ -d "$input_dir" ] || exit 1
  mkdir -p "$output_dir"
  find "$input_dir" -type f | while IFS= read -r file; do
    process_file "$file"
  done
}

main "$@"
