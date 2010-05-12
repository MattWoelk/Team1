function PredictedCoordinates = PlayerPrediction( PlayerPos, PlayerFifo, cycles, GameMode )

%PLAYERPREDICTION This function predicts where the player will
%  be based on a given set of control signals stored in the 
%  fifo. This function will return an array of length 'cycles'
%  containing the predicted future coordinates for the agent 
%  in each cycle. The fifo passed to PLAYERPREDICTION must be
%  timestamped.

global FUN

[CS, Fifo] = FUN.U_Shorten( PlayerFifo, GameMode(1), 20 ); %=% 20 is an arbitrary value. It is only used to construct CS which we don't care about right now.

PredictedCoordinates = zeros(cycles, 4);

cycles = min(cycles, size(Fifo, 1));

for i=1:cycles
  if Fifo(i, 2)   %=% we are moving forward
    %=% use the current angle vector to find x and y to add to position
    MoveVector = PlayerPos(3:4) * Fifo(i, 2);
    NewPos = PlayerPos(1:2) + MoveVector;
    PredictedCoordinates(i, :) = [ NewPos, PlayerPos(3:4) ];
    PlayerPos = PredictedCoordinates(i, :);
  elseif Fifo(i, 3)   %=% we are turning
    %=% use the rotation amount and the current angle vector to find a new angle vector

    x = PlayerPos(3);
    y = PlayerPos(4);

    %=% use of the atan2 function might make this code simpler
    if x > 0
      angle = atan(y/x);
    elseif x < 0 && y >=0
      angle = atan(y/x) + pi;
    elseif x < 0 && y < 0
      angle = atan(y/x) - pi;
    elseif x == 0 && y > 0
      angle = pi/2;
    elseif x == 0 && y < 0
      angle = -pi/2;
    elseif x == 0 && y == 0
      angle = 0;
    end

    NewAngle = angle + Fifo(i, 3);

    NewDir = [ cos(NewAngle), sin(NewAngle) ];

    PredictedCoordinates(i, :) = [ PlayerPos(1:2), NewDir ];
    PlayerPos = PredictedCoordinates(i, :);
  else
    if i ~= 1
      %=% if the number of moves in the fifo is shorter than the requested cycles, assume agents stops here
      PredictedCoordinates(i, :) = PredictedCoordinates(i-1, :);
      PlayerPos = PredictedCoordinates(i, :);
    else
      PredictedCoordinates(i, :) = PlayerPos;
    end
  end
end


% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
