#!/bin/sh

dataset_dir=$1
workspace_dir=$dataset_dir/distorted

mkdir -p $workspace_dir

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

# colmap image_undistorter
colmap image_undistorter \
    --image_path $dataset_dir/input/ \
    --input_path $workspace_dir/sparse/0 \
    --output_path $dataset_dir \
    --output_type COLMAP

# move sparse model files
mkdir $dataset_dir/sparse/0
for file in $dataset_dir/sparse/*; do
    if [ "$(basename "$file")" != "0" ]; then
        mv "$file" "$dataset_dir/sparse/0/"
    fi
done

# python3 train.py -s $dataset_dir -m ./output/$(basename $dataset_dir)