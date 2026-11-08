// Wake flat v2: built on the v6 design. One-piece L riser printed flat, plate on the bed, lip standing up.
// Kept exactly from v6: plate size (65.4 mm deep x width), 2.24 mm plate (2 + 0.24 extra back layers),
//   hex size/gap/borders/grid positions, the small W, and the lip size (2 mm thick, 20 mm deep from the front face).
// New: wall tabs on the lip top that rest by gravity in slots near the free edge of the next plate.
// No ridges, channels or bands.
//
// Axes: x = width, y = plate depth (y=0 is the lip end of the plate, v6's z_bot end), z = up (plate front face up).
// The x axis is mirrored relative to v6's panel coordinates so the part is the same physical part, not a mirror image.

half_length = false;                      // true = half-length prototype (87.5 mm)
width       = half_length ? 87.5 : 175;

// v6 plate: back_height 70.5 - panel_top_trim 1.0 - boss_h 4.1
panel_h  = 65.4;
edge_extra = 2;                           // extra solid border past the v6 plate edge (free-edge side only); hex grid and slot positions unchanged
plate_d  = panel_h + edge_extra;
wall     = 2;                             // lip thickness (v6 `wall`)
back_extra = 0.24;                        // v6: 2 * 0.12 extra layers on the back
plate_t  = wall + back_extra;
bottom_lip_depth = 20;                    // v6 lip depth, measured from the back face's y datum
lip_h    = bottom_lip_depth + back_extra; // lip height from the bed: sticks out 18 mm past the front face, same as v6
fillet_in = 1.5;                          // where the lip meets the plate

// hex grid, same as v6
hex_size   = 15;
hex_gap    = 2.5;
border_x   = 4;
border_top = 6;
band_h     = 5;                           // v6 band_v 2 + ramp_h 3: hex area starts this far from the lip end

// small W, same as v6: one hex at the far corner, max x and max v6-z
small_w_on     = true;
small_w_w      = 0.85;
small_w_h      = 0.62;
small_w_stroke = 2.0;
letter_flip    = true;

// tabs on the lip top, slots in the plate
tab_len     = 22;
tab_h       = 3;                          // tabs stick up past lip_h
tab_clear   = 0.2;                        // slot clearance per side
slot_from_edge = 3;                       // free edge to slot centre line (hex area ends border_top = 6 from the edge)
ramp_depth = 1.0;                         // funnel depth into the plate from the back face, leaves plate_t - ramp_depth straight
ramp_run_y = 1.4;                         // flare on the hex side of each slot only, none on the free-edge side (stops short of the hex area at 1.8 mm)
ramp_run_x = 3.0;                         // flare past each end, gentler lead-in

// shingle step used by the storage case: how far each piece sits along y from the one below when stacked tight
// (the lip wall and its fillet need 3.5 mm, plus 0.1)
stack_step = 3.6;
assert(stack_step >= wall + fillet_in, "stack_step too small to clear the lip wall and fillet");

tab_xs = [width / 4, 3 * width / 4];     // two tabs, at the quarter points (full width: 43.75 and 131.25)
left_end  = tab_xs[0] - (tab_len / 2 + tab_clear);   // free stretches either side of the slots, where the text goes
right_beg = tab_xs[1] + (tab_len / 2 + tab_clear);

// engraved logo and version on the front face, in the solid strip along the free edge, either side of the slots
engrave      = true;
brand_text   = "BlueBytes";
version_text = "Wake v30";
tag_size     = 3.5;
tag_depth    = 0.7;
tag_font     = "Liberation Sans:style=Bold";

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

// the v6 hex pattern as a 2D cut; the cell grid is symmetric in x, only the W cell is mirrored
module hex_cut2d(w, h) {
    cc = corner_cell(w, h);
    difference() {
        intersection() {
            for (c = cells(w, h)) translate(c) circle(d = hex_size, $fn = 6);
            square([w, h]);
        }
        if (small_w_on)
            translate([w - cc[0], cc[1]]) w_shape2d(hex_size * small_w_w, hex_size * small_w_h, small_w_stroke);
    }
}

// (y, z) profile of plate + lip + fillet, extruded along x
module body() {
    r = wall / 2;
    rotate([90, 0, 90]) linear_extrude(width) union() {
        square([plate_d, plate_t]);
        square([wall, lip_h - r]);
        translate([r, lip_h - r]) circle(r = r, $fn = 32);       // rounded lip top, as in v6
        difference() {
            translate([wall - 0.01, plate_t - 0.01]) square([fillet_in + 0.01, fillet_in + 0.01]);
            translate([wall + fillet_in, plate_t + fillet_in]) circle(r = fillet_in);
        }
    }
}

module tabs() {
    r = wall / 2;
    z0 = lip_h - r;                       // starts inside the rounded lip top
    for (x = tab_xs)
        translate([x - tab_len / 2, 0, 0]) rotate([90, 0, 90]) linear_extrude(tab_len) union() {
            translate([0, z0]) square([wall, tab_h]);                         // up to where the round starts
            translate([r, lip_h + tab_h - r]) circle(r = r, $fn = 32);        // rounded tab top, same radius as the lip
        }
}

module slots() {
    sw = wall + 2 * tab_clear;
    sl = tab_len + 2 * tab_clear;
    y0 = panel_h - slot_from_edge - sw / 2;
    for (x = tab_xs) {
        translate([x - sl / 2, y0, -1]) cube([sl, sw, plate_t + 2]);
        // lead-in funnel on the back face (z=0, the bed side), the face the tab enters from
        hull() {
            translate([x - sl / 2, y0, ramp_depth - 0.01]) cube([sl, sw, 0.01]);
            translate([x - sl / 2 - ramp_run_x, y0 - ramp_run_y, -0.01]) cube([sl + 2 * ramp_run_x, sw + ramp_run_y, 0.01]);
        }
    }
}

// text is centred on its cap height in the solid strip between the hex area and the free edge
// (cap height of Liberation Sans Bold = 0.954 x size; the text is turned 180 deg, so its up is -y)
cap_h     = 0.954 * tag_size;
strip_mid = ((panel_h - border_top) + plate_d) / 2;
module tag_text(txt, x_pos) {
    translate([x_pos, strip_mid + cap_h / 2, plate_t - tag_depth]) rotate([0, 0, 180])
        linear_extrude(height = tag_depth + 0.5)
            text(txt, size = tag_size, font = tag_font, halign = "center", valign = "baseline");
}

module riser() {
    difference() {
        union() { body(); tabs(); }
        translate([border_x, band_h, -1]) linear_extrude(plate_t + 2)
            hex_cut2d(width - 2 * border_x, panel_h - band_h - border_top);
        slots();
        if (engrave) {
            tag_text(brand_text, (border_x + left_end) / 2);
            tag_text(version_text, (right_beg + width - border_x) / 2);
        }
    }
}

// two boxes over the engraved text areas, in the riser's own coordinates, to load into the slicer as modifiers
// (ironing is a slicer setting; this just marks where). "riser" | "iron_modifiers"
output = "riser";
module iron_boxes() {
    for (x0 = [border_x + 1, right_beg + 1])
        translate([x0, panel_h - border_top, 0])
            cube([left_end - border_x - 2, plate_d - (panel_h - border_top), plate_t + 0.7]);
}

render_riser = true;
if (render_riser) { if (output == "iron_modifiers") iron_boxes(); else riser(); }
