#!/bin/sh

for f in "$@"; do
	ffmpeg -v error -i "$f" -codec copy -f null - || {
		status=$?
		echo >&2 "Failure in $f."
		exit $status
	}
done
