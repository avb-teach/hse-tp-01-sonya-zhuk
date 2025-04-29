#!/usr/bin/env bash

max_depth=""
args=()

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
      args+=("$1")
      shift
      ;;
  esac
done

if [ "${#args[@]}" -ne 2 ]; then
  exit 1
fi

src_dir="${args[0]}"
dst_dir="${args[1]}"

if [ ! -d "$src_dir" ]; then
  exit 1
fi

mkdir -p "$dst_dir"

find "$src_dir" -type f | while IFS= read -r src_file; do
  rel_path="${src_file#"$src_dir"/}"

  if [ -n "$max_depth" ]; then
    cur="$rel_path"
    slash_count=0
    while [ "${cur#*/}" != "$cur" ]; do
      slash_count=$((slash_count + 1))
      cur="${cur#*/}"
    done
    comp_count=$((slash_count + 1))
    while [ "$comp_count" -gt "$max_depth" ]; do
      rel_path="${rel_path#*/}"
      comp_count=$((comp_count - 1))
    done
  fi

  dest_path="$dst_dir/$rel_path"
  dest_dir="${dest_path%/*}"
  mkdir -p "$dest_dir"

  base_name="${dest_path##*/}"
  name_no_ext="${base_name%.*}"
  extension="${base_name##*.}"
  new_name="$base_name"
  suffix=1

  while [ -e "$dest_dir/$new_name" ]; do
    if [ "$extension" != "$base_name" ]; then
      new_name="${name_no_ext}_${suffix}.${extension}"
    else
      new_name="${name_no_ext}_${suffix}"
    fi
    suffix=$((suffix + 1))
  done

  cp "$src_file" "$dest_dir/$new_name"
done
