function output = DisplayBallPrediction(Ball,qDamp,FieldX,FieldY)

%-% Predict where the ball will be when HLS is calculated again.
%-% Now it takes into account bounces off the wall.
persistent countDown;
if isempty(countDown)
  countDown = 9;
end

ballradius = 2;

%-%if countDown > 0
%-%  countDown = countDown - 1;
%-%else
%-%  countDown = 5;
%-%end

preX = Ball.Pos(1) + Ball.Pos(3)*qDamp;
preY = Ball.Pos(2) + Ball.Pos(4)*qDamp;
for i = 2:countDown
  preX = preX + Ball.Pos(3)*qDamp;
  preY = preY + Ball.Pos(4)*qDamp;
end


%-% To consider bouncing off of walls:
if preX < (0 + ballradius)
  disp('bounce off left');
  preX = 0 + ballradius - preX;
end

if preX > (FieldX - ballradius)
  disp('bounce off right');
  preX = 2*(FieldX-ballradius) - preX;
end

if preY < (0 + ballradius)
  disp('bounce off bottom');
  preY = 0 + ballradius - preY;
end

if preY > (FieldY - ballradius)
  disp('bounce off top');
  preY = 2*(FieldY-ballradius) - preY;
end
preX
preY

figure(4);
clf;
hold on;
set(gcf,'Position',[500 30 490 300]);

xlim([0 150]);
ylim([0 100]);

output = [preX preY];

%-%line([x1 x1],[y1 y1],'Marker','o','Color','black');
line([Ball.Pos(1) Ball.Pos(1)],[Ball.Pos(2) Ball.Pos(2)],'Marker','o','Color','black');
line([preX preX],[preY preY],'Marker','o','Color','blue');

% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
