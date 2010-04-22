%-% The purpose of this function is to determine which player should chase after the ball.
%-% Whichever player can get to the ball first is chosen.

function ind = ChooseChaser2(Ball,TeamOwn)

global FUN M

for i = 1:M
  %-% the x position and y position are not used
  [garbage1, garbage2, timeTillKick(i)] = FUN.Intersection(TeamOwn{i}.Pos,TeamOwn{i}.Type,Ball.Pos,0);
    %-% 0 is chosen because we assume the opponent needs no time to wind-up.
end

[value ind] = min(timeTillKick);
