%=% The HLS function is the High-Level Strategy.
%=% This function receives all the environment parameters and returns the control signals for the team.

function ControlSignal = HLS( TeamOwn, TeamOpp, Ball, GameMode, TeamCounter )
global FUN Score
global Environment Team M FieldX FieldY qDamp
global BallTraj HLSTraj                         %=% These variables are used to draw the ball and players' trajectories 
global CycleBatch

%=% These are used for the tactical planner. 
global qDampRec qDampMRec qDampLogRec

%=% We want to remember the previous queued up commands
persistent Fifo BallPrediction PlayerPrediction

persistent kickoff %-% Whether we are starting a new round.
persistent isPlayerEngaging %-% tells whether a player is currently in the process of kicking the ball.
persistent engagingPlayer %-% tells which player is currently going after the ball.
persistent hasPossession %-% a boolean that states whether we are in possession state or not.
persistent currentGoalie %-% the player which is currently acting as the goalie
persistent matrixField %-% An unchanging matrix of values for the field.
persistent matrixFieldMir %-% An unchanging matrix of values for the field (including top & bottom mirrors)
persistent BallTrajBackup %-% A backup of BallTraj
persistent PlayerTrajBackup %-% A backup of PlayerTraj
persistent PlayerTargets %-% An array of where players want to go.
persistent engagePosition %-% Stores where the kicker is going to contact the ball.
persistent canKick %-% Stores whether a player can kick the ball or not.
persistent kickertarget %-% Stores the spot where the kicker is going to kick the ball.
persistent matrixMoveOut  %-% A black semi-circle in our net.
persistent matrixDontCamp %-% A black semi-circle in the opponent's net.
persistent matrixPlayersGoStatic %-% A field matrix for movement calculations.
persistent firstCalculation %-% so that the first kick calculation for each kick is to clear the ball.
persistent rebounds %-% VERY IMPORTANT: This sets the ability for players to calculate rebound when taking shots. (slows down the game)
persistent predictCycles %=% The number of cycles in the future we want to predict for the ball's position

persistent dimmer %=% When discouraging backwards kicks, we multiple the field behind the kicker by this
persistent ballSpeedLog




CycleBatch = GameMode(4) + GameMode(5);

qDamp  = 1-Environment.BallDampingFactor;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%=%                      SIMULATION INITIALIZATION                      %=%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if GameMode(1) == 0

  Fifo = cell(1,M);
  PlayerPrediction = cell(1,M);

  %=% These lines are needed to run the tactical planner
  qDampRec = 1 / qDamp;
  qDampMRec = 1 / (1 - qDamp);
  qDampLogRec = 1 / log(qDamp);
  %-% Initialize all our persistent variables
  isPlayerEngaging = false;
  engagingPlayer = 2;
  hasPossession = false;
  currentGoalie = 1;
  matrixField = FUN.GraphField();
  matrixFieldMir = FUN.GraphMirror(matrixField);
  BallTrajBackup = [];
  PlayerTrajBackup = [];
  PlayerTargets{1} = [];
  matrixMoveOut = FUN.GraphMoveOut();
  matrixDontCamp = FUN.GraphDontCamp();
  matrixSides = FUN.GraphSides();
  matrixPlayersGoStatic = (1-matrixField).*matrixMoveOut.*matrixSides;
  firstCalculation = true;
  rebounds = false; %-% VERY IMPORTANT: This sets the ability for players to calculate rebounds when taking shots. (slows down the game)

  %=% When discouraging backwards kicks, we multiple the field behind the kicker by this
  %=% the lower this number (between 0 and 1) the less likely we are to kick backwards
  dimmer = 0.9;

  ballSpeedLog = zeros(0,2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%=%                      KICKOFF INITIALIZATION                         %=%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if GameMode(2) == 2                     

  TeamOwn = FUN.HLS_SetUp(TeamOwn);
  ControlSignal=cell(1,Team.NoofTeamMember);
  for i= 1:Team.NoofTeamMember
    ControlSignal{i} = FUN.TP_HARD( TeamOwn, TeamOpp, CycleBatch, i );
    ControlSignal{i} = [GameMode(1) + (1:CycleBatch)', ControlSignal{i}(:,:)];  % timestamps?
    Fifo{i} = [];
    PlayerPrediction{i} = repmat(zeros(1,4), 10, 1);
  end
  %-% BallTraj is necessary to draw what the players are going to do.
  BallTraj{TeamCounter} = [-1 -1];
  for i=1:Team.NoofTeamMember
    HLSTraj{TeamCounter}{i}.data  = [TeamOwn{i}.Pos; TeamOwn{i}.Target];
    HLSTraj{TeamCounter}{i}.tst   = 0;
    HLSTraj{TeamCounter}{i}.index = 1;
  end

  kickoff = true;

  %=% This initializes the ball prediction variable
  predictCycles = 20;
  BallPrediction = repmat([FieldX/2, FieldY/2, 0, 0], predictCycles, 1);

  return
end











%=% MinKickVel = 1.6; %-% These are currently nearly arbitrary.
%=% MaxKickVel = 2.6; %-% They represent the speed which all our kicks will be.

%=% 1.6 works decently but a dynamic choice for kick speed would allow greater versitility
%=% TP_Kick (and thus canKick, our wrapper for it) will find the first working kick within a range, but it is slow and not necessarily the best kick speed
%=% we want to use the ball's current speed and use that to map a new kicking velocity on a different range

RangeKickVel = 0; %=% If we want TP_Kick to try a wider range of speeds, turn this value up
ballSpeed = norm(Ball.Pos(3:4));
MidKickVel = ballSpeed*0.35 + 1.3;
MinKickVel = MidKickVel - RangeKickVel/2;
MaxKickVel = MidKickVel + RangeKickVel/2;







for i = 1:M %-% This is just to format TeamOpp{i}.Pos to play nice with GraphShadows
  OpponentTargets{i} = TeamOpp{i}.Pos;
end
matrixShadow = FUN.GraphShadows(OpponentTargets,Ball.Pos,false,1);
if rebounds
  matrixShadowMir = FUN.GraphShadowsMir(OpponentTargets,Ball.Pos,false,1);
end
%-%FUN.DisplayMatrix(FUN.GraphShadowsMir(OpponentTargets,Ball.Pos,false,1),4);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-% Set states. (BallInterrupted, PlayerInterrupted, safeDistanceAway) %-%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-% set isPlayerEngaging to true if the kicker is in the process of kicking the ball.
isPlayerEngaging = FUN.isKicking(Fifo{engagingPlayer});
dontPickGoalie = false;

safeDistanceAway = false;
threshold = 0.8;
%-% This ignores the different in the ball's velocity
if norm(Ball.Pos(1:2) - BallPrediction(10,1:2)) > threshold
  BallInterrupted = true; %-% An opponent (or a goalpost) has contacted the ball.
  firstCalculation = true;
else
  BallInterrupted = false;
  if Ball.Pos(3) > 0 && Ball.Pos(1) > FieldX/2
    %-% If the ball is far away and has been moving away predictably then set hasPossession.
    safeDistanceAway = true;
  end
end

threshold = 0.01;

if norm(TeamOwn{engagingPlayer}.Pos(1:2) - PlayerPrediction{engagingPlayer}(10, 1:2)) > threshold || ...
    norm(TeamOwn{engagingPlayer}.Pos(3:4) - PlayerPrediction{engagingPlayer}(10, 3:4)) > threshold
  %=% The engaging player has been disrupted by another player (friend or foe) or possibly run into a wall. As a result, the kick he was trying to perform will not work as expected.
  PlayerInterrupted = true;
else
  PlayerInterrupted = false;
end

if ~FUN.canGetThereFirst(TeamOpp,TeamOwn{engagingPlayer}.Pos,TeamOwn{engagingPlayer}.Type,Ball.Pos,17)
  hasPossession = false;
  if engagingPlayer == currentGoalie
    isPlayerEngaging = false;
    Fifo{currentGoalie} = [];
    BallTraj{TeamCounter} = [-1 -1];
  end
end






%-% If someone is already engaging the ball, see if they're still being successful:
if isPlayerEngaging
  if (~BallInterrupted && ~PlayerInterrupted)
    [ControlSignal{engagingPlayer}, Fifo{engagingPlayer}] = FUN.Kick( Fifo{engagingPlayer}, TeamCounter, engagingPlayer, GameMode);
    hasPossession = true;
  else
    Fifo{engagingPlayer} = [];
    BallTraj{TeamCounter} = [-1 -1];

    isPlayerEngaging = false;
    hasPossession = false;
  end
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-% Decide who should engage the ball %-%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isPlayerEngaging
  %-% Keep state after someone kicks the ball until it is interrupted.
  if BallInterrupted
    hasPossession = false;
  end

  previousEngagingPlayer = engagingPlayer;
  if ~FUN.canGetThereFirst(TeamOpp, TeamOwn{currentGoalie}.Pos, TeamOwn{currentGoalie}.Type, Ball.Pos, 17) %=% if the goalie cannot get to the ball before an opponent, do not let him leave the net
    engagingPlayer = FUN.ChooseChaser2(Ball,TeamOwn,currentGoalie); %-% figure out who should kick the ball
  else
    engagingPlayer = FUN.ChooseChaser2(Ball,TeamOwn); %-% figure out who should kick the ball
  end

  if previousEngagingPlayer ~= engagingPlayer
    firstCalculation = true;
  end

  if engagingPlayer == currentGoalie && ~hasPossession
    %-% Define a new goalie. Maybe.
    currentGoalie = FUN.ClosestToNet(M,TeamOwn,FieldY);
    %-% NB: Set back when he's done kicking? (just a little kick-out; maybe no change needed)
  end

  %=% NB: should be fixed to account for larger/smaller teams. I think this was done as a crude patch for when the ball is not moving which happens primarily at kickoff. Since this could happen at times other than kickoff, this might want to be accounted for as well.
  if kickoff
    engagingPlayer = 3;
    kickoff = false;
  end
end







if safeDistanceAway
  hasPossession = true;
end



    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-% Tell the players where to position themselves. %-%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if hasPossession
  %-% FOR PLAYERS IN POSSESSION-STATE (who aren't going for the ball)
  for inc = 1:M
    if inc ~= engagingPlayer && inc ~= currentGoalie %-% Engaging Player is going after the ball.
      %-% NB: we want to not go through other players to get somewhere.
        %=% ^Perhaps a dim shadow behind other players could fix this?
      %-% Currently matrixGo gets a little murky when two players are beside each other, but that's probably okay.
      matrixPlayerGo = FUN.GraphShadowsStatic(TeamOwn,inc,false,1);
      matrixGo = matrixField.*matrixShadow.*matrixPlayerGo;
      matrixGo = matrixGo.*matrixDontCamp;

      [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixGo);

      %-% Send player to highPoint (coord: xVal, yVal)
      garbage = []; %-% Do not use the Fifo that GoHere gives us.
      [ControlSignal{inc}, garbage] = FUN.GoHere(inc,[xVal yVal], TeamOwn, GameMode, CycleBatch, TeamCounter);
      PlayerTargets{inc} = [xVal yVal];
    end
  end
else
  %-% FOR PLAYERS IN NON-POSSESSION-STATE (who aren't going for the ball)
  for inc = 1:M
    if inc ~= engagingPlayer && inc ~= currentGoalie
      %-% NB: We should have players go between opponents if we want to intercept passes.
      matrixPlayerGo = FUN.GraphShadowsStatic(TeamOwn,inc,false,1);
      matrixGoN = matrixPlayersGoStatic.*matrixPlayerGo.*matrixDontCamp;
      %---------%if FUN.isBallGoingForGoal(Ball)
      [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixGoN);

      %-% Send player to highPoint (coord: xVal, yVal)
      garbage = []; %-% Do not use the Fifo that GoHere gives us.
      [ControlSignal{inc}, garbage] = FUN.GoHere(inc,[xVal yVal], TeamOwn, GameMode, CycleBatch, TeamCounter);
      PlayerTargets{inc} = [xVal yVal];
    end
  end
end




%-% Tell the goalie to move to an ideal spot on the field
if engagingPlayer ~= currentGoalie
  %-% if the ball is on the way to the net, get in the way!
  [onTheWay wallIntersection] = FUN.isBallGoingForOurGoal(Ball);
  if onTheWay
    %-% Find out where the ball will intersect our net    %=% <-- I think this comment should read: Find out where the goalie can intercept the ball quickest
    intersectionPoint = FUN.DistanceToLine(Ball.Pos(1),Ball.Pos(2),0,wallIntersection,TeamOwn{currentGoalie}.Pos(1),TeamOwn{currentGoalie}.Pos(2),false);
    goalieTarget = intersectionPoint(1:2);
    %=% NB: might want goalie to start moving along the ball trajectory once it is on the line (intersectionPoint(3) < ball radius, for instance)
    %=%     move towards ball to get it away from our net? move towards our goal to slow the ball upon contact? attempt a slower/faster kick? only intercept if ball is close?
  else
    goalieTarget = FUN.Goalie(Ball,TeamOpp);
  end
  garbage = []; %-% Do not use the Fifo that GoHere gives us.
  [ControlSignal{currentGoalie}, garbage] = FUN.GoHere(currentGoalie,goalieTarget,TeamOwn, GameMode, CycleBatch, TeamCounter);

  PlayerTargets{currentGoalie} = goalieTarget;
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-% Setting up the kick %-%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isPlayerEngaging
  if ~hasPossession && firstCalculation
    %-% the first calculated place to kick doesn't take into account our players. 
    %-% - This makes kicks that are not able to be calculated more than once "clear the ball" 
    %-% - rather than kick to a place where our players are going defensively.
    %-% - hasPossession is used because we will only need to do this when we don't have ball control.
    %if rebounds
    %  matrixKick = matrixFieldMir .* matrixShadowMir .* FUN.GraphMirror(matrixMoveOut);
    %else
      matrixDimmer = FUN.GraphDimmer(TeamOwn{engagingPlayer}.Pos, dimmer);
      matrixKick = matrixField .* matrixShadow .* matrixMoveOut .* matrixDimmer;
    %end
  else
    %if rebounds
    %  matrixPlayer = FUN.GraphPlayerPositionsMir(PlayerTargets,Ball.Pos,false,1,engagingPlayer);
    %  matrixKick = max(matrixFieldMir,1-matrixPlayer) .* matrixShadowMir .* FUN.GraphMirror(matrixMoveOut);
    %else
      matrixPlayer = FUN.GraphPlayerPositions(PlayerTargets,Ball.Pos,false,1,engagingPlayer);
      matrixDimmer = FUN.GraphDimmer(TeamOwn{engagingPlayer}.Pos, dimmer);
      matrixKick = max(matrixField,1-matrixPlayer) .* matrixShadow .* matrixMoveOut .* matrixDimmer;
    %end
  end
  [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixKick);
  yVal = yVal - FieldY; %-% This is because graphs cannot have negative indices, so the mirrored graphs are one field-height too high.

  %-% This canKick is to get an estimate of how long it will take to engage the ball
  [canKick, FifoTemp, BallTrajBackup, PlayerTrajBackup]=FUN.canKick(MinKickVel, MaxKickVel, TeamOwn{engagingPlayer}, [xVal,yVal], Ball.Pos, TeamCounter, engagingPlayer, GameMode);

  if canKick
    %-% instead of using Ball's position, use the position where the player will engage the ball.
    timeUntilContact = FUN.timeLeftInKick(FifoTemp,GameMode);
    engagePositionMatrix = FUN.BallPrediction(Ball.Pos,timeUntilContact,false);
    %=% NB: these two lines can probably be replaced to improve speed; use "end" instead of "1" and no flip is needed
    engagePositionMatrix = flipud(engagePositionMatrix);
    engagePosition = engagePositionMatrix(1,:);

    %-% PlayerFuture gives the positions where the ball will be able to meet up with the players when kicked.
    PlayerFuture = FUN.IntersectPoints(TeamOwn,PlayerTargets,engagePosition,MaxKickVel,timeUntilContact,engagingPlayer,Fifo,GameMode);
    if rebounds
      matrixPlayer = FUN.GraphPlayerPositionsMir(PlayerFuture,engagePosition,false,1,engagingPlayer);
      matrixShadow2 = FUN.GraphShadowsMir(OpponentTargets, engagePosition, false, 2);
    else
      matrixPlayer = FUN.GraphPlayerPositions(PlayerFuture,engagePosition,false,1,engagingPlayer);
      matrixShadow2 = FUN.GraphShadows(OpponentTargets, engagePosition, false, 2);
    end
    if firstCalculation
      if rebounds
        matrixDimmer = FUN.GraphMirror(FUN.GraphDimmer(TeamOwn{engagingPlayer}.Pos, dimmer));
        matrixKick = matrixFieldMir .* matrixShadow2 .* FUN.GraphMirror(matrixMoveOut) .* matrixDimmer;
      else
        matrixDimmer = FUN.GraphDimmer(TeamOwn{engagingPlayer}.Pos, dimmer);
        matrixKick = matrixField .* matrixShadow2 .* matrixMoveOut .* matrixDimmer;
      end
    else
      if rebounds
        matrixDimmer = FUN.GraphMirror(FUN.GraphDimmer(TeamOwn{engagingPlayer}.Pos, dimmer));
        matrixKick = max(matrixFieldMir,1-matrixPlayer) .* matrixShadow2 .* FUN.GraphMirror(matrixMoveOut) .* matrixDimmer;
      else
        matrixDimmer = FUN.GraphDimmer(TeamOwn{engagingPlayer}.Pos, dimmer);
        matrixKick = max(matrixField,1-matrixPlayer) .* matrixShadow2 .* matrixMoveOut .* matrixDimmer;
      end
    end
    [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixKick);
    if rebounds
      yVal = yVal - FieldY; %-% This is because graphs cannot have negative indices, so the mirrored graphs are one field-height too high.
    end

    %-% This canKick is used to create the player's Fifo.
    [canKick, FifoTemp, BallTrajBackup, PlayerTrajBackup]=FUN.canKick(MinKickVel, MaxKickVel, TeamOwn{engagingPlayer}, [xVal,yVal], Ball.Pos, TeamCounter, engagingPlayer, GameMode);
    kickertarget = [xVal,yVal];
  end
else
  %-% A player is engaging, so we tell them to reevaluate until they're 30 cycles from their kick.
  timeUntilContact = FUN.timeLeftInKick(Fifo{engagingPlayer},GameMode);
  if timeUntilContact > 31
    %-% PlayerFuture gives the positions where the ball will be able to meet up with the players when kicked.
    PlayerFuture = FUN.IntersectPoints(TeamOwn,PlayerTargets,engagePosition,MaxKickVel,timeUntilContact,engagingPlayer,Fifo,GameMode);
    if rebounds
      matrixPlayer = FUN.GraphPlayerPositionsMir(PlayerFuture,engagePosition,false,1,engagingPlayer);
      matrixShadow2 = FUN.GraphShadowsMir(OpponentTargets, engagePosition, false, 2);
      matrixDimmer = FUN.GraphMirror(FUN.GraphDimmer(TeamOwn{engagingPlayer}.Pos, dimmer));
      matrixKick = max(matrixFieldMir,1-matrixPlayer) .* matrixShadow2 .* FUN.GraphMirror(matrixMoveOut) .* matrixDimmer;
    else
      matrixPlayer = FUN.GraphPlayerPositions(PlayerFuture,engagePosition,false,1,engagingPlayer);
      matrixShadow2 = FUN.GraphShadows(OpponentTargets, engagePosition, false, 2);
      matrixDimmer = FUN.GraphDimmer(TeamOwn{engagingPlayer}.Pos, dimmer);
      matrixKick = max(matrixField,1-matrixPlayer) .* matrixShadow2 .* matrixMoveOut .* matrixDimmer;
    end
    [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixKick);
    if rebounds
      yVal = yVal - FieldY; %-% This is because graphs cannot have negative indices, so the mirrored graphs are one field-height too high.
    end

    %-% This canKick is used to create the player's Fifo.
    [canKick, FifoTemp, BallTrajBackup, PlayerTrajBackup]=FUN.canKick(MinKickVel, MaxKickVel, TeamOwn{engagingPlayer}, [xVal,yVal], Ball.Pos, TeamCounter, engagingPlayer, GameMode);
    kickertarget = [xVal,yVal];
  else
    FifoTemp = Fifo{engagingPlayer};
  end
end

%=% debugging display for dynamic kicking speed
%=%disp('.');
%=%disp('.');
%=%disp('Ball speed output');
%=%disp('Ball speed:');
%=%disp(norm(Ball.Pos(3:4)));
%=%disp('Attempted kick speed:');
%=%disp(MinKickVel);
%=%disp('canKick:');
%=%disp(canKick);
%=%ballSpeedLog = [ballSpeedLog; norm(Ball.Pos(3:4)), canKick];
%=%disp(max(ballSpeedLog(:,1)));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-% Kicking (and moving if unable to kick) %-%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-% If the engaging player can kick, we tell them to. If not, we tell them to chase the ball.
if canKick
  firstCalculation = false;
  [ControlSignal{engagingPlayer}, Fifo{engagingPlayer}] = FUN.Kick( FifoTemp, TeamCounter, engagingPlayer, GameMode );
  %-% NB: Change State????(set state?)
end
if ~canKick
  %-% Tell the goalie to move to an ideal spot on the field
  if engagingPlayer == currentGoalie
    %-% if the ball is on the way to the net, get in the way!
    hasPossession = false;
    [onTheWay wallIntersection] = FUN.isBallGoingForOurGoal(Ball);
    if onTheWay
      %-% Find out where the ball will intersect our net
      intersectionPoint = FUN.DistanceToLine(Ball.Pos(1),Ball.Pos(2),0,wallIntersection,TeamOwn{currentGoalie}.Pos(1),TeamOwn{currentGoalie}.Pos(2),false);
      goalieTarget = intersectionPoint(1:2);
    else
      goalieTarget = FUN.Goalie(Ball,TeamOpp);
    end
    garbage = []; %-% Do not use the Fifo that GoHere gives us.
    [ControlSignal{currentGoalie}, garbage] = FUN.GoHere(currentGoalie,goalieTarget,TeamOwn, GameMode, CycleBatch, TeamCounter);

    PlayerTargets{currentGoalie} = goalieTarget;
  else
    %-% Reset the Fifo and BallTraj:
    Fifo{engagingPlayer} = [];
    BallTraj{TeamCounter} = [-1 -1];

    %-% Tell player to intersect the ball and block it UNLESS the ball is headed toward the opposition's net.
    %-% NB: This should be improved.
    %=% if a player is blocking a shot and is within N cycles of contact with the ball, move over slightly
    pointOfContact = BallPrediction(15,1:2);

    %=% NB: the condition for making a player move out of the way might be able to use some improvement still. Players should be moved to an intelligent location.
    if FUN.isBallGoingForGoal(Ball) && (norm(pointOfContact - TeamOwn{engagingPlayer}.Pos(1:2)) < 20) %=% Ball.Pos(1) > FieldX/2 <= Matt's
      xpos = FieldX.*0.9;
      if Ball.Pos(2) > TeamOwn{engagingPlayer}.Pos(2)
        ypos = FieldY.*0.1;
      else
        ypos = FieldY.*0.9;
      end
    else
      [xpos, ypos, cyc] = FUN.Intersection(TeamOwn{engagingPlayer}.Pos,TeamOwn{engagingPlayer}.Type,Ball.Pos,0);
    end
    garbage = []; %-% Do not use the Fifo that GoHere gives us.
    [ControlSignal{engagingPlayer}, garbage] = FUN.GoHere(engagingPlayer, [xpos,ypos],TeamOwn, GameMode, CycleBatch, TeamCounter);
    %-% NB: Change State????(set state?)
  end
end
PlayerTargets{engagingPlayer} = [];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-% Set up Ball and Player Prediction for the next 'predictCycles' cycles %-%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%=% This establishes a prediction for the future state of the ball and any kicking player.
%=% These values are used in the next HLS call to determine if a kick has been interrupted.
BallPrediction = FUN.BallPrediction(Ball.Pos,predictCycles); 
%-% plan for the kicker's contact with the ball as well.
if canKick
  timeUntilContact = FUN.timeLeftInKick(Fifo{engagingPlayer},GameMode);
  if timeUntilContact <= predictCycles
    %-% The purpose of this section is to correct BallPrediction to account for when our players kick the ball.
    engagePositionMatrix = FUN.BallPrediction(Ball.Pos,timeUntilContact,false);
    engagePositionMatrix = flipud(engagePositionMatrix);
    engagePosition = engagePositionMatrix(1,:);
    maxvel = MinKickVel; %-% Now that we're using a range of possible speeds, this doesn't work.
    delx =  engagePosition(1) - kickertarget(1);
    dely =  engagePosition(2) - kickertarget(2);
    velx = sqrt(maxvel.^2./(1+(dely.^2/delx.^2)));
    vely = sqrt(maxvel.^2 - velx.^2);
    %-% This doesn't make the velocities completely correctly, but it's okay because we don't check for them.
    targetVector = [-velx -vely];
    fakeBall.Pos = [engagePosition(1:2) targetVector];
    reflectPre = FUN.BallPrediction(fakeBall.Pos,predictCycles+1-timeUntilContact);
    reflectPreSize = size(reflectPre);
    BallPrediction = [BallPrediction(1:(timeUntilContact-1),:);reflectPre(1:reflectPreSize(1),:)];
  end
end

for i=1:M
  PlayerPrediction{i} = FUN.PlayerPrediction( TeamOwn{i}.Pos, Fifo{i}, 10, GameMode );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-% Notes for possible further improvements %-%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-% Players need much bigger radii so that they don't go near each other. (Maybe? Maybe not.)
%-% If a player is going to kick the ball AND no opponent can get there first, THEN change state. (not currently a visible issue.)
%----------------------------------------%
%-% Make the players actually get out of the way when the ball is heading toward their net. (It's close right now.)

%-% Just moving to where the ball is when we can't kick it is turning into a very dangerous (and stupid) thing.
%-%  - players will go toward the ball even when it means scoring on ourselves.
%-%  - maybe have players run between the ball and the net when they're near our goal. (might be more difficult than it sounds)
%-%  - maybe have players position themselves instead when ball's near our goal. (not a true fix)

%-% Perhaps include a timeout for how long between passes the ball is still "in our control" (so that dumb teams won't affect us as much).
%-% Using rebounds off of the sides of the field when determining how to shoot.

%-% Increase goalie winduptime delay
%-% Get players' default positions to be closer to the center of the field.
%-% Players need much bigger radiuses so that they don't go near eachother.
%-% Current biggest folly: positioning.
 
%-% If a player is going to kick the ball AND no opponent can get there first, THEN change state




% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
