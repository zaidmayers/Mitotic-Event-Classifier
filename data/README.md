# Data

Place the **Fluo-N2DL-HeLa** dataset here before running any scripts.

## Expected structure

```
data/
└── Fluo-N2DL-HeLa-Train/
    ├── 01/                     # Raw fluorescence images (t000.tif – t091.tif)
    ├── 02/                     # Second training sequence
    ├── 01_GT/
    │   ├── TRA/
    │   │   ├── man_track.txt           # Ground-truth cell lineage
    │   │   └── man_track000.tif …      # Per-frame tracking masks
    │   └── SEG/                        # Segmentation masks (GT)
    ├── 01_ST/
    │   └── SEG/                        # Submission-format segmentation masks
    └── 02_GT/, 02_ST/ …               # Same layout for sequence 02
```

## man_track.txt format

| Column | Field        | Description                              |
|--------|--------------|------------------------------------------|
| 1      | CellID       | Unique integer per cell track            |
| 2      | StartFrame   | First frame the cell appears in          |
| 3      | EndFrame     | Last frame the cell appears in           |
| 4      | ParentID     | 0 = no parent (root cell); >0 = daughter |

A non-zero ParentID marks a mitotic event: the cell is a daughter of the given parent.

## Dataset source

Fluo-N2DL-HeLa is from the **Cell Tracking Challenge**:
http://celltrackingchallenge.net/2d-datasets/

HeLa cells imaged with fluorescent nuclei, 512×512 px, 92 frames per sequence.

## Note

All `.tif` image files are **gitignored** — they are too large for GitHub.
Download the dataset from the source above and unzip it into this folder.
