$fn = 32;

// core dims
plate_len = 20;
plate_thickness = 4;
knuckle_len = 6;
knuckle_gap = 0.6;
pin_d = 1;
pin_clear = 0.4;
wall = 1.0;

// 0 = flat/print orientation, 90 = fully folded (preview only)
hinge_angle = 0;

h = plate_thickness / 2;
pin_hole_r = pin_d / 2 + pin_clear / 2;

// recede must equal h for a pure body-contact 90 deg stop, and must
// stay >= pin_hole_r + wall so the pin hole has enough material around it
recede = h;
assert(recede >= pin_hole_r + wall, "plate_thickness too thin for this pin/wall");
eps = 0.02;

// discorectangle knuckle cap: as large as the thickness budget allows
// while keeping a small cushion over the minimum enclosure radius
cap_r = pin_hole_r + wall + 0.1;
straight = recede - cap_r;
assert(straight >= 0, "cap_r bigger than recede - increase plate_thickness");

n = 3;
hinge_width = n * knuckle_len + (n - 1) * knuckle_gap;

seg_y0 = [0, knuckle_len + knuckle_gap, 2 * (knuckle_len + knuckle_gap)];
seg_y1 = [seg_y0[0] + knuckle_len, seg_y0[1] + knuckle_len, seg_y0[2] + knuckle_len];

module knuckle(y0, y1) {
    translate([0, y0, h])
        rotate([-90, 0, 0])
            linear_extrude(height = y1 - y0)
                hull() {
                    translate([-straight, 0]) circle(r = cap_r);
                    translate([straight, 0]) circle(r = cap_r);
                }
}

module pin_hole() {
    translate([0, -1, h])
        rotate([-90, 0, 0])
            cylinder(h = hinge_width + 2, r = pin_hole_r);
}

module plate_a() {
    difference() {
        union() {
            translate([recede - eps, 0, 0]) cube([plate_len, hinge_width, plate_thickness]);
            knuckle(seg_y0[0], seg_y1[0]);
            knuckle(seg_y0[2], seg_y1[2]);
        }
        pin_hole();
    }
}

module plate_b() {
    difference() {
        union() {
            translate([-recede - plate_len, 0, 0]) cube([plate_len + eps, hinge_width, plate_thickness]);
            knuckle(seg_y0[1], seg_y1[1]);
        }
        pin_hole();
    }
}

plate_a();
translate([0, 0, h]) rotate([0, hinge_angle, 0]) translate([0, 0, -h]) plate_b();
