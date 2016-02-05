eval t=\$streams_stream_${s}_codec_name
eval w=\$streams_stream_${v}_width
eval h=\$streams_stream_${v}_height

if [ -n "$s" ] && [ x"$t" = x"dvdsub" ]; then
	# these subs get merged at the INPUT side so we can match up the size
	if [ -n "$w" ] && [ -n "$h" ]; then
		plug_before_last SUB_IN SUB_OUT
		add_filter "[$plug] scale=$w:$h [SUB_OUT]"
	else
		plug_before_last SUB_IN SUB_OUT
		add_filter "[$plug] null [SUB_OUT]"
	fi
	plug_after_first VIDEO_IN VIDEO_OUT
	add_filter "[VIDEO_IN] [SUB_OUT] overlay [$plug]"
elif [ -n "$s" ]; then
	plug_before_last VIDEO_IN VIDEO_OUT
	add_filter "[$plug] subtitles=f=$in:original_size=${w}x${h}:si=$s"
fi
