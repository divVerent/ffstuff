#!/bin/sh

# Nexus 7 resolution.
w=1280
h=800
sar=1/1
dar=

# min = optimize for zoomed out display
# max = optimize for zoomed in display
mode=min

[ -n "$dar" ] || dar="($sar*$w/$h)"
[ -n "$sar" ] || sar="($dar*$h/$w)"

# size must be multiples of this
div=2

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
		-preset:v ${PRESET:-medium} \
		-threads:v 0 \
		-profile:v high \
		-tune:v animation \
		-crf:v ${CRF:-23} \
	-vf-post "scale=\
			floor(min($w*$mode(1\\,dar/$dar)\\,in_w*max(1\\,sar/$sar))/2+0.5)*2:\
			floor(min($h*$mode($dar/dar\\,1)\\,in_h*max($sar/sar\\,1))/2+0.5)*2" \
	-vf-post "format=yuv420p|yuvj420p" \
	-vf-post "setsar=1/1" \
	"$@"
