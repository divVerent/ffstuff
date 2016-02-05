#!/bin/sh

# iPhone 4 half resolution.
w=480
h=320
sar=1/1
dar=

# min = optimize for zoomed out display
# max = optimize for zoomed in display
mode=max

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
	-vsync vfr -r 120000 \
	-codec:a libfdk_aac \
		-b:a 96k \
	-codec:v libx264 \
		-threads:v 0 \
		-maxrate:v 2500k \
		-bufsize:v 1000k \
		-rc_init_occupancy:v 900k \
		-level:v 30 \
		-profile:v baseline \
		-tune:v animation \
		-crf:v 25 \
	-vf-post "scale=\
			floor(min($w*$mode(1\\,dar/$dar)\\,in_w*max(1\\,sar/$sar))/2+0.5)*2:\
			floor(min($h*$mode($dar/dar\\,1)\\,in_h*max($sar/sar\\,1))/2+0.5)*2" \
	-vf-post "setsar=1/1" \
	"$@"
