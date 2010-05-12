%=% This function maps a deadzone into the opponents goal so that we don't accidentally block shots on their goal.
%=% The matrix returned from this function should be multiplied by the matrix used to choose player's destination.

function matrix = GraphDontCamp()

global FUN Score
global Environment Team M FieldX FieldY

matrix = zeros(FieldY,FieldX);

distFromYAxis = repmat([1:FieldX], FieldY-1, 1);
distFromXAxis = repmat([1:FieldY-1]', 1, FieldX);

distToMidOppGoal = sqrt((distFromYAxis - FieldX).^2 + (distFromXAxis - FieldY/2).^2);
matrix = min(ones(size(distToMidOppGoal)), distToMidOppGoal/10.0);

% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
