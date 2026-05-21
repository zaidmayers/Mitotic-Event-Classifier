% EXPORT_FRAME_PNGS  Save every frame as an annotated full-resolution PNG.
%
% Iterates frames 1–91, renders raw image with segmentation boundaries,
% centroid markers, and tracking ID labels, then saves each to
% output/<frame_N_output.png>.
%
% Usage:
%   Set paths below and run. Output folder is created automatically.

%% --- Configure paths ---
base_path  = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01');
seg_path   = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_ST', 'SEG');
track_path = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_GT', 'TRA');
output_dir = 'output';

frame_start = 1;
frame_end   = 91;

%% --- Ensure output directory exists ---
if ~isfolder(output_dir)
    mkdir(output_dir);
end

%% --- Export frames ---
for frame = frame_start:frame_end
    raw_img    = imread(fullfile(base_path,  sprintf('t%03d.tif',         frame)));
    track_data = imread(fullfile(track_path, sprintf('man_track%03d.tif', frame)));

    seg_mask_file = fullfile(seg_path, sprintf('man_seg%03d.tif', frame));
    if isfile(seg_mask_file)
        seg_mask = imread(seg_mask_file);
    else
        seg_mask = [];
    end

    fig = figure('Units', 'normalized', 'OuterPosition', [0 0 1 1], 'Visible', 'off');
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
            plot(centroid(1), centroid(2), '.', 'Color', 'g', 'MarkerSize', 8);
            text(centroid(1) + 3, centroid(2), num2str(cell_label), ...
                'Color', 'yellow', 'FontSize', 10, 'FontWeight', 'bold');
        end
    end

    title(sprintf('Frame %d', frame));
    hold off;

    out_file = fullfile(output_dir, sprintf('frame_%d_output.png', frame));
    saveas(fig, out_file);
    close(fig);

    fprintf('Saved %s\n', out_file);
end

fprintf('Done. %d frames exported to %s/\n', frame_end - frame_start + 1, output_dir);
