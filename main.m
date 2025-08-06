% =========================================================================
% Title:          Movement Detection Pipeline (Main Script)
% Description:    Processes synchronized video marker data for multiple
%                 patients, sessions, and segments. Detects hand movement
%                 events from wrist-to-origin signals using velocity and
%                 shoulder distance as adaptive thresholds.
% Author:         Lucas R. L. Cardoso
% Project:        VRRehab_UQ-MyTurn
% Date:           2025-07-08
% Version:        1.0
% =========================================================================
% Usage:
%   Run `main.m` from MATLAB. Adjust patient/session/segment settings at the
%   top of the script before execution.
%
% Dependencies:
%   - MATLAB R2023a or later
%   - Custom functions in ./lib:
%       - filter_with_mask
%       - detect_movement
%       - plot_and_report
%       - save_viewer_asset_table
%       - combine_use_signal
%       - save_combined_use_signal
%
% Notes:
%   - If SELECTED_SEGMENTS is empty, all segments in the session folder
%     will be processed.
%   - Saves filtered data, use signals, and plots if SAVE_* flags are enabled.
%
% Changelog:
%   - v1.0: [2025-07-08] Initial implementation.
% =========================================================================

addpath('./lib');
clc;
clear;
close all;

% =========================================================================
% Configuration Parameters
% =========================================================================
fs = 30;                    % Sampling frequency (Hz)
order = 2;                  % Filter order
cutoff = 5;                 % Low-pass filter cutoff (Hz)
cutoff_shoulder_dist = 0.05; % Shoulder distance filter cutoff (Hz)
shoulder_ratio = 0.2;       % Ratio to define valid movement threshold
max_allowed_gap = fs * 0.2; % Max allowed consecutive NaNs in movement
too_fast = fs * 0.1;        % Minimum movement duration (in frames)
too_slow = fs * 3;          % Maximum movement duration (in frames)

% Flags for visualization and saving
SHOW_PLOTS   = true;
SHOW_REPORTS = false;
SAVE_PLOTS   = false;
SAVE_CSV     = false;

% =========================================================================
% Target Paths and Segments
% =========================================================================
ROOT_DIR = "C:\Users\s4659771\Documents\MyTurn_Project\Data\ReadyToAnalyse";
SELECTED_PATIENTS = ["P02"];
SELECTED_SESSIONS = ["Session3"];
SELECTED_SEGMENTS = ["Beat Saber_3"];

% =========================================================================
% Main Loop: Process Each Patient/Session/Segment
% ========================================================================= 
for p = 1:numel(SELECTED_PATIENTS)
    fprintf("\nProcessing Patient: %s\n", SELECTED_PATIENTS(p));
    patient_dir = fullfile(ROOT_DIR, SELECTED_PATIENTS(p));

    % Get matching sessions in this patient folder
    session_folders = dir(patient_dir);
    session_folders = session_folders([session_folders.isdir]);

    for s = 1:numel(SELECTED_SESSIONS)
        % Find session folder starting with the session prefix
        matching_sessions = session_folders(startsWith({session_folders.name}, SELECTED_SESSIONS(s)));

        for ms = 1:numel(matching_sessions)
            fprintf("Session: %s\n", matching_sessions(ms).name);
            session_path = fullfile(patient_dir, matching_sessions(ms).name);

            % === Get segment folders ===
            if isempty(SELECTED_SEGMENTS)
                all_segments = dir(session_path);
                all_segments = all_segments([all_segments.isdir] & ~startsWith({all_segments.name}, '.'));
                segment_names = {all_segments.name};
            else
                segment_names = cellstr(SELECTED_SEGMENTS);  % Ensure it’s a cell array of strings
            end

            for seg = 1:numel(segment_names)
                fprintf("\nSegment: %s\n", segment_names{seg});
                segment_dir = fullfile(session_path, segment_names{seg});
                camera_files = dir(fullfile(segment_dir, "Camera*.csv"));
                cameras = [];

                plot_folder = fullfile(session_path, segment_names{seg}, 'Plots', 'MovementDetection');

                % If folder exists, clean it; otherwise, create it
                if exist(plot_folder, 'dir')
                    delete(fullfile(plot_folder, '*'));  % Delete all files in the folder
                else
                    mkdir(plot_folder);
                end
                
                for cam_idx = 1:numel(camera_files)
                    file_name = camera_files(cam_idx).name;
                    cam_number = regexp(file_name, '\d+', 'match');
                    cam_number = str2double(cam_number{1});
                    full_path = fullfile(segment_dir, file_name);
                
                    % Load data and extract time vector
                    T = readtable(full_path, 'VariableNamingRule', 'preserve');
                    time = T{:, "Unix Time"};
                
                    % Extract marker positions
                    x_wrist_RH     = T{:, '11_x'};
                    y_wrist_RH     = T{:, '11_y'};
                    x_shoulder_RH  = T{:, '7_x'};
                    y_shoulder_RH  = T{:, '7_y'};
                    x_wrist_LH     = T{:, '10_x'};
                    y_wrist_LH     = T{:, '10_y'};
                    x_shoulder_LH  = T{:, '6_x'};
                    y_shoulder_LH  = T{:, '6_y'};
                    % x_midpoint_chest = (x_shoulder_LH + x_shoulder_RH) / 2;
                    % y_midpoint_chest = (y_shoulder_LH + y_shoulder_RH) / 2;
                
                    % Compute Euclidean distances
                    shoulders_dist           = sqrt((x_shoulder_RH - x_shoulder_LH).^2 + (y_shoulder_RH - y_shoulder_LH).^2);
                    wrist_to_origin_RH       = sqrt(x_wrist_RH.^2 + y_wrist_RH.^2);
                    wrist_to_origin_LH       = sqrt(x_wrist_LH.^2 + y_wrist_LH.^2); 
                    wrist_to_shoulder_RH     = sqrt((x_wrist_RH - x_shoulder_RH).^2 + (y_wrist_RH - y_shoulder_RH).^2);
                    wrist_to_shoulder_LH     = sqrt((x_wrist_LH - x_shoulder_LH).^2 + (y_wrist_LH - y_shoulder_LH).^2);
                    % wrist_to_mid_RH        = sqrt((x_wrist_RH - x_midpoint_chest).^2 + (y_wrist_RH - y_midpoint_chest).^2);
                    % wrist_to_mid_LH        = sqrt((x_wrist_LH - x_midpoint_chest).^2 + (y_wrist_LH - y_midpoint_chest).^2);
                
                    % Store raw distances before filtering
                    raw_wrist_to_origin_RH    = wrist_to_origin_RH;
                    raw_wrist_to_origin_LH    = wrist_to_origin_LH;
                    raw_wrist_to_shoulder_RH  = wrist_to_shoulder_RH;
                    raw_wrist_to_shoulder_LH  = wrist_to_shoulder_LH;
                    % raw_wrist_to_mid_RH     = wrist_to_mid_RH;
                    % raw_wrist_to_mid_LH     = wrist_to_mid_LH;
                
                    % Apply low-pass filter to distance signals
                    [b, a] = butter(order, cutoff / (fs / 2), 'low');
                    filter_signal = @(sig) filter_with_mask(sig, b, a);
                
                    wrist_to_origin_RH    = filter_signal(wrist_to_origin_RH);
                    wrist_to_origin_LH    = filter_signal(wrist_to_origin_LH);
                    wrist_to_shoulder_RH  = filter_signal(wrist_to_shoulder_RH);
                    wrist_to_shoulder_LH  = filter_signal(wrist_to_shoulder_LH);
                    % wrist_to_mid_RH     = filter_signal(wrist_to_mid_RH);
                    % wrist_to_mid_LH     = filter_signal(wrist_to_mid_LH);
                
                    % Compute velocity from filtered wrist-to-origin signals
                    dt = diff(time);
                    vel_wrist_to_origin_RH = [0; diff(wrist_to_origin_RH) ./ dt];
                    vel_wrist_to_origin_LH = [0; diff(wrist_to_origin_LH) ./ dt];
                
                    % Smooth and interpolate shoulder distance signal (used as dynamic threshold)
                    [b, a] = butter(order, cutoff_shoulder_dist / (fs / 2), 'low');
                    valid_idx = ~isnan(shoulders_dist);
                    filtered_dist = nan(size(shoulders_dist));
                    if sum(valid_idx) > 6
                        filtered_dist(valid_idx) = filtfilt(b, a, shoulders_dist(valid_idx));
                    end
                    if any(isnan(filtered_dist))
                        x = find(~isnan(filtered_dist));
                        v = filtered_dist(x);
                        xi = 1:length(filtered_dist);
                        filtered_dist = interp1(x, v, xi, 'linear', 'extrap');
                    end
                
                    % === Detect Movement Events ===
                    [binary_signal_RH, pos_cross_filtered_RH, t_cross_filtered_RH] = ...
                        detect_movement(wrist_to_origin_RH, vel_wrist_to_origin_RH, filtered_dist, time, ...
                                        shoulder_ratio, max_allowed_gap, too_fast, too_slow);

                    plot_and_report(wrist_to_origin_RH, binary_signal_RH, t_cross_filtered_RH, pos_cross_filtered_RH, ...
                                    filtered_dist, time, cam_number, 'RH', SHOW_PLOTS, SHOW_REPORTS, SAVE_PLOTS, session_path, segment_names{seg});

                    [binary_signal_LH, pos_cross_filtered_LH, t_cross_filtered_LH] = ...
                        detect_movement(wrist_to_origin_LH, vel_wrist_to_origin_LH, filtered_dist, time, ...
                                        shoulder_ratio, max_allowed_gap, too_fast, too_slow);

                    plot_and_report(wrist_to_origin_LH, binary_signal_LH, t_cross_filtered_LH, pos_cross_filtered_LH, ...
                                    filtered_dist, time, cam_number, 'LH', SHOW_PLOTS, SHOW_REPORTS, SAVE_PLOTS, session_path, segment_names{seg});

                    % === Save Signal Table ===
                    T_out{cam_idx} = save_viewer_asset_table( ...
                        time, ...
                        raw_wrist_to_origin_RH, wrist_to_origin_RH, raw_wrist_to_shoulder_RH, wrist_to_shoulder_RH, vel_wrist_to_origin_RH, binary_signal_RH, ...
                        raw_wrist_to_origin_LH, wrist_to_origin_LH, raw_wrist_to_shoulder_LH, wrist_to_shoulder_LH, vel_wrist_to_origin_LH, binary_signal_LH, ...
                        session_path, segment_names{seg}, file_name, SAVE_CSV);

                    cameras = [cameras; cam_number];
                end

                % === Combine and Save Use Signals ===
                T_combined_RH = combine_use_signal(T_out, cameras, 'RH', too_fast, too_slow, SHOW_PLOTS, SHOW_REPORTS, SAVE_PLOTS, session_path, segment_names{seg});
                T_combined_LH = combine_use_signal(T_out, cameras, 'LH', too_fast, too_slow, SHOW_PLOTS, SHOW_REPORTS, SAVE_PLOTS, session_path, segment_names{seg});

                % T_combined = save_combined_use_signal(T_combined_RH.Time, T_combined_RH.RH_Use_Signal, T_combined_LH.LH_Use_Signal, session_path, segment_names{seg}, SAVE_CSV);
                T_combined = save_combined_use_signal(T_combined_RH, T_combined_LH, session_path, segment_names{seg}, SAVE_CSV);

            end
        end
    end
end