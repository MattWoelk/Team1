function matrix = GraphShadowsMir(PlayerPositions, Pos, displayOutput, radiusMultiplier)

%-% This function displays shadows behind opponents, which are the areas where the ball should not be passed.
%-% It also takes into account rebounds when calculating where to kick.

%-% This currently doesn't take into account the radius of the ball.
%-%  - (But we don't need that much accuracy for what we're doing.)
global FUN Score
global Environment Team M FieldX FieldY


matrix = zeros(FieldY*3-2,FieldX);

ecks = [];
eck = 1:FieldX;
for n = 1:FieldY*3-1
  ecks = [ecks;eck];
end

why = [];
wh = (1:FieldY*3-1)';
for n = 1:FieldX
  why = [why wh];
end

%-% set up doubles of the opponents:
for i = 1:M
  positions{(i-1)*3+1}(1) = PlayerPositions{i}(1);
  positions{(i-1)*3+1}(2) = PlayerPositions{i}(2) + FieldY;
  positions{(i-1)*3+2}(1) = PlayerPositions{i}(1);
  positions{(i-1)*3+2}(2) = FieldY - PlayerPositions{i}(2) + FieldY + FieldY;
  positions{(i-1)*3+3}(1) = PlayerPositions{i}(1);
  positions{(i-1)*3+3}(2) = FieldY - PlayerPositions{i}(2) - FieldY + FieldY;
end


bx = Pos(1);
by = Pos(2) + FieldY;
r = 0.25*radiusMultiplier; %-% The radius of the semicircle in the polar coordinate system.
b = 0; %-% The radius of the semicircle in the Cartesian plane.
%h = 0;  %-% h is the angle in relation to the ball. It has the range: [-pi/2,+3pi/2)
k = 0; %-% k is the distance from the ball to the player.
for inc = 1:M*3
  px = positions{inc}(1);
  py = positions{inc}(2);
  k = FUN.Distance([bx,by],[px,py]);
  b = k.*sin(r);

  multiplier = 1/b^2;

  distance = FUN.DistanceToLine2(ecks,why,bx,by,px,py,true);
  %resultMatrix{inc} = b > distance;
  resultMatrix{inc} = max(1 - multiplier.*distance.^2,0.0);
end

resultMatrix2 = (1-resultMatrix{1}).*(1-resultMatrix{2});
for ink = 3:M*3
  resultMatrix2 = resultMatrix2.*(1-resultMatrix{ink});
end

if (displayOutput)
  figure(5);
  imshow(flipud(resultMatrix2));
end
%-% The following is an easy work-around
matrix = resultMatrix2(1:FieldY*3-3,:);
