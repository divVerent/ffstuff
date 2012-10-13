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
	# these subs get merged at the OUTPUT side
	# extract subtitles
	# TODO can we honor filter chain?
	if [ x"$t" = x"unknown" ]; then
		# HACK for undecodable subs. Don't ask.
		ffmpeg -i "$in" "$@" -vn -an \
			-map 0:"$s" \
			-codec copy \
			-f matroska \
			"$tempdir"/subtitles.mkv
		ffmpeg -i "$tempdir"/subtitles.mkv \
			-f ass \
			"$tempdir"/subtitles.ass
	else
		ffmpeg -i "$in" "$@" -vn -an \
			-map 0:"$s" \
			-f ass \
			"$tempdir"/subtitles.ass
	fi
	# extract attachments
	export XDG_CACHE_HOME="$tempdir"/.cache
	export XDG_DATA_HOME="$tempdir"/.local/share
	fontsdir="$XDG_DATA_HOME/fonts"
	mkdir -p "$fontsdir"
	stream=0
	while [ $stream -lt $format_nb_streams ]; do
		eval i=\$streams_stream_${stream}_index
		eval f=\$streams_stream_${stream}_tags_filename
		eval t=\$streams_stream_${stream}_codec_type
		case "$t" in
			attachment)
				ffmpeg -y -dump_attachment:$i \
					"$fontsdir/$f" \
					-i "$in" \
					-frames 0 -f null /dev/null
				;;
		esac
		stream=$(($stream + 1))
	done
	# convince fontconfig to use the dumped fonts
	fc-cache
	# add it to the filter chain, and cancel the other outputs
	plug_before_last VIDEO_IN VIDEO_OUT
	add_filter "[$plug] ass=$tempdir/subtitles.ass [VIDEO_OUT]"
fi
