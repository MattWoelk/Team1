function noOutput = DisplayMatrix(matrix,whichFigure)

figure(whichFigure);
if exist('matrix','var')
  imshow(flipud(matrix));
end

noOutput = true;
