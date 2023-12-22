import numpy as np
from PIL import Image
import gen_utils as gu
from icecream import ic
from pathlib import Path


TIERS = 1
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


def gen(folder):
    #
    # cable
    #
    for tier in range(1, TIERS + 1):
        arr = gu.shifted_base_cable(0, PIXELS, THICKNESS, YELLOW_LINE_OFFSET)
        arr = gu.make_tier_lines(
            arr,
            tier,
            TIER_FRAME_THICKNESS,
            left=False,
            top=True,
            right=False,
            bottom=True,
        )
        super_arr = gu.make_mipmaps_rgb(arr, 4)

        images["array"].append(super_arr)
        images["filename"].append(f"cable-t{tier}.png")

    #
    # provider
    #
    for tier in range(1, TIERS + 1):
        arr = gu.gen_provider(PIXELS, THICKNESS_OVER_2, TIER_FRAME_THICKNESS, tier)
        super_arr = gu.make_mipmaps_rgb(arr, 4)

        images["array"].append(super_arr)
        images["filename"].append(f"provider-t{tier}.png")

    #
    # save all images
    #
    for array, filename in zip(images["array"], images["filename"]):
        if array.shape[-1] == 3:
            Image.fromarray(array, mode="RGB").save(folder / filename)
        elif array.shape[-1] == 4:
            Image.fromarray(array, mode="RGBA").save(folder / filename)
        else:
            raise ValueError("Unknown: array.shape[-1] =", array.ndim)
