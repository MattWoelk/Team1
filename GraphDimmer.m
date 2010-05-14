function matrix = GraphDimmer (PlayerPos, Dimmer)
%=% Uses the Dimmer value to create a matrix that dims the field between the player and the player's goal.

global FieldX FieldY

matrix = [ones(FieldY-1, floor(PlayerPos(1)))*Dimmer, ones(FieldY-1, FieldX-floor(PlayerPos(1)))];
