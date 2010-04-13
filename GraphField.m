%-% This function maps the field in terms of the best locations to pass the ball to, not taking into account player positions, ball positions, or opponent positions.

function matrix = GraphShadows(displayOutput)
global FUN Score
global Environment Team M FieldX FieldY

matrix = zeros(FieldY,FieldX);

ecks = [];
eck = 1:FieldX;
for n = 1:FieldY-1
  ecks = [ecks;eck];
end

why = [];
wh = (1:FieldY-1)';
for n = 1:FieldX
  why = [why wh];
end

distance = min(sqrt((ecks - 0).^2 + (why - FieldY/2).^2),...
               sqrt((ecks - FieldX).^2 + (why - FieldY/2).^2));
resultMatrix = max((ecks < FieldX/2).*(sin((distance.*pi)./(FieldX/2) - pi./2) + 1)./4,...
                   (ecks >= FieldX/2).*((sin(((FieldX/2 -distance).*pi)./(FieldX/2) - pi./2) + 1)./4 + 0.5));
matrix = resultMatrix;
