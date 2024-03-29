import numpy as np
from PIL import Image


def compress_rgb(arr, shape):
    """
    Compress the array `arr` of shape (arr.shape[0], arr.shape[1], 3) into an
    array of shape (shape[0], shape[1], 3) by averaging appropriate elements.
    """
    sh = shape[0], arr.shape[0] // shape[0], shape[1], arr.shape[1] // shape[1]
    arr_avrg = zeros_rgb(shape[0], shape[1])
    for c in range(3):
        arr_avrg[:, :, c] = arr[:, :, c].reshape(sh).mean(-1).mean(1)
    return arr_avrg


def gen_node(pixels, thickness, tier_frame_thickness, tier):
    p_2 = pixels // 2
    t = thickness
    t_2 = thickness // 2

    arr = zeros_rgb(pixels, pixels)

    # yellow square
    arr[p_2 - t : p_2 + t, p_2 - t : p_2 + t, 0] = 225
    arr[p_2 - t : p_2 + t, p_2 - t : p_2 + t, 1] = 225

    # gray line going up
    arr[: p_2 - t, p_2 - t : p_2 + t, :] = 100

    # add arrows
    for l in range(4):
        # facing down
        o = t_2 + l - 1
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 0] = 225
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 1] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 0] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 1] = 225
        # facing up
        o = p_2 - 2 * t + (3 - l)
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 0] = 225
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 1] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 0] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 1] = 225

    # add the other three gray lines via rotation
    sub_arr = arr

    mask = np.zeros_like(arr)
    mask[: p_2 - thickness, :, :] = 1
    for _ in range(3):
        mask = rotate_counterclockwise(mask.copy())
        sub_arr = rotate_counterclockwise(sub_arr.copy())
        arr += mask * sub_arr

    arr = make_tier_edges(
        arr, tier, tier_frame_thickness, tl=True, tr=True, br=True, bl=True
    )
    return arr


def gen_receiver(pixels, thickness, tier_frame_thickness, tier):
    p_2 = pixels // 2
    t = thickness
    t_2 = thickness // 2

    arr = zeros_rgb(pixels, pixels)

    # blue square
    arr[p_2 - t : p_2 + t, p_2 - t : p_2 + t, 0] = 20
    arr[p_2 - t : p_2 + t, p_2 - t : p_2 + t, 1] = 20
    arr[p_2 - t : p_2 + t, p_2 - t : p_2 + t, 2] = 200

    # gray line going up
    arr[: p_2 - t, p_2 - t : p_2 + t, :] = 100

    # add arrow
    for l in range(4):
        # facing down
        o = t_2 + l - 1
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 0] = 225
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 1] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 0] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 1] = 225
        # facing down
        o = p_2 - 2 * t + l
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 0] = 225
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 1] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 0] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 1] = 225

    # add the other three gray lines via rotation
    sub_arr = arr
    mask = np.zeros_like(arr)
    mask[: p_2 - thickness, :, :] = 1
    for _ in range(3):
        mask = rotate_counterclockwise(mask.copy())
        sub_arr = rotate_counterclockwise(sub_arr.copy())
        arr += mask * sub_arr

    arr = make_tier_edges(
        arr, tier, tier_frame_thickness, tl=True, tr=True, br=True, bl=True
    )
    return arr


def gen_transmitter(pixels, thickness, tier_frame_thickness, tier):
    p_2 = pixels // 2
    t = thickness
    t_2 = thickness // 2

    arr = zeros_rgb(pixels, pixels)

    # red square
    arr[p_2 - t : p_2 + t, p_2 - t : p_2 + t, 0] = 200
    arr[p_2 - t : p_2 + t, p_2 - t : p_2 + t, 1] = 20
    arr[p_2 - t : p_2 + t, p_2 - t : p_2 + t, 2] = 20

    # gray line going up
    arr[: p_2 - t, p_2 - t : p_2 + t, :] = 100

    # add arrow
    for l in range(4):
        # facing up
        o = t_2 + (3 - l) - 1
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 0] = 225
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 1] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 0] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 1] = 225
        # facing up
        o = p_2 - 2 * t + (3 - l)
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 0] = 225
        arr[o, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 1] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 0] = 225
        arr[o, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 1] = 225

    # add the other three gray lines via rotation
    sub_arr = arr

    mask = np.zeros_like(arr)
    mask[: p_2 - thickness, :, :] = 1
    for _ in range(3):
        mask = rotate_counterclockwise(mask.copy())
        sub_arr = rotate_counterclockwise(sub_arr.copy())
        arr += mask * sub_arr

    arr = make_tier_edges(
        arr, tier, tier_frame_thickness, tl=True, tr=True, br=True, bl=True
    )
    return arr


def gen_underground(pixels, thickness, tier_frame_thickness, tier, down=True, up=False):
    if not (down or up):
        raise ValueError("need down or up")
    if down and up:
        raise ValueError("cannot have down and up")

    arr = zeros_rgb(pixels, pixels)
    p_2 = pixels // 2
    t_2 = thickness // 2
    offset = thickness
    for k in range(4):
        r_left = k * pixels // 4
        r_right = (k + 1) * pixels // 4
        arr[r_left:r_right, pixels // 2 - thickness : pixels // 2 + thickness, :] = (
            100 - k * 20
        )
        for l in range(4):
            col = 225 - k * 60
            if down:
                r = (1 + k * 2) * offset - 2 + l
                arr[r, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 0] = col
                arr[r, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 1] = col
                arr[r, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 0] = col
                arr[r, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 1] = col
            if up:
                r = (1 + k * 2) * offset - 2 + (3 - l)
                arr[r, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 0] = col
                arr[r, p_2 - t_2 + (l - 2) * 2 : p_2 - t_2 + (l - 1) * 2, 1] = col
                arr[r, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 0] = col
                arr[r, p_2 + t_2 - (l - 1) * 2 : p_2 + t_2 - (l - 2) * 2, 1] = col

    arr = make_tier_edges(
        arr, tier, tier_frame_thickness, tl=True, tr=True, br=True, bl=True
    )
    return arr


def make_base_cable(pixels_x, pixels_y, yellow_line_offset):
    arr = np.zeros((pixels_y, 3 * pixels_x, 3), dtype=np.uint8)
    arr[:, :, :] = 100
    # x = np.arange(3 * pixels_x) * 2 * np.pi / yellow_line_offset
    # s = np.round(pixels_y // 5 * np.sin(x)).astype("int")
    # for c, i in enumerate(s):
    #     arr[pixels_y // 2 + i, c, 0] = 225
    #     arr[pixels_y // 2 + i, c, 1] = 225
    arr[pixels_y // 3 : -pixels_y // 3, ::yellow_line_offset, 0] = 225
    arr[pixels_y // 3 : -pixels_y // 3, ::yellow_line_offset, 1] = 225
    arr[pixels_y // 3 : -pixels_y // 3, 1::yellow_line_offset, 0] = 225
    arr[pixels_y // 3 : -pixels_y // 3, 1::yellow_line_offset, 1] = 225
    arr[pixels_y // 5 : -pixels_y // 5, 4::yellow_line_offset, 0] = 225
    arr[pixels_y // 5 : -pixels_y // 5, 4::yellow_line_offset, 1] = 225
    arr[pixels_y // 5 : -pixels_y // 5, 5::yellow_line_offset, 0] = 225
    arr[pixels_y // 5 : -pixels_y // 5, 5::yellow_line_offset, 1] = 225
    arr[pixels_y // 3 : -pixels_y // 3, 8::yellow_line_offset, 0] = 225
    arr[pixels_y // 3 : -pixels_y // 3, 8::yellow_line_offset, 1] = 225
    arr[pixels_y // 3 : -pixels_y // 3, 9::yellow_line_offset, 0] = 225
    arr[pixels_y // 3 : -pixels_y // 3, 9::yellow_line_offset, 1] = 225
    return arr


def make_beginning_of_base_cable(pixels_x, pixels_y, offset, shift, yellow_line_offset):
    base_cable = make_base_cable(pixels_x, pixels_y, yellow_line_offset)
    return base_cable[:, pixels_x - shift - offset : pixels_x - shift, :]


def make_center_of_base_cable(pixels_x, pixels_y, shift, yellow_line_offset):
    base_cable = make_base_cable(pixels_x, pixels_y, yellow_line_offset)
    return base_cable[:, pixels_x - shift : 2 * pixels_x - shift, :]


def make_end_of_base_cable(pixels_x, pixels_y, offset, shift, yellow_line_offset):
    base_cable = make_base_cable(pixels_x, pixels_y, yellow_line_offset)
    return base_cable[:, pixels_x - shift - offset + 14 : pixels_x - shift + 14, :]


def make_mipmaps_rgb(arr, mipmaps):
    assert arr.ndim == 3
    assert arr.shape[-1] == 3

    target_shapes = np.zeros((mipmaps, 2), dtype=np.int32)
    for m in range(mipmaps):
        target_shapes[m, 0] = arr.shape[0] // 2**m
        target_shapes[m, 1] = arr.shape[1] // 2**m

    super_arr = zeros_rgba(arr.shape[0], np.sum(target_shapes[:, 1]))
    for m in range(mipmaps):
        if m > 0:
            arr = compress_rgb(arr, target_shapes[m, :])

        rows = target_shapes[m, 0]
        columns_l = target_shapes[m, 1]
        columns_offset = np.sum(target_shapes[:m, 1])

        super_arr[:rows, columns_offset : columns_offset + columns_l, :-1] = arr
        super_arr[:rows, columns_offset : columns_offset + columns_l, -1] = 255

    return super_arr


def make_tier_edges(
    arr, n_lines, line_thickness, tl=False, tr=False, br=False, bl=False
):
    lt = line_thickness
    r, c = arr.shape[:2]
    for k in range(1, 2 * n_lines, 2):
        if tl:
            arr[: r // 4, (k - 1) * lt : k * lt, 0] = 75
            arr[(k - 1) * lt : k * lt, : c // 4, 0] = 75
            arr[: r // 4, (k - 1) * lt : k * lt, 1] = 150
            arr[(k - 1) * lt : k * lt, : c // 4, 1] = 150
        if tr:
            arr[(k - 1) * lt : k * lt, -c // 4 :, 0] = 75
            arr[: r // 4, c - k * lt : c - (k - 1) * lt, 0] = 75
            arr[(k - 1) * lt : k * lt, -c // 4 :, 1] = 150
            arr[: r // 4, c - k * lt : c - (k - 1) * lt, 1] = 150
        if br:
            arr[-r // 4 :, c - k * lt : c - (k - 1) * lt, 0] = 75
            arr[r - k * lt : r - (k - 1) * lt, -c // 4 :, 0] = 75
            arr[-r // 4 :, c - k * lt : c - (k - 1) * lt, 1] = 150
            arr[r - k * lt : r - (k - 1) * lt, -c // 4 :, 1] = 150
        if bl:
            arr[r - k * lt : r - (k - 1) * lt, : c // 4, 0] = 75
            arr[-r // 4 :, (k - 1) * lt : k * lt, 0] = 75
            arr[r - k * lt : r - (k - 1) * lt, : c // 4, 1] = 150
            arr[-r // 4 :, (k - 1) * lt : k * lt, 1] = 150
    return arr


def make_tier_frame(pixels, n_frames, line_thickness):
    return make_tier_lines(
        arr=zeros_rgb(pixels, pixels),
        n_lines=n_frames,
        line_thickness=line_thickness,
        left=True,
        top=True,
        right=True,
        bottom=True,
    )


def make_tier_lines(
    arr, n_lines, line_thickness, left=False, top=False, right=False, bottom=False
):
    lt = line_thickness
    r, c = arr.shape[:2]
    for k in range(1, 2 * n_lines, 2):
        if left:
            arr[r // 4 : -r // 4, (k - 1) * lt : k * lt, 0] = 75
            arr[r // 4 : -r // 4, (k - 1) * lt : k * lt, 1] = 150
        if top:
            arr[(k - 1) * lt : k * lt, c // 4 : -c // 4, 0] = 75
            arr[(k - 1) * lt : k * lt, c // 4 : -c // 4, 1] = 150
        if right:
            arr[r // 4 : -r // 4, c - k * lt : c - (k - 1) * lt, 0] = 75
            arr[r // 4 : -r // 4, c - k * lt : c - (k - 1) * lt, 1] = 150
        if bottom:
            arr[r - k * lt : r - (k - 1) * lt, c // 4 : -c // 4, 0] = 75
            arr[r - k * lt : r - (k - 1) * lt, c // 4 : -c // 4, 1] = 150
    return arr


def rescale(arr, shape):
    """
    Rescale the image given by the numpy array `arr` to width and height
    given by `shape`.
    """
    if arr.shape[-1] == 3:
        mode = "RGB"
    elif arr.shape[-1] == 4:
        mode = "RGBA"
    else:
        raise ValueError(f"Unexpected arr.shape[-1] = {arr.shape[-1]}.")

    sh = (shape[1], shape[0])
    return np.array(
        Image.fromarray(arr, mode=mode).resize(sh, Image.Resampling.NEAREST)
    )


def rotate_180(arr):
    return rotate_clockwise(rotate_clockwise(arr))


def rotate_clockwise(arr):
    return np.rot90(arr, 3, axes=(0, 1))


def rotate_counterclockwise(arr):
    return np.rot90(arr, 1, axes=(0, 1))


def shifted_base_cable(shift, pixels, thickness, yellow_line_offset):
    arr = zeros_rgb(pixels, pixels)
    base_cable_center = make_center_of_base_cable(
        pixels, thickness, shift, yellow_line_offset
    )
    arr[
        pixels // 2 - thickness // 2 : pixels // 2 + thickness // 2, :, :
    ] = base_cable_center
    return arr


def surround_by_transparent(arr, left, top, right=None, bottom=None):
    right = right or left
    bottom = bottom or top
    super_arr = zeros_rgba(arr.shape[0] + top + bottom, arr.shape[1] + left + right)
    super_arr[
        top : super_arr.shape[0] - bottom, left : super_arr.shape[1] - right, :-1
    ] = arr
    super_arr[
        top : super_arr.shape[0] - bottom, left : super_arr.shape[1] - right, -1
    ] = 255  # not transparent where `arr` is
    return super_arr


def zeros_rgb(rows, columns):
    return np.zeros((rows, columns, 3), dtype=np.uint8)


def zeros_rgba(rows, columns):
    return np.zeros((rows, columns, 4), dtype=np.uint8)


def zeros_rgba_opaque(rows, columns):
    arr = np.zeros((rows, columns, 4), dtype=np.uint8)
    arr[:, :, -1] = 255
    return arr


def zeros_rgba_wh(width, height):
    return zeros_rgba(height, width)


def zeros_rgba_wh_opaque(width, height):
    return zeros_rgba_opaque(height, width)
