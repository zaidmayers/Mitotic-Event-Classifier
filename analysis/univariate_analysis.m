% UNIVARIATE_ANALYSIS  Bayesian classification using per-feature Gaussian models.
%
% Assumes a `results_table` workspace variable with columns:
%   ParentID, Distance1, Distance2
% and a `data` matrix loaded from man_track.txt (col 4 = parent labels).
%
% Steps:
%   1. Label each detection as correct/incorrect via ground truth.
%   2. Fit univariate Gaussians to Distance1 and Distance2 for each class.
%   3. Compute Bayesian posterior probabilities.
%   4. Reclassify detections based on posterior > 0.5.
%   5. Run Welch t-tests to assess feature discriminability.
%   6. Plot PDF overlays for each distance feature.
%
% Usage:
%   Ensure results_table and data (man_track.txt) are loaded, then run.

%% --- Ground truth labelling ---
ground_truth_parent_labels        = data(:, 4);
results_table.Classification      = ismember(results_table.ParentID, ground_truth_parent_labels);

false_classifications = results_table(~results_table.Classification, :);
fprintf('False classifications: %d\n', height(false_classifications));

%% --- Separate distances by class ---
distances          = [results_table.Distance1, results_table.Distance2];
correct_distances  = distances( results_table.Classification, :);
incorrect_distances = distances(~results_table.Classification, :);

%% --- Class statistics ---
mean_correct   = mean(correct_distances,   'omitnan');
std_correct    = std(correct_distances,    'omitnan');
mean_incorrect = mean(incorrect_distances, 'omitnan');
std_incorrect  = std(incorrect_distances,  'omitnan');

fprintf('\nCorrect class   — Mean: [%.3f, %.3f]  Std: [%.3f, %.3f]\n', ...
    mean_correct(1), mean_correct(2), std_correct(1), std_correct(2));
fprintf('Incorrect class — Mean: [%.3f, %.3f]  Std: [%.3f, %.3f]\n', ...
    mean_incorrect(1), mean_incorrect(2), std_incorrect(1), std_incorrect(2));

%% --- Bayesian posteriors ---
P_correct   = size(correct_distances,  1) / size(distances, 1);
P_incorrect = size(incorrect_distances,1) / size(distances, 1);

num_rows = size(distances, 1);
posteriors = zeros(num_rows, 2);

for i = 1:num_rows
    d1 = distances(i, 1);
    d2 = distances(i, 2);
    if isnan(d1) || isnan(d2)
        continue;
    end

    lk_correct   = normpdf(d1, mean_correct(1),   std_correct(1))   * ...
                   normpdf(d2, mean_correct(2),   std_correct(2));
    lk_incorrect = normpdf(d1, mean_incorrect(1), std_incorrect(1)) * ...
                   normpdf(d2, mean_incorrect(2), std_incorrect(2));

    denom = lk_correct * P_correct + lk_incorrect * P_incorrect;
    if denom > 0
        posteriors(i, 1) = (lk_correct * P_correct) / denom;
    end
    posteriors(i, 2) = 1 - posteriors(i, 1);
end

results_table.PosteriorCorrect   = posteriors(:, 1);
results_table.PosteriorIncorrect = posteriors(:, 2);
results_table.Classification     = results_table.PosteriorCorrect > 0.5;

disp(results_table(:, {'PosteriorCorrect', 'PosteriorIncorrect'}));

%% --- Welch t-tests for feature significance ---
[~, p1] = ttest2(correct_distances(:,1), incorrect_distances(:,1), 'Vartype', 'unequal');
[~, p2] = ttest2(correct_distances(:,2), incorrect_distances(:,2), 'Vartype', 'unequal');

fprintf('\nDistance1 p-value: %.4f  (%s)\n', p1, significance_label(p1));
fprintf('Distance2 p-value: %.4f  (%s)\n', p2, significance_label(p2));

%% --- PDF visualisation ---
x = linspace(0, 50, 200);
figure;

subplot(1, 2, 1);
plot(x, normpdf(x, mean_correct(1),   std_correct(1)),   'g', 'LineWidth', 1.5); hold on;
plot(x, normpdf(x, mean_incorrect(1), std_incorrect(1)), 'r', 'LineWidth', 1.5);
legend('Correct', 'Incorrect');
xlabel('Distance1 (px)'); ylabel('Probability Density');
title('Distance1 — Univariate PDF'); grid on; hold off;

subplot(1, 2, 2);
plot(x, normpdf(x, mean_correct(2),   std_correct(2)),   'g', 'LineWidth', 1.5); hold on;
plot(x, normpdf(x, mean_incorrect(2), std_incorrect(2)), 'r', 'LineWidth', 1.5);
legend('Correct', 'Incorrect');
xlabel('Distance2 (px)'); ylabel('Probability Density');
title('Distance2 — Univariate PDF'); grid on; hold off;

sgtitle('Bayesian Classification: Univariate Gaussian PDFs');

%% --- Helper ---
function label = significance_label(p)
    if p < 0.05
        label = 'significant';
    else
        label = 'not significant';
    end
end
