function matrix = GraphMirror(inputmatrix)

sizes = size(inputmatrix);

matrix = zeros(sizes(1)*3,sizes(2));
height = sizes(1);
width = sizes(2);

matrix(1:height,1:width) = flipud(inputmatrix);
matrix(height+1:2*height,1:width) = inputmatrix;
matrix(2*height+1:3*height,1:width) = flipud(inputmatrix);
