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

# [libx264 @ 0x55569ba38bc0] frame I:77    Avg QP:20.28  size: 48752
# [libx264 @ 0x55569ba38bc0] frame P:729   Avg QP:23.76  size: 15291
# [libx264 @ 0x55569ba38bc0] frame B:1402  Avg QP:26.64  size:  2868

ffencode.sh \
	"$conf" "$in" "$out" \
	-y \
	-nostdin \
	-f mp4 \
		-movflags +faststart \
	-vsync vfr -r 120000 \
	-codec:a libfdk_aac \
		-b:a 96k \
	-codec:v h264_vaapi \
		-vaapi_device /dev/dri/renderD128 \
		-bf:v 2 \
		-rc_mode:v CQP \
		-qp:v ${QP:-23} \
		-i_qfactor:v 1 \
		-i_qoffset:v 3 \
		-b_qfactor:v 1 \
		-b_qoffset:v 3 \
		-coder:v cabac \
		-profile:v high \
		-compression_level:v ${COMPRESSION_LEVEL:-0} \
	-vf-post "scale=\
			floor(min($w*$mode(1\\,dar/$dar)\\,in_w*max(1\\,sar/$sar))/2+0.5)*2:\
			floor(min($h*$mode($dar/dar\\,1)\\,in_h*max($sar/sar\\,1))/2+0.5)*2" \
	-vf-post "format=yuv420p|yuvj420p" \
	-vf-post "setsar=1/1" \
	-vf-post "format=nv12|vaapi" \
	-vf-post "hwupload" \
	"$@"
