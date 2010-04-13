function cycles = timeLeftInKick( PlayerFifo, GameMode )
% It is assumed that this function will be called before the Fifo
% gets modified by HLS. If a new Fifo is written or the current

global FUN

[CS, Fifo] = FUN.U_Shorten(PlayerFifo, GameMode(1), 20); %=% 20 is an arbitrary value. It is only used to construct CS which we don't care about right now

cycles = size(Fifo, 1);
