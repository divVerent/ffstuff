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
	-fps_mode vfr \
	-codec:a libfdk_aac \
		-b:a 96k \
	-codec:v libx264 \
		-threads:v 0 \
		-profile:v high444 \
		-tune:v animation \
		-crf:v 23 \
	-pix_fmt yuv444p \
	-vf-post scale \
	"$@"
