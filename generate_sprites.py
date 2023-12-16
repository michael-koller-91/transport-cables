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

rng = np.random.default_rng(123456789)

sprites = Path("sprites")

n_tiers = 2
pixels = 64
pixels_shadow = 70
pixels_space = 20
thickness = 10

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
# placeholder
#
arr = np.zeros((32, 32, 3), dtype=np.uint8)
arr[10:-10, 10:-10, 0] = 255
arr[10:-10, 10:-10, 2] = 255

images["array"].append(arr)
images["filename"].append("low-res-placeholder.png")

arr = np.ones((48, 48, 3), dtype=np.uint8) * 255
arr[:, :, 1] = 0
arr[3:-3, 3:-3, :] = 0

images["array"].append(arr)
images["filename"].append("low-res-placeholder-shadow.png")


#
# provider
#
for t in range(1, n_tiers + 1):
    thin_border = 2
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

    arr[
        pixels // 2 - thickness : pixels // 2 + thickness,
        pixels // 2 - thickness : pixels // 2 + thickness,
        2,
    ] = 255

    images["array"].append(arr)
    images["filename"].append(f"provider-t{t}.png")

    #
    arr = np.zeros((pixels_shadow, pixels_shadow, 3), dtype=np.uint8)

    images["array"].append(arr)
    images["filename"].append(f"provider-t{t}-shadow.png")


#
# requester
#
for t in range(1, n_tiers + 1):
    thin_border = 2
    super_arr = np.zeros((pixels, 4 * pixels + 3 * pixels_space, 4), dtype=np.uint8)
    for i in range(4):
        arr = np.zeros((pixels, pixels, 4), dtype=np.uint8)
        arr[:, :, -1] = 255
        arr[:, :, 1] = 255
        for k in range(1, 2 * t):
            arr[
                k * thin_border : -k * thin_border,
                k * thin_border : -k * thin_border,
                1,
            ] = np.uint8(
                np.round(255 * np.cos(np.pi / 2 * k) ** 2)
            )  # alternate between black and green

        arr[
            : pixels // 2 + thickness,
            pixels // 2 - thickness : pixels // 2 + thickness,
            0,
        ] = 255
        arr = np.rot90(arr, k=i * 3)

        super_arr[
            :, i * pixels + i * pixels_space : (i + 1) * pixels + i * pixels_space, :
        ] = arr

    images["array"].append(super_arr)
    images["filename"].append(f"requester-t{t}.png")

    #
    super_arr = np.zeros((pixels_shadow, 4 * pixels_shadow + 3 * pixels_space, 4), dtype=np.uint8)
    for i in range(4):
        arr = np.zeros((pixels_shadow, pixels_shadow, 4), dtype=np.uint8)
        arr[:, :, -1] = 255

        super_arr[
            :, i * pixels_shadow + i * pixels_space : (i + 1) * pixels_shadow + i * pixels_space, :
        ] = arr
    arr = np.zeros((pixels_shadow, pixels_shadow, 3), dtype=np.uint8)

    images["array"].append(super_arr)
    images["filename"].append(f"requester-t{t}-shadow.png")


#
# requester-container
#
for t in range(1, n_tiers + 1):
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

    arr[
        pixels // 2 - thickness : pixels // 2 + thickness,
        pixels // 2 - thickness : pixels // 2 + thickness,
        0,
    ] = 255

    images["array"].append(arr)
    images["filename"].append(f"requester-container-t{t}.png")

    #
    arr = np.zeros((pixels_shadow, pixels_shadow, 3), dtype=np.uint8)

    images["array"].append(arr)
    images["filename"].append(f"requester-container-t{t}-shadow.png")


#
# save all images
#
for array, filename in zip(images["array"], images["filename"]):
    if array.shape[-1] == 3:
        Image.fromarray(array, mode="RGB").save(sprites / filename)
    elif array.shape[-1] == 4:
        Image.fromarray(array, mode="RGBA").save(sprites / filename)
    else:
        raise ValueError("Unknown: array.shape[-1] =", array.ndim)
