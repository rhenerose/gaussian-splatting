#!/bin/sh

dataset_dir=$1
method=$(echo $2 | tr '[:lower:]' '[:upper:]')
workspace_dir=$dataset_dir/distorted

mkdir -p $workspace_dir

if [ -z "$2" ]; then
    # check installed hloc module
    if python3 -c "import hloc" >/dev/null 2>&1; then
        method="HLOC"
    else
        method="COLMAP"
    fi
fi

if [ $method = "HLOC" ]; then
    # hloc export_poses
    python3 convert_hloc.py --dataset_dir $dataset_dir
elif [ $method = "COLMAP" ]; then
    # colmap automatic_reconstructor
    colmap automatic_reconstructor \
        --workspace_path $workspace_dir \
        --image_path $dataset_dir/input/ \
        --data_type video \
        --quality high \
        --camera_model OPENCV \
        --single_camera 1 \
        --sparse 1 \
        --dense 0 \
        --use_gpu 1
else
    echo "Invalid method '$2'"
    exit 1
fi

# colmap image_undistorter
colmap image_undistorter \
    --image_path $dataset_dir/input/ \
    --input_path $workspace_dir/sparse/0 \
    --output_path $dataset_dir \
    --output_type COLMAP

# move sparse model files
mkdir -p $dataset_dir/sparse/0
for file in $dataset_dir/sparse/*; do
    if [ "$(basename "$file")" != "0" ]; then
        mv "$file" "$dataset_dir/sparse/0/"
    fi
done

# resize images
mkdir -p $dataset_dir/images_2
mkdir -p $dataset_dir/images_4
mkdir -p $dataset_dir/images_8

resize_process_directory() {
    for file in "$1"/*; do
        if [ -d "$file" ]; then
            resize_process_directory "$file"
        else
            echo $file
            dir_name=$(dirname "$file")
            subdir_name=${dir_name#$dataset_dir/images}
            if [ "$subdir_name" = "" ]; then
                subdir_name="."
            else
                mkdir -p $dataset_dir/images_2/$subdir_name
                mkdir -p $dataset_dir/images_4/$subdir_name
                mkdir -p $dataset_dir/images_8/$subdir_name
            fi

            # resize images use ImageMagick
            convert ${file}[50%] -write \
                mpr:thumb -write $dataset_dir/images_2/$subdir_name/$(basename $file) +delete \
                mpr:thumb -resize 50% -write mpr:thumb -write $dataset_dir/images_4/$subdir_name/$(basename $file) +delete \
                mpr:thumb -resize 50% $dataset_dir/images_8/$subdir_name/$(basename $file)
        fi
    done
}

resize_process_directory $dataset_dir/images


# python3 train.py -s $dataset_dir -m ./output/$(basename $dataset_dir)