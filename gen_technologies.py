import numpy as np
from PIL import Image
import gen_utils as gu


PIXELS = 64
THICKNESS = 16
TIER_FRAME_THICKNESS = 2
TIERS = 3
UPSCALE = 4
YELLOW_LINE_OFFSET = 32

images = {
    "array": list(),
    "filename": list(),
}


def gen(folder):
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

        # scale image up
        img = Image.fromarray(arr, mode="RGB")
        img = img.resize(
            (img.size[0] * UPSCALE, img.size[1] * UPSCALE), Image.Resampling.NEAREST
        )

        arr = np.array(img)
        super_arr = gu.make_mipmaps_rgb(arr, 4)

        images["array"].append(super_arr)
        images["filename"].append(f"t{tier}.png")

    #
    # save all images
    #
    for array, filename in zip(images["array"], images["filename"]):
        Image.fromarray(array, mode="RGBA").save(folder / filename)
