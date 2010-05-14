function matrix = GraphMirror(inputmatrix)

%-% This function takes in a field-sized graph and 
%-% outputs a graph that is the correct size to be
%-% used when calculating mirrored kicks.

sizes = size(inputmatrix);

matrix = zeros(sizes(1)*3,sizes(2));
height = sizes(1);
width = sizes(2);

matrix(1:height,1:width) = flipud(inputmatrix);
matrix(height+1:2*height,1:width) = inputmatrix;
matrix(2*height+1:3*height,1:width) = flipud(inputmatrix);

% © 2010
% Benjamin Bergman - ben.bergman@gmail.com
% Matthew Woelk - umwoelk@cc.umanitoba.ca
% This document is subject to the Creative Commons 3.0 Attribution Non-Commercial Share Alike license.
% http://creativecommons.org/licenses/by-nc-sa/3.0/
