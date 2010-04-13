%-% This function graphs a field where its values are dependent on the players' positions.

function matrix = GraphPlayerPositions(TeamOwnSave, Ball, displayOutput, radiusMultiplier)
global FUN Environment Team M FieldX FieldY qDamp

ELLIPSEcircle = false; %-% Ellipse mode is not yet working properly.

matrix = ones(FieldY,FieldX)*0.5;

bx = Ball.Pos(1);
by = Ball.Pos(2);

point2 = []; %-% This is the point with b distance from the opponent's position, between the opponent and the goal. It is one of the two focal points of the ellipse. (The other is the opponent's position)
             %-% It is only used for Ellipse mode.

ecks = [];
%eck = (1:FieldX/3)*3;
%for n = 1:FieldY/3-1
eck = 1:FieldX;
for n = 1:FieldY-1
  ecks = [ecks;eck];
end

why = [];
%wh = ((1:FieldY/3-1)*3)';
%for n = 1:FieldX/3
wh = (1:FieldY-1)';
for n = 1:FieldX
  why = [why wh];
end

%-% For our team:
for inc = 1:M
  px = TeamOwnSave{inc}.Pos(1);
  py = TeamOwnSave{inc}.Pos(2);

  r = 0.25*radiusMultiplier;
  k = FUN.Distance([bx,by],[px,py]);
  b = k.*sin(r);

  doubleradius = sqrt((ecks - px).^2 + (why - py).^2);
  multiplier = 1/b^2;
  if ELLIPSEcircle
    slope = (FieldY-by)/(FieldX/2-bx);
    i = b/sqrt(slope^2 + 1);
    j = i*slope;
    %abovenet = (py > FieldY/2)*2 - 1; %-% -1 if below the net, 1 if above
    point2 = [px-abovenet*i,py-abovenet*j];
    %point2 = [px-i,py-j];
    doubleradius = doubleradius + sqrt((ecks - point2(1)).^2 + (why - point2(2)).^2);
    multiplier = multiplier.*0.1
  end
  resultMatrix{inc} = max(1 - multiplier.*doubleradius.^2,0.0);
end

resultMatrix2 = (1-resultMatrix{1}).*(1-resultMatrix{2});
for ink = 3:M
  resultMatrix2 = resultMatrix2.*(1-resultMatrix{ink});
end

if displayOutput
  figure(4);
  imshow(flipud(resultMatrix2));
end
matrix = resultMatrix2;