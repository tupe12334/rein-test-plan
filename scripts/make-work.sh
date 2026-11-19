#!/bin/sh
# Make the work folder of one run, with an empty notes file in it. The folder
# holds the notes and the plan, so a run never writes into the home folder.
# Usage: make-work.sh <name>. Prints the folder.
name=$(printf '%s' "${1:-run}" | tr -cd 'A-Za-z0-9._-')
case "$name" in .|..|'') name=run ;; esac
dir="$HOME/test-plan-work/$name"
mkdir -p "$dir" || exit 1
: > "$dir/notes.md" || exit 1
printf '%s\n' "$dir"
