// ===== PARAMETERS =====
width           = 175;  // overall width (mm)
back_height     = 70.5; // height of vertical back panel
top_lip_depth   = 6.9;  // top lip depth, folds backward
bottom_lip_depth= 20;   // bottom lip depth, folds forward
wall            = 2;    // material thickness

hex_size   = 15;   // hex diameter across flats
hex_gap    = 2.5;  // gap between hexes (rib thickness)
border_x      = 4;    // left/right solid frame
border_top    = 6;    // top solid frame
border_bottom = 6;    // bottom solid frame

fillet_r = 1.5;   // rounds edge C (long lip outer corner)

brand_text   = "BlueBytes";   // left-aligned, engraved on short lip surface
version_text = "Wake.29";    // right-aligned, engraved on short lip surface
tag_size     = 3.5;           // text height (mm)
tag_depth    = 0.9;           // engrave depth (mm)
tag_font     = "Liberation Sans:style=Bold";
tag_margin_x = 10;            // inset from left/right edges (mm)

$fn = 32;

// ===== HEX PATTERN (spills freely, gets clipped by inner box below) =====
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

// clip the spilling grid to a clean w x h box, so edge hexes cut flat
module hex_pattern(w, h) {
    intersection() {
        hex_grid(w, h);
        cube([w, wall + 4, h]);
    }
}

// ===== BACK PANEL WITH PATTERN =====
// solid frame (border_x/border_z) around a cleanly-clipped hex pattern
module back_panel() {
    difference() {
        cube([width, wall, back_height]);
        translate([border_x, -1, border_bottom])
            hex_pattern(width - 2 * border_x, back_height - border_top - border_bottom);
    }
}

// lip with a rounded (bullnose) free edge; attaches to panel at y=0
module rounded_lip(w, depth) {
    r = wall / 2;
    union() {
        cube([w, depth - r, wall]);
        translate([0, depth - r, r])
            rotate([0, 90, 0])
                cylinder(r = r, h = w, $fn = 32);
    }
}

// top lip: folds backward (-Y), sits at top of back panel
module top_lip() {
    translate([0, wall, back_height - wall])
        mirror([0, 1, 0])
            rounded_lip(width, top_lip_depth);
}

// bottom lip: folds forward (+Y), sits at bottom of back panel
module bottom_lip() {
    rounded_lip(width, bottom_lip_depth);
}

// concave (inner) corner fillet - adds a rounded fill where two inner faces meet
module concave_fillet(y0, z0, r) {
    translate([0, y0, z0])
        rotate([0, 90, 0])
            cylinder(r = r, h = width, $fn = 64);
}

// convex (outer) corner round - cuts the sharp corner into a quarter-round
module outer_round(y0, z0, r) {
    translate([0, y0, z0])
        difference() {
            cube([width, r, r]);
            translate([0, r, r])
                rotate([0, 90, 0])
                    cylinder(r = r, h = width, $fn = 64);
        }
}

// ===== ASSEMBLY (Z-profile) =====
tag_margin_y = 6;             // inset from the lip's outer edge (mm)

module tag_text(txt, x_pos) {
    y_c = bottom_lip_depth - tag_margin_y;
    translate([x_pos, y_c, wall - tag_depth])
        rotate([0, 0, 180])
            linear_extrude(height = tag_depth + 0.5)
                text(txt, size = tag_size, font = tag_font,
                     halign = "center", valign = "center");
}

module card_riser() {
    difference() {
        union() {
            back_panel();
            top_lip();
            bottom_lip();
        }
        outer_round(0, 0, fillet_r);  // C: long lip outer corner
        tag_text(brand_text, width - border_x - tag_margin_x);
        tag_text(version_text, border_x + tag_margin_x);
    }
}

card_riser();
