function PredictedCoordinates = PlayerPrediction( Player, PlayerFifo, cycles, GameMode )

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
    %WRONG    PredictedCoordinates(i, :) = [ Player.Pos(1:2)*Fifo(i, 2), Player.Pos(3:4) ]
    MoveVector = Player.Pos(3:4) * Fifo(i, 2);
    NewPos = Player.Pos(1:2) + MoveVector;
    PredictedCoordinates(i, :) = [ NewPos, Player.Pos(3:4) ];
    Player.Pos = PredictedCoordinates(i, :);
  elseif Fifo(i, 3)   %=% we are turning
    %=% use the rotation amount and the current angle vector to find a new angle vector

    x = Player.Pos(3);
    y = Player.Pos(4);

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

    PredictedCoordinates(i, :) = [ Player.Pos(1:2), NewDir ];
    Player.Pos = PredictedCoordinates(i, :);
  end
end
