import os
import shutil
import argparse
import gen_icons
import gen_entities
import gen_technologies
from pathlib import Path


parser = argparse.ArgumentParser()
parser.add_argument(
    "--clean", action="store_true", help="remove an existing sprites directory"
)
parargs = parser.parse_args()

folder_sprites = Path("sprites")
folder_entities = folder_sprites / "entities"
folder_icons = folder_sprites / "icons"
folder_technologies = folder_sprites / "technologies"

# create the sprites directory if it does not exist
if parargs.clean and folder_sprites.exists():
    shutil.rmtree(folder_sprites)
if not folder_sprites.exists():
    os.mkdir(str(folder_sprites))
    os.mkdir(str(folder_entities))
    os.mkdir(str(folder_icons))
    os.mkdir(str(folder_technologies))


gen_entities.gen(folder_entities)
gen_icons.gen(folder_icons)
gen_technologies.gen(folder_technologies)
