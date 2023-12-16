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
thickness = 16
tier_frame_thickness = 2

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


def make_tier_frame(pixels, thickness, n_frames):
    arr = np.zeros((pixels, pixels, 3), dtype=np.uint8)
    arr[:, :, 1] = 255
    for k in range(1, 2 * n_frames):
        arr[
            k * thickness : -k * thickness,
            k * thickness : -k * thickness,
            1,
        ] = np.uint8(
            np.round(255 * np.cos(np.pi / 2 * k) ** 2)
        )  # alternate between black and green
    return arr


def shifted_base_cable(pixels, thickness, tier_frame_thickness, tier, shift):
    arr = make_tier_frame(pixels, tier_frame_thickness, tier)
    arr[pixels // 2 - thickness : pixels // 2 + thickness, :, :] = 100
    arr[pixels // 2 - thickness // 2 : pixels // 2 + thickness // 2, ::22, 0] = 255
    arr[pixels // 2 - thickness // 2 : pixels // 2 + thickness // 2, ::22, 1] = 255
    arr[pixels // 2 - thickness // 4 : pixels // 2 + thickness // 4, 2::22, 0] = 255
    arr[pixels // 2 - thickness // 4 : pixels // 2 + thickness // 4, 2::22, 1] = 255
    arr[pixels // 2 - thickness : pixels // 2 + thickness, :, :] = np.roll(
        arr[pixels // 2 - thickness : pixels // 2 + thickness, :, :], shift, axis=1
    )
    return arr


#
# create the sprites directory if it does not exist
#
if parargs.clean and sprites.exists():
    shutil.rmtree(str(sprites))
if not sprites.exists():
    os.mkdir(str(sprites))


#
# cable
#
for tier in range(1, n_tiers + 1):
    # straight cables
    for i in range(4):
        for j in range(16):
            arr = shifted_base_cable(
                pixels, thickness, tier_frame_thickness, tier, 2 * j
            )
            if i // 2:
                arr = np.rot90(arr, k=i * 2 + 1)
            else:
                arr = np.rot90(arr, k=i * 2)

            arr = surround_by_transparent(arr, pixels // 2, pixels // 2)
            if j == 0:
                super_arr = arr
            else:
                super_arr = np.concatenate([super_arr, arr], axis=1)
        if i == 0:
            straight_cables = super_arr
        else:
            straight_cables = np.concatenate([straight_cables, super_arr], axis=0)

    transport_cable = straight_cables

    images["array"].append(transport_cable)
    images["filename"].append(f"cable-t{tier}.png")
    images["array"].append(super_arr)
    images["filename"].append(f"hr-cable-t{tier}.png")

#
# provider
#
for tier in range(1, n_tiers + 1):
    arr = make_tier_frame(pixels, tier_frame_thickness, tier)

    arr[
        pixels // 2 - thickness : pixels // 2 + thickness,
        pixels // 2 - thickness : pixels // 2 + thickness,
        2,
    ] = 255

    images["array"].append(arr)
    images["filename"].append(f"provider-t{tier}.png")
    images["array"].append(arr)
    images["filename"].append(f"hr-provider-t{tier}.png")

    #
    arr = np.zeros((pixels_shadow, pixels_shadow, 3), dtype=np.uint8)

    images["array"].append(arr)
    images["filename"].append(f"provider-t{tier}-shadow.png")
    images["array"].append(arr)
    images["filename"].append(f"hr-provider-t{tier}-shadow.png")


#
# requester
#
for tier in range(1, n_tiers + 1):
    for i in range(4):
        arr = make_tier_frame(pixels, tier_frame_thickness, tier)

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
    images["filename"].append(f"requester-t{tier}.png")
    images["array"].append(super_arr)
    images["filename"].append(f"hr-requester-t{tier}.png")

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
    images["filename"].append(f"requester-t{tier}-shadow.png")
    images["array"].append(super_arr)
    images["filename"].append(f"hr-requester-t{tier}-shadow.png")


#
# requester-container
#
for tier in range(1, n_tiers + 1):
    pixels = 64
    arr = make_tier_frame(pixels, tier_frame_thickness, tier)

    arr[
        pixels // 2 - thickness : pixels // 2 + thickness,
        pixels // 2 - thickness : pixels // 2 + thickness,
        0,
    ] = 255

    images["array"].append(arr)
    images["filename"].append(f"requester-container-t{tier}.png")
    images["array"].append(arr)
    images["filename"].append(f"hr-requester-container-t{tier}.png")

    #
    arr = np.zeros((pixels_shadow, pixels_shadow, 3), dtype=np.uint8)

    images["array"].append(arr)
    images["filename"].append(f"requester-container-t{tier}-shadow.png")
    images["array"].append(arr)
    images["filename"].append(f"hr-requester-container-t{tier}-shadow.png")


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
