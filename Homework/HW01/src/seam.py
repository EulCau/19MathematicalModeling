import cv2
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import Button

# Read image and convert to RGB format
im = cv2.imread('peppers.png')
im = cv2.cvtColor(im, cv2.COLOR_BGR2RGB)

# Create figure and subplots
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 7))
fig.subplots_adjust(bottom=0.2)

# Display original image
ax1.imshow(im, aspect='auto', extent=[0, im.shape[1], im.shape[0], 0])
ax1.set_title('Input Image')
ax1.set_xlabel(f'Width: {im.shape[1]} pixels')
ax1.set_ylabel(f'Height: {im.shape[0]} pixels')

# Initialize resized image display with proper extent
ax2_img = ax2.imshow(np.zeros_like(im), 
                    aspect='auto',
                    extent=[0, im.shape[1], im.shape[0], 0])
ax2.set_title('Resized Image\nClick button to resize')
ax2.set_xlabel(f'Width: {im.shape[1]} pixels')
ax2.set_ylabel(f'Height: {im.shape[0]} pixels')
ax2.set_xlim(0, im.shape[1])
ax2.set_ylim(im.shape[0], 0)  # Invert y-axis for image coordinates

# Configure axis ticks
for ax in [ax1, ax2]:
    ax.xaxis.set_major_locator(plt.MultipleLocator(100))
    ax.yaxis.set_major_locator(plt.MultipleLocator(100))
    ax.grid(linestyle='--', alpha=0.7)

# Energy calculation using gradient kernel
def calculate_energy(img):
    kernel = np.array([[0.5, 1, 0.5],
                       [1, -6, 1],
                       [0.5, 1, 0.5]], dtype=np.float32)
    img_float = img.astype(np.float32)
    conv = np.zeros_like(img_float)
    for channel in range(3):
        conv[:, :, channel] = cv2.filter2D(img_float[:, :, channel], -1, kernel, 
                                         borderType=cv2.BORDER_REFLECT)
    return np.sum(conv**2, axis=2)

# Dynamic programming for seam finding
def find_optimal_seam(energy_map):
    h, w = energy_map.shape
    dp = energy_map.copy()
    backtrack = np.zeros_like(dp, dtype=int)
    
    # Populate DP matrix
    for row in range(1, h):
        for col in range(w):
            min_idx = max(0, col-1) + np.argmin(dp[row-1, max(0, col-1):min(w, col+2)])
            dp[row, col] += dp[row-1, min_idx]
            backtrack[row, col] = min_idx
    
    # Backtrack to find seam
    seam = []
    col = np.argmin(dp[-1])
    for row in reversed(range(h)):
        seam.append(col)
        col = backtrack[row, col]
    return list(reversed(seam))

# Remove identified seam from image
def remove_seam(image, seam):
    h, w = image.shape[:2]
    mask = np.ones((h, w), dtype=bool)
    for row, col in enumerate(seam):
        mask[row, col] = False
    return image[mask].reshape((h, w-1, 3))

# Main carving algorithm
def seam_carve(image, target_size):
    current_img = image.copy()
    width_diff = current_img.shape[1] - target_size[1]
    for _ in range(width_diff):
        energy = calculate_energy(current_img)
        seam = find_optimal_seam(energy)
        current_img = remove_seam(current_img, seam)
    return current_img

# Button click handler with proper display updates
def update_display(event):
    target_width = im.shape[1] - 300
    resized = seam_carve(im, (im.shape[0], target_width))
    
    # Update image data and display parameters
    ax2_img.set_data(resized)
    ax2_img.set_extent([0, resized.shape[1], resized.shape[0], 0])
    ax2.set_xlabel(f'Width: {resized.shape[1]} pixels')
    ax2.set_ylabel(f'Height: {resized.shape[0]} pixels')
    ax2.set_xlim(0, resized.shape[1])
    ax2.set_ylim(resized.shape[0], 0)
    
    # Redraw canvas
    fig.canvas.draw_idle()

# Create resize button
button_ax = plt.axes([0.35, 0.05, 0.3, 0.075])
resize_btn = Button(button_ax, 'Resize Image', color='lightblue', hovercolor='0.9')
resize_btn.on_clicked(update_display)

plt.show()