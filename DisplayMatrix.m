function noOutput = DisplayMatrix(matrix,whichFigure)

%-% This function displays matrix on figure whichFigure.

if exist('whichFigure','var')
  figure(whichFigure);
else
  figure(4);
end
imshow(flipud(matrix));

noOutput = true;
