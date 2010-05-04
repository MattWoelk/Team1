function [sparseMatrix,xVal,yVal] = FindHighestValue(matrix)

%-% This function returns the x and y location of the highest
%-% point in matrix.
%-% It also gives a sparse matrix which contains a single non-zero
%-% where the high point in matrix is.

[maxes,yVals] = max(matrix);
[maxVal,xVal] = max(maxes);
yVal = yVals(xVal);
sizeOfMatrix = size(matrix);
sparseMatrix = zeros(sizeOfMatrix(1),sizeOfMatrix(2));
sparseMatrix(yVal,xVal) = 0.9999;
