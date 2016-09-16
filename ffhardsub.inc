eval t=\$streams_stream_${s}_codec_name
eval w=\$streams_stream_${v}_width
eval h=\$streams_stream_${v}_height

if [ -n "$s" ] && [ x"$t" = x"dvd_subtitle" ]; then
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
	si=0
	for ss in $sstreams; do
		if [ "$ss" -eq "$s" ]; then
			plug_before_last VIDEO_IN VIDEO_OUT
			escape() {
				echo "$1" | sed -e 's/[^A-Za-z0-9]/\\&/g'
			}
			in_escaped=`escape "$in"`
			add_filter "[$plug] subtitles=f=${in_escaped}:original_size=${w}x${h}:si=$si"
			si=
			break
		fi
		si=$((si + 1))
	done
	if [ -n "$si" ]; then
		echo >&2 "Failed to find subtitle stream $s (available: $sstreams)."
	fi
fi
