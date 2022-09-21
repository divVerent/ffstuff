#!/bin/sh

conf=$1
shift
in=$1
shift
out=$1
shift

ffencode.sh \
	"$conf" "$in" "$out" \
	-y \
	-nostdin \
	-f mp4 \
		-movflags +faststart \
	-vsync vfr -r 120000 \
	-codec:a libfdk_aac \
		-b:a 96k \
	-codec:v libx264 \
		-threads:v 0 \
		-profile:v high \
		-tune:v animation \
		-crf:v 23 \
	-vf-post "setsar=$sar" \
	"$@"
