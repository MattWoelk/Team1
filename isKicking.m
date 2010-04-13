function isKicking = isKicking( Fifo );
%ISKICKING Returns a boolean telling us if the agent is in the middle
% of a kick. The input is the Fifo for the agent in question.
% NOTE: The fifos for each agent should be stored as a persistent
% variable, likely in the HLS function. When a kick is to be abandoned
% the fifo for the kicking player should be emptied, ie. set to [].

isKicking = ~isempty(Fifo);
