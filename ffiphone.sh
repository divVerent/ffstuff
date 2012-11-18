#!/bin/sh

# full res?
#w=960
#h=640

# half res
w=480
h=320

# size must be multiples of this
div=2

mode=max

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
		-crf:v 27 \
	-af-post "volume=-1dB" \
	-vf-post "scale=\
			$mode($w\\,floor($h*dar/$div+.5)*$div):\
			$mode(floor($w/dar/$div+.5)*$div\\,$h)" \
	-vf-post "setsar=1:1" \
	"$@"
