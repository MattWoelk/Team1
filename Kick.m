function [CS, Fifo] = Kick( Fifo, TeamCounter, agentIndex, GameMode, BallTrajBackup, PlayerTrajBackup );
%KICK Generates a control signal for the provided player using the
% provided Fifo. The returned CS and Fifo are properly timestamped
% and have all previously executed commands cut out.
% Player's HLSTraj information is set during KICK. It should only be
% manually set if you assign different commands to the robot.
%
% Outputs:
% CS:                  This is the properly formatted and truncated
%                      control signal needed by the simulator
% Fifo:                This is the fifo of all future moves needed
%                      to complete the current kick. This fifo is 
%                      only for the current player.
%
% Inputs:
% Fifo:                This is the fifo of moves we want to format
%                      for use by the simulator. This should only
%                      be the fifo of the current player
% TeamCounter:         This is the number of the current player's 
%                      team.
% agentIndex:          This is the agent number of the current player.
% GameMode:            This is the GameMode variable passed from the
%                      simulator.
% BallTrajBackup:      This is the backup of the BallTraj used in a 
%                      continued kick. If a new kick is being
%                      performed, this does not need to be set as it
%                      was set with CANKICK.
%                 NOTE: There is only one BallTraj per team, so be
%                      careful if multiple agents are running the 
%                      CANKICK function.
% PlayerTrajBackup:    Similar to BallTrajBackup.

global FUN

global M
global BallTraj HLSTraj
global CycleBatch

if exist('BallTrajBackup', 'var') && exist('PlayerTrajBackup')
  BallTraj{TeamCounter} = BallTrajBackup;
  HLSTraj{TeamCounter}{agentIndex} = PlayerTrajBackup;
end

%=% Add time stamping and create control signal
Fifo = FUN.U_TimeStamp(Fifo, GameMode(1));	
[CS, Fifo] = FUN.U_Shorten(Fifo, GameMode(1), CycleBatch);
