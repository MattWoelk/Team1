function Passable = ShadowDetermine(TeamOppSave, Ball, xpos, ypos)

%-% This function calculates whether an opponent is blocking a position or not.
%-% In other words: if an opponent can reach the ball if we pass it to the given position,
%-% then this function will return False;

global FUN Score
global Environment Team M FieldX FieldY qDamp


i = xpos;
j = ypos;
ballx = Ball.Pos(1);
bally = Ball.Pos(2);

r = 0.25; %-% The radius of the semicircle in the polar coordinate system.
b = 0; %-% The radius of the semicircle in the Cartesian plane.
h = 0;  %-% h is the angle in relation to the ball. It has the range: [-pi/2,+3pi/2)
k = 0; %-% k is the distance from the ball to the player.

for inc = 1:M
  quant(inc) = R > (-sqrt(((b).^2).*(1 - ((theta - h2).^2)/r.^2)) + k).*... %-% Graph a semicircle
                        (((1-heaviside(theta - (h2-r)))+heaviside(theta - (h2+r))).*499 + 1);
end

quant2 = max(quant(1),quant(2));
for ink = 3:M
  quant2 = max(quant2,quant(ink));
end

Passable = logical(quant2);


% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
