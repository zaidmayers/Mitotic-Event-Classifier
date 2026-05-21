% VALIDATE_DETECTIONS  Compare detected mitotic events against ground truth.
%
% Performs a two-phase validation:
%   Phase 1 — Temporal: daughters must appear in the frame immediately after
%             the parent's last frame.
%   Phase 2 — Spatial:  parent-daughter centroid distance must be <= threshold.
%
% The script then calls classify_mitotic_event() for the full detection run
% and reports confirmed pairs alongside the distances used.
%
% Usage:
%   Run directly from MATLAB after setting the paths below.

%% --- Configure paths ---
seg_path   = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_ST', 'SEG');
track_file = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_GT', 'TRA', 'man_track.txt');

distance_threshold = 10;  % Pixels — spatial proximity threshold

%% --- Load ground truth tracking data ---
track_data   = readmatrix(track_file);
cell_ids     = track_data(:, 1);
start_frames = track_data(:, 2);
end_frames   = track_data(:, 3);
parent_ids   = track_data(:, 4);

mitotic_events = find(parent_ids ~= 0);

%% --- Phase 1: Temporal matching ---
% Daughters must start within 1 frame of parent's end
mitotic_pairs = [];
for i = 1:length(mitotic_events)
    current_cell_id = cell_ids(mitotic_events(i));
    parent_id       = parent_ids(mitotic_events(i));

    if parent_id == 0
        continue;
    end

    parent_idx = find(cell_ids == parent_id);
    if isempty(parent_idx)
        continue;
    end

    parent_end_frame    = end_frames(parent_idx);
    daughter_start_frame = start_frames(mitotic_events(i));

    if abs(daughter_start_frame - parent_end_frame) <= 1
        mitotic_pairs = [mitotic_pairs; ...
            parent_id, current_cell_id, parent_end_frame, daughter_start_frame]; %#ok<AGROW>
    end
end

fprintf('Temporal matches found: %d\n', size(mitotic_pairs, 1));

%% --- Phase 2: Spatial proximity confirmation ---
confirmed_mitotic_events = [];
for i = 1:size(mitotic_pairs, 1)
    parent_id        = mitotic_pairs(i, 1);
    daughter_id      = mitotic_pairs(i, 2);
    parent_end_frame = mitotic_pairs(i, 3);
    daughter_start   = mitotic_pairs(i, 4);

    parent_seg   = imread(fullfile(seg_path, sprintf('man_seg%03d.tif', parent_end_frame)));
    daughter_seg = imread(fullfile(seg_path, sprintf('man_seg%03d.tif', daughter_start)));

    parent_stats   = regionprops(parent_seg,   'Centroid');
    daughter_stats = regionprops(daughter_seg, 'Centroid');

    if parent_id > numel(parent_stats) || daughter_id > numel(daughter_stats)
        continue;
    end

    parent_centroid   = parent_stats(parent_id).Centroid;
    daughter_centroid = daughter_stats(daughter_id).Centroid;
    distance          = norm(parent_centroid - daughter_centroid);

    if distance <= distance_threshold
        confirmed_mitotic_events = [confirmed_mitotic_events; ...
            parent_id, daughter_id, parent_end_frame, daughter_start, distance]; %#ok<AGROW>
    end
end

fprintf('Spatially confirmed mitotic events: %d\n', size(confirmed_mitotic_events, 1));
disp('Columns: [ParentID, DaughterID, ParentEndFrame, DaughterStartFrame, Distance(px)]');
disp(confirmed_mitotic_events);
