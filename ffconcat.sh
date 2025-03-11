#!/bin/sh

concatfile=$(mktemp -t ffconcat.XXXXXX)
trap 'rm -f "$concatfile"' EXIT

first=true
last=
for f in "$@"; do
	if $first; then
		first=false
	else
		echo "file '$(realpath "$last" | sed -e "s,','\\\\'',g")'" >> "$concatfile"
	fi
	last=$f
done

ffmpeg -safe 0 -f concat -i "$concatfile" -codec copy "$last"
