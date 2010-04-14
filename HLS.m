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
persistent BallTrajBackup %-% An unchanging matrix of values for the field.
persistent PlayerTrajBackup %-% An unchanging matrix of values for the field.




if isempty(kickoff)
  kickoff = true;
end




CycleBatch = GameMode(4) + GameMode(5);

qDamp  = 1-Environment.BallDampingFactor;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           Initialisation and an alignment have it started               %
%%%%%%%%%%%%%%%%(::  The filling of team data/assigning  ::)%%%%%%%%%%%%%%%
if GameMode(1) == 0

    %%%%%%%%%%%%(::  The initialisation of players' parameters  ::)%%%%%%%%%%%%
    Fifo = cell(1,M);
    PlayerPrediction = cell(1,M);

    %=% These lines are needed to run the tactical planner
    qDampRec = 1 / qDamp;
    qDampMRec = 1 / (1 - qDamp);
    qDampLogRec = 1 / log(qDamp);


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
        PlayerPrediction{i} = repmat([0 0 0 0], 10, 1);
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















if isempty(isPlayerEngaging)
  isPlayerEngaging = false;
end
if isempty(engagingPlayer)
  engagingPlayer = 2;
end
if isempty(hasPossession)
  hasPossession = false;
end
if isempty(currentGoalie)
  currentGoalie = 1;
end
if isempty(matrixField)
  matrixField = FUN.GraphField(false);
end
if isempty(BallTrajBackup)
  BallTrajBackup = [];
end
if isempty(PlayerTrajBackup)
  PlayerTrajBackup = [];
end
persistent PlayerTargets %-% An array of where players want to go.
if isempty(PlayerTargets)
  PlayerTargets{1} = [];
end






%-% NB: What we REALLY want is players to be able to set up shots. So one player would be setting up to kick a ball that ball didn't even have the trajectory yet. Though having the player just moving to the right spot might be just the same. On that note: I'm going to make it calculate where to pass the ball based on where the players are moving to, rather than where they currently are.

for i = 1:M %-% This is just to format TeamOpp{i}.Pos to play nice with GraphShadows
  OpponentTargets{i} = TeamOpp{i}.Pos;
end
matrixShadow = FUN.GraphShadows(OpponentTargets,Ball.Pos,false,1);




%-% IN BOTH STATES, ONE PLAYER GOES AFTER THE BALL WHILE THE OTHERS POSITION THEMSELVES
%=% States are "has possession" and "does not have possession"

%-% set isPlayerEngaging to true if the kicker is in the process of kicking the ball.
isPlayerEngaging = FUN.isKicking(Fifo{engagingPlayer});



%-% Where to pass to:
%-% We may want to change this to not include the kicker.

if isPlayerEngaging
  %-% Determine whether or not we have possession:
  threshold = 0.8;
  if norm(Ball.Pos(1:2) - BallPrediction(10,1:2)) > threshold || ...
      norm(Ball.Pos(3:4) - BallPrediction(10,3:4)) > threshold
    BallInterrupted = true; %-% An opponent (or a goalpost) has contacted the ball.
    %-%disp('Ball interrupted');
  else
    BallInterrupted = false;
    %-%disp('Ball as planned');
  end

  threshold = 0.001;
  if norm(TeamOwn{engagingPlayer}.Pos(1:2) - PlayerPrediction{engagingPlayer}(10, 1:2)) > threshold || ...
      norm(TeamOwn{engagingPlayer}.Pos(3:4) - PlayerPrediction{engagingPlayer}(10, 3:4)) > threshold
    %=% The engaging player has been disrupted by another player (friend or foe) or possibly run into a wall. As a result, the kick he was trying to perform will not work as expected.
    PlayerInterrupted = true;
  else
    PlayerInterrupted = false;
  end

  %-% if kick is not interrupted, tell the engaging player to continue its kick.
  if ~BallInterrupted && ~PlayerInterrupted
    [ControlSignal{engagingPlayer}, Fifo{engagingPlayer}] = FUN.Kick( Fifo{engagingPlayer}, TeamCounter, engagingPlayer, GameMode);
    hasPossession = true;
  else
    Fifo{engagingPlayer} = [];
    BallTraj{TeamCounter} = [-1 -1];

    hasPossession = false;
    isPlayerEngaging = false;
  end
else
  %-% This function could be made much more intelligent as well.
  engagingPlayer = FUN.ChooseChaser(M,Ball,TeamOwn,false); %-% figure out who should kick the ball

  if kickoff
    engagingPlayer = 3;
    kickoff = false;
  end

  if engagingPlayer == currentGoalie
    %-% Define a new goalie.
    currentGoalie = FUN.ClosestToNet(M,TeamOwn,FieldY,currentGoalie);
    %-% Define the new goal back when he's done kicking? (just a little kick-out; maybe no change needed)
    %-% Maybe once a player is done kicking, we see who should be goalie.
  end
end



%-% Tell the players where to position themselves.
if hasPossession
  %-% FOR PLAYERS IN POSSESSION-STATE (who aren't going for the ball)
  %%^&%disp('  ++we have possession');
  for inc = 1:M
    if inc ~= engagingPlayer && inc ~= currentGoalie %-% Engaging Player is going after the ball.
      %-% We want the radius of matrixPlayer to be independent of distance from player.
      %-%   ...and we want to not go through other players to get somewhere.
      %-% Currently it gets a little murky when two players are beside each other, but that's probably okay.
      matrixPlayerGo = FUN.GraphShadowsStatic(TeamOwn,inc,false,1);
      matrixGo = matrixField.*matrixShadow.*matrixPlayerGo;
      [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixGo);
      %-%figure(4);
      %-%imshow(flipud(matrixGo));

      %-% Send player to highPoint (coord: xVal, yVal)
      garbage = []; %-% Do not use the Fifo that GoHere gives us.
      [ControlSignal{inc}, garbage] = FUN.GoHere(Fifo{inc},inc,[xVal yVal], TeamOwn, GameMode, CycleBatch, TeamCounter);
      PlayerTargets{inc} = [xVal yVal];
    end
  end
else
  %-% FOR PLAYERS IN NON-POSSESSION-STATE (who aren't going for the ball)
  %%^&%disp('  oo-we dont have possession');
  for inc = 1:M
    if inc ~= engagingPlayer && inc ~= currentGoalie
      %-% NB: We should have players go between opponents if we want to intercept passes.
      matrixPlayerGo = FUN.GraphShadowsStatic(TeamOwn,inc,false,1);
      matrixGoN = (1-matrixField).*matrixPlayerGo;
      [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixGoN);

      %$ Send player to highPoint (coord: xVal, yVal)
      garbage = []; %-% Do not use the Fifo that GoHere gives us.
      [ControlSignal{inc}, garbage] = FUN.GoHere(Fifo{inc},inc,[xVal yVal], TeamOwn, GameMode, CycleBatch, TeamCounter);
      PlayerTargets{inc} = [xVal yVal];
    end
  end

  %-%figure(4);
  %-%imshow(flipud(matrixGoN));
end




%-% Tell the goalie to move to an ideal spot on the field
goalieTarget = FUN.Goalie(Ball,TeamOpp);
garbage = []; %-% Do not use the Fifo that GoHere gives us.
[ControlSignal{currentGoalie}, garbage] = FUN.GoHere(Fifo{currentGoalie},currentGoalie,goalieTarget,TeamOwn, GameMode, CycleBatch, TeamCounter);

PlayerTargets{currentGoalie} = goalieTarget;





if ~isPlayerEngaging
  matrixPlayer = FUN.GraphPlayerPositions(PlayerTargets,Ball.Pos,false,1,engagingPlayer);
  matrixKick = max(matrixField,1-matrixPlayer) .* matrixShadow;
  [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixKick);

  MinKickVel = 1.6; %-% These are currently nearly arbitrary.
  MaxKickVel = 1.6;

  %-% This canKick is to get an estimate of how long it will take to engage the ball
  [canKick, FifoTemp, BallTrajBackup, PlayerTrajBackup]=FUN.canKick(MinKickVel, MaxKickVel, TeamOwn{engagingPlayer}, [xVal,yVal], Ball.Pos, TeamCounter, engagingPlayer, GameMode);

  if canKick
    %-% instead of using Ball's position, use the position where the player will engage the ball.
    timeUntilContact = FUN.timeLeftInKick(FifoTemp,GameMode);
    engagePositionMatrix = FUN.BallPrediction(Ball,timeUntilContact,false);
    engagePositionMatrix = flipud(engagePositionMatrix);
    engagePosition = engagePositionMatrix(1,:);

    matrixPlayer = FUN.GraphPlayerPositions(PlayerTargets,engagePosition,false,1,engagingPlayer);
    matrixShadow2 = FUN.GraphShadows(OpponentTargets, engagePosition, false, 1);
    matrixKick = max(matrixField,1-matrixPlayer) .* matrixShadow2;
    [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixKick);

    MinKickVel = 1.6; %-% These are currently nearly arbitrary.
    MaxKickVel = 1.6;

    %-% This canKick is used to create the player's Fifo.
    [canKick, FifoTemp, BallTrajBackup, PlayerTrajBackup]=FUN.canKick(MinKickVel, MaxKickVel, TeamOwn{engagingPlayer}, [xVal,yVal], Ball.Pos, TeamCounter, engagingPlayer, GameMode);
  end

  %-% If the player can kick, we tell them to. If not, we tell them to chase the ball.
  if canKick
    %Display Values:
    %figure(4);
    %imshow(flipud(matrixKick));
    %figure(5);
    %imshow(flipud(highPoint));
  
    [ControlSignal{engagingPlayer}, Fifo{engagingPlayer}] = FUN.Kick( FifoTemp, TeamCounter, engagingPlayer, GameMode );
    %$ Change State????(set state?)
  else
    %-% Reset the Fifo and BallTraj:
    Fifo{engagingPlayer} = [];
    BallTraj{TeamCounter} = [-1 -1];
    %$ Run to the ball. NB: we can make this more intelligent.
    garbage = []; %-% Do not use the Fifo that GoHere gives us.
    [ControlSignal{engagingPlayer}, garbage] = FUN.GoHere(Fifo{engagingPlayer}, engagingPlayer, [Ball.Pos(1),Ball.Pos(2)],TeamOwn, GameMode, CycleBatch, TeamCounter);
    %$ Change State????(set state?)
  end
  PlayerTargets{engagingPlayer} = [];
end





%=% This establishes a prediction for the future state of the ball and any kicking player.
%=% These values are used in the next HLS call to determine if a kick has been interrupted.
BallPrediction = FUN.BallPrediction(Ball,10); 
for i=1:M
  PlayerPrediction{i} = FUN.PlayerPrediction( TeamOwn{i}, Fifo{i}, 10, GameMode );
end





%-% NB: when engagingPlayer is within 10, calculate matrices.
%-% NB: OR when engagingPlayer is more than 10 units away, keep calculating where the kick should be.
%-% NB: EVEN BETTER would be instead of 10 units, a certain amount of cycles before ball contact.
%-% NB: change state when the ball is far away from our net and it's been moving away from us for a long amount of time. Change back when opponent hits the ball.
