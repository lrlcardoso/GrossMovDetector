% =========================================================================
% Title:          Plot and Report Movement Detection
% Description:    Visualizes position, binary use signal, shoulder distance,
%                 and movement event markers. Optionally displays summary stats
%                 and saves the figure for later inspection.
% Author:         Lucas R. L. Cardoso
% Project:        VRRehab_UQ-MyTurn
% Date:           2025-07-08
% Version:        1.0
% =========================================================================
% Usage:
%   plot_and_report(pos, binary_signal, t_cross_filtered, pos_cross_filtered, ...
%                   filtered_dist, time, cam_idx, label, ...
%                   do_plot, do_report, do_savePlots, ...
%                   session_path, segment_name)
%
% Dependencies:
%   - MATLAB R2023a or later
%   - Helper function: ternary
%
% Notes:
%   - Uses `yyaxis` to plot position and shoulder width on separate axes.
%   - Plots start/end movement events based on filtered zero-crossings.
%   - Output figures are saved to the 'Plots/MovementDetection' directory.
%
% Changelog:
%   - v1.0: [2025-07-08] Initial implementation.
% =========================================================================

function plot_and_report(pos, binary_signal, t_cross_filtered, pos_cross_filtered, filtered_dist, time, cam_idx, label, do_plot, do_report, do_savePlots, session_path, segment_name)

% Parameters:
%   pos              - Position signal (e.g., wrist_to_origin_RH)
%   binary_signal    - Logical array indicating movement (e.g., binary_signal_RH)
%   t_cross_filtered - Timestamps of zero-crossings kept after filtering
%   filtered_dist    - Shoulder span signal
%   time             - Unix timestamp vector
%   cam_idx          - Camera index (for labeling)
%   label            - 'Right Hand' or 'Left Hand'
%   do_plot          - true/false: whether to generate plot
%   do_report        - true/false: whether to display summary in console
%   do_savePlots     - true/false: whether to save the plot

    timestamp = datetime(time, 'ConvertFrom', 'posixtime', 'TimeZone', 'Australia/Brisbane');
    tod = timeofday(timestamp);

    if do_plot || do_savePlots
        % Create figure (invisible if only saving)
        fig = figure('Visible', ternary(do_plot, 'on', 'off'));

        yyaxis left
        pos_range = max(pos) - min(pos);
        h1 = plot(tod, pos, 'b', 'DisplayName', 'Distance to Origin'); hold on;
        h2 = plot(tod, binary_signal * pos_range + min(pos), 'k', 'LineWidth', 0.5, 'DisplayName', 'Use Signal');
        t_cross_tod = timeofday(datetime(t_cross_filtered, 'ConvertFrom', 'posixtime', 'TimeZone', 'Australia/Brisbane'));
        h3 = plot(t_cross_tod, pos_cross_filtered, 'ro', 'DisplayName', 'Start/End Movs.');
        ylabel('Distance to Origin (pixels)');

        yyaxis right
        h4 = plot(tod, filtered_dist, 'LineWidth', 0.5, 'DisplayName', 'Shoulder Width');
        ylabel('Shoulder Width (pixels)');

        xlabel('Timestamp');
        title(['Camera ' num2str(cam_idx) ' - ' label]);
        grid on;
        legend([h1 h2 h3 h4], 'Location', 'best');

        % Save figure if requested
        if do_savePlots
            plot_folder = fullfile(session_path, segment_name, 'Plots', 'MovementDetection');
            if ~exist(plot_folder, 'dir')
                mkdir(plot_folder);
            end

            safe_label = strrep(label, ' ', '_');
            base_name = ['Camera' num2str(cam_idx) '_' safe_label];
            savefig(fig, fullfile(plot_folder, [base_name '.fig']));
            exportgraphics(fig, fullfile(plot_folder, [base_name '.png']), 'Resolution', 300);
        end
    end

    if do_report
        edges = diff([0; binary_signal(:); 0]);
        segment_starts = find(edges == 1);
        num_segments = numel(segment_starts);
        duration_minutes = minutes(tod(end) - tod(1));
        disp(['Camera ' num2str(cam_idx) ' - ' label ...
              ' - Number of movements: ' num2str(num_segments) ...
              ' in ' num2str(duration_minutes,3) ' minutes (' num2str(num_segments / duration_minutes,3) ' moves/min)']);
        % disp(['Camera ' num2str(cam_idx) ' - ' label ...
        %       ' - Number of movements: ' num2str(num_segments) ...
        %       ' | Movements per minute: ' num2str(num_segments / duration_minutes)]);
    end
end