function [sparseMatrix,xVal,yVal] = FindHighestValue(matrix)

[maxes,yVals] = max(matrix);
[maxVal,xVal] = max(maxes);
yVal = yVals(xVal);
sizeOfMatrix = size(matrix);
sparseMatrix = zeros(sizeOfMatrix(1),sizeOfMatrix(2));
sparseMatrix(yVal,xVal) = 0.9999;
