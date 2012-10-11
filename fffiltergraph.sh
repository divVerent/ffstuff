#!/bin/sh

# This script is to be sourced
# INPUT: ffmpeg command line with -filter_complex options in "$@"
# OUTPUT: ffmpeg command line with the filters removed in "$@", and $filtergraph
# also: filter graph management functions

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
		filtergraph="$filtergraph;$arg"
	elif [ x"$arg" = x"-filter_complex" ]; then
		isfilter=true
	else
		set -- "$@" "$arg"
	fi
done

rewire()
{
	case "$filtergraph" in
		*\[$1\]*)
			filtergraph=`echo "$filtergraph" |\
				sed -e "s/\[$1\]/\[$2\]/g"`
			true
			;;
		*)
			false
			;;
	esac
}

rewire_or()
{
	rewire "$1" "$2" && echo "$2" || echo "$3"
}

# plug_before_last:
# parameters: A B
# "insert before B"
# [A] foo [B]
# [A] foo [REWIRED] bar [B]
# so, we need to rewire B to REWIRED, then return REWIRED
# and if B does not exist, return A

wire=0
plug_before_last()
{
	n=REWIRED_$wire
	wire=$(($wire + 1))
	rewire_or "$2" "$wire" "$1"
}

# plug_after_first:
# parameters: A B
# "insert after A"
# [A] foo [B]
# [A] bar [REWIRED] foo [B]
# so, we need to rewire A to REWIRED, then return REWIRED
# and if A does not exist, return B

plug_after_first()
{
	n=REWIRED_$wire
	wire=$(($wire + 1))
	rewire_or "$1" "$wire" "$2"
}

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

rewire_inputs()
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
