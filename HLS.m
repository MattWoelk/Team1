%function is responsible for high-level strategy. Receives all the
%environment parameters and outputs the control signal

function ControlSignal = HLS( TeamOwn, TeamOpp, Ball, GameMode, TeamCounter )
global FUN Score

global Environment Team M FieldX FieldY qDamp
global BallTraj HLSTraj                         % is needed for drawing: the route of a ball and the robots planned trajektóriái [=.Target*]
persistent TeamOwnSave TeamOppSave % previous Priority, Target... storing state infos
persistent KickParam KICKANGLE
global CycleBatch

%=% These are used for the tactical planner. 
global qDampRec qDampMRec qDampLogRec

%=% We want to remember the previous queued up commands
persistent Fifo kickoff BallPrediction

if isempty(kickoff)
  kickoff = true;
end




CycleBatch = GameMode(4) + GameMode(5);

qDamp  = 1-Environment.BallDampingFactor;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           Initialisation and an alignment have it started               %
%%%%%%%%%%%%%%%%(::  The filling of team data/assigning  ::)%%%%%%%%%%%%%%%
if GameMode(1) == 0

    %%%%%%%%%%%%%%%%%(::  The initialisation of players' parameters  ::)%%%%%%%%%%%%%%%%%
    Fifo = cell(1,M);

    %=% These lines are needed to run the tactical planner
    qDampRec = 1 / qDamp;
    qDampMRec = 1 / (1 - qDamp);
    qDampLogRec = 1 / log(qDamp);

    %=% This initializes the ball prediction variable
    for i = 1:10
      BallPrediction(i, 1:4) = [FieldX/2, FieldY/2, 0, 0];
    end

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
    for i=1:10
        BallPrediction(i, 1:4) = [FieldX/2, FieldY/2, 0, 0];
    end

    return
end










%prePos = FUN.DisplayBallPrediction(Ball,qDamp,FieldX,FieldY);
matrix = FUN.BallPrediction(Ball,20);






persistent isPlayerEngaging %-% tells whether a player is currently in the process of kicking the ball.
if isempty(isPlayerEngaging)
  isPlayerEngaging = false;
end
persistent engagingPlayer %-% tells which player is currently going after the ball.
if isempty(engagingPlayer)
  engagingPlayer = 2;
end
persistent hasPossession %-% a boolean that states whether we are in possession state or not.
if isempty(hasPossession)
  hasPossession = false;
end
persistent currentGoalie %-% the player which is currently acting as the goalie
if isempty(currentGoalie)
  currentGoalie = 1;
end
persistent matrixField %-% An unchanging matrix of values for the field.
if isempty(matrixField)
  matrixField = FUN.GraphField(false);
end
persistent BallTrajBackup %-% An unchanging matrix of values for the field.
if isempty(BallTrajBackup)
  BallTrajBackup = [];
end
persistent PlayerTrajBackup %-% An unchanging matrix of values for the field.
if isempty(PlayerTrajBackup)
  PlayerTrajBackup = [];
end

%-% Determine whether or not we have possession:
threshold = 0.2;
if norm(Ball.Pos(1:2) - BallPrediction(10,1:2)) > threshold || ...
    norm(Ball.Pos(3:4) - BallPrediction(10,3:4)) > threshold
  BallInterrupted = true; %-% An opponent (or a goalpost) has contacted the ball.
  %-%disp('Ball interrupted');
else
  BallInterrupted = false;
  %-%disp('Ball as planned');
end

%-% NB: What we REALLY want is players to be able to set up shots. So one player would be setting up to kick a ball that ball didn't even have the trajectory yet. Though having the player just moving to the right spot might be just the same. On that note: I'm going to make it calculate where to pass the ball based on where the players are moving to, rather than where they currently are.

matrixShadow = FUN.GraphShadows(TeamOpp,Ball,false,1);

%-% IN BOTH STATES, ONE PLAYER GOES AFTER THE BALL WHILE THE OTHERS POSITION THEMSELVES

%$ set isPlayerEngaging to true if the kicker is in the process of kicking the ball.
isPlayerEngaging = FUN.isKicking(Fifo{engagingPlayer});

%-% Where to pass to:
%-% We may want to change this to not include the kicker.

if isPlayerEngaging
  %-% if kick is not interrupted, tell the engaging player to continue its kick.
  if ~BallInterrupted
    [ControlSignal{engagingPlayer}, Fifo{engagingPlayer}] = FUN.Kick( Fifo{engagingPlayer}, TeamCounter, engagingPlayer, GameMode);
    hasPossession = true;
  else
    Fifo{engagingPlayer} = [];
    BallTraj{TeamCounter} = [-1 -1];

    hasPossession = false;
    isPlayerEngaging = false;
  end
end

if ~isPlayerEngaging
  %%^&%disp('no one is engaging');
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

  matrixPlayer = FUN.GraphPlayerPositions(TeamOwn,Ball,false,1);
  matrixKick = max(matrixField,1-matrixPlayer) .* matrixShadow;
  [highPoint,xVal,yVal] = FUN.FindHighestValue(matrixKick);

  MinKickVel = 1.6; %-% These are currently nearly arbitrary.
  MaxKickVel = 1.6;

  %-% See if the chosen player is able to engage the ball.
  [canKick, FifoTemp, BallTrajBackup, PlayerTrajBackup]=FUN.canKick(MinKickVel, MaxKickVel, TeamOwn{engagingPlayer}, [xVal,yVal], Ball.Pos, TeamCounter, engagingPlayer);

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
end



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
    end
  end

  %-%figure(4);
  %-%imshow(flipud(matrixGoN));
end


%-% Tell the goalie to move to an ideal spot on the field
goalieTarget = FUN.Goalie(Ball,TeamOpp);
garbage = []; %-% Do not use the Fifo that GoHere gives us.
[ControlSignal{currentGoalie}, garbage] = FUN.GoHere(Fifo{currentGoalie},currentGoalie,goalieTarget,TeamOwn, GameMode, CycleBatch, TeamCounter);




BallPrediction = FUN.BallPrediction(Ball,10); 
%-% when engagingPlayer is within 10, calculate matrices.
