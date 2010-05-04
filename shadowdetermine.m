function Passable = ShadowDetermine(TeamOppSave, Ball, xpos, ypos)

%-% This function calculates whether an opponent is blocking a position or not.
%-% In other words: if an opponent can reach the ball if we pass it to the given position,
%-% then this function will return False;

global FUN Score
global Environment Team M FieldX FieldY qDamp


i = xpos;
j = ypos;
ballx = Ball.Pos(1);
bally = Ball.Pos(2);

r = 0.25; %-% The radius of the semicircle in the polar coordinate system.
b = 0; %-% The radius of the semicircle in the Cartesian plane.
h = 0;  %-% h is the angle in relation to the ball. It has the range: [-pi/2,+3pi/2)
k = 0; %-% k is the distance from the ball to the player.

for inc = 1:M
%-%  k = sqrt((TeamOppSave{inc}.Pos(2) - bally).^2 + (TeamOppSave{inc}.Pos(1) - ballx).^2); %only needs one calc per opponent
%-%  b = k.*sin(r); %only needs one calc per opponent
%-%  if TeamOppSave{inc}.Pos(1) - ballx >= 0 %all of this, only once
%-%    if TeamOppSave{inc}.Pos(2) - bally == 0
%-%      h = 0;
%-%    else
%-%      h = asin((TeamOppSave{inc}.Pos(2) - bally)/k); 
%-%    end
%-%  elseif TeamOppSave{inc}.Pos(1) - ballx < 0
%-%    h = pi - asin((TeamOppSave{inc}.Pos(2) - bally)/k);
%-%  end
%-%
%-%  R = sqrt((j - bally).^2 + (i - ballx).^2);
%-%  if i - ballx >= 0
%-%    %%%%h) = asin((TeamOppSave{i}.Pos(2) - bally)/k(i)); 
%-%    theta = asin((j - bally)./R);
%-%  elseif i - ballx == 0 && j - bally == 0
%-%    theta = 0
%-%  else
%-%    theta = pi - asin((j - bally)/R);
%-%  end
%-%
%-%  %-%This is to take care of angle wrapping:
%-%  if j-bally<0 && i-ballx>0 && TeamOppSave{inc}.Pos(1)-ballx<0
%-%    h2 = h - 2*pi;
%-%  elseif j-bally<0 && i-ballx<0 && TeamOppSave{inc}.Pos(1)-ballx>0
%-%    h2 = h + 2*pi;
%-%  else
%-%    h2 = h;
%-%  end

  quant(inc) = R > (-sqrt(((b).^2).*(1 - ((theta - h2).^2)/r.^2)) + k).*... %-% Graph a semicircle
                        (((1-heaviside(theta - (h2-r)))+heaviside(theta - (h2+r))).*499 + 1);
end

quant2 = max(quant(1),quant(2));
for ink = 3:M
  quant2 = max(quant2,quant(ink));
end

Passable = logical(quant2);
