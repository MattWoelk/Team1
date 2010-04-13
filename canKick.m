function [CanKick, Fifo, BallTrajBackup, PlayerTrajBackup] = canKick( MinKickVel, MaxKickVel, Player, Target, BallPos, TeamCounter, agentIndex, GameMode);
%CANKICK Generates a set of control signals for the provided player
% and determines whether that player is able to perform a kick from
% their current location on the field.
%
% Outputs:
% CanKick:             Boolean. This will be 0 if we are not able to
%                      initiate kick from the current pos.
% Fifo:                The set of control signals for the new kick.
%                      This is the fifo for the current player only.
% BallTrajBackup:      This is a backup of the previous BallTraj.
%                      The use of TP_KICK overwrites the previous
%                      value which is needed for properly displaying 
%                      a continued kick. This needs to be passed to
%                      KICK if continuing a previous kick.
%                 NOTE: There is only one BallTraj per team, so be
%                      careful if multiple agents are running the 
%                      canKick function.
% PlayerTrajBackup:    Similar to BallTrajBackup.
% 
% Inputs:
% MinKickVel:          This is the minimum speed we want the ball to
%                      have when we kick it.
% MaxKickVel:          This is the maximum speed we want the ball to
%                      have when we kick it.
%                 NOTE: Having a wide range of values between the
%                      above inputs will cause TP_KICK to be quite
%                      slow. Ideally the same value should be passed
%                      for both of these inputs.
% Player:              This is the player we want to make the kick.
%                      For instance, pass TeamOwn{agentIndex}.
% Target:              This is the X and Y value of our kick target.
%                      For example, if we want to kick into the goal,
%                      use Target = [150, 50].
% BallPos:             This is the ball's position and velocity.
% TeamCounter:         This is the team number of the current player.
% agentIndex:          This is the agent number of the current player.
% GameMode:            This is the GameMode variable passed from the
%                      simulator. 


global FUN

global BallTraj HLSTraj

BallTrajBackup = BallTraj{TeamCounter};
PlayerTrajBackup = HLSTraj{TeamCounter}{agentIndex};

[Fifo, BallPosPlanned, CyclePlanned] = FUN.TP_Kick(MinKickVel, MaxKickVel, Player, Target, BallPos, TeamCounter, agentIndex);

if isempty(Fifo)
  CanKick = 0;
else
  CanKick = 1;
end

Fifo = FUN.U_TimeStamp(Fifo, GameMode(1));	
