#!/usr/bin/env bash

reverseNumbering=true
#playlistURL="https://www.youtube.com/playlist?list=PLGl3cau5E3unqx9uN3AKRqzhN-l4klWu_"
listID=$1


if [[ -z ${listID} ]]; then
  listID=$(gum input --prompt "Youtube playlist id: ")
fi


playlistURL="https://www.youtube.com/playlist?list=$listID"
# Haal het totaal aantal video's in de playlist op
nrOfVideosInList=$(yt-dlp --flat-playlist --playlist-items 1 --print "%(playlist_count)s" "$playlistURL")
if [[ ! ${nrOfVideosInList} -gt 0 ]]; then
    echo "The list ID is invalid."
    exit 1
fi

startVideoNr=$(gum input --prompt "Video number start: ")
amountOfVideos=$(gum input --prompt "Amount of videos to download: ")
reverseNumbering=$(gum choose yes no --selected "no")

while [[ -z "$prefixOutputFilename" ]]; do
    prefixOutputFilename=$(gum input --prompt "Prefix for output filename: ")
done

if [[ "$reverseNumbering" == "yes" ]]; then
    # Bij reverse numbering betekent "startVideoNr = 1" dat je vanaf de laatste video telt
    startVideoNr=$((nrOfVideosInList - startVideoNr ))
    endVideoNr=$((startVideoNr - amountOfVideos + 1))

    # Voorkom dat we onder 1 komen
    if [[ $endVideoNr -lt 1 ]]; then
        endVideoNr=1
    fi
else
    endVideoNr=$((startVideoNr + amountOfVideos - 1))

    # Voorkom dat we over de playlist-limiet gaan
    if [[ $endVideoNr -gt $nrOfVideosInList ]]; then
        endVideoNr=$nrOfVideosInList
    fi
fi

# Gebruik 'seq' om een reeks getallen te genereren in de juiste volgorde
if [[ "$reverseNumbering" == "yes" ]]; then
    rangeVideoNrs=$(seq "$startVideoNr" -1 "$endVideoNr")
else
    rangeVideoNrs=$(seq "$startVideoNr" "$endVideoNr")
fi

echo "Downloading videos in range: $rangeVideoNrs"

for num in $rangeVideoNrs; do
  echo "debug $num"
  unset outputNum
    if [[ $reverseNumbering == "yes" ]]; then
        # Bereken het juiste nummer in de lijst bij omgekeerde nummering
        echo "Omnummeren"
        outputNum=$(($nrOfVideosInList - num  ))
    else
        echo "nummer behouden"
        outputNum=$num
    fi
    echo "Download video $num and save it as  $outputNum"
    yt-dlp --playlist-items "$num" "$playlistURL" -o "${prefixOutputFilename}-${outputNum}.webm"
done
