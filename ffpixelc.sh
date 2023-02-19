#!/bin/sh

# Half Pixel C resolution.
w=1280
h=900
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
	-f webm \
	-fps_mode vfr \
	-codec:a libvorbis \
	-codec:v libvpx-vp9 \
		-pass 1 \
		-b:v 0 \
		-crf:v 23 \
		-threads:v 8 \
		-speed:v 4 \
		-tile-columns:v 6 \
		-frame-parallel:v 1 \
	-vf-post "scale=\
			floor(min($w*$mode(1\\,dar/$dar)\\,in_w*max(1\\,sar/$sar))/2+0.5)*2:\
			floor(min($h*$mode($dar/dar\\,1)\\,in_h*max($sar/sar\\,1))/2+0.5)*2" \
	-vf-post "setsar=1/1" \
	"$@"
ffencode.sh \
	"$conf" "$in" "$out" \
	-y \
	-nostdin \
	-f webm \
	-fps_mode vfr \
	-codec:a libvorbis \
	-codec:v libvpx-vp9 \
		-pass 2 \
		-b:v 0 \
		-crf:v 23 \
		-threads:v 8 \
		-speed:v 2 \
		-tile-columns:v 6 \
		-frame-parallel:v 1 \
		-auto-alt-ref 1 \
		-lag-in-frames 25 \
	-vf-post "scale=\
			floor(min($w*$mode(1\\,dar/$dar)\\,in_w*max(1\\,sar/$sar))/2+0.5)*2:\
			floor(min($h*$mode($dar/dar\\,1)\\,in_h*max($sar/sar\\,1))/2+0.5)*2" \
	-vf-post "setsar=1/1" \
	"$@"
