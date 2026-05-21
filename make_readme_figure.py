"""
Generates docs/mitosis_example.png — a three-panel figure showing a
mitotic event: Parent cell 1 in frames 29 & 30, then daughter cells
8 and 9 appearing in frame 31.
"""

import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from PIL import Image
import scipy.ndimage as ndi

BASE   = r"Fluo-N2DL-HeLa-Train\01"
SEG    = r"Fluo-N2DL-HeLa-Train\01_ST\SEG"
TRACK  = r"Fluo-N2DL-HeLa-Train\01_GT\TRA"

FRAMES       = [29, 30, 31]
PARENT_ID    = 1
DAUGHTER_IDS = [8, 9]

CROP_PAD = 80   # pixels of context around the cell of interest

def load(folder, pattern, frame):
    path = fr"{folder}\{pattern.format(frame)}"
    return np.array(Image.open(path))

def centroid_of(track_mask, cell_id):
    mask = track_mask == cell_id
    if not mask.any():
        return None
    cy, cx = ndi.center_of_mass(mask)
    return cx, cy   # (x, y) for matplotlib

def crop_box(img, cx, cy, pad):
    h, w = img.shape[:2]
    x0 = max(0, int(cx) - pad)
    x1 = min(w, int(cx) + pad)
    y0 = max(0, int(cy) - pad)
    y1 = min(h, int(cy) + pad)
    return img[y0:y1, x0:x1], x0, y0

# ── find a shared crop centred on the division site ──────────────────────────
track30 = load(TRACK, "man_track{:03d}.tif", 30)
track31 = load(TRACK, "man_track{:03d}.tif", 31)

parent_cx, parent_cy = centroid_of(track30, PARENT_ID)

d_cents = [centroid_of(track31, d) for d in DAUGHTER_IDS if centroid_of(track31, d)]
all_cx  = [parent_cx] + [c[0] for c in d_cents]
all_cy  = [parent_cy] + [c[1] for c in d_cents]
focus_cx = np.mean(all_cx)
focus_cy = np.mean(all_cy)

# ── build figure ──────────────────────────────────────────────────────────────
PANEL_FRAMES = [29, 30, 31]
TITLES       = ["Frame 29\n(parent, pre-division)",
                "Frame 30\n(parent, final frame)",
                "Frame 31\n(daughters appear)"]

fig, axes = plt.subplots(1, 3, figsize=(13, 5))
fig.patch.set_facecolor('#0d0d0d')

for ax, frame, title in zip(axes, PANEL_FRAMES, TITLES):
    raw   = load(BASE,  "t{:03d}.tif", frame)
    track = load(TRACK, "man_track{:03d}.tif", frame)

    # normalise 16-bit to 8-bit for display
    raw_f = raw.astype(float)
    raw_u8 = ((raw_f - raw_f.min()) / (raw_f.max() - raw_f.min() + 1e-9) * 255).astype(np.uint8)

    # crop around division site
    cropped, x0, y0 = crop_box(raw_u8, focus_cx, focus_cy, CROP_PAD)
    ax.imshow(cropped, cmap='gray', interpolation='nearest')

    # ── annotate cells ────────────────────────────────────────────────────────
    def draw_cell(cell_id, color, label):
        c = centroid_of(track, cell_id)
        if c is None:
            return
        lx, ly = c[0] - x0, c[1] - y0
        circ = plt.Circle((lx, ly), 14, color=color, fill=False, linewidth=2)
        ax.add_patch(circ)
        ax.text(lx, ly - 18, label, color=color, fontsize=9,
                ha='center', va='bottom', fontweight='bold',
                bbox=dict(boxstyle='round,pad=0.2', fc='#0d0d0d', ec='none', alpha=0.7))

    if frame in [29, 30]:
        draw_cell(PARENT_ID, '#00e676', f'Parent (ID {PARENT_ID})')

    if frame == 31:
        colors = ['#40c4ff', '#ff6d00']
        for d_id, col in zip(DAUGHTER_IDS, colors):
            draw_cell(d_id, col, f'Daughter {d_id}')

        # arrow pointing between the two daughters
        c1 = centroid_of(track, DAUGHTER_IDS[0])
        c2 = centroid_of(track, DAUGHTER_IDS[1])
        if c1 and c2:
            mx = ((c1[0] + c2[0]) / 2) - x0
            my = ((c1[1] + c2[1]) / 2) - y0
            ax.annotate('', xy=(c2[0]-x0, c2[1]-y0), xytext=(c1[0]-x0, c1[1]-y0),
                        arrowprops=dict(arrowstyle='<->', color='white',
                                        lw=1.5, connectionstyle='arc3,rad=0.0'))
            ax.text(mx, my - 5, 'division', color='white', fontsize=8,
                    ha='center', va='bottom',
                    bbox=dict(boxstyle='round,pad=0.2', fc='#333', ec='none', alpha=0.8))

    ax.set_title(title, color='white', fontsize=10, pad=6)
    ax.axis('off')

# ── divider arrow between panels 30→31 ───────────────────────────────────────
fig.text(0.645, 0.5, '→  divides  →', color='#ff9800', fontsize=11,
         ha='center', va='center', fontweight='bold')

plt.suptitle('Mitotic Event Detection — Fluo-N2DL-HeLa',
             color='white', fontsize=13, fontweight='bold', y=1.01)
plt.tight_layout(pad=1.5)

out = r"docs\mitosis_example.png"
plt.savefig(out, dpi=150, bbox_inches='tight',
            facecolor=fig.get_facecolor())
print(f"Saved {out}")
