% =========================================================================
% Title:          Save Viewer Asset Table
% Description:    Constructs and optionally saves a detailed signal table
%                 for a given camera file. Includes raw and filtered
%                 distances, velocities, and use signals for both RH and LH.
% Author:         Lucas R. L. Cardoso
% Project:        VRRehab_UQ-MyTurn
% Date:           2025-07-08
% Version:        1.0
% =========================================================================
% Usage:
%   T_out = save_viewer_asset_table( ...
%               time, ...
%               raw_wrist_to_origin_RH, wrist_to_origin_RH, ...
%               raw_wrist_to_shoulder_RH, wrist_to_shoulder_RH, ...
%               vel_wrist_to_origin_RH, binary_signal_RH, ...
%               raw_wrist_to_origin_LH, wrist_to_origin_LH, ...
%               raw_wrist_to_shoulder_LH, wrist_to_shoulder_LH, ...
%               vel_wrist_to_origin_LH, binary_signal_LH, ...
%               session_path, segment_name, file_name, save_csv)
%
% Dependencies:
%   - MATLAB R2023a or later
%
% Notes:
%   - Saves outputs to the 'ViewerAssets' folder within each segment directory.
%   - Output CSV contains time, distance, velocity, and use signal for RH and LH.
%   - Columns are labeled with a consistent naming convention.
%
% Changelog:
%   - v1.0: [2025-07-08] Initial implementation.
% =========================================================================

function T_out = save_viewer_asset_table( ...
    time, ...
    raw_wrist_to_origin_RH, wrist_to_origin_RH, raw_wrist_to_shoulder_RH, wrist_to_shoulder_RH, vel_wrist_to_origin_RH, binary_signal_RH, ...
    raw_wrist_to_origin_LH, wrist_to_origin_LH, raw_wrist_to_shoulder_LH, wrist_to_shoulder_LH, vel_wrist_to_origin_LH, binary_signal_LH, ...
    session_path, segment_name, file_name, save_csv)

% Parameters:
%   - time, signals: data vectors for both hands (RH and LH)
%   - session_path: base folder for the session
%   - segment_name: name of the segment (e.g., "CT_1")
%   - file_name: output CSV file name
%   - cam_idx: camera index (used for messages)
%   - save_csv: logical flag, whether to write the table to disk
%
% Returns:
%   - T_out: output table with all signal and binary columns

    % === Build output table ===
    T_out = table(time, ...
        raw_wrist_to_origin_RH, wrist_to_origin_RH, raw_wrist_to_shoulder_RH, wrist_to_shoulder_RH, vel_wrist_to_origin_RH, binary_signal_RH, ...
        raw_wrist_to_origin_LH, wrist_to_origin_LH, raw_wrist_to_shoulder_LH, wrist_to_shoulder_LH, vel_wrist_to_origin_LH, binary_signal_LH, ...
        'VariableNames', { ...
            'Time', ...
            'RH_Dist_to_Ori_raw', 'RH_Dist_to_Ori_filt', 'RH_Dist_to_Should_raw', 'RH_Dist_to_Should_filt', 'RH_Dist_to_Ori_vel', 'RH_Use_Signal', ...
            'LH_Dist_to_Ori_raw', 'LH_Dist_to_Ori_filt', 'LH_Dist_to_Should_raw', 'LH_Dist_to_Should_filt', 'LH_Dist_to_Ori_vel', 'LH_Use_Signal' ...
        });

    % === Optionally save to CSV ===
    if save_csv
        output_path = fullfile(session_path, segment_name, 'ViewerAssets', file_name);
        output_folder = fileparts(output_path);

        if ~exist(output_folder, 'dir')
            mkdir(output_folder);
        end

        writetable(T_out, output_path);
    end
end
