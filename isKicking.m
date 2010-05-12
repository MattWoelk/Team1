function isKicking = isKicking( Fifo );
%ISKICKING Returns a boolean telling us if the agent is in the middle
% of a kick. The input is the Fifo for the agent in question.
% NOTE: The fifos for each agent should be stored as a persistent
% variable, likely in the HLS function. When a kick is to be abandoned
% the fifo for the kicking player should be emptied, ie. set to [].

isKicking = ~isempty(Fifo);
%=% NB: should this do any truncating?


% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
