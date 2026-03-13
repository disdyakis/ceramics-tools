include <BOSL2/std.scad>
$fn= $preview ? 20 : 200;

h = $h;
w = $w;
ppi = $ppi;
utomm = ppi/25.4;
// how much the texture extrudes in mm (3-8)
depth = $depth * utomm;
threshold = $threshold;
hole_diameter = $hole;
clearence = $clearence;


rotate([0, 180, 0]) {
    difference() {
        up((depth/threshold) - depth) scale([1, 1, 1/100 * (depth/threshold)])
        surface(file = "$img", center = true, invert = true);
        up(depth/threshold/2) cube([w * 1.5, h * 1.5, depth/threshold], center=true, $fn=100);
    }
    thickness = depth;
    down(depth*3/2 - 1) rotate([0, 0, 90])
        cube([h - 1, w - 1, thickness], center=true, $fn=100);
}

circ = circle($fn=80, r=12);

down(1) difference() {
    height = 10;
    rotate([0, 0, 90]) up(depth * 2) skin([rect([h - 1, w - 1]), circle(r=utomm * 6)], z=[0, height*utomm], slices=20);
    up(depth * 2) scale(utomm) cylinder(r=(hole_diameter - clearence)/2, h=height+1);
}
