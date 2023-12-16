import os
import shutil
import argparse
import numpy as np
from PIL import Image
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument(
    "--clean", action="store_true", help="remove an existing sprites directory"
)
parargs = parser.parse_args()

sprites = Path("sprites")
n_tiers = 3
rng = np.random.default_rng(123456789)
images = {
    "array": list(),
    "filename": list(),
}

#
# create the sprites directory if it does not exist
#
if parargs.clean and sprites.exists():
    shutil.rmtree(str(sprites))
if not sprites.exists():
    os.mkdir(str(sprites))


#
# provider
#
for t in range(1, n_tiers + 1):
    border = 20
    thin_border = 2
    pixels = 64
    arr = np.zeros((pixels, pixels, 3), dtype=np.uint8)
    arr[:, :, 1] = 255
    for k in range(1, 2 * t):
        arr[
            k * thin_border : -k * thin_border,
            k * thin_border : -k * thin_border,
            1,
        ] = np.uint8(
            np.round(255 * np.cos(np.pi / 2 * k) ** 2)
        )  # alternate between black and green

    arr[border:-border, border:-border, 1] = 0
    arr[border:-border, border:-border, 2] = rng.integers(
        100, 256, (pixels - 2 * border, pixels - 2 * border)
    )

    images["array"].append(arr)
    images["filename"].append(f"provider-t{t}.png")

    #
    arr = np.zeros((70, 70, 3), dtype=np.uint8)

    images["array"].append(arr)
    images["filename"].append(f"provider-t{t}-shadow.png")


#
# save all images
#
for array, filename in zip(images["array"], images["filename"]):
    Image.fromarray(array, mode="RGB").save(sprites / filename)
