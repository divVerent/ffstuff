#!/bin/sh

# This script is to be sourced
# INPUT: ffmpeg command line with -filter_complex options in "$@"
# OUTPUT: ffmpeg command line with the filters removed in "$@", and $filtergraph
# also: filter graph management functions

add_filter()
{
	case "$filtergraph" in
		'')
			filtergraph="$1"
			;;
		*)
			filtergraph="$filtergraph;$1"
			;;
	esac
}

filtergraph=
isfilter=false
first=true
# extract the filter graph data
for arg in "$@"; do
	if $first; then
		first=false
		set --
	fi
	if $isfilter; then
		isfilter=false
		add_filter "$arg"
	elif [ x"$arg" = x"-filter_complex" ]; then
		isfilter=true
	else
		set -- "$@" "$arg"
	fi
done

have_label()
{
	case "$filtergraph" in
		*\[$1\]*)
			true
			;;
		*)
			false
			;;
	esac
}

rewire()
{
	if have_label "$1"; then
		filtergraph=`echo "$filtergraph" |\
			sed -e "s/\[$1\]/\[$2\]/g"`
		true
	else
		false
	fi
}

# plug_before_last:
# parameters: A B
# output: $plug
# "insert before B"
# [A] foo [B]
# [A] foo [REWIRED] bar [B]
# so, we need to rewire B to REWIRED, then return REWIRED
# and if B does not exist, return A

wire=0
plug_before_last()
{
	wire=$(($wire + 1))
	if rewire "$2" "PLUG_$wire"; then
		plug=PLUG_$wire
	else
		plug=$1
	fi
}

# plug_after_first:
# parameters: A B
# output: $plug
# "insert after A"
# [A] foo [B]
# [A] bar [REWIRED] foo [B]
# so, we need to rewire A to REWIRED, then return REWIRED
# and if A does not exist, return B

plug_after_first()
{
	wire=$(($wire + 1))
	if rewire "$1" "PLUG_$wire"; then
		plug=PLUG_$wire
	else
		plug=$2
	fi
}

connect_inputs()
{
	if [ -n "${s#s}" ]; then
		if rewire SUB_IN 0:"$s"; then
			s=
		fi
	fi
	if [ -n "${a#a}" ]; then
		if rewire AUDIO_IN 0:"$a"; then
			a=
		fi
	fi
	if [ -n "${v#v}" ]; then
		if rewire VIDEO_IN 0:"$v"; then
			v=
		fi
	fi
}

connect_outputs()
{
	if have_label SUB_IN; then
		echo >&2 "Subtitles were not connected... bailing out"
		exit 1
	fi
	if have_label AUDIO_IN; then
		echo >&2 "Subtitles were not connected... bailing out"
		exit 1
	fi
	if have_label VIDEO_IN; then
		echo >&2 "Subtitles were not connected... bailing out"
		exit 1
	fi

	# connect the outputs
	if have_label VIDEO_OUT; then
		echo -map "[VIDEO_OUT]" "$@"
	fi
	if [ -n "$v" ]; then
		echo -map 0:"$v" "$@"
	fi
	if have_label AUDIO_OUT; then
		echo -map "[AUDIO_OUT]" "$@"
	fi
	if [ -n "$a" ]; then
		echo -map 0:"$a" "$@"
	fi
	if ! $hardsub; then
		if have_label SUB_OUT; then
			echo -map "[SUB_OUT]" "$@"
		fi
		if [ -n "$s" ]; then
			echo -map 0:"$s" "$@"
		fi
	fi
}
