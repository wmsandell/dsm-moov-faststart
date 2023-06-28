#!/usr/bin/env bash

# by Matt Sephton @gingerbeardman
# requires SynoCommunity ffmpeg to be installed

log="/volume1/video/Scripts/faststart.log"
work="/volume1/video/Scripts/"
start="../"

export log
export bin

function output ()
{
	echo "$1"
	echo "$1" >> $log
}
export -f output

function outprint ()
{
	printf "$1"
	printf "$1" >> $log
}
export -f outprint

function notify ()	# Faststart, status, path, info
{
	#echo "Args are \"$@\""

	synodsmnotify @administrators "$1 $2" "$3"
	msg="$2 = $3"
	output $msg
}
export -f notify

cd $work
total=$(find "$start" -type f \( -iname \*.mp4 \) -not -path "../#recycle*" | wc -l)
if [ $total -eq 0 ]; then
	output "no MP4 files found"
	exit
fi
#notify Faststart found "$total files"

function process_pass ()
{
	#notify Faststart OK "$short ($runtime seconds)"
	output "OK"
	rm "$1"
	mv "${1%.*}.fast.mp4" "$1"
}
export -f process_pass

function process_fail ()
{
	notify Faststart FAIL "$short" ""
}
export -f process_fail

function process_file ()
{
	fullname=$(basename "$1")
	short="${fullname%.*}"

	outprint "$short = "

	start=`date +%s`
	/usr/local/ffmpeg/bin/ffmpeg -y -i "$1" -movflags faststart -acodec copy -vcodec copy "${1%.*}.fast.mp4" -hide_banner -loglevel error
	end=`date +%s`
	
	runtime=$((end-start))

	status=$?
	[ $status -eq 0 ] && process_pass "$1" || process_fail "$1"
}
export -f process_file

echo "" > $log

find "$start" -type f \( -iname \*.mp4 \) -not -path "../#recycle*" -print0 | xargs -0 -n1 bash -c 'process_file "$@"' _

wait
total=$(find "$start" -type f \( -iname \*.mp4 \) -not -path "../#recycle*" | wc -l)
notify Faststart complete "$total files processed"
