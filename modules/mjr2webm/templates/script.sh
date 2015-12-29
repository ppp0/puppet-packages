#!/bin/bash
#
# Copyright (c) 2015 Me
# Rev: PA1
# Convert local Janus .mjr files (audio and video) to an .webm file
# containing video and 2ch audio (vp8 + opus)
#
# dependencies:
#    janus-pp-rec (Janus postprocessing) must have been compiled and installed
#    ffmpeg (2015->) must have been installed.
#    (static versions for download exist on the internet)
#
# input is:
# mjr2webm -v myvideo.mjr -a myaudio.mjr out.webm
myhelp () {
    echo $0
    echo 'Usage: mjr2webm -v videofile -a audiofile [outputfile]'
    echo '   "videofile" must be a .mjr video file output from Janus'
    echo '   "audiofile" must be a .mjr audio file output from Janus'
    echo '   "outputfile", if not specified, is "default.webm"'
    echo '   if specified, it must end with filetype ".webm"'
}

video=-v
audio=-a
out=default.webm

if test $# -eq 0; then
   myhelp
   exit 0
fi

if ! which ffmpeg > /dev/null; then
   if ! which ./ffmpeg > /dev/null; then
     echo "Aborting: No 'ffmpeg' found" 1>&2
     exit 1
   else
      ffmpeg=./ffmpeg
   fi
else
   ffmpeg=ffmpeg
fi

if ! which janus-pp-rec > /dev/null; then
     echo "Aborting: No 'janus-pp-rec' found" 1>&2
     exit 1
fi

while test $# -gt 0
do
  case $1 in

  # Normal option processing
    -h | --help)
      # usage and help
      myhelp
      exit 0
      break
      ;;
    -v | --video)
      shift
      video=$1
      ;;
    -a | --audio)
      shift
      audio=$1
      ;;
  # ...
  # Done with options
    *)
      break
      ;;
  esac

  # for testing purposes:
  echo "param $1"

  shift
done


if ! [ -f $video ]; then
   echo "Videofile $video does not exist"
   exit 1
else
   if ! [[ "$video" == *.mjr ]]; then
      echo "Video file must end with .mjr"
      exit 1
   fi
fi
if ! [ -f $audio ]; then
   echo "Audio $audio does not exist"
   exit 1
else
   if ! [[ "$audio" == *.mjr ]]; then
      echo "Video file must end with .mjr"janus-pp-rec
      exit 1janus-pp-rec
   fi
fi
if [ -z "$1" ]; then
    echo "Using default.webm as output file"
else
    out=$1
    if ! [[ "$out" == *.webm ]]; then
       echo "Output file must end with .webm"
       exit 1
    fi
fi

# make temp files
TFILE="$$"
opus=$TFILE.opus
webm=$TFILE.webm

# convert audio to opus
janus-pp-rec $audio $opus

# convert video to webm
janus-pp-rec $video $webm

# mix the two:
# file gets large with high fr.
# by re-coding it we loose quality but reduce the bitrate to 1/4
# however, takes quite some time...
$ffmpeg -i $webm -i $opus -c:v libvpx -b:v 500k -c:a libopus -b:a 64k -r 25 $out

# fast modus
#$ffmpeg -i $webm -i $opus -c:v copy -c:a copy $out

# remove temp files
rm $opus
rm $webm
# done
echo "done!"
#------- end
