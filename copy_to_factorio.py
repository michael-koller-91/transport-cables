import os
import glob
import shutil
import json
from pathlib import Path


with open("info.json", "r") as f:
    version = json.load(f)["version"]


source = Path(os.getcwd())
print("source:", source)

destination = Path(r"C:\Users\Admin\AppData\Roaming\Factorio\mods")
mod_folder = f"transport-cables_{version}"
dest = destination / mod_folder
print("destination:", destination / mod_folder)

# delete old transport-cables folders
for f in glob.glob(str(destination / "transport-cables_*")):
    shutil.rmtree(f)
    print("removed:", f)

# make new transport-cables folder
os.mkdir(destination / mod_folder)
print("made:", destination / mod_folder)

folders = ["locale", "prototypes", "sprites"]
files = ["control.lua", "data.lua", "info.json", "lib.lua"]


for folder in folders:
    shutil.copytree(source / folder, dest / folder)
    print("copied to:", dest / folder)

for file in files:
    shutil.copy(source / file, dest / file)
    print("copied to:", dest / file)
