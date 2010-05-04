function matrix = GraphDimmer (PlayerPos, Dimmer)

global FieldX FieldY

matrix = [ones(FieldY-1, floor(PlayerPos(1)))*Dimmer, ones(FieldY-1, FieldX-floor(PlayerPos(1)))];
