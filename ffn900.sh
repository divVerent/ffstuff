#!/bin/sh

# N900 resolution.
w=800
h=480
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
	-codec:a aac \
		-b:a 96k \
	-codec:v libx264 \
		-threads:v 0 \
		-profile:v baseline \
		-level:v 30 \
		-maxrate:v 10000k \
		-bufsize:v 10000k \
		-rc_init_occupancy:v 9000k \
		-refs:v 5 \
		-crf:v 23 \
	-pix_fmt yuv420p \
	-vf-post "scale=\
			floor(min($w*$mode(1\\,dar/$dar)\\,in_w*max(1\\,sar/$sar))/2+0.5)*2:\
			floor(min($h*$mode($dar/dar\\,1)\\,in_h*max($sar/sar\\,1))/2+0.5)*2" \
	-vf-post "setsar=1/1" \
	"$@"
