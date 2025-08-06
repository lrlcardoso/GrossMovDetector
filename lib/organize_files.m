% =========================================================================
% Title:          Organize Plot Files into Synchronization Folder
% Description:    Moves all files (excluding folders) from the 'Plots'
%                 directory into a subfolder named 'Synchronization' for
%                 a given patient/session/segment structure.
% Author:         Lucas R. L. Cardoso
% Project:        VRRehab_UQ-MyTurn
% Date:           2025-07-08
% Version:        1.0
% =========================================================================
% Usage:
%   Adjust the user input section to define:
%     - ROOT_DIR: base path to the data directory
%     - patient: patient folder name (e.g., "P01")
%     - session_prefix: prefix of the session folder (e.g., "Session3")
%     - segment: leave empty "" to run on all segments
%
% Dependencies:
%   - MATLAB R2023a or later
%
% Notes:
%   - Will create 'Synchronization' folder inside each segment's 'Plots' folder.
%   - Skips segments where no 'Plots' folder is found.
%   - Moves only files (not subfolders).
%
% Changelog:
%   - v1.0: [2025-07-08] Initial implementation.
% =========================================================================

clc;
clear;

% ========== USER INPUT ==========
ROOT_DIR = "C:\Users\s4659771\Documents\MyTurn_Project\Data\ReadyToAnalyse";
patient = "P10";
session_prefix = "Session3";
segment = "";  % Leave empty "" to run for all segments
% =================================

% Build full path to patient directory
patient_dir = fullfile(ROOT_DIR, patient);

% Find the session folder that starts with the given prefix
session_folders = dir(patient_dir);
session_folders = session_folders([session_folders.isdir]);
session_match = startsWith({session_folders.name}, session_prefix);

if ~any(session_match)
    error("❌ No session folder found starting with '%s'", session_prefix);
end

session_folder = session_folders(find(session_match, 1)).name;
session_path = fullfile(patient_dir, session_folder);

% Determine which segments to process
if segment == ""
    segment_folders = dir(session_path);
    segment_folders = segment_folders([segment_folders.isdir] & ~startsWith({segment_folders.name}, '.'));
    segments = {segment_folders.name};
else
    segments = {segment};
end

% Process each segment
for i = 1:numel(segments)
    seg = segments{i};
    plots_path = fullfile(session_path, seg, "Plots");

    if ~isfolder(plots_path)
        fprintf("⚠️ Skipping: Plots folder not found for segment '%s'\n", seg);
        continue;
    end

    % Create Synchronization folder if it doesn't exist
    sync_path = fullfile(plots_path, "Synchronization");
    if ~isfolder(sync_path)
        mkdir(sync_path);
    end

    % Move files from Plots to Synchronization (excluding folders)
    all_items = dir(plots_path);
    is_file = ~[all_items.isdir];

    moved_any = false;
    for j = 1:length(all_items)
        if is_file(j)
            src = fullfile(plots_path, all_items(j).name);
            dest = fullfile(sync_path, all_items(j).name);
            movefile(src, dest);
            fprintf("✅ [%s] Moved: %s\n", seg, all_items(j).name);
            moved_any = true;
        end
    end

    if ~moved_any
        fprintf("ℹ️ [%s] No files to move.\n", seg);
    else
        fprintf("🎉 [%s] All files moved to 'Synchronization'.\n", seg);
    end
end
