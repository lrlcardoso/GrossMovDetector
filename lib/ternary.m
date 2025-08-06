% =========================================================================
% Title:          Ternary Operator (Utility Function)
% Description:    Mimics the behavior of a ternary conditional operator.
%                 Returns `valTrue` if `cond` is true, otherwise returns `valFalse`.
% Author:         Lucas R. L. Cardoso
% Project:        VRRehab_UQ-MyTurn
% Date:           2025-07-08
% Version:        1.0
% =========================================================================
% Usage:
%   result = ternary(condition, value_if_true, value_if_false)
%
% Dependencies:
%   - None
%
% Notes:
%   - This function is useful in expressions or plot configuration where
%     inline conditional logic is preferred.
%
% Changelog:
%   - v1.0: [2025-07-08] Initial implementation.
% =========================================================================

function out = ternary(cond, valTrue, valFalse)
    if cond
        out = valTrue;
    else
        out = valFalse;
    end
end