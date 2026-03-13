include <$temp_dir/texture.scad>
$fn= $preview ? 20 : 200;

//desired ppi has to be specified so the thickness and embossing depth can be consistent
ppi = $ppi;
h = $h;
w = $w;
r = w/(2 * PI);
utomm = ppi/25.4;
// how much the texture extrudes in mm (3-8)
depth = $depth * utomm;

points = [ for (i = [ 0 : h ], j = [ 0 : w - 1 ]) let (radius = i < h ? r + depth * (1 - leapord[i][j]) : r + depth, theta = toDegrees(PI * 2 * j / w), phi = toDegrees(PI * i / h)) [radius * cos(theta) * sin(phi), radius * sin(theta) * sin(phi), radius * cos(phi)] ];

faces = [ for (i = [ 0 : h - 1 ], j = [ 0 : w - 1 ]) let (p1 = i * w + j, p3 = (i + 1) * w + (j + 1)) each [[p1, p3, (i + 1) * w + j], [p1, i * w + (j + 1), p3]]];

polyhedron(points = points, faces = faces, convexity = 10);
