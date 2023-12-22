import os
import shutil
import argparse
from icecream import ic
from pathlib import Path
import gen_entities
import gen_icons


parser = argparse.ArgumentParser()
parser.add_argument(
    "--clean", action="store_true", help="remove an existing sprites directory"
)
parargs = parser.parse_args()

folder_sprites = Path("sprites")
folder_entities = folder_sprites / "entities"
folder_icons = folder_sprites / "icons"

#
# create the sprites directory if it does not exist
#
if parargs.clean and folder_sprites.exists():
    shutil.rmtree(str(folder_sprites))
if not folder_sprites.exists():
    os.mkdir(str(folder_sprites))
    os.mkdir(str(folder_entities))
    os.mkdir(str(folder_icons))


gen_entities.gen(folder_entities)
gen_icons.gen(folder_icons)
