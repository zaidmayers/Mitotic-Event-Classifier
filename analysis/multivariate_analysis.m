% MULTIVARIATE_ANALYSIS  Fit a bivariate Gaussian to (Distance1, Distance2).
%
% Assumes a `results_table` workspace variable with columns Distance1 and Distance2
% produced by detect_mitotic_events.m.
%
% Steps:
%   1. Remove NaN rows from the distance matrix.
%   2. Estimate mean vector and covariance matrix (with singularity guard).
%   3. Compute log-likelihood under the fitted multivariate Gaussian.
%   4. Plot a contour overlay on the observed data scatter.
%
% Usage:
%   Ensure results_table is in the workspace, then run.

%% --- Prepare distance matrix ---
distances  = [results_table.Distance1, results_table.Distance2];
valid_idx  = ~isnan(distances(:,1)) & ~isnan(distances(:,2));
distances  = distances(valid_idx, :);

%% --- Fit multivariate Gaussian ---
mean_vector = mean(distances);
cov_matrix  = cov(distances);

% Regularise if nearly singular to ensure numerical stability
if rcond(cov_matrix) < 1e-12
    disp('Covariance matrix is nearly singular — applying regularisation.');
    cov_matrix = cov_matrix + 1e-6 * eye(size(cov_matrix));
end

log_likelihood = sum(log(mvnpdf(distances, mean_vector, cov_matrix)));

fprintf('Multivariate Gaussian fit:\n');
fprintf('  Mean vector:     [%.4f, %.4f]\n', mean_vector(1), mean_vector(2));
fprintf('  Covariance:\n');
disp(cov_matrix);
fprintf('  Log-likelihood:  %.4f\n', log_likelihood);

%% --- Visualise ---
grid_n = 100;
x_range = linspace(min(distances(:,1)), max(distances(:,1)), grid_n);
y_range = linspace(min(distances(:,2)), max(distances(:,2)), grid_n);
[X, Y] = meshgrid(x_range, y_range);

Z = mvnpdf([X(:), Y(:)], mean_vector, cov_matrix);
Z = reshape(Z, size(X));

figure;
contour(X, Y, Z, 10);
hold on;
scatter(distances(:,1), distances(:,2), 20, 'r.', 'DisplayName', 'Observed Data');
xlabel('Distance1 (px)');
ylabel('Distance2 (px)');
title('Bivariate Gaussian Fit — Distance1 vs Distance2');
legend;
grid on;
hold off;
