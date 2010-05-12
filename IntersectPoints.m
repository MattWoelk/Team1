function locations = IntersectPoints(TeamOwn,PlayerTargets,engagePosition,MaxKickVel,offset,engagingPlayer,Fifo,GameMode)

global FUN M

locations = [];

for i = 1:M
  %-% Create a fake ball with the speed that we will kick it at.
  if i ~= engagingPlayer
    kickertarget = PlayerTargets{i};
    maxvel = MaxKickVel;
    delx =  engagePosition(1) - kickertarget(1);
    dely =  engagePosition(2) - kickertarget(2);
    velx = sqrt(maxvel.^2./(1+(dely.^2/delx.^2)));
    vely = sqrt(maxvel.^2 - velx.^2);
    targetVector = [-velx -vely];
    fakeBall.Pos = [engagePosition(1:2) targetVector];

    [xpos,ypos,cycles] = FUN.PassIntersection(TeamOwn{i}.Pos,TeamOwn{i}.Type,Fifo{i},GameMode,engagePosition,MaxKickVel,offset);
    %-%[xpos,ypos,cycles] = FUN.Intersection(TeamOwn{i}.Pos,TeamOwn{i}.Type,engagePosition,offset);
    locations{i} = [xpos ypos];
    if locations{i} < 0
      locations{i} = PlayerTargets{i};
    end
    %disp(strcat('locations | ',num2str(i),' | ',num2str(locations{i})));
    %disp(strcat('targetsss | ',num2str(i),' | ',num2str(PlayerTargets{i})));
  else
    locations{i} = [];
  end
end



% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
