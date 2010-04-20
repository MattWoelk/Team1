function TeamOwn = HLS_SetUp( TeamOwn );
global FUN
global Team FieldX FieldY TField

 
%Kezdeti felallas egyvonalban
for i=1:Team.NoofTeamMember
    InitPosMatrix(i,1)=FieldX*0.1 + FieldX*0.35/Team.NoofTeamMember*(i-1);
    InitPosMatrix(i,2)=FieldY/2;
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


