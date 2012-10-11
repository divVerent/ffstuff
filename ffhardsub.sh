if ! have_label SUB_OUT; then
	if [ -n "${s#s}" ] && ! have_label SUB_IN; then
		add_filter "[SUB_IN] null [SUB_OUT]"
	fi
fi

if have_label SUB_OUT; then
	eval t=\$streams_stream_${s}_codec_name
	if [ x"$t" = x"dvdsub" ]; then
		# these subs get merged at the INPUT side
		f=`plug_after_first VIDEO_IN VIDEO_OUT`
		add_filter "[VIDEO_IN] [SUB_OUT] overlay [$f]"
	else
		# these subs get merged at the OUTPUT side
		# extract subtitles (FIXME honor filter chain?)
		( rewire_inputs
		if [ x"$t" = x"unknown" ]; then
			# HACK for undecodable subs. Don't ask.
			ffmpeg -i "$in" "$@" -vn -an \
				-filter_complex "$filtergraph" \
				-map "[SUB_OUT]" \
				-codec copy \
				-f matroska \
				"$tempdir"/subtitles.mkv
			ffmpeg -i "$tempdir"/subtitles.mkv \
				"$tempdir"/subtitles.ass
		else
			ffmpeg -i "$in" "$@" -vn -an \
				-filter_complex "$filtergraph" \
				-map "[SUB_OUT]" \
				-f ass \
				"$tempdir"/subtitles.ass
		fi )
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
					ffmpeg -dump_attachment:$i \
						"$fontsdir/$f" \
						-i "$in" \
						-y -frames 0 -f null /dev/null
					;;
			esac
			stream=$(($stream + 1))
		done
		# convince fontconfig to use the dumped fonts
		fc-cache
		# add it to the filter chain, and cancel the other outputs
		f=`plug_before_last VIDEO_IN VIDEO_OUT`
		filtergraph="$filtergraph;\
			[$f] ass=$tempdir/subtitles.ass [VIDEO_OUT]"
	fi
fi
