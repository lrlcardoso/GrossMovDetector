% =========================================================================
% Title:          Detect Movement Events
% Description:    Identifies valid movement segments based on velocity
%                 zero-crossings, position thresholds relative to shoulder
%                 distance, and segment quality checks (e.g., length and NaNs).
% Author:         Lucas R. L. Cardoso
% Project:        VRRehab_UQ-MyTurn
% Date:           2025-07-08
% Version:        1.0
% =========================================================================
% Usage:
%   [binary_signal, pos_cross_filtered, t_cross_filtered] = ...
%       detect_movement(pos, vel, filtered_dist, time, ...
%                       shoulder_ratio, max_allowed_gap, ...
%                       too_fast, too_slow)
%
% Dependencies:
%   - MATLAB R2023a or later
%
% Notes:
%   - Movement is detected between filtered velocity zero-crossings
%     that exceed a threshold based on shoulder distance.
%   - Final signal is cleaned by removing segments that are too short,
%     too long, or contain too many consecutive NaNs.
%
% Changelog:
%   - v1.0: [2025-07-08] Initial implementation.
% =========================================================================

function [binary_signal, pos_cross_filtered, t_cross_filtered] = detect_movement(pos, vel, filtered_dist, time, shoulder_ratio, max_allowed_gap, too_fast, too_slow)
    % === Step 1: Detect velocity zero-crossings ===
    zero_crossings_idx = find(vel(1:end-1) .* vel(2:end) < 0);

    % === Step 2: Filter zero-crossings by neighbor distance ===
    keep_mask = false(size(zero_crossings_idx));
    for i = 1:length(zero_crossings_idx)
        curr_idx = zero_crossings_idx(i);
        curr_pos = pos(curr_idx);
        threshold = filtered_dist(curr_idx) * shoulder_ratio;
        keep = false;

        if i > 1
            prev_pos = pos(zero_crossings_idx(i - 1));
            if abs(curr_pos - prev_pos) >= threshold
                keep = true;
            end
        end
        if i < length(zero_crossings_idx)
            next_pos = pos(zero_crossings_idx(i + 1));
            if abs(curr_pos - next_pos) >= threshold
                keep = true;
            end
        end
        keep_mask(i) = keep;
    end

    % === Step 3: Build binary signal from filtered crossings ===
    filtered_idx = zero_crossings_idx(keep_mask);
    t_cross_filtered = time(filtered_idx);
    pos_cross_filtered = pos(filtered_idx);
    binary_signal = zeros(size(time));

    for i = 1:length(pos_cross_filtered) - 1
        curr_time = t_cross_filtered(i);
        next_time = t_cross_filtered(i + 1);
        curr_pos = pos_cross_filtered(i);
        next_pos = pos_cross_filtered(i + 1);
        threshold = filtered_dist(filtered_idx(i)) * shoulder_ratio;
    
        if i == 1
            binary_signal(time >= curr_time & time < next_time) = 1;
            continue;
        end
    
        if abs(next_pos - curr_pos) < threshold
            mid_time = next_time;
            binary_signal(time >= curr_time & time < mid_time) = 0;
    
            % Only proceed if i + 2 does not exceed bounds
            if i + 2 <= length(t_cross_filtered)
                binary_signal(time >= mid_time & time < t_cross_filtered(i + 2)) = 1;
            end
        else
            idx_current = find(time >= curr_time, 1, 'first');
            idx_next = find(time < next_time, 1, 'last');
            if ~isempty(idx_current) && ~isempty(idx_next)
                binary_signal(idx_current) = 0;
                binary_signal(idx_current + 1:idx_next) = 1;
            end
        end
    end

    % === Step 4: Quality control and filtering ===
    binary_signal_qc = binary_signal;

    % Identify start and end indices of 1-segments
    diff_bin = [0; diff(binary_signal_qc)];
    start_idx = find(diff_bin == 1);
    end_idx = find(diff_bin == -1) - 1;

    % Handle edge case: signal ends with 1
    if binary_signal_qc(end) == 1
        end_idx(end + 1) = length(binary_signal_qc);
    end

    % Mark invalid segments
    valid_segments = true(size(start_idx));
    for i = 1:length(start_idx)
        s = start_idx(i);
        e = end_idx(i);
        segment_pos = pos(s:e);
        segment_len = e - s + 1;

        % Rule 1: Too many consecutive NaNs
        nan_streak = movsum(isnan(segment_pos), [max_allowed_gap - 1, 0]) >= max_allowed_gap;
        if any(nan_streak)
            valid_segments(i) = false;
            continue;
        end

        % Rule 2: Duration too short or too long
        if segment_len <= too_fast || segment_len >= too_slow
            valid_segments(i) = false;
        end
    end

    % Remove invalid segments
    for i = find(~valid_segments)'
        binary_signal_qc(start_idx(i):end_idx(i)) = 0;
    end

    % Final cleaned binary signal
    binary_signal = logical(binary_signal_qc);
end