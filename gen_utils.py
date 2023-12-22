import numpy as np


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


def make_base_cable(pixels_x, pixels_y, yellow_line_offset):
    arr = np.zeros((pixels_y, 3 * pixels_x, 3), dtype=np.uint8)
    arr[:, :, :] = 100
    arr[pixels_y // 7 : -pixels_y // 7, ::yellow_line_offset, 0] = 255
    arr[pixels_y // 7 : -pixels_y // 7, ::yellow_line_offset, 1] = 255
    arr[pixels_y // 7 : -pixels_y // 7, 1::yellow_line_offset, 0] = 255
    arr[pixels_y // 7 : -pixels_y // 7, 1::yellow_line_offset, 1] = 255
    arr[pixels_y // 5 : -pixels_y // 5, 4::yellow_line_offset, 0] = 255
    arr[pixels_y // 5 : -pixels_y // 5, 4::yellow_line_offset, 1] = 255
    arr[pixels_y // 5 : -pixels_y // 5, 5::yellow_line_offset, 0] = 255
    arr[pixels_y // 5 : -pixels_y // 5, 5::yellow_line_offset, 1] = 255
    arr[pixels_y // 3 : -pixels_y // 3, 8::yellow_line_offset, 0] = 255
    arr[pixels_y // 3 : -pixels_y // 3, 8::yellow_line_offset, 1] = 255
    arr[pixels_y // 3 : -pixels_y // 3, 9::yellow_line_offset, 0] = 255
    arr[pixels_y // 3 : -pixels_y // 3, 9::yellow_line_offset, 1] = 255
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


def make_tier_edges(
    arr, n_lines, line_thickness, tl=False, tr=False, br=False, bl=False
):
    lt = line_thickness
    r, c = arr.shape[:2]
    for k in range(1, 2 * n_lines, 2):
        if tl:
            arr[: r // 4, (k - 1) * lt : k * lt, 1] = 255
            arr[(k - 1) * lt : k * lt, : c // 4, 1] = 255
        if tr:
            arr[(k - 1) * lt : k * lt, -c // 4 :, 1] = 255
            arr[: r // 4, c - k * lt : c - (k - 1) * lt, 1] = 255
        if br:
            arr[-r // 4 :, c - k * lt : c - (k - 1) * lt, 1] = 255
            arr[r - k * lt : r - (k - 1) * lt, -c // 4 :, 1] = 255
        if bl:
            arr[r - k * lt : r - (k - 1) * lt, : c // 4, 1] = 255
            arr[-r // 4 :, (k - 1) * lt : k * lt, 1] = 255
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
            arr[r // 4 : -r // 4, (k - 1) * lt : k * lt, 1] = 255
        if top:
            arr[(k - 1) * lt : k * lt, c // 4 : -c // 4, 1] = 255
        if right:
            arr[r // 4 : -r // 4, c - k * lt : c - (k - 1) * lt, 1] = 255
        if bottom:
            arr[r - k * lt : r - (k - 1) * lt, c // 4 : -c // 4, 1] = 255
    return arr


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
    super_arr[top:-bottom, left:-right, :-1] = arr
    super_arr[top:-bottom, left:-right, -1] = 255
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
