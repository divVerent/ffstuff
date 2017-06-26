#!/bin/sh

# This script is to be sourced
# INPUT: ffprobe vars, try_languages()
# OUTPUT: $v $a $s

tempdir=`mktemp -d -t attach.XXXXXX`

stream=0
astreams=
vstreams=
sstreams=
while [ $stream -lt $format_nb_streams ]; do
	eval i=\$streams_stream_${stream}_index
	eval t=\$streams_stream_${stream}_codec_type
	case "$t" in
		video)
			vstreams="$vstreams $i"
			;;
		audio)
			astreams="$astreams $i"
			;;
		subtitle)
			sstreams="$sstreams $i"
			;;
	esac
	stream=$(($stream + 1))
done

use_streams()
{
	score=1
	if [ -n "$v" ]; then
		score=$(($score + 10))
		eval d=\$streams_stream_${v}_disposition_attached_pic
		if [ $d -gt 0 ]; then
			continue
		fi
		eval d=\$streams_stream_${v}_disposition_default
		if [ $d -gt 0 ]; then
			score=$(($score + 1))
		fi
	fi
	if [ -n "$a" ]; then
		score=$(($score + 10))
		eval d=\$streams_stream_${a}_disposition_default
		if [ $a -gt 0 ]; then
			score=$(($score + 1))
		fi
	fi
	if [ -n "$s" ]; then
		score=$(($score + 10))
		eval d=\$streams_stream_${s}_disposition_default
		if [ $d -gt 0 ]; then
			score=$(($score + 1))
		fi
	fi
	if [ $score -gt $hiscore ]; then
		hiscore=$score
		hiv=$v
		hia=$a
		his=$s
	fi
}

match_lang()
{
	# $1: stream type
	# $2: stream number or stream type (for all) or empty string (for none)
	# $3: stream language
	# $4: requested language

	# lowercase and clean up the stream language
	set -- "$1" "$2" "`echo "$3" | tr -d : | tr A-Z a-z`" "$4"
	# match
	case "$2":"$3":"$4" in
		# requested is empty: we want no stream at all
		'':*:'') ;;
		*:*:'') return 1 ;;
		# requested is *: take them all
		"$4":*:'*') ;;
		# requested is ?: take ANY stream
		[0-9]*:*:'?') ;;
		# wantslang is a stream number: take it
		[0-9]*:*:"$2") ;;
		# wantslang is a prefix for the language: take it
		[0-9]*:"$4"*:*) ;;
		# otherwise fail
		*) return 1 ;;
	esac
	return 0
}

try_sub()
{
	eval slang=\$streams_stream_${s}_tags_language
	if match_lang s "$s" "$slang" "$wantslang"; then
		use_streams
	fi
}

try_audio()
{
	eval alang=\$streams_stream_${a}_tags_language
	if match_lang a "$a" "$alang" "$wantalang"; then
		for s in $sstreams '' s; do
			try_sub
		done
	fi
}

try_video()
{
	eval vlang=\$streams_stream_${v}_tags_language
	if match_lang v "$v" "$vlang" "$wantvlang"; then
		for a in $astreams '' a; do
			try_audio
		done
	fi
}

try_language()
{
	if [ $hiscore -gt 0 ]; then
		return
	fi
	matches=''
	wantvlang=$1
	wantalang=$2
	wantslang=$3
	for v in $vstreams '' v; do
		try_video
	done
	if [ $hiscore -gt 0 ]; then
		v=$hiv
		a=$hia
		s=$his
	fi
}

hiscore=0

try_languages

if [ $hiscore -le 0 ]; then
	echo >&2 "No streams found."
	exit 1
fi

echo >&2 "Selected $v/$a/$s"
