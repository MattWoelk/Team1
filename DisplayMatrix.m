function noOutput = DisplayMatrix(matrix,whichFigure)

figure(whichFigure);
if exist('matrix','var')
  imshow(flipud(matrix));
end

noOutput = true;

% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
