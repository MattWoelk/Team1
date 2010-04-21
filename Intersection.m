function [ xpos, ypos, cycles ] = Intersection ( PlayerPos, Type, BallPos, Offset )

%INTERSECTION Returns the position and number of cycles in the future
%  where the provided player and ball will collide. The returned number
%  of cycles is the number of cycles after the provided offset.

%-% Offset will most often be the number of cycles before the player kicks the ball.

global FUN

BallRadius = 1;
PredictCycles = 70;
BallPredict = FUN.BallPrediction(BallPos, PredictCycles);

if ~exist('Offset', 'var')
  Offset = 0;
end

for i = Offset+1:PredictCycles
  j = i - Offset;
  distVector = (BallPredict(j, 1:2) - PlayerPos(1:2));
  unitVector = distVector/norm(distVector);
  PlayerLoc = unitVector.*Type.MaxSpeed.*i + PlayerPos(1:2);
  if norm(PlayerLoc - BallPredict(j,1:2)) < (Type.BoundingRadius + BallRadius)
    %=% collide near here
    xpos = PlayerLoc(1);
    ypos = PlayerLoc(2);
    cycles = i;
    return
  end
end

%=% Player is unable to contact ball.
PlayerLoc = [-1 -1];
xpos = PlayerLoc(1);
ypos = PlayerLoc(2);
cycles = inf;


