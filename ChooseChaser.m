function inc = ChooseChaser(M,Ball,TeamOwnSave,displayOutput)
global FUN

%-% The purpose of this function is to determine which player should chase after the ball.
%-% This is the old version, which doesn't work as well as the new one.

for inc = 1:M
  px(inc) = TeamOwnSave{inc}.Pos(1);
  py(inc) = TeamOwnSave{inc}.Pos(2);
  bx = Ball.Pos(1);
  by = Ball.Pos(2);
  bvx = bx + Ball.Pos(3)*300;%-% An arbitrary point in the direction that the ball is moving.
  bvy = by + Ball.Pos(4)*300;

  btemp{inc} = FUN.DistanceToLine(bx,by,bvx,bvy,px(inc),py(inc),true); %-% Distance from the player to the ball's path.
  b(inc) = btemp{inc}(3);
  a(inc) = sqrt((btemp{inc}(1) - bx).^2 + (btemp{inc}(2) - by).^2);%-% Distance from the closest point to the character on the ball's path to the ball.
  tp(inc) = b(inc) / 1; %-% Time it takes for the player to get to the intersection.
  ballSpeed = sqrt(Ball.Pos(3).^2 + Ball.Pos(4).^2);
  tb(inc) = a(inc) / ballSpeed; %-% Time it takes for ball to get to the intersection.
  if tp(inc) > tb(inc)
    %-% If none of them can reach the ball, pick the one who's intersection is furthest away from the ball.
    tb(inc) = 1000000 - a(inc); %-% Use the distance instead.
  end
end

%-% If all of the players are behind the ball:
if logical(min(tb == 1000000))
  %-% If all of the elements in tb are 1000000
  tb = b;
end

%-% THIS CURRENTLY ASSUMES CONSTANT BALL SPEED!
[temp,inc] = min(tb);

if displayOutput
  figure(4)
  clf;
  hold on;
  set(gcf,'Position',[500 30 490 300])
  xlim([0 150]);
  ylim([0 100]);

  line([bx bvx],[by bvy],'Color',[0.5 0.5 0.5]);
  line([btemp{1}(1) px(1)],[btemp{1}(2) py(1)],'Marker','o','Color',[1 0 0]);
  line([btemp{2}(1) px(2)],[btemp{2}(2) py(2)],'Marker','o','Color',[0 1 0]);
  line([btemp{3}(1) px(3)],[btemp{3}(2) py(3)],'Marker','o','Color',[0 0 1]);
end
