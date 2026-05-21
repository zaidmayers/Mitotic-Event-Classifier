% CREATE_TRACKING_VIDEO  Render an annotated AVI from all dataset frames.
%
% For each frame, overlays:
%   - Red cell boundaries (from segmentation masks)
%   - Green centroid dots
%   - Yellow tracking ID labels
%
% Output: cell_tracking_movie.avi saved in the current directory.
%
% Usage:
%   Set the paths below and run. Requires the Image Processing Toolbox.

%% --- Configure paths ---
base_path  = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01');
seg_path   = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_ST',  'SEG');
track_path = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_GT',  'TRA');

frame_start  = 0;
frame_end    = 91;
output_file  = 'cell_tracking_movie.avi';
frame_rate   = 5;  % Frames per second

%% --- Write video ---
outputVideo            = VideoWriter(output_file);
outputVideo.FrameRate  = frame_rate;
open(outputVideo);

fig = figure;
for frame = frame_start:frame_end
    raw_img    = imread(fullfile(base_path, sprintf('t%03d.tif', frame)));
    track_data = imread(fullfile(track_path, sprintf('man_track%03d.tif', frame)));

    seg_mask_file = fullfile(seg_path, sprintf('man_seg%03d.tif', frame));
    if isfile(seg_mask_file)
        seg_mask = imread(seg_mask_file);
    else
        seg_mask = [];
    end

    imshow(raw_img, []);
    hold on;

    if ~isempty(seg_mask)
        visboundaries(seg_mask > 0, 'Color', 'r');
    end

    stats = regionprops(track_data, 'Centroid', 'PixelIdxList');
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

    writeVideo(outputVideo, getframe(fig));
end

close(outputVideo);
fprintf('Video saved to %s\n', output_file);
