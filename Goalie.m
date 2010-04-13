%-% Biased to Team1???
%function defines the position of the goalie in defense case
function target = Goalie(Ball,TeamOpp)
persistent boundingRadius myline1
global  FieldY Environment M FUN

if ~isempty(boundingRadius)
  boundingRadius = TeamOwn{1}.Type.BoundingRadius
end

%-% Define Care zone
distBtwnPnts = @(x1,y1,x2,y2) (sqrt((x2-x1).^2 + (y2-y1).^2));
%-%See which opponent is closest to the center of the net, and return that distance.

%-%WILL ONLY WORK IF WE ARE TEAM1 (assuming no global reversal of directions...)
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

%-% TODO:
%-%   get the goalie to attack the ball if he knows he's going to get there before anyone else. 
%-%       OR get the goalie to go to where the ball is going to be, rather than where the ball currently is.
%-%   when this happens, get the goalie to actually kick the ball intelligently
%-%   and also determined by possible bounce shots
%-%   Implement the 2-sates system. Intercepting (to be added) and positions (currently implemented)
%-%   Document this all in diagrams and put references to it in the code

%-% SHOW LIMITING LINES: --v
%-%figure(3)
%-%cla
%-%line([0,150],[0,0]);
%-%line([0,0],[0,100]);
%-%myline1 = line([0,Ball.Pos(1)],[ypos,Ball.Pos(2)],'LineStyle','-','Color','blue');
%-%myline2 = line([intersection(1),TeamOpp{care}.Pos(1)],[intersection(2),TeamOpp{care}.Pos(2)],'LineStyle','-','Color','red');
%-% --^


%-%OLD CODE--v
%a%%Received parameters
%a%Bx=Ball.Pos(1);
%a%By=Ball.Pos(2);
%a%Vx=Ball.Pos(3);
%a%Vy=Ball.Pos(4);
%a%
%a%target = 0;
%a%
%a%if Bx > 10
%a%    distToGoal = 5; %distance from the goal, keep slightly more to allow for kicking out
%a%else
%a%    distToGoal = 3;
%a%end
%a%
%a%%-%target = [placement,FieldY/2];
%a%if Vx < 0
%a%    %if the ball is aimed at our goal
%a%    slope = Vy/Vx;
%a%
%a%    %x=0-side coordinate under attack
%a%    ua = slope*(distToGoal - Bx) + By;
%a%
%a%
%a%    if ua < FieldY/2+Environment.GoalSize/2 && ua > FieldY/2-Environment.GoalSize/2
%a%        %if ball is aimed at the goal - catch it!
%a%        target = [distToGoal, ua];
%a%    elseif ua < FieldY/2-Environment.GoalSize/2
%a%        %otherwise - stay in the closest to attack point corner
%a%        target = [distToGoal, FieldY/2-Environment.GoalSize/2];
%a%    elseif ua > FieldY/2+Environment.GoalSize/2
%a%        target = [distToGoal, FieldY/2+Environment.GoalSize/2];
%a%    end
%a%else
%a%    %otherwise - stay in the middle of the goal
%a%    target = [distToGoal, FieldY/2];
%a%end
%a%
%a%
