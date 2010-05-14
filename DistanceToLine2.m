function inter = DistanceToLine2 (x1, y1, x2, y2, x3, y3, OnLineSegment) %inter = [x, y, dist]

%-% function returns the distance to line (point1 to point 2) and the third point and the intersection point 
%-% This function takes in matrices of points instead of just points.

%-% adapted from:
%-% http://www.gamedev.net/community/forums/topic.asp?topic_id=444154
%-% accessed on March 5, 2010
%-% made by oliii (GDNet+ Member)
%-%   posted on 17/4/2007


sizex = size(x1);
sizey = size(y1);

Ax = x1;
Ay = y1;
Bx = ones(sizex(1),sizex(2))*x2;
By = ones(sizey(1),sizey(2))*y2;
Px = ones(sizex(1),sizex(2))*x3;
Py = ones(sizey(1),sizey(2))*y3;

APx = Px-Ax;
APy = Py-Ay;
ABx = Bx-Ax;
ABy = By-Ay;
ab2 = ABx.*ABx + ABy.*ABy;
apab = APx.*ABx + APy.*ABy;
tee = apab./ab2;
if OnLineSegment
  tee = max(tee,0.0);
  tee = min(tee,0.999);
end
closestx = Ax + ABx.*tee;
closesty = Ay + ABy.*tee;

inter = sqrt((x3-closestx).^2 + (y3 - closesty).^2);

% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
