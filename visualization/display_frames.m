% DISPLAY_FRAMES  Show a sequence of frames side-by-side in a single figure.
%
% Useful for inspecting cell state across consecutive frames during a
% mitotic event. Each tile shows: raw image + red segmentation boundaries
% + green centroid dots + yellow tracking ID labels.
%
% Usage:
%   Edit the `frames` array below and run.

%% --- Configure ---
frames     = [12, 13, 14, 15];  % Frame numbers to display
base_path  = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01');
seg_path   = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_GT', 'SEG');
track_path = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_GT', 'TRA');

%% --- Render tiled layout ---
num_frames = length(frames);
figure;
tiledlayout(1, num_frames, 'Padding', 'compact', 'TileSpacing', 'compact');

for i = 1:num_frames
    frame      = frames(i);
    raw_img    = imread(fullfile(base_path,  sprintf('t%03d.tif',           frame)));
    seg_mask   = imread(fullfile(seg_path,   sprintf('man_seg%03d.tif',     frame)));
    track_data = imread(fullfile(track_path, sprintf('man_track%03d.tif',   frame)));

    nexttile;
    imshow(raw_img, []);
    hold on;
    visboundaries(seg_mask > 0, 'Color', 'r');

    stats = regionprops(seg_mask, 'Centroid', 'PixelIdxList');
    for k = 1:length(stats)
        centroid   = stats(k).Centroid;
        cell_label = unique(track_data(stats(k).PixelIdxList));
        cell_label = cell_label(cell_label > 0);
        if ~isempty(cell_label)
            plot(centroid(1), centroid(2), '.', 'Color', 'g', 'MarkerSize', 3);
            text(centroid(1) + 3, centroid(2), num2str(cell_label), ...
                'Color', 'yellow', 'FontSize', 8, 'FontWeight', 'bold');
        end
    end

    title(sprintf('Frame %d', frame));
    hold off;
end

sgtitle('Cell Tracking Across Selected Frames');
