%-% This function displays shadows behind opponents, which are the areas where the players should not move.

function matrix = GraphShadowsStatic(TeamOppSave, CurrentPlayer, displayOutput, radiusMultiplier)
global FUN Score
global Environment Team M FieldX FieldY



%-%Calculate a matrix of coordinates that represent good passing spots.
matrix = zeros(FieldY,FieldX);

ecks = [];
eck = 1:FieldX;
for n = 1:FieldY-1
  ecks = [ecks;eck];
end

why = [];
wh = (1:FieldY-1)';
for n = 1:FieldX
  why = [why wh];
end

b = 30*radiusMultiplier; %-% The radius of the semicircle in the Cartesian plane.

for inc = 1:M
  px = TeamOppSave{inc}.Pos(1);
  py = TeamOppSave{inc}.Pos(2);

  multiplier = 1/b^2;

  %-%distance = FUN.DistanceToLine2(ecks,why,bx,by,px,py,true);
  %-%distance = sqrt((ecks-px).^2 + (why-py).^2);
  distance = FUN.DistanceToLine2(ecks,why,TeamOppSave{CurrentPlayer}.Pos(1),TeamOppSave{CurrentPlayer}.Pos(2),px,py,true);
  %resultMatrix{inc} = b > distance;
  resultMatrix{inc} = max(1 - multiplier.*distance.^2,0.0);
end


if CurrentPlayer == 1
  resultMatrix2 = 1-resultMatrix{2};
elseif CurrentPlayer == 2
  resultMatrix2 = 1-resultMatrix{1};
else
  resultMatrix2 = (1-resultMatrix{1}).*(1-resultMatrix{2});
end

for ink = 3:M
  if ink ~= CurrentPlayer
    resultMatrix2 = resultMatrix2.*(1-resultMatrix{ink});
  end
end

if (displayOutput)
  figure(5);
  imshow(flipud(resultMatrix2));
end
matrix = resultMatrix2;


% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
