import math
import os

from PIL import Image

# Constants
DPI = 180
A4_SIZE = (int(8.27 * DPI), int(11.69 * DPI))
MARGIN = 50  # Margin around edges
PADDING = 10  # Space between images

# Load images from a folder
image_folder = "5-labelled/"
output_pdf = "montage.pdf"

images = [
    Image.open(os.path.join(image_folder, f))
    for f in os.listdir(image_folder)
    if f.endswith(".png")
]

pages = []
current_page = Image.new("RGB", A4_SIZE, "white")
x, y = MARGIN, MARGIN
max_height_in_row = 0

for img in images:
    img_width, img_height = img.size

    # If the image doesn't fit in the row, move to the next row
    if x + img_width > A4_SIZE[0] - MARGIN:
        x = MARGIN
        y += max_height_in_row + PADDING
        max_height_in_row = 0

    # If the image doesn't fit on the page, save current page and start a new one
    if y + img_height > A4_SIZE[1] - MARGIN:
        pages.append(current_page)
        current_page = Image.new("RGB", A4_SIZE, "white")
        x, y = MARGIN, MARGIN

    # Paste image onto the page
    current_page.paste(img, (x, y))
    x += img_width + PADDING
    max_height_in_row = max(max_height_in_row, img_height)

# Save last page
pages.append(current_page)

# Save as PDF
pages[0].save(output_pdf, save_all=True, append_images=pages[1:])
print(f"PDF saved as {output_pdf}")
