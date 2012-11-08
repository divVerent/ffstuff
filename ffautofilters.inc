if [ -n "$FFAUTOFILTER_YADIF" ]; then
	plug_after_first VIDEO_IN VIDEO_OUT
	add_filter "[VIDEO_IN] yadif [$plug]"
fi
