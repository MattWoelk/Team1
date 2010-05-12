function [ xpos, ypos, cycles ] = Intersection ( PlayerPos, Type, BallPos, Offset )

%INTERSECTION Returns the position and number of cycles in the future
%  where the provided player and ball will collide. 
%  If the agent cannot intercept the ball within PredictCycles, the pos
%  returned is [-1, -1] and cycles is inf.
%  Note that this function calculates the absolute minimum time for an 
%  agent to contact the ball, not the time it will take to make a 
%  calculated kick.


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
  

  Count = FUN.U_Count( 0, U_TurnAngle( asin(unitVector(2)) ), Type, (Type.MaxSpeed/Type.Parameters(2)) );



  PlayerLoc = unitVector.*Type.MaxSpeed.* (i - Count) + PlayerPos(1:2);
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




% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
