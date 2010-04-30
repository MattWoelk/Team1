function canGetThereFirst = canGetThereFirst(TeamOpp,PlayerPos,PlayerType,BallPos,offset)
%-% offset: roughly how long it takes to set up a shot. (17 seems like a good choice)
%=% NB: this offset is an approximation. If the ball is moving quickly, this approximation will fail. This might be better to incorporate with the Intersection function.

global FUN M

%-% the x position and y position are not used
[garbage1, garbage2, timeTillGKick] = FUN.Intersection(PlayerPos,PlayerType, BallPos, 0);
for i = 1:M
  [xpos, ypos, timeTillOKick(i)] = FUN.Intersection(TeamOpp{i}.Pos,PlayerType,BallPos,0);
end
%-% we assume the opponent needs no time to wind-up.
if any(timeTillOKick < timeTillGKick + offset)
  canGetThereFirst = false;
else
  canGetThereFirst = true;
end
