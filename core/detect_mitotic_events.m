% DETECT_MITOTIC_EVENTS  Main pipeline: detect all mitotic events in a video.
%
% Loads tracking ground truth, iterates over every parent cell ID, computes
% an adaptive distance threshold based on parent cell area, and calls
% classify_mitotic_event() to find the two daughter cells per division.
%
% Usage:
%   Run this script directly from MATLAB after setting the paths below.
%
% Outputs:
%   - Console log of each detected parent -> daughter pair
%   - Scatter plot visualising mitotic events over time
%
% Dependency: classify_mitotic_event.m (must be on the MATLAB path)

%% --- Configure paths (update these to match your local data location) ---
seg_path   = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_ST', 'SEG');
track_file = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_GT', 'TRA', 'man_track.txt');

%% --- Load tracking data ---
track_data   = readmatrix(track_file);
cell_ids     = track_data(:, 1);
start_frames = track_data(:, 2);
end_frames   = track_data(:, 3);
parent_ids   = track_data(:, 4);

%% --- Detect mitotic events ---
scaling_factor     = 2.0;   % Multiplier for adaptive distance threshold
mitotic_event_count = 0;
mitotic_event_data  = [];   % [parent_id, frame, daughter_id1, daughter_id2]

parent_ids_to_test = unique(cell_ids);

for parent_id = parent_ids_to_test'
    parent_frame = end_frames(cell_ids == parent_id);

    if isempty(parent_frame)
        continue;
    end

    % Adaptive threshold: scale with the square root of parent cell area
    parent_seg   = imread(fullfile(seg_path, sprintf('man_seg%03d.tif', parent_frame)));
    parent_stats = regionprops(parent_seg, 'Area');
    if parent_id > numel(parent_stats)
        continue;
    end
    parent_area        = parent_stats(parent_id).Area;
    distance_threshold = sqrt(parent_area) * scaling_factor;

    daughter_ids = classify_mitotic_event(parent_id, parent_frame, seg_path, distance_threshold);

    if ~isempty(daughter_ids)
        fprintf('Mitotic event: Parent %d  ->  Daughters %d & %d  (Frame %d)\n', ...
            parent_id, daughter_ids(1), daughter_ids(2), parent_frame);
        mitotic_event_count = mitotic_event_count + 1;
        mitotic_event_data  = [mitotic_event_data; ...
            parent_id, parent_frame, daughter_ids(1), daughter_ids(2)]; %#ok<AGROW>
    end
end

fprintf('\nTotal mitotic events detected: %d\n', mitotic_event_count);

%% --- Visualise detected events ---
if isempty(mitotic_event_data)
    disp('No mitotic events detected.');
    return;
end

frames              = mitotic_event_data(:, 2);
parent_ids_visual   = mitotic_event_data(:, 1);
daughter_ids_visual = mitotic_event_data(:, 3:4);

figure;
hold on;
scatter(frames,     parent_ids_visual,          100, 'g', 'filled', 'DisplayName', 'Parent Cells');
scatter(frames + 1, daughter_ids_visual(:, 1),   50, 'b', 'filled', 'DisplayName', 'Daughter Cell 1');
scatter(frames + 1, daughter_ids_visual(:, 2),   50, 'r', 'filled', 'DisplayName', 'Daughter Cell 2');

for i = 1:size(mitotic_event_data, 1)
    pf = frames(i);
    d  = daughter_ids_visual(i, :);
    plot([pf, pf+1], [parent_ids_visual(i), d(1)], 'b--');
    plot([pf, pf+1], [parent_ids_visual(i), d(2)], 'r--');
end

xlabel('Frame Number');
ylabel('Cell IDs');
title('Detected Mitotic Events');
legend('show');
grid on;
hold off;
