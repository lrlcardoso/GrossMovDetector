% =========================================================================
% Title:          Save Combined Use Signal
% Description:    Merges RH and LH use signals across time, aligning them
%                 into a unified table and optionally exporting the result
%                 to a CSV file for further analysis or visualization.
% Author:         Lucas R. L. Cardoso
% Project:        VRRehab_UQ-MyTurn
% Date:           2025-07-08
% Version:        1.0
% =========================================================================
% Usage:
%   T_out = save_combined_use_signal(T_combined_RH, T_combined_LH, ...
%                                    session_path, segment_name, save_csv)
%
% Dependencies:
%   - MATLAB R2023a or later
%
% Notes:
%   - Aligns RH and LH signals using the union of time vectors.
%   - NaNs are assigned to missing values during alignment.
%   - Outputs a table with columns: Time, RH, LH.
%   - CSV is saved to the segment folder if `save_csv` is true.
%
% Changelog:
%   - v1.0: [2025-07-08] Initial implementation.
% =========================================================================

function T_out = save_combined_use_signal(T_combined_RH, T_combined_LH, session_path, segment_name, save_csv)

% Parameters:
%   - time: time vector (Unix timestamp)
%   - T_combined_RH: logical vector of combined RH_Use_Signal
%   - T_combined_LH: logical vector of combined LH_Use_Signal
%   - session_path: base session directory
%   - segment_name: segment folder name (e.g., 'CT_1')
%   - save_csv: true/false flag to control file writing
%
% Returns:
%   - T_out: table with time, RH_Use_Signal, and LH_Use_Signal

    % === Create output table ===
    % === Compute union of time vectors ===
    all_time = union(T_combined_RH.Time, T_combined_LH.Time);
    
    % === Initialize empty signal columns ===
    RH_signal = nan(size(all_time));
    LH_signal = nan(size(all_time));
    
    % === Fill values from RH ===
    [~, idx_all, idx_rh] = intersect(all_time, T_combined_RH.Time);
    RH_signal(idx_all) = T_combined_RH.RH_Use_Signal(idx_rh);
    
    % === Fill values from LH ===
    [~, idx_all, idx_lh] = intersect(all_time, T_combined_LH.Time);
    LH_signal(idx_all) = T_combined_LH.LH_Use_Signal(idx_lh);
    
    % === Build combined table ===
    T_out = table(all_time, RH_signal, LH_signal, ...
        'VariableNames', {'Time', 'RH', 'LH'});


    % === Optionally save to CSV ===
    if save_csv
        % Define output file path
        output_path = fullfile(session_path, segment_name, 'UseSignal.csv');
        output_folder = fileparts(output_path);

        % Ensure output folder exists
        if ~exist(output_folder, 'dir')
            mkdir(output_folder);
        end

        % Write table to CSV
        writetable(T_out, output_path);

    end
end