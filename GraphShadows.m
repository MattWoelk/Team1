function matrix = GraphShadows(PlayerPositions, Pos, displayOutput, radiusMultiplier)

%-% This function displays shadows behind opponents, which are the areas where the ball should not be passed.

global FUN Score
global Environment Team M FieldX FieldY


%-% This makes it so the last part of the code is the only part that is run!!!!!!!!
%-% (The last part is the only good part, and the rest can probably be deleted)
drawShadowFunction = false;
  drawShadowFunctionPolar = false;
  drawShadowFunctionCartesian = false;
    drawShadowFunctionCartesianPlayers = false;
drawShadowValues = false;
drawEfficientShadowValues = true;





if drawShadowFunction %-% This section generates a plot that shows the good and bad locations to shoot to based on the opponents' positions.
  ballx = Pos(1);
  bally = Pos(2);

  r = 0.25; %-% The radius of the semicircle in the polar coordinate system.
  b = 0; %-% The radius of the semicircle in the Cartesian plane.
  h = 0;  %-% h is the angle in relation to the ball. It has the range: [-pi/2,+3pi/2)
  k = 0; %-% k is the distance from the ball to the player.
  numberOfValues = 300;
  x = linspace(-pi,2*pi,numberOfValues); %-% x is a range of angles that will be cut down to [-pi/2,3pi/2).

  for i = 1:M
    k(i) = sqrt((PlayerPositions{i}(2) - bally).^2 + (PlayerPositions{i}(1) - ballx).^2);
    b(i) = k(i).*sin(r);
    if PlayerPositions{i}(1) - ballx >= 0
      if PlayerPositions{i}(2) - bally == 0
        h(i) = 0;
      else
        h(i) = asin((PlayerPositions{i}(2) - bally)/k(i)); 
      end
    elseif PlayerPositions{i}(1) - ballx < 0
      h(i) = pi - asin((PlayerPositions{i}(2) - bally)/k(i));
    end
  end

  y = min(... %-% Combine the graphs of two of the opponents together.
         (-sqrt(((b(1)).^2).*(1 - ((x - h(1)).^2)/r.^2)) + k(1)).*... %-% Graph a semicircle
         (((1-heaviside(x - (h(1)-r)))+heaviside(x - (h(1)+r))).*499 + 1),... %-% Use the step function to isolate the semicircle
         (-sqrt(((b(2)).^2).*(1 - ((x - h(2)).^2)/r.^2)) + k(2)).*... %-% Graph a semicircle
         (((1-heaviside(x - (h(2)-r)))+heaviside(x - (h(2)+r))).*499 + 1));
  for inc = 3:M %-% Combine the rest of the players too.
    y = min(y,... 
           (-sqrt(((b(inc)).^2).*(1 - ((x - h(inc)).^2)/r.^2)) + k(inc)).*... %-% Graph a semicircle
           (((1-heaviside(x - (h(inc)-r)))+heaviside(x - (h(inc)+r))).*499 + 1));
  end

  y = real(y); %-% Ignore the imaginary parts of the plot.
  y = max(y,(zeros(1,length(y)))); %-% This will get rid of negative values.

  %-% Now we want the arcs from one angle to wrap around to the other side.
  temp = min(y(1:numberOfValues/3),y(numberOfValues*2/3+1:numberOfValues)); %-% Take the minimum of the regions that wrap around.
  y(1:numberOfValues/3) = temp; %-% Replace the x values with the new minimums
  y(numberOfValues*2/3+1:numberOfValues) = temp;


  figure(4)
  clf;
  hold on;
  set(gcf,'Position',[500 30 490 300])

  if drawShadowFunctionCartesian %-% This will plot in Cartesian coordinates.
    %-% Now we convert it to Cartesian coordinates.
    f{1} = y.*cos(x) + ballx;
    f{2} = y.*sin(x) + bally;
    plot(f{1},f{2});
    %plot3(x,f{1},f{2}); %-% Plot it in Cartesian coordinates.
    xlim([0 150]);
    ylim([0 100]);
  end

  if drawShadowFunctionCartesianPlayers %-% This plots the opponents, the ball, and our players on the Cartesian graph.
    for i = 1:M
      line([PlayerPositions{i}(1) PlayerPositions{i}(1)],[PlayerPositions{i}(2) PlayerPositions{i}(2)],'Marker','o','Color','black')
    end
    line([TeamOwnSave{1}(1) TeamOwnSave{1}(1)],[TeamOwnSave{1}(2) TeamOwnSave{1}(2)],'Marker','o','Color','red')
    line([TeamOwnSave{2}(1) TeamOwnSave{2}(1)],[TeamOwnSave{2}(2) TeamOwnSave{2}(2)],'Marker','o','Color','green')
    line([TeamOwnSave{3}(1) TeamOwnSave{3}(1)],[TeamOwnSave{3}(2) TeamOwnSave{3}(2)],'Marker','o','Color','blue')
    line([Pos(1) Pos(1)],[Pos(2) Pos(2)],'Marker','o','Color',[0.5 0.5 0.5])
    xlim([0 150]);
    ylim([0 100]);
  end

  if drawShadowFunctionPolar %-% This will plot in polar coordinates.
    plot(x,y); 
    xlim([-pi/2 3*pi/2]); 
    ylim([0 200]);
  end
end







if drawShadowValues %-%Calculate and display a matrix of coordinates that represent good passing spots.
  ballx = Pos(1);
  bally = Pos(2);
  r = 0.25; %-% The radius of the semicircle in the polar coordinate system.
  b = 0; %-% The radius of the semicircle in the Cartesian plane.
  h = 0;  %-% h is the angle in relation to the ball. It has the range: [-pi/2,+3pi/2)
  k = 0; %-% k is the distance from the ball to the player.
  for inc = 1:M
    k = sqrt((PlayerPositions{inc}(2) - bally).^2 + (PlayerPositions{inc}(1) - ballx).^2);
    b = k.*sin(r);
    if PlayerPositions{inc}(1) - ballx >= 0
      if PlayerPositions{inc}(2) - bally == 0
        h = 0;
      else
        h = asin((PlayerPositions{inc}(2) - bally)/k); 
      end
    elseif PlayerPositions{inc}(1) - ballx < 0
      h = pi - asin((PlayerPositions{inc}(2) - bally)/k);
    end

    for i = 1:2:Environment.FieldSize(1)
      for j = 1:2:Environment.FieldSize(2)
        R = sqrt((j - bally).^2 + (i - ballx).^2);
        if i - ballx >= 0
          %%%%h) = asin((PlayerPositions{i}(2) - bally)/k(i)); 
          theta = asin((j - bally)./R);
        elseif i - ballx == 0 && j - bally == 0
          theta = 0
        else
          theta = pi - asin((j - bally)/R);
        end

        %-%This is to take care of angle wrapping:
        if j-bally<0 && i-ballx>0 && PlayerPositions{inc}(1)-ballx<0
          h2 = h - 2*pi;
        elseif j-bally<0 && i-ballx<0 && PlayerPositions{inc}(1)-ballx>0
          h2 = h + 2*pi;
        else
          h2 = h;
        end

        quant{inc}(j,i) = R > (-sqrt(((b).^2).*(1 - ((theta - h2).^2)/r.^2)) + k).*... %-% Graph a semicircle
                              (((1-heaviside(theta - (h2-r)))+heaviside(theta - (h2+r))).*499 + 1);
      end
    end
  end

  quant2 = max(quant{1},quant{2});
  for ink = 3:M
    quant2 = max(quant2,quant{ink});
  end

  if drawShadowValues %-% This will graph the data as an upside-down image.
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








if drawEfficientShadowValues %-%Calculate and display a matrix of coordinates that represent good passing spots, efficiently.
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

  bx = Pos(1);
  by = Pos(2);
  r = 0.25*radiusMultiplier; %-% The radius of the semicircle in the polar coordinate system.
  b = 0; %-% The radius of the semicircle in the Cartesian plane.
  %h = 0;  %-% h is the angle in relation to the ball. It has the range: [-pi/2,+3pi/2)
  k = 0; %-% k is the distance from the ball to the player.
  for inc = 1:M
    px = PlayerPositions{inc}(1);
    py = PlayerPositions{inc}(2);
    k = FUN.Distance([bx,by],[px,py]);
    b = k.*sin(r);

    multiplier = 1/b^2;

    distance = FUN.DistanceToLine2(ecks,why,bx,by,px,py,true);
    %resultMatrix{inc} = b > distance;
    resultMatrix{inc} = max(1 - multiplier.*distance.^2,0.0);
  end

  resultMatrix2 = (1-resultMatrix{1}).*(1-resultMatrix{2});
  for ink = 3:M
    resultMatrix2 = resultMatrix2.*(1-resultMatrix{ink});
  end
  
  if (displayOutput)
    figure(5);
    imshow(flipud(resultMatrix2));
  end
  matrix = resultMatrix2;
end

