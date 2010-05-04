function target = Goalie(Ball,TeamOpp)

%-% This function defines the position where the goalie should go
%-% when the goalie in defensive mode.

persistent boundingRadius myline1
global  FieldY Environment M FUN

if ~isempty(boundingRadius)
  boundingRadius = TeamOwn{1}.Type.BoundingRadius
end

%-% Define Care zone
distBtwnPnts = @(x1,y1,x2,y2) (sqrt((x2-x1).^2 + (y2-y1).^2));
%-%See which opponent is closest to the center of the net, and return that distance.

%-%Calculate the angle formed by two lines that go from the goalposts to the ball:
%-%distance between goalposts:
c = Environment.GoalSize;
%-%distance from both goalposts to the ball:
a = distBtwnPnts(Ball.Pos(1),Ball.Pos(2),0,Environment.FieldSize(2)/2+Environment.GoalSize/2);
b = distBtwnPnts(Ball.Pos(1),Ball.Pos(2),0,Environment.FieldSize(2)/2-Environment.GoalSize/2);

%-%Cos Law:
%-%C = acos((a.^2+b.^2-c.^2)/(2*a*b));
angleC = acos((a.^2+b.^2-c.^2)/(2*a*b));

%-%Finding the point in the net where a line that is halfway between those two lines (in terms of angle) intersects the goal line (xpos, ypos)
angleB = acos((a.^2+c.^2-b.^2)/(2*a*c));
%-%3 angles of a triangle add up to pi
intermediateAngle = pi - angleC/2 - angleB;

%-%Sin Law:
%-% sin(A)/a = sin(B)/b = sin(C)/c
yposAboveNet = sin(angleC/2)*b / sin(angleB);

ypos = yposAboveNet + Environment.FieldSize(2)/2 - Environment.GoalSize/2;


%-%Find opponent with the closest intersection,it's the one we care about
care = [];
olddist = 999; %-%Arbitrarily large

for i=1:M
  %-%Find the intersection at the closest point between the location of the opponent and the line made by the ball and the calculated point in the net (ypos).
  intersection = FUN.DistanceToLine(0,ypos,Ball.Pos(1),Ball.Pos(2),TeamOpp{i}.Pos(1),TeamOpp{i}.Pos(2),false);

  newdist = intersection(1);

  if newdist < olddist
    care = i;
    olddist = newdist;
  end
end
intersection = FUN.DistanceToLine(0,ypos,Ball.Pos(1),Ball.Pos(2),TeamOpp{care}.Pos(1),TeamOpp{care}.Pos(2),false);


%-%Put the goalie between the calculated spot and the ball, but not further away from the net as 'intersection'
if intersection(1) > Ball.Pos(1)/3
  target = [Ball.Pos(1)/3, ypos - (ypos-Ball.Pos(2))/3];
elseif intersection(1) < boundingRadius
  %-%This is the case where the intersection is behind the net.
  %-%Put the goalie on the goal-line at ypos
  target = [0,ypos];
else
  target = [intersection(1), ypos - (ypos-Ball.Pos(2))/3];
end

%-% SHOW LIMITING LINES: --v
%-%figure(3)
%-%cla
%-%line([0,150],[0,0]);
%-%line([0,0],[0,100]);
%-%myline1 = line([0,Ball.Pos(1)],[ypos,Ball.Pos(2)],'LineStyle','-','Color','blue');
%-%myline2 = line([intersection(1),TeamOpp{care}.Pos(1)],[intersection(2),TeamOpp{care}.Pos(2)],'LineStyle','-','Color','red');
%-% --^
