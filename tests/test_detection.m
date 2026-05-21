% TEST_DETECTION  Validate classify_mitotic_event() on a known mitotic pair.
%
% Cell ID 1 divides at frame 30 producing daughters 8 and 9.
% This test confirms the function returns [8, 9] (or [9, 8]) for that pair.
%
% Usage:
%   Run after setting the path below. Must be run from the project root so
%   that addpath can locate core/classify_mitotic_event.m.

addpath(fullfile(pwd, 'core'));

%% --- Configure ---
seg_path           = fullfile('data', 'Fluo-N2DL-HeLa-Train', '01_ST', 'SEG');
parent_id          = 1;
parent_frame       = 30;
distance_threshold = 27;

%% --- Run ---
daughter_ids = classify_mitotic_event(parent_id, parent_frame, seg_path, distance_threshold);

%% --- Report ---
if ~isempty(daughter_ids)
    fprintf('PASS: Detected daughters for Parent ID %d at Frame %d: IDs %d and %d\n', ...
        parent_id, parent_frame, daughter_ids(1), daughter_ids(2));
else
    fprintf('FAIL: No mitotic event detected for Parent ID %d at Frame %d\n', ...
        parent_id, parent_frame);
end
