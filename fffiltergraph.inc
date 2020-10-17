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
VIDEOfpre=0
VIDEOfpost=0
AUDIOfpre=0
AUDIOfpost=0
SUBfpre=0
SUBfpost=0
isfilter=
first=true
# extract the filter graph data
for arg in "$@"; do
	if $first; then
		first=false
		set --
	fi
	case "$isfilter:$arg" in
		'':-filter_complex)
			isfilter=-filter_complex
			;;
		-filter_complex:*)
			add_filter "$arg"
			isfilter=
			;;
		'':-vf-pre)
			isfilter=-vf-pre
			;;
		-vf-pre:*)
			eval VIDEOfpre_$VIDEOfpre=\$arg
			VIDEOfpre=$(($VIDEOfpre+1))
			isfilter=
			;;
		'':-vf-post)
			isfilter=-vf-post
			;;
		-vf-post:*)
			eval VIDEOfpost_$VIDEOfpost=\$arg
			VIDEOfpost=$(($VIDEOfpost+1))
			isfilter=
			;;
		'':-af-pre)
			isfilter=-af-pre
			;;
		-af-pre:*)
			eval AUDIOfpre_$AUDIOfpre=\$arg
			AUDIOfpre=$(($AUDIOfpre+1))
			isfilter=
			;;
		'':-af-post)
			isfilter=-af-post
			;;
		-af-post:*)
			eval AUDIOfpost_$AUDIOfpost=\$arg
			AUDIOfpost=$(($AUDIOfpost+1))
			isfilter=
			;;
		'':-sf-pre)
			isfilter=-sf-pre
			;;
		-sf-pre:*)
			eval SUBfpre_$SUBfpre=\$arg
			SUBfpre=$(($SUBfpre+1))
			isfilter=
			;;
		'':-sf-post)
			isfilter=-sf-post
			;;
		-sf-post:*)
			eval SUBfpost_$SUBfpost=\$arg
			SUBfpost=$(($SUBfpost+1))
			isfilter=
			;;
		*)
			set -- "$@" "$arg"
			;;
	esac
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
		filtergraph=`printf '%s\n' "$filtergraph" |\
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
		printf -- '-map [VIDEO_OUT]\n'
	fi
	if [ -n "$v" ]; then
		printf -- '-map 0:%d\n' "$v"
	fi
	if have_label AUDIO_OUT; then
		printf -- '-map [AUDIO_OUT]\n'
	fi
	if [ -n "$a" ]; then
		printf -- '-map 0:%d\n' "$a"
	fi
	if ! $hardsub; then
		if have_label SUB_OUT; then
			printf -- '-map [SUB_OUT]\n'
		fi
		if [ -n "$s" ]; then
			printf -- '-map 0:%d\n' "$s"
		fi
	fi
}

# now add possible pre-/posterous filters
for t in AUDIO VIDEO SUB; do
	eval n=\$$t"fpre"
	i=0
	while [ $i -lt $n ]; do
		plug_after_first "$t""_IN" "$t""_OUT"
		eval f=\$$t"fpre_"$i
		add_filter "[$t""_IN] $f [$plug]"
		i=$(($i+1))
	done
	eval n=\$$t"fpost"
	i=0
	while [ $i -lt $n ]; do
		plug_before_last "$t""_IN" "$t""_OUT"
		eval f=\$$t"fpost_"$i
		add_filter "[$plug] $f [$t""_OUT]"
		i=$(($i+1))
	done
done
