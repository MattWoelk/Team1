function lowestPlayer = ClosestToNet(M,TeamOwnSave,FieldY,NotThisOne)

%-% Choose who will be goalie (not including NotThisOne)
%-% This is done by determining which player is closest to the center of our goal.

%-% If no current goalie is specified, all players are considered.
if ~exist('NotThisOne', 'var')
  NotThisOne = -1;
end

distanceFromNet = @(x,y) sqrt((x - 0).^2 + (y - FieldY/2).^2);
lowestValue = 999; %-% Arbitrarily high

if NotThisOne ~= 1
  lowestValue = distanceFromNet(TeamOwnSave{1}.Pos(1),TeamOwnSave{1}.Pos(2));
  lowestPlayer = 1;
end
for inc = 2:M
  if distanceFromNet(TeamOwnSave{inc}.Pos(1),TeamOwnSave{inc}.Pos(2)) < lowestValue && inc ~= NotThisOne
    lowestPlayer = inc;
  end
end

% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
