function cycles = timeLeftInKick( PlayerFifo, GameMode )
% It is assumed that this function will be called before the Fifo
% gets modified by HLS. 

global FUN

[CS, Fifo] = FUN.U_Shorten(PlayerFifo, GameMode(1), 20); %=% 20 is an arbitrary value. It is only used to construct CS which we don't care about right now

cycles = size(Fifo, 1);


% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
