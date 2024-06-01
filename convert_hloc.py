# import os
import shutil
from pathlib import Path

from hloc import (
    extract_features,
    match_features,
    reconstruction,
    # pairs_from_exhaustive,
    pairs_from_retrieval,
)

import pycolmap

import argparse

# args parser
parser = argparse.ArgumentParser()
parser.add_argument("--dataset_dir", required=True, type=Path)

args = parser.parse_args()
dataset_dir = args.dataset_dir

# init params
datasets = Path(dataset_dir)
images = datasets / "input"
workspaces = datasets / "distorted"
if workspaces.exists():
    # Remove previous results
    shutil.rmtree(workspaces)

sfm_pairs = workspaces / "pairs-sfm.txt"
loc_pairs = workspaces / "pairs-loc.txt"
sfm_dir = workspaces / "sfm"
features = workspaces / "features.h5"
matches = workspaces / "matches.h5"


# get all references
def get_references(dir, references=None):
    references = [] if references is None else references
    for p in dir.iterdir():
        if p.is_file():
            references.append(str(p.relative_to(images)))
        elif p.is_dir():
            get_references(p, references)

    return references


references = get_references(images)

# init hloc configs
retrieval_conf = extract_features.confs["netvlad"]
feature_conf = extract_features.confs["superpoint_aachen"]
matcher_conf = match_features.confs["superglue"]

# set retrieval configs
# retrieval_conf["model"]["model_name"] = "VGG16-NetVLAD-Pitts30K"
retrieval_conf["model"]["model_name"] = "VGG16-NetVLAD-TokyoTM"
retrieval_conf["model"]["whiten"] = True

# extract features and match
retrieval_path = extract_features.main(
    retrieval_conf, images, workspaces, image_list=references
)
pairs_from_retrieval.main(retrieval_path, sfm_pairs, num_matched=5)

extract_features.main(
    feature_conf, images, image_list=references, feature_path=features
)
# pairs_from_exhaustive.main(sfm_pairs, image_list=references)
match_features.main(matcher_conf, sfm_pairs, features=features, matches=matches)

# reconstruct SfM model
model = reconstruction.main(
    sfm_dir,
    images,
    sfm_pairs,
    features,
    matches,
    camera_mode=pycolmap.CameraMode.SINGLE,
    image_list=references,
)

# Export to COLMAP format
export_path = workspaces / "sparse/0"
if export_path.exists():
    shutil.rmtree(export_path)
export_path.mkdir(parents=True, exist_ok=True)
model.write(export_path)
