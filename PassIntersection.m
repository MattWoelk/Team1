function [ xpos, ypos, cycles ] = PassIntersection ( PlayerPos, PlayerType, PlayerFifo, GameMode, BallPos, BallVel, Offset )

%======================%INTERSECTION Returns the position and number of cycles in the future
%======================%  where the provided player and ball will collide. The returned number
%======================%  of cycles is the number of cycles after the provided offset.
%======================%  If the agent cannot intercept the ball within PredictCycles, the pos
%======================%  returned is [-1, -1] and cycles is inf.
%======================%  Note that this function calculates the absolute minimum time for an 
%======================%  agent to contact the ball, not the time it will take to make a 
%======================%  calculated kick.


global FUN

BallRadius = 1;
PredictCycles = 70;
PlayerPredict = FUN.PlayerPrediction( PlayerPos, PlayerFifo, PredictCycles, GameMode );
if ~exist('BallVel', 'var') || BallVel == 0
  BallVel = norm(BallPos(3:4));
end
if ~exist('Offset', 'var')
  Offset = 0;
end

for i = Offset+1:PredictCycles
  j = i - Offset;
  distVector = PlayerPredict(i, 1:2) - BallPos(1:2);
  unitVector = distVector/norm(distVector);

  FakeBall = [BallPos(1:2), BallVel*unitVector(1:2)];
  BallPredict = FUN.BallPrediction(FakeBall, PredictCycles);  %=% NB: don't need this many cycles, but this will always be sufficient

  if (norm(BallPredict(j, 1:2) - PlayerPredict(i, 1:2)) < (PlayerType.BoundingRadius + BallRadius)) && ~(norm(PlayerPredict(i, 1:2) - [0 0]) < 0.1)
    %=% there is a collision

    xpos = PlayerPredict(i, 1);
    ypos = PlayerPredict(i, 2);
    cycles = i;
    return
  end
end



%=% Player is unable to contact ball.
xpos = -1;
ypos = -1;
cycles = inf;
