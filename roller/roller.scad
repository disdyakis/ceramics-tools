include <BOSL2/std.scad>
include <$temp_dir/texture.scad>

$fn= $preview ? 20 : 200;

//desired ppi has to be specified so the thickness and embossing depth can be consistent
ppi = $ppi;
h = $h;
w = $w;

radius = w/(2*PI);
height = h;
path = circle(r=radius);
utomm = ppi/25.4;

// how much the texture extrudes in mm (3-8)
depth = $depth * utomm;
// how thick the cylinder is (5mm)
thickness = $thickness * utomm;

difference() {
    linear_sweep(
        path, texture=image_array, tex_inset=false, tex_depth=-depth, tex_size=[h, w],
        h=height, style=\"alt\");
    down(10) cylinder(h=height + 20, r=radius - thickness);
}
