function [] = plot_hrv_freq_spectrum( ax, plot_data, varargin )
%PLOT_HRV_FREQ_SPECTRUM Plots the spectrums generated by hrv_freq.
%   ax: axes handle to plot to.
%   plot_data: struct returned from hrv_freq.
%

%% Input
SUPPORTED_METHODS = {'Lomb', 'AR', 'Welch', 'FFT'};

p = inputParser;
p.addRequired('ax', @(x) isgraphics(x, 'axes'));
p.addRequired('plot_data', @isstruct);
p.addParameter('clear', false, @islogical);
p.addParameter('tag', default_axes_tag(mfilename), @ischar);
p.addParameter('xscale', 'linear', @(x)strcmpi(x,'log')||strcmpi(x,'linear'));
p.addParameter('yscale', 'log', @(x)strcmpi(x,'log')||strcmpi(x,'linear'));
p.addParameter('ylim', 'auto');
p.addParameter('peaks', false);
p.addParameter('detailed_legend', true);
p.addParameter('methods', SUPPORTED_METHODS, @(x) cellfun(@(m) any(cellfun(@(ms) strcmp(m,ms), SUPPORTED_METHODS)), x));

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;
xscale = p.Results.xscale;
yscale = p.Results.yscale;
yrange = p.Results.ylim;
plot_peaks = p.Results.peaks;
detailed_legend = p.Results.detailed_legend;
methods = p.Results.methods;

f_axis          = plot_data.f_axis;
pxx_lomb        = plot_data.pxx_lomb;
pxx_ar          = plot_data.pxx_ar;
pxx_welch       = plot_data.pxx_welch;
pxx_fft         = plot_data.pxx_fft;
vlf_band        = plot_data.vlf_band;
lf_band         = plot_data.lf_band;
hf_band         = plot_data.hf_band;
f_max           = plot_data.f_max;
t_win           = plot_data.t_win;
welch_overlap   = plot_data.welch_overlap;
ar_order        = plot_data.ar_order;
num_windows     = plot_data.num_windows;
lf_peak         = plot_data.lf_peaks(1);
hf_peak         = plot_data.hf_peaks(1);

%% Plot
if clear
    cla(ax);
end

hold(ax, 'on');
legend_handles = [];
legend_entries = {};
colors = lines(length(methods));

% Plot PSDs
for ii = 1:length(methods)
    pxx = plot_data.(['pxx_' lower(methods{ii})]);

    % Skip this power method if it wasn't calculated or if it wasn't requested for plotting
    if isempty(pxx) || ~any(cellfun(@(m) strcmp(methods{ii}, m), methods))
        continue;
    end

    % Plot PSD
    hp = plot(ax, f_axis, pxx, 'Color', colors(ii,:));

    % Save handle
    legend_handles(ii) = hp;
    
    % Create legend label
    if detailed_legend
        switch lower(methods{ii})
            case {'fft', 'lomb'}
                legend_entries{ii} = sprintf('%s (t_{win}=%.1fm, n=%d)', methods{ii}, t_win/60, num_windows);
            case 'welch'
                legend_entries{ii} = sprintf('%s (%d%%)', methods{ii}, welch_overlap);
            case 'ar'
                legend_entries{ii} = sprintf('%s (%d)', methods{ii}, ar_order);
        end
    else
        legend_entries{ii} = methods{ii};
    end
end

% Peaks
if plot_peaks && ~isnan(lf_peak)
    hp = plot(ax, lf_peak, pxx_lomb(f_axis==lf_peak).*1.25, 'bv', 'MarkerSize', 8, 'MarkerFaceColor', 'blue');
    legend_handles(end+1) = hp;
    legend_entries{end+1} = sprintf('%.3f Hz', lf_peak);
end
if plot_peaks && ~isnan(hf_peak)
    hp = plot(ax, hf_peak, pxx_lomb(f_axis==hf_peak).*1.25, 'rv', 'MarkerSize', 8, 'MarkerFaceColor', 'red');
    legend_handles(end+1) = hp;
    legend_entries{end+1} = sprintf('%.3f Hz', hf_peak);
end

% Set axes scales (linear/log)
set(ax, 'XScale', xscale, 'YScale', yscale);
grid(ax, 'on');
axis(ax, 'tight');

% Axes limits
xrange = [0,f_max*1.01];
xlim(ax, xrange);
ylim(ax, yrange);
yrange = ylim(ax); % in case it was 'auto'

% Vertical lines of frequency ranges
lw = 3; ls = ':'; lc = 'black';
line(vlf_band(1) * ones(1,2), yrange, 'Parent', ax, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
line(lf_band(1)  * ones(1,2), yrange, 'Parent', ax, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
line(hf_band(1)  * ones(1,2), yrange, 'Parent', ax, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
line(hf_band(2)  * ones(1,2), yrange, 'Parent', ax, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);

% Names of frequency ranges
text(vlf_band(1), yrange(2) * 0.9, ' VLF', 'Parent', ax);
text( lf_band(1), yrange(2) * 0.9,  ' LF', 'Parent', ax);
text( hf_band(1), yrange(2) * 0.9,  ' HF', 'Parent', ax);

% Labels
legend(ax, legend_handles, legend_entries);
xlabel(ax, 'Frequency [Hz]');
ylabel(ax, 'Log Power Density [s^2/Hz]');

%% Tag
ax.Tag = tag;

end

