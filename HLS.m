%function is responsible for high-level strategy. Receives all the
%environment parameters and outputs the control signal

function ControlSignal = HLS( TeamOwn, TeamOpp, Ball, GameMode, TeamCounter )
global FUN Score

global Environment Team M FieldX FieldY qDamp
global BallTraj HLSTraj                         % is needed for drawing: the route of a ball and the robots planned trajektóriái [=.Target*]
global CycleBatch

%=% These are used for the tactical planner. 
global qDampRec qDampMRec qDampLogRec

%=% We want to remember the previous queued up commands
persistent Fifo BallPrediction PlayerPrediction

persistent kickoff 
persistent isPlayerEngaging %-% tells whether a player is currently in the process of kicking the ball.
persistent engagingPlayer %-% tells which player is currently going after the ball.
persistent hasPossession %-% a boolean that states whether we are in possession state or not.
persistent currentGoalie %-% the player which is currently acting as the goalie
persistent matrixField %-% An unchanging matrix of values for the field.
persistent BallTrajBackup %-% A backup of BallTraj
persistent PlayerTrajBackup %-% A backup of PlayerTraj
persistent PlayerTargets %-% An array of where players want to go.
persistent engagePosition %-% Stores where the kicker is going to contact the ball.
persistent canKick %-% Stores whether a player can kick the ball or not.
persistent justKicked %-% Stores whether the ball was contacted between this HLS call and the previous one.
persistent kickertarget %-% Stores the spot where the kicker is going to kick the ball.
persistent matrixMoveOut 
persistent matrixDontCamp
persistent matrixPlayersGoStatic





CycleBatch = GameMode(4) + GameMode(5);

qDamp  = 1-Environment.BallDampingFactor;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           Initialisation and an alignment have it started               %
%%%%%%%%%%%%%%%%(::  The filling of team data/assigning  ::)%%%%%%%%%%%%%%%
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
    BallTrajBackup = [];
    PlayerTrajBackup = [];
    PlayerTargets{1} = [];
    justKicked = false;
    matrixMoveOut = FUN.GraphMoveOut();
    matrixDontCamp = FUN.GraphDontCamp();
    matrixPlayersGoStatic = (1-matrixField).*matrixMoveOut;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            RE-ALLOCATION [fixed-point situation]                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if GameMode(2) == 2                     % 2:positioning manner of playing

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
    BallPrediction = repmat([FieldX/2, FieldY/2, 0, 0], 10, 1);

    return
end




MinKickVel = 1.6; %-% These are currently nearly arbitrary.
MaxKickVel = 1.6;










for i = 1:M %-% This is just to format TeamOpp{i}.Pos to play nice with GraphShadows
  OpponentTargets{i} = TeamOpp{i}.Pos;
end
%-% NB: We might want this to use the result from matrixShadow2 (produced for a kick) so that players go to what WILL be a good position, rather than what is currently a good position.
matrixShadow = FUN.GraphShadows(OpponentTargets,Ball.Pos,false,1);




%-% IN BOTH STATES, ONE PLAYER GOES AFTER THE BALL WHILE THE OTHERS POSITION THEMSELVES
%=% States are "has possession" and "does not have possession"

%-% set isPlayerEngaging to true if the kicker is in the process of kicking the ball.
isPlayerEngaging = FUN.isKicking(Fifo{engagingPlayer});



%-% Determine whether or not we have possession:
safeDistanceAway = false;
threshold = 0.8;
%-% This ignores the different in the ball's velocity
if norm(Ball.Pos(1:2) - BallPrediction(10,1:2)) > threshold
  BallInterrupted = true; %-% An opponent (or a goalpost) has contacted the ball.
else
  BallInterrupted = false;
  if Ball.Pos(3) > 0 && Ball.Pos(1) > FieldX/2
    %-% If the ball is far away and has been moving away predictably then set hasPossession.
    safeDistanceAway = true;
  end
end

threshold = 0.001;
    
if isPlayerEngaging
  if norm(TeamOwn{engagingPlayer}.Pos(1:2) - PlayerPrediction{engagingPlayer}(10, 1:2)) > threshold || ...
      norm(TeamOwn{engagingPlayer}.Pos(3:4) - PlayerPrediction{engagingPlayer}(10, 3:4)) > threshold
    %=% The engaging player has been disrupted by another player (friend or foe) or possibly run into a wall. As a result, the kick he was trying to perform will not work as expected.
    PlayerInterrupted = true;
  else
    PlayerInterrupted = false;
  end

  %-% if kick is not interrupted, tell the engaging player to continue its kick.
  if (~BallInterrupted && ~PlayerInterrupted)
    [ControlSignal{engagingPlayer}, Fifo{engagingPlayer}] = FUN.Kick( Fifo{engagingPlayer}, TeamCounter, engagingPlayer, GameMode);
    hasPossession = true;
  else
    Fifo{engagingPlayer} = [];
    BallTraj{TeamCounter} = [-1 -1];

    if justKicked
      hasPossession = true;
    else
      hasPossession = false;
    end
    isPlayerEngaging = false;
  end
  if safeDistanceAway
    hasPossession = true;
  end
else
  if BallInterrupted
    hasPossession = false;
  elseif safeDistanceAway
    hasPossession = true;
  end
  engagingPlayer = FUN.ChooseChaser2(Ball,TeamOwn); %-% figure out who should kick the ball

  if kickoff
    engagingPlayer = 3;
    kickoff = false;
  end

  if engagingPlayer == currentGoalie
    %-% Define a new goalie. Maybe.
    currentGoalie = FUN.ClosestToNet(M,TeamOwn,FieldY);
    %-% NB: Set back when he's done kicking? (just a little kick-out; maybe no change needed)
    %-% -- Maybe once a player is done kicking, we see who should be goalie.
  end
end



%-% Tell the players where to position themselves.
if hasPossession
  %-% FOR PLAYERS IN POSSESSION-STATE (who aren't going for the ball)
  %-%disp('have possession');
  for inc = 1:M
    if inc ~= engagingPlayer && inc ~= currentGoalie %-% Engaging Player is going after the ball.
      %-% NB: we want to not go through other players to get somewhere.
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
  %-%disp('no possession');
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


  %Display Values:
  %figure(4);
  %if exist('matrixGo','var')
  %  imshow(flipud(matrixGo));
  %elseif exist('matrixGoN','var')
  %  imshow(flipud(matrixGoN));
  %end


%-% Tell the goalie to move to an ideal spot on the field
if engagingPlayer ~= currentGoalie
  goalieTarget = FUN.Goalie(Ball,TeamOpp);
  garbage = []; %-% Do not use the Fifo that GoHere gives us.
  [ControlSignal{currentGoalie}, garbage] = FUN.GoHere(currentGoalie,goalieTarget,TeamOwn, GameMode, CycleBatch, TeamCounter);

  PlayerTargets{currentGoalie} = goalieTarget;
end


matrixPlayer = [];
matrixKick = [];



if ~isPlayerEngaging
  matrixPlayer = FUN.GraphPlayerPositions(PlayerTargets,Ball.Pos,false,1,engagingPlayer);
  matrixKick = max(matrixField,1-matrixPlayer) .* matrixShadow;
  [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixKick);

  %-% This canKick is to get an estimate of how long it will take to engage the ball
  [canKick, FifoTemp, BallTrajBackup, PlayerTrajBackup]=FUN.canKick(MinKickVel, MaxKickVel, TeamOwn{engagingPlayer}, [xVal,yVal], Ball.Pos, TeamCounter, engagingPlayer, GameMode);

  if canKick
    %-% instead of using Ball's position, use the position where the player will engage the ball.
    timeUntilContact = FUN.timeLeftInKick(FifoTemp,GameMode);
    engagePositionMatrix = FUN.BallPrediction(Ball.Pos,timeUntilContact,false);
    engagePositionMatrix = flipud(engagePositionMatrix);
    engagePosition = engagePositionMatrix(1,:);

    %-% PlayerFuture gives the positions where the ball will be able to meet up with the players when kicked.
    PlayerFuture = FUN.IntersectPoints(TeamOwn,PlayerTargets,engagePosition,MaxKickVel,timeUntilContact,engagingPlayer,Fifo,GameMode);
    matrixPlayer = FUN.GraphPlayerPositions(PlayerFuture,engagePosition,false,1,engagingPlayer);
    matrixShadow2 = FUN.GraphShadows(OpponentTargets, engagePosition, false, 1);
    matrixKick = max(matrixField,1-matrixPlayer) .* matrixShadow2;
    [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixKick);

    %-% This canKick is used to create the player's Fifo.
    [canKick, FifoTemp, BallTrajBackup, PlayerTrajBackup]=FUN.canKick(MinKickVel, MaxKickVel, TeamOwn{engagingPlayer}, [xVal,yVal], Ball.Pos, TeamCounter, engagingPlayer, GameMode);
    kickertarget = [xVal,yVal];
  end
else
  %-% A player is engaging, so we tell them to reevaluate when they're 30 cycles from their kick.
  timeUntilContact = FUN.timeLeftInKick(Fifo{engagingPlayer},GameMode);
  if timeUntilContact > 31
    %-%disp('reevaluated');

    %-% PlayerFuture gives the positions where the ball will be able to meet up with the players when kicked.
    PlayerFuture = FUN.IntersectPoints(TeamOwn,PlayerTargets,engagePosition,MaxKickVel,timeUntilContact,engagingPlayer,Fifo,GameMode);
    matrixPlayer = FUN.GraphPlayerPositions(PlayerFuture,engagePosition,false,1,engagingPlayer);
    matrixShadow2 = FUN.GraphShadows(OpponentTargets, engagePosition, false, 1);
    matrixKick = max(matrixField,1-matrixPlayer) .* matrixShadow2;
    [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixKick);

    MinKickVel = 1.6; %-% These are currently nearly arbitrary.
    MaxKickVel = 1.6;

    %-% This canKick is used to create the player's Fifo.
    [canKick, FifoTemp, BallTrajBackup, PlayerTrajBackup]=FUN.canKick(MinKickVel, MaxKickVel, TeamOwn{engagingPlayer}, [xVal,yVal], Ball.Pos, TeamCounter, engagingPlayer, GameMode);
    kickertarget = [xVal,yVal];
  else
    FifoTemp = Fifo{engagingPlayer};
  end
end

  %Display Values:
  %figure(4);
  %if ~isempty(matrixPlayer)
  %  imshow(flipud(matrixPlayer));
  %end

  %Display Values:
  %figure(4);
  %if ~isempty(matrixKick)
  %  imshow(flipud(matrixKick));
  %end

%-% If the engaging player can kick, we tell them to. If not, we tell them to chase the ball.
if canKick
  %Display Values:
  %figure(4);
  %imshow(flipud(matrixKick));
  %figure(5);
  %imshow(flipud(highPoint));
  %if ~isempty(matrixKick)
  %  matrixKick
  %  [val ind] = max(matrixKick);
  %  max(val)
  %  matrixKick(yVal,xVal)
  %end

  if engagingPlayer == currentGoalie
    %-% check to see if we actually should kick! If an opponent can get to the ball before us, we should move to it instead of kick
    %-% the x position and y position are not used
    [garbage1, garbage2, timeTillGKick] = FUN.Intersection(TeamOwn{currentGoalie}.Pos,TeamOwn{currentGoalie}.Type, Ball.Pos, 8);
      %-% 8 is chosen as an offset because that's roughly how long it takes to set up a shot.
    for i = 1:M
      [xpos, ypos, timeTillOKick(i)] = FUN.Intersection(TeamOpp{i}.Pos,TeamOwn{i}.Type,Ball.Pos,0);
        %-% 0 is chosen because we assume the opponent needs no time to wind-up.
    end
    if any(timeTillOKick < timeTillGKick)
      canKick = false;
    end
  end

  [ControlSignal{engagingPlayer}, Fifo{engagingPlayer}] = FUN.Kick( FifoTemp, TeamCounter, engagingPlayer, GameMode );
  %-% NB: Change State????(set state?)
end
if ~canKick
  %-% Tell the goalie to move to an ideal spot on the field
  if engagingPlayer == currentGoalie
    %-% Reset the Fifo and BallTraj:
    Fifo{engagingPlayer} = [];
    BallTraj{TeamCounter} = [-1 -1];

    %-% if the ball is on the way to the net, get in the way!
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
    %-% end
  else
    %-% Reset the Fifo and BallTraj:
    Fifo{engagingPlayer} = [];
    BallTraj{TeamCounter} = [-1 -1];

    %-% Tell player to intersect the ball and block it UNLESS the ball is headed toward the opposition's net.
    if FUN.isBallGoingForGoal(Ball)
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



%=% This establishes a prediction for the future state of the ball and any kicking player.
%=% These values are used in the next HLS call to determine if a kick has been interrupted.
BallPrediction = FUN.BallPrediction(Ball.Pos,10); 
%-% plan for the kicker's contact with the ball as well.
if canKick
  timeUntilContact = FUN.timeLeftInKick(Fifo{engagingPlayer},GameMode);
  if timeUntilContact <= 10
    %-% The purpose of this section is to correct BallPrediction to account for when our players kick the ball.
    justKicked = true;
    engagePositionMatrix = FUN.BallPrediction(Ball.Pos,timeUntilContact,false);
    engagePositionMatrix = flipud(engagePositionMatrix);
    engagePosition = engagePositionMatrix(1,:);
    maxvel = MinKickVel;
    delx =  engagePosition(1) - kickertarget(1);
    dely =  engagePosition(2) - kickertarget(2);
    velx = sqrt(maxvel.^2./(1+(dely.^2/delx.^2)));
    vely = sqrt(maxvel.^2 - velx.^2);
    %-% This doesn't make the velocities completely correctly, but it's okay because we don't check for them.
    targetVector = [-velx -vely];
    fakeBall.Pos = [engagePosition(1:2) targetVector];
    reflectPre = FUN.BallPrediction(fakeBall.Pos,11-timeUntilContact);
    reflectPreSize = size(reflectPre);
    BallPrediction = [BallPrediction(1:(timeUntilContact-1),:);reflectPre(1:reflectPreSize(1),:)];
  end
end
  
for i=1:M
  PlayerPrediction{i} = FUN.PlayerPrediction( TeamOwn{i}.Pos, Fifo{i}, 10, GameMode );
end

%-% NB: Make our team able to be Team2
%-% NB: Make players' GoHere matrices depend on where other players want to go as well. (Not really that important)
%-% Might want to increase the size of the opponent's shadows
%-% Weird things happen when one player gives up on kicking the ball. We think it's a problem in TP_Kick
%disp('-------------------------------------');
%-% Make the players actually get out of the way when the ball is heading toward their net.
%-% Perhaps include a timeout for how long between passes the ball is still "in our control" (so that dumb teams won't affect us as much).

%-% Current: kick to where the player will intersect the ball. (Using IntersectPoints)
