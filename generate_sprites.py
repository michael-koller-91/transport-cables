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

folder_sprites = Path("sprites")
folder_entities = folder_sprites / "entities"

TIERS = 1
OFFSET_CABLE = 14
PIXELS = 64
PIXELS_SHADOW = 70
THICKNESS = 16
TIER_FRAME_THICKNESS = 2
YELLOW_LINE_OFFSET = 32

images = {
    "array": list(),
    "filename": list(),
}


def make_transparent(pixels_x, pixels_y):
    arr = np.zeros((pixels_y, pixels_x, 4), dtype=np.uint8)
    arr[:, :, -1] = 0
    return arr


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


def make_base_cable(pixels_x, pixels_y):
    arr = np.zeros((pixels_y, 3 * pixels_x, 3), dtype=np.uint8)
    arr[:, :, :] = 100
    arr[pixels_y // 3 : -pixels_y // 3, ::YELLOW_LINE_OFFSET, 0] = 255
    arr[pixels_y // 3 : -pixels_y // 3, ::YELLOW_LINE_OFFSET, 1] = 255
    arr[pixels_y // 3 : -pixels_y // 3, 1::YELLOW_LINE_OFFSET, 0] = 255
    arr[pixels_y // 3 : -pixels_y // 3, 1::YELLOW_LINE_OFFSET, 1] = 255
    arr[pixels_y // 8 : -pixels_y // 8, 4::YELLOW_LINE_OFFSET, 0] = 255
    arr[pixels_y // 8 : -pixels_y // 8, 4::YELLOW_LINE_OFFSET, 1] = 255
    arr[pixels_y // 8 : -pixels_y // 8, 5::YELLOW_LINE_OFFSET, 0] = 255
    arr[pixels_y // 8 : -pixels_y // 8, 5::YELLOW_LINE_OFFSET, 1] = 255
    arr[pixels_y // 3 : -pixels_y // 3, 8::YELLOW_LINE_OFFSET, 0] = 255
    arr[pixels_y // 3 : -pixels_y // 3, 8::YELLOW_LINE_OFFSET, 1] = 255
    arr[pixels_y // 3 : -pixels_y // 3, 9::YELLOW_LINE_OFFSET, 0] = 255
    arr[pixels_y // 3 : -pixels_y // 3, 9::YELLOW_LINE_OFFSET, 1] = 255
    return arr


def center_of_base_cable(pixels_x, pixels_y, shift):
    base_cable = make_base_cable(pixels_x, pixels_y)
    return base_cable[:, pixels_x - shift : 2 * pixels_x - shift, :]


def beginning_of_base_cable(pixels_x, pixels_y, offset, shift):
    base_cable = make_base_cable(pixels_x, pixels_y)
    return base_cable[:, pixels_x - shift - offset : pixels_x - shift, :]


def end_of_base_cable(pixels_x, pixels_y, offset, shift):
    base_cable = make_base_cable(pixels_x, pixels_y)
    return base_cable[:, pixels_x - shift - offset + 14 : pixels_x - shift + 14, :]


def shifted_base_cable(tier, shift):
    arr = make_tier_frame(PIXELS, tier)
    base_cable_center = center_of_base_cable(PIXELS, THICKNESS, shift)
    arr[
        PIXELS // 2 - THICKNESS // 2 : PIXELS // 2 + THICKNESS // 2, :, :
    ] = base_cable_center
    return arr


def shifted_base_cable_connector(tier, shift, beginning=False, end=False):
    arr = make_tier_frame_top_bottom(PIXELS, OFFSET_CABLE, tier)
    if beginning:
        base_cable = beginning_of_base_cable(PIXELS, THICKNESS, OFFSET_CABLE, shift)
    if end:
        base_cable = end_of_base_cable(PIXELS, THICKNESS, OFFSET_CABLE, shift)
        base_cable *= 2
    if not (beginning or end):
        raise ValueError("need beginning or end")
    if beginning and end:
        raise ValueError("cannot have beginning and end")
    arr[PIXELS // 2 - THICKNESS // 2 : PIXELS // 2 + THICKNESS // 2, :, :] = base_cable
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
if parargs.clean and folder_sprites.exists():
    shutil.rmtree(str(folder_sprites))
if not folder_sprites.exists():
    os.mkdir(str(folder_sprites))
    os.mkdir(str(folder_entities))


#
# cable
#
# two helper images for pixel alignment
base_cable = make_base_cable(PIXELS, PIXELS)
images["array"].append(base_cable)
images["filename"].append("base_straight.png")

for shift in range(30):
    base_cable_shifted = shifted_base_cable(1, shift)
    base_cable_connector_beginning = (
        shifted_base_cable_connector(1, shift, True, False) * 2
    )
    base_cable_connector_end = shifted_base_cable_connector(1, shift, False, True) * 2
    arr = np.concatenate(
        [base_cable_connector_beginning, base_cable_shifted, base_cable_connector_end],
        axis=1,
    )
    if shift == 0:
        base_cable_alignment = arr
    else:
        base_cable_alignment = np.concatenate([base_cable_alignment, arr], axis=0)
images["array"].append(base_cable_alignment)
images["filename"].append("base_cable_alignment.png")

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

    #
    # cable connectors
    #
    # If we were standing on a belt and facing in the direction in which it is
    # traveling, the beginning of the belt is behind us and the end of the belt
    # is ahead of us. With this nomenclature, we have the following layout of
    # the 8 rows of connectors:
    # * row 1: The beginning of a south-north running belt.
    # * row 2: The end of a north-south running belt.
    # * row 3: The beginning of a west-east running belt.
    # * row 4: The end of a east-west running belt.
    # * row 5: The beginning of a north-south running belt.
    # * row 6: The end of a south-north running belt.
    # * row 7: The beginning of a east-west running belt.
    # * row 8: The end of a west-east running belt.
    #
    # Lastly, the base_cable_connector is a west-east running belt.

    # * row 1: The beginning of a south-north running belt.
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j, beginning=True)
        arr = rotate_counterclockwise(arr)  # rotate south-north
        arr = surround_by_transparent(
            arr,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
        )
        if j == 0:
            row_1 = arr
        else:
            row_1 = np.concatenate([row_1, arr], axis=1)

    # * row 2: The end of a north-south running belt.
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j, end=True)
        arr = rotate_clockwise(arr)  # rotate north-south
        arr = surround_by_transparent(
            arr,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
        )
        if j == 0:
            row_2 = arr
        else:
            row_2 = np.concatenate([row_2, arr], axis=1)

    # * row 3: The beginning of a west-east running belt.
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j, beginning=True)
        arr = surround_by_transparent(
            arr,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2,
        )
        if j == 0:
            row_3 = arr
        else:
            row_3 = np.concatenate([row_3, arr], axis=1)

    # * row 4: The end of a east-west running belt.
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j, end=True)
        arr = rotate_180(arr)  # rotate east-west
        arr = surround_by_transparent(
            arr,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2,
        )
        if j == 0:
            row_4 = arr
        else:
            row_4 = np.concatenate([row_4, arr], axis=1)

    # * row 5: The beginning of a north-south running belt.
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j, beginning=True)
        arr = rotate_clockwise(arr)  # rotate north-south
        arr = surround_by_transparent(
            arr,
            PIXELS // 2,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
            PIXELS // 2,
            PIXELS // 2,
        )
        if j == 0:
            row_5 = arr
        else:
            row_5 = np.concatenate([row_5, arr], axis=1)

    # * row 6: The end of a south-north running belt.
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j, end=True)
        arr = rotate_counterclockwise(arr)  # rotate south-north
        arr = surround_by_transparent(
            arr,
            PIXELS // 2,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
            PIXELS // 2,
            PIXELS // 2,
        )
        if j == 0:
            row_6 = arr
        else:
            row_6 = np.concatenate([row_6, arr], axis=1)

    # * row 7: The beginning of a east-west running belt.
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j, beginning=True)
        arr = rotate_180(arr)  # rotate east-west
        arr = surround_by_transparent(
            arr,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
            PIXELS // 2,
        )
        if j == 0:
            row_7 = arr
        else:
            row_7 = np.concatenate([row_7, arr], axis=1)

    # * row 8: The end of a west-east running belt.
    for j in range(16):
        arr = shifted_base_cable_connector(tier, 2 * j, end=True)
        arr = surround_by_transparent(
            arr,
            PIXELS // 2,
            PIXELS // 2,
            PIXELS // 2 + PIXELS - OFFSET_CABLE,
            PIXELS // 2,
        )
        if j == 0:
            row_8 = arr
        else:
            row_8 = np.concatenate([row_8, arr], axis=1)

    cable_connectors = np.concatenate(
        [row_1, row_2, row_3, row_4, row_5, row_6, row_7, row_8],
        axis=0,
    )

    transport_cable = np.concatenate(
        [straight_cables, curved_cables, cable_connectors], axis=0
    )

    images["array"].append(transport_cable)
    images["filename"].append(f"cable-t{tier}.png")

#
# cable scanner
#
for tier in range(1, TIERS + 1):
    images["array"].append(make_transparent(320, 658))
    images["filename"].append(f"ccm-belt-04a-sequence-{tier}.png")


#
# lamp
#
for tier in range(1, TIERS + 1):
    images["array"].append(make_transparent(32, 32))
    images["filename"].append("lamp.png")
    images["array"].append(make_transparent(32, 32))
    images["filename"].append("lamp-shadow.png")
    images["array"].append(make_transparent(32, 32))
    images["filename"].append("lamp-light.png")


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


#
# save all images
#
for array, filename in zip(images["array"], images["filename"]):
    filename_lr = "lr-" + filename
    filename_hr = "hr-" + filename
    if array.shape[-1] == 3:
        Image.fromarray(array, mode="RGB").save(folder_entities / filename_lr)
        Image.fromarray(array, mode="RGB").save(folder_entities / filename_hr)
    elif array.shape[-1] == 4:
        Image.fromarray(array, mode="RGBA").save(folder_entities / filename_lr)
        Image.fromarray(array, mode="RGBA").save(folder_entities / filename_hr)
    else:
        raise ValueError("Unknown: array.shape[-1] =", array.ndim)
