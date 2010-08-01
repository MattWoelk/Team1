function matrix = GraphDimmer (PlayerPos, Dimmer)
%=% Uses the Dimmer value to create a matrix that dims the field between the player and the player's goal.

global FieldX FieldY

matrix = [ones(FieldY-1, floor(PlayerPos(1)))*Dimmer, ones(FieldY-1, FieldX-floor(PlayerPos(1)))];

% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
