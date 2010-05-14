function [ControlSignalForPlayer, FifoForPlayer] = GoHere(agentIndex, Target, TeamOwn, GameMode, CycleBatch, TeamCounter)

%-% This function tells a player to go to a location specified in Target.

global FUN HLSTraj

DesiredSpeedTime = 1;
TeamOwn{agentIndex}.Target=[Target 0 0];
[CS,TeamOwn{agentIndex}.Target,TeamOwn{agentIndex}.TargetSpeedTime]=...
    FUN.moveTo(agentIndex,TeamOwn,DesiredSpeedTime);

FifoForPlayer = FUN.U_TimeStamp(CS, GameMode(1));  %=% adds timestamps to controlsignals
[ControlSignalForPlayer, FifoForPlayer] = ...
    FUN.U_Shorten(FifoForPlayer, GameMode(1), CycleBatch);

HLSTraj{TeamCounter}{agentIndex}.data  = TeamOwn{agentIndex}.Target;
HLSTraj{TeamCounter}{agentIndex}.tst   = TeamOwn{agentIndex}.TargetSpeedTime;
HLSTraj{TeamCounter}{agentIndex}.index = 1;

% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
