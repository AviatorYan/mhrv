function [ mse_result, scale_axis ] = mse( sig, varargin )
%MSE Multi-scale entropy of a signal
%   Calculates the MSE of a signal, a measure of the signals complexity.
%   The algorithms calculates the Sample Entropy of the signal at various 'scales' from 1 to
%   max_scale. At each scale, the signal is downsampled by averaging 'scale' samples and the Sample
%   Entropy is calculated for the downsampled signal.
%
%   Input:
%       - sig: Signal to calculate MSE for.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - mse_max_scale: Maximal scale to calculate up to. Default: 20.
%           - sampen_r: Value of 'r' parameter to use when calculating sample entropy (max distance
%                       between two points that's considered a match). Default: 0.2.
%           - sampen_m: Value of 'm' parameter to use when calculating sample entropy (length of
%             templates to match). Default: 2.
%           - plot: true/false whether to generate a plot. Defaults to true if no output
%                   arguments were specified.
%   Output:
%       - mse_result: The sample entropy value at each scale.
%       - scale_axis: The corresponding scale values that were used.
%
%   Reference:
%       Costa, M. D., Goldberger, A. L., & Peng, C.-K. (2002).
%       Multiscale entropy analysis of complex physiologic time series.
%       Physical Review Letters, 89(6), 68102.
%       http://doi.org/10.1103/PhysRevLett.92.089803

%% === Input
DEFAULT_MSE_MAX_SCALE = rhrv_default('mse.mse_max_scale', 20);
DEFAULT_SAMPEN_R = rhrv_default('mse.sampen_r', 0.2); % percent of std. dev.
DEFAULT_SAMPEN_M = rhrv_default('mse.sampen_m', 2);

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('sig', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('mse_max_scale', DEFAULT_MSE_MAX_SCALE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_r', DEFAULT_SAMPEN_R, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_m', DEFAULT_SAMPEN_M, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(sig, varargin{:});
mse_max_scale = p.Results.mse_max_scale;
sampen_r = p.Results.sampen_r;
sampen_m = p.Results.sampen_m;
should_plot = p.Results.plot;

% Normalize input
N = length(sig);
sig_normalized = sig - mean(sig);
sig_normalized = sig_normalized / sqrt(var(sig_normalized));

% Preallocate result vector
mse_result = zeros(1, mse_max_scale);

scale_axis = 1:mse_max_scale;
for scale = scale_axis
    % Split the signal into windows of length 'scale'
    max_idx = floor(N/scale) * scale;
    sig_windows = reshape(sig_normalized(1:max_idx), scale, []);
    
    % Calculate the mean of each window to obtain the 'coarse-grained' signal
    sig_coarse = mean(sig_windows, 1);
    
    % Calculate sample entropy of the coarse-grained signal
    mse_result(scale) = sample_entropy(sig_coarse, sampen_m, sampen_r);
end

if (should_plot)
    % Plot MSE of the signal
    figure;
    plot(scale_axis, mse_result, '--ko', 'MarkerSize', 7); hold on;
    
    % Also plot the MSE of a shuffled version of the signal for comparison
    sig_shuffled = sig(randperm(N));
    [mse_shuffled, ~] = mse(sig_shuffled, 'mse_max_scale', mse_max_scale, 'sampen_r', sampen_r, 'sampen_m', sampen_m);
    plot(scale_axis, mse_shuffled, '--rx', 'MarkerSize', 7);

    grid on;
    xlabel('Scale factor'); ylabel('Sample Entropy');
    title(['MSE, ', 'r=' num2str(sampen_r), ' m=' num2str(sampen_m)]);
    legend('Original', 'Shuffled');
end
end
