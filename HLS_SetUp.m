function TeamOwn = HLS_SetUp( TeamOwn );
global FUN
global Team FieldX FieldY TField
persistent xrand yrand

%-% This is to make every game unique
if isempty(xrand)
  xrand(1) = rand(1);
  xrand(2) = rand(1);
  xrand(3) = rand(1);
  xrand(4) = rand(1);
  yrand(1) = rand(1);
  yrand(2) = rand(1);
  yrand(3) = rand(1);
  yrand(4) = rand(1);

  %-% Print off the random variables so that we can reuse them later to reproduce the game.
  xrand
  yrand
end

%-% for the second operand in InitPosMatrix:
%-% 1: x coord
%-% 2: y coord
%-% 3: x coord to make angle
%-% 4: y coord to make angle

%Kezdeti felallas egyvonalban

%-% If there are more than 3 team members then the rest are placed randomly in our side of the field.
InitPosMatrix(1,1)=FieldX*0.1 + FieldX*0.35/Team.NoofTeamMember*(1-1);
InitPosMatrix(2,1)=FieldX*0.33 + xrand(2)*4;
InitPosMatrix(3,1)=FieldX*0.33 + xrand(3)*4;
for i = 4:Team.NoofTeamMember
  InitPosMatrix(i,1)=FieldX/2*rand(1);
end

InitPosMatrix(1,2)=FieldY/2 + yrand(1)*4; %the second term is for slight randomness
InitPosMatrix(2,2)=FieldY/2 + FieldY*0.16 + yrand(2)*4; %-%the last term is for slight randomness
InitPosMatrix(3,2)=FieldY/2 - FieldY*0.16 + yrand(3)*4; %-%the last term is for slight randomness
for i = 4:Team.NoofTeamMember
  InitPosMatrix(i,2)=FieldY*rand(1);
end

for i=1:Team.NoofTeamMember
    InitPosMatrix(i,3)=1;
    InitPosMatrix(i,4)=0;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Action:
%   []  - undefined
%   0   - undefined
%   1   - moving
%   2   - kicking the ball
%   3   - receiving a pass
% TPMode:
%   -1  - TP will not be a call onto the robot, because the full one is
%   found beav.jel(!!) sequence (pl. in case of a shooting player)
%   0   - TP will not be a call onto the robot, drawn drawn dedicated one
%   the robot is at a standstill [locked], all nought beav.jellel, what HLS generates
%   1   - TP_HARD: lineal interpolation the granted trajektóriára
%   [TeamOwn{i}.Target: nx4 dot series]
%   2   - TP_SOFT: obstacle roundabout navigation onto the granted target
for i=1:Team.NoofTeamMember
    TeamOwn{i}.Action          = 1; % moving
    TeamOwn{i}.TPMode          = 1; % HARD -> lin. interpoláció
    TeamOwn{i}.Target          = InitPosMatrix(i,:); % is not needed here to transform, because the beav.jelekhez is needed, own k.rendszerben
    TeamOwn{i}.TargetSpeedTime = zeros(1,size(TeamOwn{i}.Target,1)); % max. speed
    TeamOwn{i}.TargetIndex     = 1; % .target 1. his row counts (but there are not more now)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

