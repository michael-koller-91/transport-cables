import os
import shutil
import argparse
import numpy as np
from PIL import Image
from icecream import ic
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument(
    "--clean", action="store_true", help="remove an existing sprites directory"
)
parargs = parser.parse_args()

rng = np.random.default_rng(123456789)

sprites = Path("sprites")

TIERS = 1
OFFSET_CABLE = 14
PIXELS = 64
PIXELS_SHADOW = 70
THICKNESS = 16
TIER_FRAME_THICKNESS = 2
YELLOW_LINE_OFFSET = 39

images = {
    "array": list(),
    "filename": list(),
}


def rotate_clockwise(arr):
    return np.rot90(arr, 3, axes=(0, 1))


def rotate_counterclockwise(arr):
    return np.rot90(arr, 1, axes=(0, 1))


def rotate_180(arr):
    return rotate_clockwise(rotate_clockwise(arr))


def surround_by_transparent(arr, left, top, right=None, bottom=None):
    right = right or left
    bottom = bottom or top
    super_arr = np.zeros(
        (
            arr.shape[0] + top + bottom,
            arr.shape[1] + left + right,
            4,
        ),
        dtype=arr.dtype,
    )
    super_arr[top:-bottom, left:-right, :-1] = arr
    super_arr[top:-bottom, left:-right, -1] = 255
    return super_arr


def make_tier_frame(pixels, n_frames):
    arr = np.zeros((pixels, pixels, 3), dtype=np.uint8)
    arr[:, :, 1] = 255
    for k in range(1, 2 * n_frames):
        arr[
            k * TIER_FRAME_THICKNESS : -k * TIER_FRAME_THICKNESS,
            k * TIER_FRAME_THICKNESS : -k * TIER_FRAME_THICKNESS,
            1,
        ] = np.uint8(
            np.round(255 * np.cos(np.pi / 2 * k) ** 2)
        )  # alternate between black and green
    return arr


def make_tier_frame_top_bottom(pixels_x, pixels_y, n_frames):
    arr = np.zeros((pixels_x, pixels_y, 3), dtype=np.uint8)
    for k in range(0, n_frames + 1, 2):
        # top
        arr[k * TIER_FRAME_THICKNESS : (k + 1) * TIER_FRAME_THICKNESS, :, 1] = 255
        # bottom
        arr[
            -(k + 1) * TIER_FRAME_THICKNESS : arr.shape[0] - k * TIER_FRAME_THICKNESS,
            :,
            1,
        ] = 255
    return arr


def make_base_cable(pixels_x, pixels_y, shift):
    arr = np.zeros((pixels_y, pixels_x, 3), dtype=np.uint8)
    arr[:, :, :] = 100
    arr[:, ::YELLOW_LINE_OFFSET, 0] = 255
    arr[:, ::YELLOW_LINE_OFFSET, 1] = 255
    arr[pixels_y // 4 : -pixels_y // 4, 2::YELLOW_LINE_OFFSET, 0] = 255
    arr[pixels_y // 4 : -pixels_y // 4, 2::YELLOW_LINE_OFFSET, 1] = 255
    arr = np.roll(arr, shift, axis=1)
    return arr


def shifted_base_cable(tier, shift):
    arr = make_tier_frame(PIXELS, tier)
    base_cable = make_base_cable(PIXELS + OFFSET_CABLE, THICKNESS, shift)
    arr[PIXELS // 2 - THICKNESS // 2 : PIXELS // 2 + THICKNESS // 2, :, :] = base_cable[
        :, OFFSET_CABLE:, :
    ]
    return arr


def shifted_base_cable_connector(tier, shift):
    arr = make_tier_frame_top_bottom(PIXELS, OFFSET_CABLE, tier)
    base_cable = make_base_cable(PIXELS + OFFSET_CABLE, THICKNESS, shift)
    arr[PIXELS // 2 - THICKNESS // 2 : PIXELS // 2 + THICKNESS // 2, :, :] = base_cable[
        :, :OFFSET_CABLE, :
    ]
    return arr


def merge_upper_left(array_horizontal, array_vertical):
    arr = make_tier_frame(PIXELS, tier)
    arr[
        : PIXELS // 2 + THICKNESS // 2, PIXELS // 2 - THICKNESS // 2 :, :
    ] = array_vertical[
        : PIXELS // 2 + THICKNESS // 2, PIXELS // 2 - THICKNESS // 2 :, :
    ]
    arr[
        : PIXELS // 2 + THICKNESS // 2, : PIXELS // 2 + THICKNESS // 2, :
    ] += array_horizontal[
        : PIXELS // 2 + THICKNESS // 2, : PIXELS // 2 + THICKNESS // 2, :
    ]
    arr[arr == np.mod(2 * 100, 2**8)] = 100
    arr[arr == np.mod(2 * 255, 2**8)] = 255
    arr[arr == np.mod(100 + 255, 2**8)] = 255
    return arr


def merge_upper_right(array_horizontal, array_vertical):
    arr = make_tier_frame(PIXELS, tier)
    arr[
        : PIXELS // 2 + THICKNESS // 2, PIXELS // 2 - THICKNESS // 2 :, :
    ] = array_vertical[
        : PIXELS // 2 + THICKNESS // 2, PIXELS // 2 - THICKNESS // 2 :, :
    ]
    arr[
        : PIXELS // 2 + THICKNESS // 2, PIXELS // 2 - THICKNESS // 2 :, :
    ] += array_horizontal[
        : PIXELS // 2 + THICKNESS // 2, PIXELS // 2 - THICKNESS // 2 :, :
    ]
    arr[arr == np.mod(2 * 100, 2**8)] = 100
    arr[arr == np.mod(2 * 255, 2**8)] = 255
    arr[arr == np.mod(100 + 255, 2**8)] = 255
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
base_cable = make_base_cable(PIXELS + OFFSET_CABLE, PIXELS, 0)
images["array"].append(base_cable)
images["filename"].append("base_straight.png")

for tier in range(1, TIERS + 1):
    # straight cables
    for i in range(4):
        for j in range(16):
            arr = shifted_base_cable(tier, 2 * j)
            if i // 2:
                arr = np.rot90(arr, k=i * 2 + 1)
            else:
                arr = np.rot90(arr, k=i * 2)

            arr = surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
            if j == 0:
                super_arr = arr
            else:
                super_arr = np.concatenate([super_arr, arr], axis=1)
        if i == 0:
            straight_cables = super_arr
        else:
            straight_cables = np.concatenate([straight_cables, super_arr], axis=0)

    # curved cables
    for j in range(16):
        arr_left_right = shifted_base_cable(tier, 2 * j)
        arr_right_left = np.rot90(arr_left_right, 2, axes=(0, 1))
        arr_bottom_top = np.rot90(arr_left_right, 1, axes=(0, 1))

        arr = merge_upper_right(arr_right_left, arr_bottom_top)

        arr = surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
        arr_rotated = rotate_clockwise(arr)
        if j == 0:
            super_arr_r_to_t = arr
            super_arr_b_to_r = arr_rotated
        else:
            super_arr_r_to_t = np.concatenate([super_arr_r_to_t, arr], axis=1)
            super_arr_b_to_r = np.concatenate([super_arr_b_to_r, arr_rotated], axis=1)
    for j in range(16):
        arr_left_right = shifted_base_cable(tier, 2 * j)
        arr_top_bottom = np.rot90(arr_left_right, 3, axes=(0, 1))
        arr = merge_upper_right(arr_left_right, arr_top_bottom)

        arr = surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
        arr_rotated = rotate_clockwise(arr)
        if j == 0:
            super_arr_t_to_r = arr
            super_arr_r_to_b = arr_rotated
        else:
            super_arr_t_to_r = np.concatenate([super_arr_t_to_r, arr], axis=1)
            super_arr_r_to_b = np.concatenate([super_arr_r_to_b, arr_rotated], axis=1)
    for j in range(16):
        arr_left_right = shifted_base_cable(tier, 2 * j)
        arr_bottom_top = np.rot90(arr_left_right, 1, axes=(0, 1))

        arr = merge_upper_left(arr_left_right, arr_bottom_top)

        arr = surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
        arr_rotated = rotate_counterclockwise(arr)
        if j == 0:
            super_arr_l_to_t = arr
            super_arr_b_to_l = arr_rotated
        else:
            super_arr_l_to_t = np.concatenate([super_arr_l_to_t, arr], axis=1)
            super_arr_b_to_l = np.concatenate([super_arr_b_to_l, arr_rotated], axis=1)
    for j in range(16):
        arr_left_right = shifted_base_cable(tier, 2 * j)
        arr_right_left = np.rot90(arr_left_right, 2, axes=(0, 1))
        arr_top_bottom = np.rot90(arr_left_right, 3, axes=(0, 1))

        arr = merge_upper_left(arr_right_left, arr_top_bottom)

        arr = surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
        arr_rotated = rotate_counterclockwise(arr)
        if j == 0:
            super_arr_t_to_l = arr
            super_arr_l_to_b = arr_rotated
        else:
            super_arr_t_to_l = np.concatenate([super_arr_t_to_l, arr], axis=1)
            super_arr_l_to_b = np.concatenate([super_arr_l_to_b, arr_rotated], axis=1)

    curved_cables = np.concatenate(
        [
            super_arr_r_to_t,
            super_arr_t_to_r,
            super_arr_l_to_t,
            super_arr_t_to_l,
            super_arr_b_to_r,
            super_arr_r_to_b,
            super_arr_b_to_l,
            super_arr_l_to_b,
        ],
        axis=0,
    )

    # cable connectors
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j)
        arr = rotate_counterclockwise(arr)

        arr = surround_by_transparent(
            arr,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
        )
        arr_rotated = rotate_180(arr)
        if j == 0:
            super_arr_b_to_t_top = arr
            super_arr_b_to_t_bottom = arr_rotated
        else:
            super_arr_b_to_t_top = np.concatenate([super_arr_b_to_t_top, arr], axis=1)
            super_arr_b_to_t_bottom = np.concatenate(
                [super_arr_b_to_t_bottom, arr_rotated], axis=1
            )
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j)
        arr = rotate_clockwise(arr)

        arr = surround_by_transparent(
            arr,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
        )
        arr_rotated = rotate_180(arr)
        if j == 0:
            super_arr_t_to_b_top = arr
            super_arr_t_to_b_bottom = arr_rotated
        else:
            super_arr_t_to_b_top = np.concatenate([super_arr_t_to_b_top, arr], axis=1)
            super_arr_t_to_b_bottom = np.concatenate(
                [super_arr_t_to_b_bottom, arr_rotated], axis=1
            )
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j)

        arr = surround_by_transparent(
            arr,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2,
        )
        arr_rotated = rotate_180(arr)
        if j == 0:
            super_arr_l_to_r_right = arr
            super_arr_l_to_r_left = arr_rotated
        else:
            super_arr_l_to_r_right = np.concatenate(
                [super_arr_l_to_r_right, arr], axis=1
            )
            super_arr_l_to_r_left = np.concatenate(
                [super_arr_l_to_r_left, arr_rotated], axis=1
            )
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j)
        arr = rotate_180(arr)

        arr = surround_by_transparent(
            arr,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2,
        )
        arr_rotated = rotate_180(arr)
        if j == 0:
            super_arr_r_to_l_right = arr
            super_arr_r_to_l_left = arr_rotated
        else:
            super_arr_r_to_l_right = np.concatenate(
                [super_arr_r_to_l_right, arr], axis=1
            )
            super_arr_r_to_l_left = np.concatenate(
                [super_arr_r_to_l_left, arr_rotated], axis=1
            )

    cable_connectors = np.concatenate(
        [
            super_arr_b_to_t_top,
            super_arr_t_to_b_top,
            super_arr_l_to_r_right,
            super_arr_r_to_l_right,
            super_arr_b_to_t_bottom,
            super_arr_t_to_b_bottom,
            super_arr_l_to_r_left,
            super_arr_r_to_l_left,
        ],
        axis=0,
    )

    transport_cable = np.concatenate(
        [straight_cables, curved_cables, cable_connectors], axis=0
    )

    images["array"].append(transport_cable)
    images["filename"].append(f"cable-t{tier}.png")
    images["array"].append(transport_cable)
    images["filename"].append(f"hr-cable-t{tier}.png")

#
# provider
#
for tier in range(1, TIERS + 1):
    arr = make_tier_frame(PIXELS, tier)

    arr[
        PIXELS // 2 - THICKNESS : PIXELS // 2 + THICKNESS,
        PIXELS // 2 - THICKNESS : PIXELS // 2 + THICKNESS,
        2,
    ] = 255

    images["array"].append(arr)
    images["filename"].append(f"provider-t{tier}.png")
    images["array"].append(arr)
    images["filename"].append(f"hr-provider-t{tier}.png")

    #
    arr = np.zeros((PIXELS_SHADOW, PIXELS_SHADOW, 3), dtype=np.uint8)

    images["array"].append(arr)
    images["filename"].append(f"provider-t{tier}-shadow.png")
    images["array"].append(arr)
    images["filename"].append(f"hr-provider-t{tier}-shadow.png")


#
# requester
#
for tier in range(1, TIERS + 1):
    for i in range(4):
        arr = make_tier_frame(PIXELS, tier)

        arr[
            : PIXELS // 2 + THICKNESS,
            PIXELS // 2 - THICKNESS : PIXELS // 2 + THICKNESS,
            0,
        ] = 255
        arr = np.rot90(arr, k=i * 3)

        arr = surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
        if i == 0:
            super_arr = arr
        else:
            super_arr = np.concatenate([super_arr, arr], axis=1)

    images["array"].append(super_arr)
    images["filename"].append(f"requester-t{tier}.png")
    images["array"].append(super_arr)
    images["filename"].append(f"hr-requester-t{tier}.png")

    for i in range(4):
        arr = np.zeros((PIXELS_SHADOW, PIXELS_SHADOW, 3), dtype=np.uint8)
        arr = surround_by_transparent(arr, PIXELS_SHADOW // 2, PIXELS_SHADOW // 2)
        if i == 0:
            super_arr = arr
        else:
            super_arr = np.concatenate([super_arr, arr], axis=1)

    images["array"].append(super_arr)
    images["filename"].append(f"requester-t{tier}-shadow.png")
    images["array"].append(super_arr)
    images["filename"].append(f"hr-requester-t{tier}-shadow.png")


#
# requester-container
#
for tier in range(1, TIERS + 1):
    PIXELS = 64
    arr = make_tier_frame(PIXELS, tier)

    arr[
        PIXELS // 2 - THICKNESS : PIXELS // 2 + THICKNESS,
        PIXELS // 2 - THICKNESS : PIXELS // 2 + THICKNESS,
        0,
    ] = 255

    images["array"].append(arr)
    images["filename"].append(f"requester-container-t{tier}.png")
    images["array"].append(arr)
    images["filename"].append(f"hr-requester-container-t{tier}.png")

    #
    arr = np.zeros((PIXELS_SHADOW, PIXELS_SHADOW, 3), dtype=np.uint8)

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
