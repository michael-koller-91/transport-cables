import numpy as np
from PIL import Image
import gen_utils as gu


TIERS = 3
OFFSET_CABLE = 14
PIXELS = 64
PIXELS_SHADOW = 64
THICKNESS = 16
THICKNESS_OVER_2 = THICKNESS // 2
TIER_FRAME_THICKNESS = 2
YELLOW_LINE_OFFSET = 32

images = {
    "array": list(),
    "filename": list(),
}


def shifted_base_cable_connector(shift, beginning=False, end=False):
    if not (beginning or end):
        raise ValueError("need beginning or end")
    if beginning and end:
        raise ValueError("cannot have beginning and end")

    arr = gu.zeros_rgb(PIXELS, OFFSET_CABLE)
    if beginning:
        base_cable = gu.make_beginning_of_base_cable(
            PIXELS, THICKNESS, OFFSET_CABLE, shift, YELLOW_LINE_OFFSET
        )
    if end:
        base_cable = gu.make_end_of_base_cable(
            PIXELS, THICKNESS, OFFSET_CABLE, shift, YELLOW_LINE_OFFSET
        )
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


def gen(folder):
    print("generating entities ... ", end="", flush=True)

    #
    # cable
    #
    # auxiliary cable image
    base_cable = gu.make_base_cable(PIXELS, PIXELS, YELLOW_LINE_OFFSET)
    images["array"].append(base_cable)
    images["filename"].append("base-straight.png")

    # helper for aligning straight parts
    for shift in range(30):
        base_cable_shifted = gu.shifted_base_cable(
            shift, PIXELS, THICKNESS, YELLOW_LINE_OFFSET
        )
        base_cable_shifted = gu.make_tier_lines(
            base_cable_shifted,
            1,
            TIER_FRAME_THICKNESS,
            left=False,
            top=True,
            right=False,
            bottom=True,
        )
        images["array"].append(base_cable_shifted)
        images["filename"].append("base_cable_shifted.png")

        base_cable_connector_beginning = (
            shifted_base_cable_connector(shift, True, False) * 2
        )
        base_cable_connector_beginning = gu.make_tier_lines(
            base_cable_connector_beginning,
            1,
            TIER_FRAME_THICKNESS,
            top=True,
            bottom=True,
        )
        images["array"].append(base_cable_connector_beginning)
        images["filename"].append("base_cable_connector_beginning.png")

        base_cable_connector_end = shifted_base_cable_connector(shift, False, True) * 2
        base_cable_connector_end = gu.make_tier_lines(
            base_cable_connector_end, 1, TIER_FRAME_THICKNESS, top=True, bottom=True
        )
        images["array"].append(base_cable_connector_end)
        images["filename"].append("base_cable_connector_end.png")

        arr = np.concatenate(
            [
                base_cable_connector_beginning,
                base_cable_shifted,
                base_cable_connector_end,
            ],
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
        arr_left_right = gu.shifted_base_cable(
            2 * j, PIXELS, THICKNESS, YELLOW_LINE_OFFSET
        )
        arr_right_left = np.rot90(arr_left_right, 2, axes=(0, 1))
        arr_top_bottom = np.rot90(arr_left_right, 3, axes=(0, 1))

        arr = combine_ur_ll(arr_right_left, arr_top_bottom)
        arr = gu.make_tier_lines(arr, 1, TIER_FRAME_THICKNESS, right=True, bottom=True)

        arr = gu.surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
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
                arr = gu.shifted_base_cable(
                    2 * j, PIXELS, THICKNESS, YELLOW_LINE_OFFSET
                )
                arr = gu.make_tier_lines(
                    arr, tier, TIER_FRAME_THICKNESS, top=True, bottom=True
                )
                if i // 2:
                    arr = np.rot90(arr, k=i * 2 + 1)
                else:
                    arr = np.rot90(arr, k=i * 2)

                arr = gu.surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
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
            arr_left_right = gu.shifted_base_cable(
                2 * j, PIXELS, THICKNESS, YELLOW_LINE_OFFSET
            )
            arr_right_left = np.rot90(arr_left_right, 2, axes=(0, 1))
            arr_bottom_top = np.rot90(arr_left_right, 1, axes=(0, 1))

            arr = combine_ul_lr(arr_right_left, arr_bottom_top)
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, left=True, bottom=True
            )

            arr = gu.surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
            arr_rotated = gu.rotate_clockwise(arr)
            if j == 0:
                super_arr_r_to_t = arr
                super_arr_b_to_r = arr_rotated
            else:
                super_arr_r_to_t = np.concatenate([super_arr_r_to_t, arr], axis=1)
                super_arr_b_to_r = np.concatenate(
                    [super_arr_b_to_r, arr_rotated], axis=1
                )
        # * top to right
        # * right to bottom
        for j in range(16):
            arr_left_right = gu.shifted_base_cable(
                2 * j, PIXELS, THICKNESS, YELLOW_LINE_OFFSET
            )
            arr_top_bottom = np.rot90(arr_left_right, 3, axes=(0, 1))

            arr = combine_ul_lr(arr_left_right, arr_top_bottom)
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, left=True, bottom=True
            )

            arr = gu.surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
            arr_rotated = gu.rotate_clockwise(arr)
            if j == 0:
                super_arr_t_to_r = arr
                super_arr_r_to_b = arr_rotated
            else:
                super_arr_t_to_r = np.concatenate([super_arr_t_to_r, arr], axis=1)
                super_arr_r_to_b = np.concatenate(
                    [super_arr_r_to_b, arr_rotated], axis=1
                )
        # * left to top
        # * bottom to left
        for j in range(16):
            arr_left_right = gu.shifted_base_cable(
                2 * j, PIXELS, THICKNESS, YELLOW_LINE_OFFSET
            )
            arr_bottom_top = np.rot90(arr_left_right, 1, axes=(0, 1))

            arr = combine_ur_ll(arr_left_right, arr_bottom_top)
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, right=True, bottom=True
            )

            arr = gu.surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
            arr_rotated = gu.rotate_counterclockwise(arr)
            if j == 0:
                super_arr_l_to_t = arr
                super_arr_b_to_l = arr_rotated
            else:
                super_arr_l_to_t = np.concatenate([super_arr_l_to_t, arr], axis=1)
                super_arr_b_to_l = np.concatenate(
                    [super_arr_b_to_l, arr_rotated], axis=1
                )
        # * top to left
        # * left to bottom
        for j in range(16):
            arr_left_right = gu.shifted_base_cable(
                2 * j, PIXELS, THICKNESS, YELLOW_LINE_OFFSET
            )
            arr_right_left = np.rot90(arr_left_right, 2, axes=(0, 1))
            arr_top_bottom = np.rot90(arr_left_right, 3, axes=(0, 1))

            arr = combine_ur_ll(arr_right_left, arr_top_bottom)
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, right=True, bottom=True
            )

            arr = gu.surround_by_transparent(arr, PIXELS // 2, PIXELS // 2)
            arr_rotated = gu.rotate_counterclockwise(arr)
            if j == 0:
                super_arr_t_to_l = arr
                super_arr_l_to_b = arr_rotated
            else:
                super_arr_t_to_l = np.concatenate([super_arr_t_to_l, arr], axis=1)
                super_arr_l_to_b = np.concatenate(
                    [super_arr_l_to_b, arr_rotated], axis=1
                )

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
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, top=True, bottom=True
            )
            arr = gu.rotate_counterclockwise(arr)  # rotate south-north
            arr = gu.surround_by_transparent(
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
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, top=True, bottom=True
            )
            arr = gu.rotate_clockwise(arr)  # rotate north-south
            arr = gu.surround_by_transparent(
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
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, top=True, bottom=True
            )
            arr = gu.surround_by_transparent(
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
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, top=True, bottom=True
            )
            arr = gu.rotate_180(arr)  # rotate east-west
            arr = gu.surround_by_transparent(
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
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, top=True, bottom=True
            )
            arr = gu.rotate_clockwise(arr)  # rotate north-south
            arr = gu.surround_by_transparent(
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
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, top=True, bottom=True
            )
            arr = gu.rotate_counterclockwise(arr)  # rotate south-north
            arr = gu.surround_by_transparent(
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
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, top=True, bottom=True
            )
            arr = gu.rotate_180(arr)  # rotate east-west
            arr = gu.surround_by_transparent(
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
            arr = gu.make_tier_lines(
                arr, tier, TIER_FRAME_THICKNESS, top=True, bottom=True
            )
            arr = gu.surround_by_transparent(
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
        images["array"].append(gu.zeros_rgba_wh(320, 658))
        images["filename"].append(f"cable-circuit-frame-main-t{tier}.png")
        images["array"].append(gu.zeros_rgba_wh(198, 72))
        images["filename"].append(f"cable-circuit-patch-back-t{tier}.png")
        images["array"].append(gu.zeros_rgba_wh(640, 784))
        images["filename"].append(f"cable-circuit-frame-main-t{tier}-shadow.png")
        images["array"].append(gu.zeros_rgba_wh(176, 64))
        images["filename"].append(f"cable-circuit-frame-main-scanner-t{tier}.png")

    #
    # empty
    #
    for tier in range(1, TIERS + 1):
        images["array"].append(gu.zeros_rgba_wh(8, 8))
        images["filename"].append(f"empty-t{tier}.png")
        images["array"].append(gu.zeros_rgba_wh(8, 8))
        images["filename"].append(f"empty-t{tier}-shadow.png")

    #
    # lamp
    #
    for tier in range(1, TIERS + 1):
        images["array"].append(gu.zeros_rgba_wh(32, 32))
        images["filename"].append("lamp.png")
        images["array"].append(gu.zeros_rgba_wh(32, 32))
        images["filename"].append("lamp-shadow.png")
        images["array"].append(gu.zeros_rgba_wh(32, 32))
        images["filename"].append("lamp-light.png")

    #
    # node
    #
    for tier in range(1, TIERS + 1):
        arr = gu.gen_node(PIXELS, THICKNESS_OVER_2, TIER_FRAME_THICKNESS, tier)

        images["array"].append(arr)
        images["filename"].append(f"node-t{tier}.png")

        images["array"].append(gu.zeros_rgba_wh(32, 32))
        images["filename"].append(f"node-t{tier}-shadow.png")

    #
    # provider
    #
    for tier in range(1, TIERS + 1):
        arr = gu.gen_provider(PIXELS, THICKNESS_OVER_2, TIER_FRAME_THICKNESS, tier)

        images["array"].append(arr)
        images["filename"].append(f"provider-t{tier}.png")

        #
        arr = np.zeros((PIXELS_SHADOW, PIXELS_SHADOW, 3), dtype=np.uint8)

        images["array"].append(arr)
        images["filename"].append(f"provider-t{tier}-shadow.png")

    #
    # requester with requester-container
    #
    for tier in range(1, TIERS + 1):
        requester = gu.gen_requester(
            PIXELS, THICKNESS_OVER_2, TIER_FRAME_THICKNESS, tier
        )
        container = gu.gen_requester_container(
            PIXELS, THICKNESS_OVER_2, TIER_FRAME_THICKNESS, tier
        )

        arr = np.concatenate([container, requester], axis=0)

        images["array"].append(arr)
        images["filename"].append(f"requester-with-container-north-t{tier}.png")

        arr = gu.rotate_clockwise(arr)
        images["array"].append(arr)
        images["filename"].append(f"requester-with-container-east-t{tier}.png")

        arr = gu.rotate_clockwise(arr)
        images["array"].append(arr)
        images["filename"].append(f"requester-with-container-south-t{tier}.png")

        arr = gu.rotate_clockwise(arr)
        images["array"].append(arr)
        images["filename"].append(f"requester-with-container-west-t{tier}.png")

    #
    # underground
    #
    # We use the position of the "hole" or "tunnel entry" and the direction
    # into which the arrows point in the sprite sheet. Here, we do not imagine
    # to be standing on a belt, we merely look at the sprite sheet
    # __base__/graphics/entity/underground-belt/underground-belt-structure.png
    # * row 1:
    #   * hole bottom, arrow down
    #   * hole left,   arrow left
    #   * hole top,    arrow up
    #   * hole right,  arrow right
    #
    # Lastly, gen_underground produces "hole top, arrow down/up".
    for tier in range(1, TIERS + 1):
        arr_down = gu.gen_underground(
            PIXELS, THICKNESS_OVER_2, TIER_FRAME_THICKNESS, tier, down=True, up=False
        )
        arr_up = gu.gen_underground(
            PIXELS, THICKNESS_OVER_2, TIER_FRAME_THICKNESS, tier, down=False, up=True
        )
        empty = gu.zeros_rgba(3 * PIXELS, 3 * PIXELS)
        # * row 1:
        arr = gu.rotate_180(arr_up)
        arr = gu.surround_by_transparent(arr, PIXELS, PIXELS, PIXELS, PIXELS)
        row_1 = arr
        for i in range(3):
            arr = gu.rotate_clockwise(arr)
            row_1 = np.concatenate([row_1, arr], axis=1)

        # * row 2:
        arr = gu.rotate_180(arr_down)
        arr = gu.surround_by_transparent(arr, PIXELS, PIXELS, PIXELS, PIXELS)
        row_2 = arr
        for i in range(3):
            arr = gu.rotate_clockwise(arr)
            row_2 = np.concatenate([row_2, arr], axis=1)

        # * row 3:
        row_3 = np.concatenate(
            [
                empty,
                gu.surround_by_transparent(
                    gu.rotate_counterclockwise(arr_up), PIXELS, PIXELS, PIXELS, PIXELS
                ),
                empty,
                gu.surround_by_transparent(
                    gu.rotate_clockwise(arr_up), PIXELS, PIXELS, PIXELS, PIXELS
                ),
            ],
            axis=1,
        )

        # * row 4:
        row_4 = np.concatenate(
            [
                empty,
                gu.surround_by_transparent(
                    gu.rotate_counterclockwise(arr_down), PIXELS, PIXELS, PIXELS, PIXELS
                ),
                empty,
                gu.surround_by_transparent(
                    gu.rotate_clockwise(arr_down), PIXELS, PIXELS, PIXELS, PIXELS
                ),
            ],
            axis=1,
        )

        super_arr = np.concatenate([row_1, row_2, row_3, row_4], axis=0)

        images["array"].append(super_arr)
        images["filename"].append(f"underground-cable-structure-t{tier}.png")

        arr = gu.zeros_rgba_wh(768, 192)

        images["array"].append(arr)
        images["filename"].append(f"underground-cable-back-patch-t{tier}.png")

        arr = gu.zeros_rgba_wh(768, 192)

        images["array"].append(arr)
        images["filename"].append(f"underground-cable-front-patch-t{tier}.png")

    #
    # save all images
    #
    for array, filename in zip(images["array"], images["filename"]):
        filename_lr = "lr-" + filename
        filename_hr = "hr-" + filename
        if array.shape[-1] == 3:
            Image.fromarray(array, mode="RGB").save(folder / filename_lr)
            Image.fromarray(array, mode="RGB").save(folder / filename_hr)
        elif array.shape[-1] == 4:
            Image.fromarray(array, mode="RGBA").save(folder / filename_lr)
            Image.fromarray(array, mode="RGBA").save(folder / filename_hr)
        else:
            raise ValueError("Unknown: array.shape[-1] =", array.ndim)

    print("done", flush=True)
