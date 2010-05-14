function inter = DistanceToLine (x1, y1, x2, y2, x3, y3, OnLineSegment) %inter = [x, y, dist]

%function returns the distance to line (point1 to point 2) and the third point and the intersection point 

%-% adapted from:
%-% http://www.gamedev.net/community/forums/topic.asp?topic_id=444154
%-% accessed on March 5, 2010
%-% made by oliii (GDNet+ Member)
%-%   posted on 17/4/2007


A = [x1,y1];
B = [x2,y2];
P = [x3,y3];

AP = P-A;
AB = B-A;
ab2 = AB(1)*AB(1) + AB(2)*AB(2);
apab = AP(1)*AB(1) + AP(2)*AB(2);
tee = apab/ab2;
if OnLineSegment
  if tee < 0.0
    tee = 0.0;
  elseif tee > 1.0
    tee = 1.0;
  end
end
closest = A + AB*tee;

inter = [closest,Distance([x3,y3],closest)];
                


% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
