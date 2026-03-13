include <BOSL2/std.scad>
$fn= $preview ? 20 : 200;

h = $h;
w = $w;
ppi = $ppi;
utomm = ppi/25.4;
// how much the texture extrudes in mm (3-8)
depth = $depth * utomm;
hole_diameter = $hole;
circle = $circle;
border = min(h, w)/10;

intersection() {
    union() {
        up(depth) scale([-1, 1, 1/100*depth])
                surface(file = "$img", center = true, invert = true);

        difference() {
            up(depth/2 - border/2) cube([w + border, h + border, depth + border +1], center=true);
            translate([0, 0, (depth/2)]) cube([w-1, h-1, depth+2], center=true);
        }

    }
    if (circle) {
        up(depth/2 - border/2) cylinder(r=max(w + border, h + border)/2, h=depth + border +1, center=true);
    }
}
if (circle) {
    difference() {
        up(depth/2 - border/2) cylinder(r=max(w + border, h + border)/2, h=depth + border +1, center=true);
        translate([0, 0, (depth/2)]) cylinder(r=max(w-1, h-1)/2, h=depth+2, center=true);
    }
}
