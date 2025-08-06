% =========================================================================
% Title:          Combine Use Signal (Multi-Camera Merge)
% Description:    Merges use signals (RH or LH) from multiple camera views
%                 into a unified binary signal. Selects the base camera with
%                 the most detected movements and fills missing data using
%                 secondary views. Filters segments by duration and
%                 optionally plots and saves the result.
% Author:         Lucas R. L. Cardoso
% Project:        VRRehab_UQ-MyTurn
% Date:           2025-07-08
% Version:        1.0
% =========================================================================
% Usage:
%   T_combined = combine_use_signal(T_out, cameras, hand_prefix, ...
%                                   too_fast, too_slow, ...
%                                   show_plot, show_report, save_plot, ...
%                                   session_path, segment_name)
%
% Dependencies:
%   - MATLAB R2023a or later
%   - Helper function: ternary
%
% Notes:
%   - Assumes all input tables in T_out share the same time base.
%   - Movement segments shorter than `too_fast` or longer than `too_slow`
%     are discarded.
%   - Plots are saved to the MovementDetection folder if enabled.
%
% Changelog:
%   - v1.0: [2025-07-08] Initial implementation.
% =========================================================================

function T_combined = combine_use_signal(T_out, cameras, hand_prefix, too_fast, too_slow, show_plot, show_report, save_plot, session_path, segment_name)
% Parameters:
%   - T_out: cell array of camera tables
%   - hand_prefix: 'RH' or 'LH'
%   - too_fast: min allowed segment length (in frames)
%   - too_slow: max allowed segment length (in frames)
%   - show_plot: logical, whether to generate a debug plot
%   - show_report: logical, whether to print a summary report
%
% Returns:
%   - T_combined: output table with merged and cleaned <prefix>_Use_Signal

    use_col      = [hand_prefix '_Use_Signal'];
    dist_filt_col = [hand_prefix '_Dist_to_Ori_filt'];
    dist_raw_col  = [hand_prefix '_Dist_to_Ori_raw'];

    if numel(cameras) == 1
        T_combined = T_out{1};
        best_cam_idx=1;
    else
        % --- Step 1: Choose best base camera by most detected movement segments
        num_segments = arrayfun(@(i) ...
            sum(diff([0; logical(T_out{i}.(use_col)); 0]) == 1), 1:numel(T_out));
        [~, best_cam_idx] = max(num_segments);

        T_base = T_out{best_cam_idx};
        combined_signal = T_base.(use_col);
        nan_idx = isnan(T_base.(dist_filt_col));

        % --- Step 2: Fill NaN gaps using other cameras
        for i = 1:numel(T_out)
            if i == best_cam_idx
                continue;
            end
        
            % Match rows based on shared time values
            [~, idx_base, idx_other] = intersect(T_base.Time, T_out{i}.Time);
        
            % Get valid indices in other camera
            other_valid = ~isnan(T_out{i}.(dist_filt_col)(idx_other));
        
            % Fill NaNs only where both time and validity match
            valid_to_fill = nan_idx(idx_base) & other_valid;
            combined_signal(idx_base(valid_to_fill)) = T_out{i}.(use_col)(idx_other(valid_to_fill));
        end


        % --- Step 3: Remove segments that are too short or too long
        binary_signal = logical(combined_signal);

        diff_bin = [0; diff(binary_signal)];
        start_idx = find(diff_bin == 1);
        end_idx = find(diff_bin == -1) - 1;

        if binary_signal(end) == 1
            end_idx(end+1) = length(binary_signal);
        end

        for j = 1:length(start_idx)
            seg_len = end_idx(j) - start_idx(j) + 1;
            if seg_len <= too_fast || seg_len >= too_slow
                binary_signal(start_idx(j):end_idx(j)) = 0;
            end
        end

        % Assign final signal
        T_combined = T_base;
        T_combined.(use_col) = binary_signal;
    end

    % --- Optional: Plot, Report and Save ---
    if show_plot || show_report || save_plot
        % Convert time for plotting and reporting
        timestamp = datetime(T_combined.Time, 'ConvertFrom', 'posixtime', 'TimeZone', 'Australia/Brisbane');
        tod = timeofday(timestamp);
        duration_of_session = minutes(tod(end) - tod(1));
        binary_signal = T_combined.(use_col);
    end
    
    % === Plotting and Saving ===
    if show_plot || save_plot
        % Create figure (invisible if saving only)
        fig = figure('Visible', ternary(show_plot, 'on', 'off'));
    
        % Scale and plot
        raw_signal = T_combined.(dist_raw_col);
        signal_range = max(raw_signal) - min(raw_signal);
    
        plot(tod, raw_signal, 'b', 'DisplayName', 'Distance to Origin'); hold on;
        plot(tod, binary_signal * signal_range + min(raw_signal), 'k--', ...
             'LineWidth', 0.5, 'DisplayName', 'Use Signal');
    
        ylabel('Distance to Origin (pixels)');
        xlabel('Timestamp');
        title(['Combined (Base: Camera ' num2str(cameras(best_cam_idx)) ') - ' hand_prefix]);
        legend('Location', 'best');
        grid on;
    
        % Save plot if requested
        if save_plot
            plot_folder = fullfile(session_path, segment_name, 'Plots', 'MovementDetection');
            if ~exist(plot_folder, 'dir')
                mkdir(plot_folder);
            end
    
            base_name = ['Combined_Cameras(Base_Camera' num2str(cameras(best_cam_idx)) ')-' hand_prefix];
            savefig(fig, fullfile(plot_folder, [base_name '.fig']));
            exportgraphics(fig, fullfile(plot_folder, [base_name '.png']), 'Resolution', 300);
        end
    end
    
    % === Reporting ===
    if show_report
        edges = diff([0; binary_signal(:); 0]);
        segment_starts = find(edges == 1);
        num_segments = numel(segment_starts);
        disp(['Combined (Base: Camera ' num2str(cameras(best_cam_idx)) ') - ' hand_prefix ...
              ' - Number of movements: ' num2str(num_segments) ...
              '  in ' num2str(duration_of_session,3) ' minutes (' num2str(num_segments / duration_of_session,3) ' moves/min)']);
        % disp(['Combined (Base: Camera ' num2str(cameras(best_cam_idx)) ') - ' hand_prefix ...
        %       ' - Movements: ' num2str(num_segments) ...
        %       ' | Per minute: ' num2str(num_segments / duration_of_session)]);
    end

end