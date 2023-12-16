import numpy as np
from PIL import Image
from pathlib import Path

sprites = Path("sprites")

rng = np.random.default_rng(123456789)

border = 10
box = np.zeros((64, 64, 3), dtype=np.uint8)
box[:, :, 1] = 255
box[border:-border, border:-border, 1] = 0
box[border:-border, border:-border, 2] = rng.integers(
    100, 256, (box.shape[0] - 2 * border, box.shape[0] - 2 * border)
)
im = Image.fromarray(box, mode="RGB")
im.save(sprites / "box.png")

box_shadow = np.zeros((70, 70, 3), dtype=np.uint8)
im = Image.fromarray(box_shadow, mode="RGB")
im.save(sprites / "box-shadow.png")
