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
THICKNESS_OVER_2 = THICKNESS // 2
TIER_FRAME_THICKNESS = 2
YELLOW_LINE_OFFSET = 32

images = {
    "array": list(),
    "filename": list(),
}


def zeros_rgb(rows, columns):
    return np.zeros((rows, columns, 3), dtype=np.uint8)


def zeros_rgba(rows, columns):
    return np.zeros((rows, columns, 4), dtype=np.uint8)


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
    return make_tier_lines(
        arr=zeros_rgb(pixels, pixels),
        n_lines=n_frames,
        left=True,
        top=True,
        right=True,
        bottom=True,
    )


def make_tier_lines(arr, n_lines, left=False, top=False, right=False, bottom=False):
    tft = TIER_FRAME_THICKNESS
    rows, columns = arr.shape[:2]
    for k in range(1, 2 * n_lines, 2):
        if left:
            arr[rows//4:-rows//4, (k - 1) * tft  : k * tft , 1] = 255
        if top:
            arr[(k - 1) * tft  : k * tft , columns//4:-columns//4, 1] = 255
        if right:
            arr[rows//4:-rows//4, columns - k * tft  : columns - (k - 1) * tft , 1] = 255
        if bottom:
            arr[rows - k * tft  : rows - (k - 1) * tft , columns//4:-columns//4, 1] = 255
    return arr


def make_base_cable(pixels_x, pixels_y):
    arr = np.zeros((pixels_y, 3 * pixels_x, 3), dtype=np.uint8)
    arr[:, :, :] = 100
    arr[pixels_y // 7 : -pixels_y // 7, ::YELLOW_LINE_OFFSET, 0] = 255
    arr[pixels_y // 7 : -pixels_y // 7, ::YELLOW_LINE_OFFSET, 1] = 255
    arr[pixels_y // 7 : -pixels_y // 7, 1::YELLOW_LINE_OFFSET, 0] = 255
    arr[pixels_y // 7 : -pixels_y // 7, 1::YELLOW_LINE_OFFSET, 1] = 255
    arr[pixels_y // 5 : -pixels_y // 5, 4::YELLOW_LINE_OFFSET, 0] = 255
    arr[pixels_y // 5 : -pixels_y // 5, 4::YELLOW_LINE_OFFSET, 1] = 255
    arr[pixels_y // 5 : -pixels_y // 5, 5::YELLOW_LINE_OFFSET, 0] = 255
    arr[pixels_y // 5 : -pixels_y // 5, 5::YELLOW_LINE_OFFSET, 1] = 255
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


def shifted_base_cable(shift):
    arr = zeros_rgb(PIXELS, PIXELS)
    base_cable_center = center_of_base_cable(PIXELS, THICKNESS, shift)
    arr[
        PIXELS // 2 - THICKNESS // 2 : PIXELS // 2 + THICKNESS // 2, :, :
    ] = base_cable_center
    return arr


def shifted_base_cable_connector(shift, beginning=False, end=False):
    arr = zeros_rgb(PIXELS, OFFSET_CABLE)
    if beginning:
        base_cable = beginning_of_base_cable(PIXELS, THICKNESS, OFFSET_CABLE, shift)
    if end:
        base_cable = end_of_base_cable(PIXELS, THICKNESS, OFFSET_CABLE, shift)
    if not (beginning or end):
        raise ValueError("need beginning or end")
    if beginning and end:
        raise ValueError("cannot have beginning and end")
    arr[PIXELS // 2 - THICKNESS // 2 : PIXELS // 2 + THICKNESS // 2, :, :] = base_cable
    return arr


def combine_ur_ll(array_horizontal, array_vertical):
    """
    Combine the upper right half of `array_vertical` and the lower left half of
    `array_horizontal`.
    """
    mask_upper_right_triangular = np.zeros(array_vertical.shape)
    for i in range(mask_upper_right_triangular.shape[0]):
        for j in range(i, mask_upper_right_triangular.shape[1]):
            mask_upper_right_triangular[i, j, :] = 1
        mask_upper_right_triangular[i, i, :] = 0.5

    mask_lower_left_triangular = np.zeros(array_vertical.shape)
    for i in range(mask_lower_left_triangular.shape[0]):
        for j in range(i):
            mask_lower_left_triangular[i, j, :] = 1
        mask_lower_left_triangular[i, i, :] = 0.5

    arr = (
        mask_upper_right_triangular * array_vertical
        + mask_lower_left_triangular * array_horizontal
    ).astype(np.uint8)
    return arr


def combine_ul_lr(array_horizontal, array_vertical):
    """
    Combine the upper left half of `array_vertical` and the lower right half of
    `array_vertical`.
    """
    assert np.array_equal(array_horizontal.shape, array_vertical.shape)

    mask_upper_left_triangular = np.zeros(array_vertical.shape)
    for i in range(mask_upper_left_triangular.shape[0]):
        for j in range(mask_upper_left_triangular.shape[1] - i):
            mask_upper_left_triangular[i, j, :] = 1
        mask_upper_left_triangular[i, i, :] = 0.5

    mask_lower_right_triangular = np.zeros(array_horizontal.shape)
    for i in range(mask_lower_right_triangular.shape[0]):
        for j in range(
            mask_upper_left_triangular.shape[1] - i, mask_upper_left_triangular.shape[1]
        ):
            mask_lower_right_triangular[i, j, :] = 1
        mask_lower_right_triangular[i, i, :] = 0.5

    arr = (
        mask_upper_left_triangular * array_vertical
        + mask_lower_right_triangular * array_horizontal
    ).astype(np.uint8)
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
# auxiliary cable image
base_cable = make_base_cable(PIXELS, PIXELS)
images["array"].append(base_cable)
images["filename"].append("base_straight.png")

# helper for aligning straight parts
for shift in range(30):
    base_cable_shifted = shifted_base_cable(shift)
    base_cable_shifted = make_tier_lines(
        base_cable_shifted, 1, left=False, top=True, right=False, bottom=True
    )
    images["array"].append(base_cable_shifted)
    images["filename"].append("base_cable_shifted.png")

    base_cable_connector_beginning = shifted_base_cable_connector(shift, True, False) * 2
    base_cable_connector_beginning = make_tier_lines(
        base_cable_connector_beginning, 1, top=True, bottom=True
    )
    images["array"].append(base_cable_connector_beginning)
    images["filename"].append("base_cable_connector_beginning.png")

    base_cable_connector_end = shifted_base_cable_connector(shift, False, True) * 2
    base_cable_connector_end = make_tier_lines(
        base_cable_connector_end, 1, top=True, bottom=True
    )
    images["array"].append(base_cable_connector_end)
    images["filename"].append("base_cable_connector_end.png")

    arr = np.concatenate(
        [base_cable_connector_beginning, base_cable_shifted, base_cable_connector_end],
        axis=1,
    )
    if shift == 0:
        base_cable_alignment = arr
    else:
        base_cable_alignment = np.concatenate([base_cable_alignment, arr], axis=0)
images["array"].append(base_cable_alignment)
images["filename"].append("base_cable_straight_alignment.png")

# helper for aligning curved parts
for j in range(16):
    arr_left_right = shifted_base_cable(2 * j)
    arr_right_left = np.rot90(arr_left_right, 2, axes=(0, 1))
    arr_top_bottom = np.rot90(arr_left_right, 3, axes=(0, 1))

    arr = combine_ur_ll(arr_right_left, arr_top_bottom)
    arr = make_tier_lines(arr, 1, right=True, bottom=True)

    arr = surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
    if j == 0:
        super_arr = arr
    else:
        super_arr = np.concatenate([super_arr, arr], axis=1)
images["array"].append(super_arr)
images["filename"].append("ase_cable_curved_alignment.png")


for tier in range(1, TIERS + 1):
    #
    # straight cables
    #
    for i in range(4):
        for j in range(16):
            arr = shifted_base_cable(2 * j)
            arr = make_tier_lines(arr, tier, top=True, bottom=True)
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

    #
    # curved cables
    #
    # * right to top
    # * bottom to right
    for j in range(16):
        arr_left_right = shifted_base_cable(2 * j)
        arr_right_left = np.rot90(arr_left_right, 2, axes=(0, 1))
        arr_bottom_top = np.rot90(arr_left_right, 1, axes=(0, 1))

        arr = combine_ul_lr(arr_right_left, arr_bottom_top)
        arr = make_tier_lines(arr, tier, left=True, bottom=True)

        arr = surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
        arr_rotated = rotate_clockwise(arr)
        if j == 0:
            super_arr_r_to_t = arr
            super_arr_b_to_r = arr_rotated
        else:
            super_arr_r_to_t = np.concatenate([super_arr_r_to_t, arr], axis=1)
            super_arr_b_to_r = np.concatenate([super_arr_b_to_r, arr_rotated], axis=1)
    # * top to right
    # * right to bottom
    for j in range(16):
        arr_left_right = shifted_base_cable(2 * j)
        arr_top_bottom = np.rot90(arr_left_right, 3, axes=(0, 1))

        arr = combine_ul_lr(arr_left_right, arr_top_bottom)
        arr = make_tier_lines(arr, tier, left=True, bottom=True)

        arr = surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
        arr_rotated = rotate_clockwise(arr)
        if j == 0:
            super_arr_t_to_r = arr
            super_arr_r_to_b = arr_rotated
        else:
            super_arr_t_to_r = np.concatenate([super_arr_t_to_r, arr], axis=1)
            super_arr_r_to_b = np.concatenate([super_arr_r_to_b, arr_rotated], axis=1)
    # * left to top
    # * bottom to left
    for j in range(16):
        arr_left_right = shifted_base_cable(2 * j)
        arr_bottom_top = np.rot90(arr_left_right, 1, axes=(0, 1))

        arr = combine_ur_ll(arr_left_right, arr_bottom_top)
        arr = make_tier_lines(arr, tier, right=True, bottom=True)

        arr = surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
        arr_rotated = rotate_counterclockwise(arr)
        if j == 0:
            super_arr_l_to_t = arr
            super_arr_b_to_l = arr_rotated
        else:
            super_arr_l_to_t = np.concatenate([super_arr_l_to_t, arr], axis=1)
            super_arr_b_to_l = np.concatenate([super_arr_b_to_l, arr_rotated], axis=1)
    # * top to left
    # * left to bottom
    for j in range(16):
        arr_left_right = shifted_base_cable(2 * j)
        arr_right_left = np.rot90(arr_left_right, 2, axes=(0, 1))
        arr_top_bottom = np.rot90(arr_left_right, 3, axes=(0, 1))

        arr = combine_ur_ll(arr_right_left, arr_top_bottom)
        arr = make_tier_lines(arr, tier, right=True, bottom=True)

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
        arr = shifted_base_cable_connector(2 * j, beginning=True)
        arr = make_tier_lines(arr, tier, top=True, bottom=True)
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
        arr = shifted_base_cable_connector(2 * j, end=True)
        arr = make_tier_lines(arr, tier, top=True, bottom=True)
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
        arr = shifted_base_cable_connector(2 * j, beginning=True)
        arr = make_tier_lines(arr, tier, top=True, bottom=True)
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
        arr = shifted_base_cable_connector(2 * j, end=True)
        arr = make_tier_lines(arr, tier, top=True, bottom=True)
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
        arr = shifted_base_cable_connector(2 * j, beginning=True)
        arr = make_tier_lines(arr, tier, top=True, bottom=True)
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
        arr = shifted_base_cable_connector(2 * j, end=True)
        arr = make_tier_lines(arr, tier, top=True, bottom=True)
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
        arr = shifted_base_cable_connector(2 * j, beginning=True)
        arr = make_tier_lines(arr, tier, top=True, bottom=True)
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
        arr = shifted_base_cable_connector(2 * j, end=True)
        arr = make_tier_lines(arr, tier, top=True, bottom=True)
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
    images["filename"].append(f"cable-circuit-frame-main-t{tier}.png")
    images["array"].append(make_transparent(198, 72))
    images["filename"].append(f"cable-circuit-patch-back-t{tier}.png")
    images["array"].append(make_transparent(640, 784))
    images["filename"].append(f"cable-circuit-frame-main-t{tier}-shadow.png")
    images["array"].append(make_transparent(176, 64))
    images["filename"].append(f"cable-circuit-frame-main-scanner-t{tier}.png")


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
        PIXELS // 2 - THICKNESS_OVER_2 : PIXELS // 2 + THICKNESS_OVER_2,
        PIXELS // 2 - THICKNESS_OVER_2 : PIXELS // 2 + THICKNESS_OVER_2,
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
            : PIXELS // 2 + THICKNESS_OVER_2,
            PIXELS // 2 - THICKNESS_OVER_2 : PIXELS // 2 + THICKNESS_OVER_2,
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
        PIXELS // 2 - THICKNESS_OVER_2 : PIXELS // 2 + THICKNESS_OVER_2,
        PIXELS // 2 - THICKNESS_OVER_2 : PIXELS // 2 + THICKNESS_OVER_2,
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
