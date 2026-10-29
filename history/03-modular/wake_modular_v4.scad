// Wake modular v3. v2 is kept as is.
// Long (bottom) lip: separate flat plate, ridge on the baseplate slides into a groove in the lip.
//   The groove is offset so the lip seats flush against the back (D) with the play on the front side.
// Short (top) side: no separate lip. The baseplate ends in a stepped tab (inset from both ends)
//   that rests in a shallow blind groove cut in the underside of the long lip of the riser below
//   (the face opposite the attach channel). It prints facing the bed and bridges 2.5mm, no supports.
//
// Letters: D back face, F front face, K blind end (x=0), L open end (x=width) where glue goes.

part      = "print";   // "print" | "baseplate" | "bottom_lip" | "assembled"
test_mode = false;     // true = 30mm coupon, false = full riser

half_length      = true;    // prototype: half of the 175mm width
width            = test_mode ? 30 : (half_length ? 87.5 : 175);
back_height      = 70.5;    // overall height, lip underside to tab top
bottom_lip_depth = 20;
wall             = 2;       // lip thickness
panel_t          = wall + 2 * 0.12;   // baseplate thickness, extra layers on the back side only

hex_size   = 15;
hex_gap    = 2.5;

// W letter: the W strokes are laid over the hex grid, hexes under a stroke are partly or fully filled in
letter_on       = false; // big W across the panel (uses the finer grid below)
letter_flip     = true;  // model z runs from the ridge end (bottom) up, true = W reads upright with the ridge end at the TOP
letter_hex_size = 10;    // grid size while the letter is on
letter_hex_gap  = 2.0;
letter_h_frac   = 0.8;   // W height as a fraction of the hex area height
letter_aspect   = 1.3;   // W width / height
letter_stroke   = 9;     // W stroke thickness in mm

// small W inside one hex, bottom right as seen with the ridge end at the top
small_w_on     = true;
small_w_w      = 0.85;  // W centre-line width as a fraction of the hex size
small_w_h      = 0.62;  // W centre-line height as a fraction of the hex size
small_w_stroke = 2.0;
hs = letter_on ? letter_hex_size : hex_size;
hg = letter_on ? letter_hex_gap  : hex_gap;
border_x   = 4;
border_top = 6;
fillet_r   = 1.5;

engrave      = false;
brand_text   = "BlueBytes";
version_text = "Wake v27";
tag_size     = 3.5;
tag_depth    = 0.5;
tag_font     = "Liberation Sans:style=Bold";
tag_margin_x = 10;
tag_margin_y = 6;

// ridge (baseplate) / groove (long lip)
ridge_h     = 3.0;
ridge_head  = 4.2;
flare       = 0.8;   // 45 deg flank
dt_clear    = 0.1;   // depth clearance and detent clearance
back_clear  = 0.0;   // clearance on the D side, 0 = lip seats flush against the back
front_clear = 0.2;   // all the lateral play goes on the F side
dt_stop     = 3;
tip_ch      = 0.3;
floor_t     = 1.0;
side_wall   = 1.2;
ramp_h      = 3;
band_v      = 2;

// stacking tab (baseplate top edge) and its groove (top face of the long lip)
tab_h         = 1.0;   // tab protrusion
tab_inset     = 6;     // tab stops this far from each end
stack_clear   = 0.15;  // groove clearance per side
stack_clear_x = 0.4;   // groove end clearance
stack_depth   = tab_h + dt_clear;
groove_edge   = 0;     // 0 = groove runs out through the rounded table-side edge

// detent: one dome on the ridge, one recess in the groove floor, near the open end L
dimple_from_L = [7];
dimple_h      = 0.6;   // was 0.4, net squeeze = dimple_h - dt_clear
dimple_r      = 1.5;
recess_depth  = 0.5;
recess_r      = 1.7;

// the ridge is short at BOTH ends and has an indent near each end, so the lip can go on either way round;
// the lip has one bump in its groove near its open end
reverse_stopper = false;  // true = the lip's blind stopper is at x=width, open end at x=0

test_panel_h   = 30;
test_lip_depth = 14;

hh      = ridge_head / 2;
nh      = (ridge_head - 2 * flare) / 2;
F_y     = wall;
back_extra = panel_t - wall;
yc      = F_y - hh;
g_d     = ridge_h + dt_clear;
D_y     = yc - hh - back_clear - side_wall;
y_front = yc + hh + front_clear + side_wall;
boss_h  = g_d + floor_t;
z_bot   = boss_h;
total_h = test_mode ? z_bot + test_panel_h + tab_h : back_height;
z_top   = total_h - tab_h;
band_h  = band_v + ramp_h;
dimple_xs = [for (d = dimple_from_L) width - d];
ridge_recess_xs = concat(dimple_xs, [for (d = dimple_from_L) d]);

$fn = 32;

function cells(w, h) =
    let (pitch = hs + hg, step_x = pitch * 0.75, step_z = pitch * 0.866,
         cx = w / 2, cz = h / 2,
         ncols = ceil(w / (2 * step_x)) + 2, nrows = ceil(h / (2 * step_z)) + 2)
    [for (col = [-ncols : ncols]) for (row = [-nrows : nrows])
        let (parity = ((col % 2) + 2) % 2,
             x = cx + col * step_x,
             z = cz + row * step_z + (parity == 0 ? 0 : step_z / 2))
        [x, z]];

// a cell fully inside the hex area, as far to the bottom right as possible (right = +x, bottom = +z)
function corner_cell(w, h) =
    let (c = [for (p = cells(w, h)) if (p[0] - hs / 2 >= 0 && p[0] + hs / 2 <= w && p[1] - hs / 2 >= 0 && p[1] + hs / 2 <= h) p],
         best = max([for (p = c) p[0] + p[1]]))
    [for (p = c) if (p[0] + p[1] == best) p][0];

module hex_grid(w, h) {
    for (c = cells(w, h))
        translate([c[0], panel_t / 2, c[1]]) rotate([90, 0, 0])
            cylinder(d = hs, h = panel_t + 4, center = true, $fn = 6);
}

module w_shape2d(lw, lh, stroke) {
    f = letter_flip ? -1 : 1;
    pts = [[-lw / 2, f * lh / 2], [-lw / 4, -f * lh / 2], [0, f * lh * 0.15], [lw / 4, -f * lh / 2], [lw / 2, f * lh / 2]];
    for (i = [0 : 3]) hull() {
        translate(pts[i]) circle(d = stroke, $fn = 24);
        translate(pts[i + 1]) circle(d = stroke, $fn = 24);
    }
}

module hex_pattern(w, h) {
    lh = h * letter_h_frac - letter_stroke;
    lw = min(lh * letter_aspect, w - letter_stroke - 2);
    cc = corner_cell(w, h);
    difference() {
        intersection() { hex_grid(w, h); cube([w, panel_t + 4, h]); }
        if (letter_on)
            translate([w / 2, panel_t / 2, h / 2]) rotate([90, 0, 0])
                linear_extrude(height = panel_t + 6, center = true) w_shape2d(lw, lh, letter_stroke);
        if (small_w_on)
            translate([cc[0], panel_t / 2, cc[1]]) rotate([90, 0, 0])
                linear_extrude(height = panel_t + 6, center = true)
                    w_shape2d(hs * small_w_w, hs * small_w_h, small_w_stroke);
    }
}

module xflip() {
    if (reverse_stopper) translate([width, 0, 0]) mirror([1, 0, 0]) children();
    else children();
}

// profiles are (y, z), extruded along X
module along_x(x0, len) { translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(len) children(); }

// e = joint plane, s = direction into the lip
module groove(e, s) {
    d = g_d;
    along_x(dt_stop, width - dt_stop + 1)
        polygon([[yc - nh - back_clear, e - s], [yc - nh - back_clear, e],
                 [yc - hh - back_clear, e + s * flare], [yc - hh - back_clear, e + s * d],
                 [yc + hh + front_clear, e + s * d], [yc + hh + front_clear, e + s * flare],
                 [yc + nh + front_clear, e], [yc + nh + front_clear, e - s]]);
}

module ridge_body(e, s) {
    along_x(dt_stop + dt_clear, width - 2 * (dt_stop + dt_clear))
        polygon([[yc - nh, e - s * 0.01], [yc - nh, e], [yc - hh, e + s * flare],
                 [yc - hh, e + s * (ridge_h - tip_ch)], [yc - hh + tip_ch, e + s * ridge_h],
                 [yc + hh - tip_ch, e + s * ridge_h], [yc + hh, e + s * (ridge_h - tip_ch)],
                 [yc + hh, e + s * flare], [yc + nh, e], [yc + nh, e - s * 0.01]]);
}

module cap(xc, plane, s, h, a) {
    R = (a * a + h * h) / (2 * h);
    intersection() {
        translate([xc, yc, plane + s * (h - R)]) sphere(r = R, $fn = 48);
        translate([xc - a - 0.5, yc - a - 0.5, min(plane - s * 0.02, plane + s * h)])
            cube([2 * a + 1, 2 * a + 1, h + 0.02]);
    }
}

module ridge(e, s) {
    difference() {
        ridge_body(e, s);
        for (x = ridge_recess_xs) cap(x, e + s * ridge_h, -s, recess_depth, recess_r);
    }
}

module bumps(e, s) {
    for (x = dimple_xs) cap(x, e + s * g_d, -s, dimple_h, dimple_r);
}

module panel() {
    translate([0, -back_extra, z_bot]) difference() {
        cube([width, panel_t, z_top - z_bot]);
        translate([border_x, -1, band_h])
            hex_pattern(width - 2 * border_x, z_top - z_bot - band_h - border_top);
    }
}

module bottom_band() {
    yb = -back_extra + 0.01;
    along_x(0, width) polygon([[yb, z_bot], [D_y, z_bot], [D_y, z_bot + band_v], [yb, z_bot + band_h]]);
}

module tab() {
    translate([tab_inset, -back_extra, z_top - 0.01])
        cube([width - 2 * tab_inset, panel_t, tab_h + 0.01]);
}

module baseplate() {
    union() {
        panel();
        bottom_band();
        tab();
        ridge(z_bot, -1);
    }
}

module rounded_lip(w, depth) {
    r = wall / 2;
    union() {
        cube([w, depth - r, wall]);
        translate([0, depth - r, r]) rotate([0, 90, 0]) cylinder(r = r, h = w, $fn = 32);
    }
}

module outer_round(y0, z0, r) {
    translate([0, y0, z0]) difference() {
        cube([width, r, r]);
        translate([0, r, r]) rotate([0, 90, 0]) cylinder(r = r, h = width, $fn = 64);
    }
}

module tag_text(txt, x_pos) {
    translate([x_pos, bottom_lip_depth - tag_margin_y, wall - tag_depth])
        rotate([0, 0, 180]) linear_extrude(height = tag_depth + 0.5)
            text(txt, size = tag_size, font = tag_font, halign = "center", valign = "center");
}

module stack_groove() {
    gx0 = tab_inset - stack_clear_x;
    gw  = panel_t + 2 * stack_clear;
    end_y = test_mode ? test_lip_depth : bottom_lip_depth;
    translate([gx0, end_y - groove_edge - gw, -1])
        cube([width - 2 * gx0, gw + groove_edge + 1, stack_depth + 1]);
}

module bottom_lip() {
    end_y = test_mode ? test_lip_depth : bottom_lip_depth;
    union() {
        difference() {
            union() {
                translate([0, D_y, 0]) rounded_lip(width, end_y - D_y);
                translate([0, D_y, 0]) cube([width, y_front - D_y, boss_h]);
            }
            outer_round(D_y, 0, fillet_r);
            xflip() groove(z_bot, -1);
            stack_groove();
            if (!test_mode && engrave) {
                tag_text(brand_text, width - border_x - tag_margin_x);
                tag_text(version_text, border_x + tag_margin_x);
            }
        }
        xflip() bumps(z_bot, -1);
    }
}

// baseplate prints F down, ridge and tab lying in the bed plane
module flat(z0) { translate([0, -z0, F_y]) rotate([-90, 0, 0]) children(); }

module bottom_lip_print() { translate([0, -D_y, 0]) bottom_lip(); }

module layout() {
    bp_len = (z_top - z_bot) + ridge_h + tab_h;
    flat(z_bot - ridge_h) baseplate();
    translate([0, bp_len + 8, 0]) bottom_lip_print();
}

if (part == "baseplate_print") flat(z_bot - ridge_h) baseplate();
else if (part == "bottom_lip_print") bottom_lip_print();
else if (part == "baseplate") baseplate();
else if (part == "bottom_lip") bottom_lip();
else if (part == "preview2d") projection() rotate([-90, 0, 0]) baseplate();
else if (part == "assembled") { baseplate(); bottom_lip(); }
else layout();
