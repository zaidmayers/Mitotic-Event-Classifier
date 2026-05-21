function daughter_ids = classify_mitotic_event(parent_id, parent_frame, seg_path, distance_threshold)
% CLASSIFY_MITOTIC_EVENT  Detect daughter cells for a given parent cell.
%
%   daughter_ids = classify_mitotic_event(parent_id, parent_frame, seg_path, distance_threshold)
%
%   Inputs:
%     parent_id          - Cell ID of the parent cell
%     parent_frame       - Frame number where the parent cell ends
%     seg_path           - Path to segmentation mask directory (man_seg*.tif)
%     distance_threshold - Max centroid distance (px) from parent to daughter
%
%   Output:
%     daughter_ids - [1x2] array of two daughter cell IDs, or [] if no
%                    valid mitotic event is detected

    % Load segmentation for parent frame and the next frame (daughter frame)
    parent_seg = imread(fullfile(seg_path, sprintf('man_seg%03d.tif', parent_frame)));
    daughter_frame = parent_frame + 1;
    daughter_seg_path = fullfile(seg_path, sprintf('man_seg%03d.tif', daughter_frame));

    % Return empty if no daughter frame exists (parent was in last frame)
    if ~isfile(daughter_seg_path)
        daughter_ids = [];
        return;
    end
    daughter_seg = imread(daughter_seg_path);

    % Validate parent cell: must exist, have a centroid, and be large enough
    parent_stats = regionprops(parent_seg, 'Centroid', 'Area');
    if parent_id > numel(parent_stats) || ...
       isempty(parent_stats(parent_id).Centroid) || ...
       parent_stats(parent_id).Area < 10
        fprintf('Skipping Parent ID %d in Frame %d: invalid or too small.\n', parent_id, parent_frame);
        daughter_ids = [];
        return;
    end
    parent_centroid = parent_stats(parent_id).Centroid;

    % Gather all candidate cells in the daughter frame
    daughter_stats  = regionprops(daughter_seg, 'Centroid', 'Area');
    daughter_centroids = vertcat(daughter_stats.Centroid);
    daughter_areas     = [daughter_stats.Area]';

    % Filter out noise regions below minimum area
    min_area = 10;
    valid_indices     = find(daughter_areas >= min_area);
    filtered_centroids = daughter_centroids(valid_indices, :);

    % Euclidean distance from parent centroid to all candidate daughters
    distances = vecnorm(filtered_centroids - parent_centroid, 2, 2);

    % Pick the two closest candidates
    [sorted_distances, sorted_indices] = sort(distances);
    sorted_valid_indices = valid_indices(sorted_indices);

    % Both closest daughters must be within the distance threshold
    if numel(sorted_distances) >= 2 && ...
       sorted_distances(1) <= distance_threshold && ...
       sorted_distances(2) <= distance_threshold
        daughter_ids = sorted_valid_indices(1:2);
    else
        daughter_ids = [];
        return;
    end

    % Reject if the two daughters are too far apart from each other
    max_daughter_separation = 15;
    c1 = daughter_stats(daughter_ids(1)).Centroid;
    c2 = daughter_stats(daughter_ids(2)).Centroid;
    if norm(c1 - c2) > max_daughter_separation
        fprintf('Daughters for Parent ID %d are too far apart (%.2f px).\n', ...
            parent_id, norm(c1 - c2));
        daughter_ids = [];
    end
end
