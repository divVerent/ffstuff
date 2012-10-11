#!/bin/sh

# abort on error
set -e

# set PATH
me=`realpath "$0"`
case "$me" in
	*/*)
		export PATH=${me%/*}:$PATH
		;;
esac

# files
conf=$1
shift
in=$1
shift
out=$1
shift

if ! [ -f ~/.ffautostreamsrc ]; then
	cat >~/.ffautostreamsrc <<'EOF'
hardsub=true
try_languages()
{
	# here:
	# '' means none
	# '?' means one (any)
	# '*' means all
	try_language '?' jpn eng
	try_language '?' eng ''
	try_language '?' '?' '?'
	try_language '?' '?' ''
}
add_filters()
{
	# here you can append to $filtergraph, and call rewire
	# this is called BEFORE inputs are rewired
	:
}
EOF
fi

case "$conf" in
	/*)
		;;
	*)
		conf="$PWD/$conf"
		;;
esac
. ~/.ffautostreamsrc
if [ -f "$conf" ]; then
	. "$conf"
fi

eval `ffprobe -print_format flat=s=_ -show_format -show_streams "$in"`

. ffstreamselect.sh

. fffiltergraph.sh

add_filters

# if we want to hardsub... let's do it
if $hardsub; then
	. ffhardsub.sh
fi

rewire_inputs
set -- `connect_outputs` "$@"
set -- -filter_complex "$filtergraph" "$@"

# run the encode!
set -x
ffmpeg -i "$in" "$@" "$out"

# clean up
rm -rf "$tempdir"
