% DEMO_SINGLE_FRAME  Display one annotated frame — a quick sanity check.
%
% Shows: raw fluorescence image with red segmentation boundaries,
% green centroid dots, and yellow tracking ID labels.
%
% Usage:
%   Change `frame` below to any value in [0, 91] and run.

%% --- Configure ---
frame      = 1;
base_path  = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01');
seg_path   = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_ST', 'SEG');
track_path = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_GT', 'TRA');

%% --- Load data ---
raw_img    = imread(fullfile(base_path,  sprintf('t%03d.tif',         frame)));
seg_mask   = imread(fullfile(seg_path,   sprintf('man_seg%03d.tif',   frame)));
track_data = imread(fullfile(track_path, sprintf('man_track%03d.tif', frame)));

%% --- Render ---
figure;
imshow(raw_img, []);
hold on;

boundary_handle = visboundaries(seg_mask > 0, 'Color', 'r');

stats          = regionprops(track_data, 'Centroid', 'PixelIdxList');
centroid_handle = [];
for i = 1:length(stats)
    centroid   = stats(i).Centroid;
    cell_label = unique(track_data(stats(i).PixelIdxList));
    centroid_handle = plot(centroid(1), centroid(2), '.', 'Color', 'g', 'MarkerSize', 8);
    text(centroid(1) + 3, centroid(2), num2str(cell_label), ...
        'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold');
end

xlabel('X (pixels)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Y (pixels)', 'FontSize', 14, 'FontWeight', 'bold');
legend([boundary_handle, centroid_handle], ...
    {'Segmentation Boundaries', 'Cell Centroids (tracking IDs in yellow)'}, ...
    'Location', 'northeast');
title(sprintf('Frame %d — Segmentation & Tracking Labels', frame), ...
    'FontSize', 16, 'FontWeight', 'bold');
hold off;
