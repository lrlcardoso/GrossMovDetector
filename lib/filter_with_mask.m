% =========================================================================
% Title:          Filter with NaN Masking
% Description:    Applies zero-phase filtering (filtfilt) to the valid
%                 (non-NaN) portion of a signal while preserving NaNs in the
%                 output. Useful for handling discontinuous marker data.
% Author:         Lucas R. L. Cardoso
% Project:        VRRehab_UQ-MyTurn
% Date:           2025-07-08
% Version:        1.0
% =========================================================================
% Usage:
%   filtered = filter_with_mask(signal, b, a)
%
% Dependencies:
%   - MATLAB R2023a or later
%   - Signal Processing Toolbox (for filtfilt)
%
% Notes:
%   - Returns NaNs in the same locations as the input.
%   - Skips filtering if fewer than 7 valid points are found.
%   - Issues a warning if filtering fails (e.g., due to instability).
%
% Changelog:
%   - v1.0: [2025-07-08] Initial implementation.
% =========================================================================

function filtered = filter_with_mask(signal, b, a)

    % Initialize output as NaNs (same size as input)
    filtered = nan(size(signal));

    % Find indices of valid (non-NaN) values
    valid_idx = find(~isnan(signal));

    % Apply filter only if enough valid samples exist
    if numel(valid_idx) > 6  % filtfilt requires a few data points
        try
            % Apply zero-phase filtering to the valid portion
            filtered(valid_idx) = filtfilt(b, a, signal(valid_idx));
        catch
            % Catch errors (e.g., badly conditioned filter) and issue a warning
            warning("Filtering failed for a segment — possibly due to insufficient or unstable data.");
        end
    end
end