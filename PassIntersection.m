function [ xpos, ypos, cycles ] = PassIntersection ( PlayerPos, PlayerType, PlayerFifo, GameMode, BallPos, BallVel, Offset )

%PASSINTERSECTION Returns the position and number of cycles in the
%  future where the provided player and ball can collide. This point
%  is based on the provided Fifo of moves for the player and the 
%  speed of the ball. The offset is the time until we can kick the
%  ball at the provided speed. The BallPos should be the position
%  at that same kick time.
%  Note that this function calculates the absolute minimum time for 
%  the ball to get to the agent's path. This does not consider the
%  receiving agent slowing down for a kick, nor does it consider how
%  the passing angle affects the first agent's wind up.


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


% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
