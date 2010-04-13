%-% Choose who will be goalie (not including the current goalie)
%-% This is done by determining which player is closest to the center of our goal.
%-% Send -1 as currentGoalie to ignore this restriction.
function lowestPlayer = ClosestToNet(M,TeamOwnSave,FieldY,currentGoalie)

distanceFromNet = @(x,y) sqrt((x - 0).^2 + (y - FieldY/2).^2);
lowestValue = 999; %-% Arbitrarily high

if currentGoalie ~= 1
  lowestValue = distanceFromNet(TeamOwnSave{1}.Pos(1),TeamOwnSave{1}.Pos(2));
  lowestPlayer = 1;
end
for inc = 2:M
  if distanceFromNet(TeamOwnSave{inc}.Pos(1),TeamOwnSave{inc}.Pos(2)) < lowestValue && inc ~= currentGoalie
    lowestPlayer = inc;
  end
end
