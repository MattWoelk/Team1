function matrix = GraphField()

%-% This function maps the field in terms of the best locations to pass the ball to, not taking into account player positions, ball positions, or opponent positions.

global FUN Score
global Environment Team M FieldX FieldY

matrix = zeros(FieldY,FieldX);

%=% NB: Could probably replace for loops with repmat command for improved performance. Not deemed strictly necessary as this function should only be run once. See "GraphDontBlock" for example on how to replace with repmat.

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

distance = min(sqrt((ecks - 0).^2 + (why - FieldY/2).^2),...
               sqrt((ecks - FieldX).^2 + (why - FieldY/2).^2));
resultMatrix = max((ecks < FieldX/2).*(sin((distance.*pi)./(FieldX/2) - pi./2) + 1)./4,...
                   (ecks >= FieldX/2).*((sin(((FieldX/2 -distance).*pi)./(FieldX/2) - pi./2) + 1)./4 + 0.5));
matrix = resultMatrix;


%-% Make a few spots in the center of the net always bright white:
matrix(FieldY/2+Environment.GoalSize/2 - 1:FieldY/2-Environment.GoalSize/2 + 1,FieldX) = 1;
%-% The value 1 is the ball radius.

% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
