function matrix = BallPrediction(Ball,cycles,displayOutput)

global qDamp FieldX FieldY

%-% Predict where the ball will be when HLS is calculated again.
%-% Now it takes into account bounces off the wall.
ballradius = 1;

%-% This is a workaround to fix rebounding off top:
ballradiustop = 1.3;

matrix = zeros(cycles,4);

prevX = Ball.Pos(3)*qDamp; %-% predicted velocity of the ball.
prevY = Ball.Pos(4)*qDamp;
preX = Ball.Pos(1) + prevX; %-% predicted position of the ball.
preY = Ball.Pos(2) + prevY;

%-% To consider bouncing off of walls:
if preX < (0 + ballradius)
  preX = 2*ballradius - preX;
  prevX = - prevX;
end

if preX > (FieldX - ballradius)
  preX = 2*(FieldX-ballradius) - preX;
  prevX = - prevX;
end

if preY < (0 + ballradius)
  preY = 2*ballradius - preY;
  prevY = - prevY;
end

if preY > (FieldY - ballradiustop)
  preY = 2*(FieldY-ballradiustop) - preY;
  prevY = - prevY;
end

matrix(1,:) = [preX preY prevX prevY];

for i = 2:cycles
  prevX = prevX*qDamp; %-% predicted velocity of the ball.
  prevY = prevY*qDamp;
  preX = preX + prevX; %-% predicted position of the ball.
  preY = preY + prevY;

  %-% To consider bouncing off of walls:
  if preX < (0 + ballradius)
    preX = 2*ballradius - preX;
    prevX = - prevX;
  end

  if preX > (FieldX - ballradius)
    preX = 2*(FieldX-ballradius) - preX;
    prevX = - prevX;
  end

  if preY < (0 + ballradius)
    preY = 2*ballradius - preY;
    prevY = - prevY;
  end

  if preY > (FieldY - ballradiustop)
    preY = 2*(FieldY-ballradiustop) - preY;
    prevY = - prevY;
  end

  matrix(i,:) = [preX preY prevX prevY];
end


if exist('displayOutput', 'var') && displayOutput
  figure(4);
  clf;
  hold on;
  set(gcf,'Position',[500 30 490 300]);

  xlim([0 150]);
  ylim([0 100]);

  line([Ball.Pos(1) Ball.Pos(1)],[Ball.Pos(2) Ball.Pos(2)],'Marker','o','Color','black');
  line([preX preX],[preY preY],'Marker','o','Color','blue');
end
