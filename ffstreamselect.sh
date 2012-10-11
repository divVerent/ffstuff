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
	echo >&2 "CANDIDATE: $v/$a/$s -> $score"
	if [ $score -gt $hiscore ]; then
		hiscore=$score
		hiv=$v
		hia=$a
		his=$s
	fi
}

try_sub()
{
	eval slang=\$streams_stream_${s}_tags_language
	case "$s":"$wantslang" in
		'':'') ;;
		*:'') return ;;
		s:'*') ;;
		[0-9]*:'?') ;;
		[0-9]*:"$s") ;;
		[0-9]*:"$slang") ;;
		*) return ;;
	esac
	use_streams
}

try_audio()
{
	eval alang=\$streams_stream_${a}_tags_language
	case "$a":"$wantalang" in
		'':'') ;;
		*:'') return ;;
		a:'*') ;;
		[0-9]*:'?') ;;
		[0-9]*:"$a") ;;
		[0-9]*:"$alang") ;;
		*) return ;;
	esac
	for s in $sstreams '' s; do
		try_sub
	done
}

try_video()
{
	eval vlang=\$streams_stream_${v}_tags_language
	case "$v":"$wantvlang" in
		'':'') ;;
		*:'') return ;;
		v:'*') ;;
		[0-9]*:'?') ;;
		[0-9]*:"$v") ;;
		[0-9]*:"$vlang") ;;
		*) return ;;
	esac
	for a in $astreams '' a; do
		try_audio
	done
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

echo >&2 "Selected $v/$a/$s"
