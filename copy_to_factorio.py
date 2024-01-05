import os
import glob
import shutil
import json
from pathlib import Path


source = Path(os.getcwd())
destination = Path(r"C:\Users\Admin\AppData\Roaming\Factorio\mods")
folders = ["locale", "prototypes", "sprites"]
files = ["control.lua", "data.lua", "debuglib.lua", "info.json", "lib.lua"]

with open("info.json", "r") as f:
    version = json.load(f)["version"]

mod_folder = f"transport-cables_{version}"
dest = destination / mod_folder

print("source:", source)
print("destination:", destination / mod_folder)

# delete old transport-cables folders
for f in glob.glob(str(destination / "transport-cables_*")):
    shutil.rmtree(f)
    print("removed:", f)

# make new transport-cables folder
os.mkdir(destination / mod_folder)
print("made:", destination / mod_folder)

for folder in folders:
    shutil.copytree(source / folder, dest / folder)
    print("copied to:", dest / folder)

for file in files:
    shutil.copy(source / file, dest / file)
    print("copied to:", dest / file)
