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
thickness = 10

images = {
    "array": list(),
    "filename": list(),
}


def surround_by_transparent(arr, space_left, space_top):
    super_arr = np.zeros(
        (arr.shape[0] + 2 * space_top, arr.shape[1] + 2 * space_left, 4),
        dtype=arr.dtype,
    )
    super_arr[space_top:-space_top, space_left:-space_left, :-1] = arr
    super_arr[space_top:-space_top, space_left:-space_left, -1] = 255
    return super_arr


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
    images["array"].append(arr)
    images["filename"].append(f"hr-provider-t{t}.png")

    #
    arr = np.zeros((pixels_shadow, pixels_shadow, 3), dtype=np.uint8)

    images["array"].append(arr)
    images["filename"].append(f"provider-t{t}-shadow.png")
    images["array"].append(arr)
    images["filename"].append(f"hr-provider-t{t}-shadow.png")


#
# requester
#
for t in range(1, n_tiers + 1):
    thin_border = 2
    for i in range(4):
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
            : pixels // 2 + thickness,
            pixels // 2 - thickness : pixels // 2 + thickness,
            0,
        ] = 255
        arr = np.rot90(arr, k=i * 3)

        arr = surround_by_transparent(arr, pixels // 2, pixels // 2)
        if i == 0:
            super_arr = arr
        else:
            super_arr = np.concatenate(
                [super_arr, arr],
                axis=1,
            )

    images["array"].append(super_arr)
    images["filename"].append(f"requester-t{t}.png")
    images["array"].append(super_arr)
    images["filename"].append(f"hr-requester-t{t}.png")

    for i in range(4):
        arr = np.zeros((pixels_shadow, pixels_shadow, 3), dtype=np.uint8)
        arr = surround_by_transparent(arr, pixels_shadow // 2, pixels_shadow // 2)
        if i == 0:
            super_arr = arr
        else:
            super_arr = np.concatenate(
                [super_arr, arr],
                axis=1,
            )

    images["array"].append(super_arr)
    images["filename"].append(f"requester-t{t}-shadow.png")
    images["array"].append(super_arr)
    images["filename"].append(f"hr-requester-t{t}-shadow.png")


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
    images["array"].append(arr)
    images["filename"].append(f"hr-requester-container-t{t}.png")

    #
    arr = np.zeros((pixels_shadow, pixels_shadow, 3), dtype=np.uint8)

    images["array"].append(arr)
    images["filename"].append(f"requester-container-t{t}-shadow.png")
    images["array"].append(arr)
    images["filename"].append(f"hr-requester-container-t{t}-shadow.png")


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
