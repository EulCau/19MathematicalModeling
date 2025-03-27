import numpy as np
import cv2
import tkinter as tk
from tkinter import filedialog
from matplotlib import pyplot as plt
import cvxpy as cp


def robust_pca(A, lambda_val=None, max_iter=1000, tol=1e-7):
	m, n = A.shape
	if lambda_val is None:
		lambda_val = 1 / np.sqrt(max(m, n))

	L = cp.Variable((m, n))
	S = cp.Variable((m, n))

	objective = cp.Minimize(cp.normNuc(L) + lambda_val * cp.norm1(S))
	constraints = [A == L + S]
	prob = cp.Problem(objective, constraints)
	prob.solve(solver=cp.SCS, verbose=True, max_iters=max_iter)

	return L.value, S.value


def process_image(filepath):
	image = cv2.imread(filepath, cv2.IMREAD_GRAYSCALE)
	image = image.astype(np.float64) / 255.0
	L, S = robust_pca(image)

	fig, axs = plt.subplots(1, 3, figsize=(12, 4))
	axs[0].imshow(image, cmap='gray')
	axs[0].set_title('Original Image')
	axs[1].imshow(L, cmap='gray')
	axs[1].set_title('Low-Rank (Denoised)')
	axs[2].imshow(S, cmap='gray')
	axs[2].set_title('Sparse (Noise)')

	for ax in axs:
		ax.axis('off')

	plt.show()


def open_file():
	filepath = filedialog.askopenfilename(filetypes=[("Image Files", "*.png;*.jpg;*.jpeg;*.bmp")])
	if filepath:
		process_image(filepath)


root = tk.Tk()
root.title("RPCA Image Denoising")
btn = tk.Button(root, text="Select Image", command=open_file)
btn.pack(pady=20)
root.mainloop()
