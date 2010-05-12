%-%This function displays shadows behind opponents, which are the areas where the ball should not be passed.

function = GraphShadows2(TeamOppSave, Pos)
global FUN Score
global Environment Team M FieldX FieldY qDamp


drawShadowValues = true;


bx = Pos(1);
by = Pos(2);

if drawShadowValues %-%Calculate and display a matrix of coordinates that represent good passing spots.
  r = 0.25; %-% The radius of the semicircle in the polar coordinate system.
  b = 0; %-% The radius of the semicircle in the Cartesian plane.
  k = 0; %-% k is the distance from the ball to the player.
  for inc = 1:M
    quant{inc} = zeros(ceil(FieldX/3),ceil(FieldY/3));

    px = TeamOppSave{inc}.Pos(1);
    py = TeamOppSave{inc}.Pos(2);
    k = FUN.Distance([bx,by],[px,py]);
    b = k.*sin(r);
    for i = 1:ceil(FieldX/3)
      for j = 1:ceil(FieldY/3)
        %-%distance: (1) is xpos, (2) is ypos, (3) is the distance
        distance = FUN.DistanceToLine(i*3,j*3,Pos(1),Pos(2),TeamOppSave{inc}.Pos(1),TeamOppSave{inc}.Pos(2),true);
        quant{inc}(j,i) = b > distance(3);
      end
    end
  end

  quant2 = max(quant{1},quant{2});
  for ink = 3:M
    quant2 = max(quant2,quant{ink});
  end

  if true %-% This will graph the data as an upside-down image.
    figure(4);
    imshow(flipud(quant2));
    figure(5)
    imshow(flipud(quant{1}))
    figure(6)
    imshow(flipud(quant{2}))
    figure(7)
    imshow(flipud(quant{3}))
  end
end

% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
