function [ xpos, ypos, cycles ] = Intersection ( Player, Ball )

%=% NB: change input to require BallPos instead of Ball. This requires changes to BallPrediction as well.

global FUN

BallRadius = 1;
PredictCycles = 70;
BallPredict = FUN.BallPrediction(Ball, PredictCycles);

for i = 1:PredictCycles
  distVector = (BallPredict(i, 1:2) - Player.Pos(1:2));
  unitVector = distVector/norm(distVector);
  PlayerLoc = unitVector.*Player.Type.MaxSpeed.*i + Player.Pos(1:2);
  if norm(PlayerLoc - BallPredict(i,1:2)) < (Player.Type.BoundingRadius + BallRadius)
    %=% collide near here
    xpos = PlayerLoc(1);
    ypos = PlayerLoc(2);
    PlayerLoc
    cycles = i
    return
  end
end

%=% Player is unable to contact ball.
PlayerLoc = [-1 -1];
xpos = PlayerLoc(1);
ypos = PlayerLoc(2);
cycles = -1;


