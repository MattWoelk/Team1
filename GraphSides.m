function matrix = GraphSides()

global FUN Score FieldX FieldY

%-% This makes a nice curve that keeps players away from the edges of the field.
fandle = @(x) (1.17 - 1./(x./4+0.8));

distFromYAxis = repmat([1:FieldX], FieldY-1, 1);
distFromXAxis = repmat([1:FieldY-1]', 1, FieldX);

distFromSide = min(fandle(distFromXAxis),fandle(FieldY - distFromXAxis));
distFromSide = min(distFromSide,fandle(distFromYAxis));
distFromSide = min(distFromSide,fandle(FieldX - distFromYAxis));

matrix = min(1,distFromSide);
matrix = max(0,distFromSide);

%-% 0.9 - 1/(x+0.8)
