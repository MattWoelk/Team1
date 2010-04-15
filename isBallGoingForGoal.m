function isBallGoingForGoal = isBallGoingForGoal( Ball )

%=% This function does not take into account rebounds off of the walls.

global FieldX FieldY Environment

%Received parameters
Bx=Ball.Pos(1);
By=Ball.Pos(2);
BVx=Ball.Pos(3);
BVy=Ball.Pos(4);

isBallGoingForGoal = 0;

if BVx > 0
  if BVx || BVy ~= 0
    slope = BVy/BVx;
    ua = slope*(FieldX - Bx) + By;

    if ua < FieldY/2+Environment.GoalSize/2 && ua > FieldY/2-Environment.GoalSize/2
      isBallGoingForGoal = 1;
    end
  end
end
