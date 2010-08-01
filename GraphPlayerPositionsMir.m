function matrix = GraphPlayerPositionsMir(PlayerPositions, Pos, displayOutput, radiusMultiplier, ignorePlayer)

%-% This function graphs a field where its values are dependent on the players' positions.
%-% It takes into account rebounds when calculating where to kick.
%-% It also runs very slowly

global FUN Environment Team M FieldX FieldY qDamp

ELLIPSEcircle = false; %-% Ellipse mode is not yet working properly.

matrix = ones(FieldY*3,FieldX)*0.5;

bx = Pos(1);
by = Pos(2) + FieldY;

point2 = []; %-% This is the point with b distance from the opponent's position, between the opponent and the goal. It is one of the two focal points of the ellipse. (The other is the opponent's position)
             %-% It is only used for Ellipse mode.

ecks = [];
%eck = (1:FieldX/3)*3;
%for n = 1:FieldY/3-1
eck = 1:FieldX;
for n = 1:FieldY*3-1
  ecks = [ecks;eck];
end

why = [];
%wh = ((1:FieldY/3-1)*3)';
%for n = 1:FieldX/3
wh = (1:FieldY*3-1)';
for n = 1:FieldX
  why = [why wh];
end

ignoreNumbers = zeros(M*3);
if ignorePlayer > 0
  ignoreNumbers((ignorePlayer-1)*3 + 1) = 1;
  ignoreNumbers((ignorePlayer-1)*3 + 2) = 1;
  ignoreNumbers((ignorePlayer-1)*3 + 3) = 1;
end

howbig = size(PlayerPositions);
%-% set up doubles of the players:
for i = 1:howbig(2)
  if ~isempty(PlayerPositions{i})
    positions{(i-1)*3+1}(1) = PlayerPositions{i}(1);
    positions{(i-1)*3+1}(2) = PlayerPositions{i}(2) + FieldY;
    positions{(i-1)*3+2}(1) = PlayerPositions{i}(1);
    positions{(i-1)*3+2}(2) = FieldY - PlayerPositions{i}(2) + FieldY + FieldY;
    positions{(i-1)*3+3}(1) = PlayerPositions{i}(1);
    positions{(i-1)*3+3}(2) = FieldY - PlayerPositions{i}(2) - FieldY + FieldY;
  end
end

sizeofpos = size(positions);

%-% For our team:
for inc = 1:sizeofpos(2)
  if ~ignoreNumbers(inc) && ~isempty(positions{inc})
    px = positions{inc}(1);
    py = positions{inc}(2);

    r = 0.25*radiusMultiplier;
    k = FUN.Distance([bx,by],[px,py]);
    b = k.*sin(r);

    doubleradius = sqrt((ecks - px).^2 + (why - py).^2);
    multiplier = 1/b^2;
    if ELLIPSEcircle
      slope = (FieldY-by)/(FieldX/2-bx);
      i = b/sqrt(slope^2 + 1);
      j = i*slope;
      %abovenet = (py > FieldY/2)*2 - 1; %-% -1 if below the net, 1 if above
      point2 = [px-abovenet*i,py-abovenet*j];
      %point2 = [px-i,py-j];
      doubleradius = doubleradius + sqrt((ecks - point2(1)).^2 + (why - point2(2)).^2);
      multiplier = multiplier.*0.1
    end
    resultMatrix{inc} = max(1 - multiplier.*doubleradius.^2,0.0);
  else
    resultMatrix{inc} = [];
  end
end

resultMatrix2 = ones(FieldY*3-1,FieldX);

for ink = 1:sizeofpos(2)
  if ~ignoreNumbers(ink) && ~isempty(resultMatrix{ink})
    resultMatrix2 = resultMatrix2.*(1-resultMatrix{ink});
  end
end

if displayOutput
  figure(4);
  imshow(flipud(resultMatrix2));
end
matrix = max(0.001,resultMatrix2);
%-% The following is an easy work-around
matrix = matrix(1:FieldY*3-3,:);

% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
