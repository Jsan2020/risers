// Wake flat v1: one-piece L riser, printed flat (plate on the bed, wall standing up).
// Wall tabs on the top edge of the wall drop by gravity into slots near the free edge of the next plate.
// Plate and hex layout follow Wake v6: same hex size/gap, borders, and small W.
//
// Axes: x = width, y = plate depth (y=0 is the wall side), z = up.

half_length = true;                       // prototype: half of 175 mm
width       = half_length ? 87.5 : 175;
plate_d     = 65;                         // plate depth, wall side to free edge
plate_t     = 2;
wall_t      = 2;
wall_h      = 20;                         // lip height, measured from the bed
inner_r     = 1.5;                        // fillet where the wall meets the plate

// hex grid (same as Wake)
hex_size   = 15;
hex_gap    = 2.5;
border_x   = 4;
border_wall = 6;                          // clear zone between the fillet and the hex area
border_free = 8;                          // clear zone along the free edge, holds the slots

// small W inside one hex, far corner from the wall at max x
small_w_on     = true;
small_w_w      = 0.85;
small_w_h      = 0.62;
small_w_stroke = 2.0;
letter_flip    = true;

// tabs on the wall top, slots in the plate
tab_count   = half_length ? 2 : 3;
tab_len     = 22;
tab_h       = 3;
tab_clear   = 0.2;                        // slot clearance per side
slot_from_edge = 3;                       // free edge to slot centre line
tab_xs = [for (i = [0 : tab_count - 1]) width * (i + 1) / (tab_count + 1)];

$fn = 32;

function cells(w, h) =
    let (pitch = hex_size + hex_gap, step_x = pitch * 0.75, step_z = pitch * 0.866,
         cx = w / 2, cz = h / 2,
         ncols = ceil(w / (2 * step_x)) + 2, nrows = ceil(h / (2 * step_z)) + 2)
    [for (col = [-ncols : ncols]) for (row = [-nrows : nrows])
        let (parity = ((col % 2) + 2) % 2,
             x = cx + col * step_x,
             z = cz + row * step_z + (parity == 0 ? 0 : step_z / 2))
        [x, z]];

function corner_cell(w, h) =
    let (c = [for (p = cells(w, h)) if (p[0] - hex_size / 2 >= 0 && p[0] + hex_size / 2 <= w && p[1] - hex_size / 2 >= 0 && p[1] + hex_size / 2 <= h) p],
         best = max([for (p = c) p[0] + p[1]]))
    [for (p = c) if (p[0] + p[1] == best) p][0];

module w_shape2d(lw, lh, stroke) {
    f = letter_flip ? -1 : 1;
    pts = [[-lw / 2, f * lh / 2], [-lw / 4, -f * lh / 2], [0, f * lh * 0.15], [lw / 4, -f * lh / 2], [lw / 2, f * lh / 2]];
    for (i = [0 : 3]) hull() {
        translate(pts[i]) circle(d = stroke, $fn = 24);
        translate(pts[i + 1]) circle(d = stroke, $fn = 24);
    }
}

module hex_cut2d(w, h) {
    cc = corner_cell(w, h);
    difference() {
        intersection() {
            for (c = cells(w, h)) translate(c) circle(d = hex_size, $fn = 6);
            square([w, h]);
        }
        if (small_w_on)
            translate(cc) w_shape2d(hex_size * small_w_w, hex_size * small_w_h, small_w_stroke);
    }
}

// (y, z) profile of plate + wall + fillet, extruded along x
module body() {
    rotate([90, 0, 90]) linear_extrude(width) union() {
        square([plate_d, plate_t]);
        square([wall_t, wall_h]);
        difference() {
            translate([wall_t - 0.01, plate_t - 0.01]) square([inner_r + 0.01, inner_r + 0.01]);
            translate([wall_t + inner_r, plate_t + inner_r]) circle(r = inner_r);
        }
    }
}

module tabs() {
    for (x = tab_xs)
        translate([x - tab_len / 2, 0, wall_h - 0.01]) cube([tab_len, wall_t, tab_h + 0.01]);
}

module slots() {
    sw = wall_t + 2 * tab_clear;
    sl = tab_len + 2 * tab_clear;
    for (x = tab_xs)
        translate([x - sl / 2, plate_d - slot_from_edge - sw / 2, -1]) cube([sl, sw, plate_t + 2]);
}

module riser() {
    hy0 = wall_t + inner_r + border_wall;
    hh  = plate_d - hy0 - border_free;
    difference() {
        union() { body(); tabs(); }
        translate([border_x, hy0, -1]) linear_extrude(plate_t + 2) hex_cut2d(width - 2 * border_x, hh);
        slots();
    }
}

riser();
