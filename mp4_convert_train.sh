#!/bin/sh

# Usage: ./convert_train.sh <dataset_dir> <mp4_file>
# Example: ./convert_train.sh ./dataset ./data/input.mp4
dataset_dir=$1
mp4_file=$2

usage() {
    echo "Usage: $0 <dataset_dir> <mp4_file>"
    echo "Example: $0 ./dataset ./data/video.mp4"
    echo "       : $0 ./dataset \"./data/video.mp4;./data/video2.mp4\"  # multiple mp4 files"
    echo "       : $0 ./dataset                                       # search mp4 file in the dataset directory"
}

# Check if the dataset directory exists
if [ ! -d "$dataset_dir" ]; then
    echo "Directory '$dataset_dir' does not exist"
    mkdir -p "$dataset_dir"
    # exit 1
fi

# Check mp4 file in the dataset directory
if [ -z "$mp4_file" ]; then
    echo "Searching for mp4 file in $dataset_dir"
    mp4_file=""
    for video_file in "$dataset_dir"/*.mp4
    do
        mp4_file="$mp4_file$video_file;"
        echo "find '$video_file'"
    done
    # Remove the last semicolon
    mp4_file=${mp4_file%;}
    sleep 5
fi
# Check arguments
if [ -z "$dataset_dir" ] || [ -z "$mp4_file" ]; then
    echo "Invalid arguments"
    usage
    exit 1
fi

# if [ ! -f "$mp4_file" ]; then
#     echo "File '$mp4_file' does not exist"
#     exit 1
# fi

# Convert mp4 to images
echo "Converting $mp4_file to images in $dataset_dir"

# Remove the directory if it exists
if [ -d "$dataset_dir/input/" ]; then
    rm -rf "$dataset_dir/input/"
fi
mkdir -p "$dataset_dir/input/"



# Convert the string to an array
OLDIFS=$IFS
IFS=';'
set -- $mp4_file
IFS=$OLDIFS
for video_file
do
    echo "Processing $video_file"
    # Get the width of the video
    width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=s=x:p=0 "$video_file")
    videoname=$(basename "$video_file" .mp4)

    # Remove the directory if it exists
    if [ -d "$dataset_dir/input/$videoname" ]; then
        rm -rf "$dataset_dir/input/$videoname"
    fi
    mkdir -p "$dataset_dir/input/$videoname"

    if [ "$width" -gt 1600 ]; then
        # If the width is greater than 1600, resize the width to 1600
        ffmpeg -i "$video_file" -r 2 -vf "scale=1600:-1" "$dataset_dir/input/$videoname/image_${videoname}_%05d.jpg"
    else
        ffmpeg -i "$video_file" -r 2 "$dataset_dir/input/$videoname/image_${videoname}_%05d.jpg"
    fi
done

# convert images to dataset
echo create colmap dataset
echo convert.py -s "$dataset_dir" --resize
python3 convert.py -s "$dataset_dir" --resize

# train gaussian splatting
echo train gaussian splatting
echo train.py -s "$dataset_dir" -m "./output/$(basename $dataset_dir)"
python3 train.py -s "$dataset_dir" -m "./output/$(basename $dataset_dir)"