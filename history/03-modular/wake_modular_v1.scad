// Wake modular: flat baseplate + separate short (top) and long (bottom) lips.
// Both lips are flat plates with a dovetail ridge that slides into a groove cut in the
// top / bottom edge of the baseplate. Both thickening ramps are on the back (D), so the
// baseplate prints flat, front (F) down, with no supports.
//
// Letters: D back face, F front face, A/E top/underside of a lip, B short-lip free edge,
//   G long-lip shelf, H long-lip free edge, J long-lip underside,
//   K blind end (x=0), L open end (x=width) where the glue goes.

part      = "print";   // "print" | "baseplate" | "top_lip" | "bottom_lip" | "assembled"
test_mode = true;      // true = 30mm coupons, false = full riser

width            = test_mode ? 30 : 175;
back_height      = 70.5;   // overall height, lip underside to lip top (as v27)
bottom_lip_depth = 20;
wall             = 2;

hex_size = 15;
hex_gap  = 2.5;
border_x = 4;

fillet_r = 1.5;

brand_text   = "BlueBytes";
version_text = "Wake v27";
tag_size     = 3.5;
tag_depth    = 0.5;
tag_font     = "Liberation Sans:style=Bold";
tag_margin_x = 10;
tag_margin_y = 6;

// ramps + dovetail
band_t     = 2.5;   // ramp thickness added behind the panel
band_h     = 6;     // ramp height at each end, 45 deg underside
lip_reach  = 4.9;   // short lip length past face D
ridge_h    = 2.0;   // ridge height into the groove
ridge_head = 2.5;   // ridge head width
flare      = 0.5;   // 45 deg flank, neck = head - 2*flare
dt_clear   = 0.2;   // clearance per side
dt_stop    = 2;     // solid end wall at blind end K
tip_ch     = 0.3;

coupon_h       = 14;
test_lip_depth = 8;  // long lip depth in test_mode

z_bot = wall;
z_top = back_height - wall;
D_y   = -band_t;
yc    = D_y + (wall + band_t) / 2;   // dovetail centre line

$fn = 32;

module hex_grid(w, h) {
    pitch  = hex_size + hex_gap;
    step_x = pitch * 0.75;
    step_z = pitch * 0.866;
    cx = w / 2;
    cz = h / 2;
    ncols = ceil(w / (2 * step_x)) + 2;
    nrows = ceil(h / (2 * step_z)) + 2;
    for (col = [-ncols : ncols]) {
        x = cx + col * step_x;
        parity = ((col % 2) + 2) % 2;
        z_offset = (parity == 0) ? 0 : step_z / 2;
        for (row = [-nrows : nrows]) {
            z = cz + row * step_z + z_offset;
            translate([x, wall / 2, z])
                rotate([90, 0, 0])
                    cylinder(d = hex_size, h = wall + 4, center = true, $fn = 6);
        }
    }
}

module hex_pattern(w, h) {
    intersection() {
        hex_grid(w, h);
        cube([w, wall + 4, h]);
    }
}

// profiles are (y, z), extruded along X
module along_x(x0, len) {
    translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(len) children();
}

// e = plane of the lip joint face, s = +1 groove/ridge goes up, -1 goes down
module groove(e, s) {
    m = (ridge_head - 2 * flare) / 2 + dt_clear;
    h = ridge_head / 2 + dt_clear;
    d = ridge_h + dt_clear;
    along_x(dt_stop, width - dt_stop + 1)
        polygon([[yc - m, e - s], [yc - m, e], [yc - h, e + s * flare],
                 [yc - h, e + s * d], [yc + h, e + s * d], [yc + h, e + s * flare],
                 [yc + m, e], [yc + m, e - s]]);
}

module ridge(e, s) {
    n  = (ridge_head - 2 * flare) / 2;
    hh = ridge_head / 2;
    along_x(dt_stop + dt_clear, width - dt_stop - dt_clear)
        polygon([[yc - n, e - s * 0.01], [yc - n, e], [yc - hh, e + s * flare],
                 [yc - hh, e + s * (ridge_h - tip_ch)], [yc - hh + tip_ch, e + s * ridge_h],
                 [yc + hh - tip_ch, e + s * ridge_h], [yc + hh, e + s * (ridge_h - tip_ch)],
                 [yc + hh, e + s * flare], [yc + n, e], [yc + n, e - s * 0.01]]);
}

module panel() {
    translate([0, 0, z_bot]) difference() {
        cube([width, wall, z_top - z_bot]);
        translate([border_x, -1, band_h])
            hex_pattern(width - 2 * border_x, z_top - z_bot - 2 * band_h);
    }
}

module bands() {
    v = band_h - band_t;
    along_x(0, width)
        polygon([[0.01, z_bot], [D_y, z_bot], [D_y, z_bot + v], [0.01, z_bot + band_h]]);
    along_x(0, width)
        polygon([[0.01, z_top], [D_y, z_top], [D_y, z_top - v], [0.01, z_top - band_h]]);
}

module baseplate() {
    difference() {
        union() { panel(); bands(); }
        groove(z_bot, 1);
        groove(z_top, -1);
    }
}

module rounded_lip(w, depth) {
    r = wall / 2;
    union() {
        cube([w, depth - r, wall]);
        translate([0, depth - r, r])
            rotate([0, 90, 0])
                cylinder(r = r, h = w, $fn = 32);
    }
}

module outer_round(y0, z0, r) {
    translate([0, y0, z0])
        difference() {
            cube([width, r, r]);
            translate([0, r, r])
                rotate([0, 90, 0])
                    cylinder(r = r, h = width, $fn = 64);
        }
}

module tag_text(txt, x_pos) {
    translate([x_pos, bottom_lip_depth - tag_margin_y, wall - tag_depth])
        rotate([0, 0, 180])
            linear_extrude(height = tag_depth + 0.5)
                text(txt, size = tag_size, font = tag_font,
                     halign = "center", valign = "center");
}

module top_lip() {
    translate([0, wall, z_top]) mirror([0, 1, 0])
        rounded_lip(width, wall - D_y + lip_reach);
    ridge(z_top, -1);
}

module bottom_lip() {
    end_y = test_mode ? test_lip_depth : bottom_lip_depth;
    difference() {
        union() {
            translate([0, D_y, 0]) rounded_lip(width, end_y - D_y);
            ridge(z_bot, 1);
        }
        outer_round(D_y, 0, fillet_r);
        if (!test_mode) {
            tag_text(brand_text, width - border_x - tag_margin_x);
            tag_text(version_text, border_x + tag_margin_x);
        }
    }
}

// baseplate prints F down, ramps face up
module flat(z0) { translate([0, -z0, wall]) rotate([-90, 0, 0]) children(); }

module coupon(z0, z1) {
    intersection() {
        baseplate();
        translate([-1, -10, z0]) cube([width + 2, 30, z1 - z0]);
    }
}

module top_lip_print()    { translate([0, wall, back_height]) rotate([180, 0, 0]) top_lip(); }
module bottom_lip_print() { translate([0, -D_y, 0]) bottom_lip(); }

module layout() {
    lip_len = (test_mode ? test_lip_depth : bottom_lip_depth) - D_y;
    y0 = test_mode ? 2 * coupon_h + 14 : (z_top - z_bot) + 8;
    if (test_mode) {
        flat(z_bot) coupon(z_bot, z_bot + coupon_h);
        translate([0, coupon_h + 6, 0]) flat(z_top - coupon_h) coupon(z_top - coupon_h, z_top);
    } else {
        flat(z_bot) baseplate();
    }
    translate([0, y0, 0]) bottom_lip_print();
    translate([0, y0 + lip_len + 8, 0]) top_lip_print();
}

if (part == "baseplate") baseplate();
else if (part == "top_lip") top_lip();
else if (part == "bottom_lip") bottom_lip();
else if (part == "assembled") { baseplate(); top_lip(); bottom_lip(); }
else layout();
