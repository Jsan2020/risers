// ===== PARAMETERS =====
width        = 130;   // overall width (mm)
back_height  = 65;    // height of vertical back panel
lip_depth    = 45;    // depth of bottom shelf
wall         = 3;     // material thickness

hex_size     = 8;     // hex diameter across flats
hex_gap      = 2;     // gap between hexes
border       = 6;      // solid border margin around pattern

$fn = 32;

// ===== HEX PATTERN =====
module hex_grid(w, h) {
    step_x = hex_size + hex_gap;
    step_y = (hex_size + hex_gap) * 0.866; // row spacing for tessellation
    cols = ceil(w / step_x) + 2;
    rows = ceil(h / step_y) + 2;

    for (row = [0 : rows - 1]) {
        y = row * step_y;
        x_offset = (row % 2 == 0) ? 0 : step_x / 2;
        for (col = [0 : cols - 1]) {
            x = col * step_x + x_offset;
            if (x < w && y < h) {
                translate([x, y, -1])
                    cylinder(d = hex_size, h = wall + 2, $fn = 6);
            }
        }
    }
}

// ===== BACK PANEL WITH PATTERN =====
module back_panel() {
    difference() {
        cube([width, wall, back_height]);

        // rotate pattern into the panel's face (XZ plane)
        translate([border, -1, border])
            rotate([-90, 0, 0])
                hex_grid(width - 2 * border, back_height - 2 * border);
    }
}

// ===== BOTTOM LIP (shelf that holds card) =====
module bottom_lip() {
    cube([width, lip_depth, wall]);
}

// ===== ASSEMBLY =====
module card_riser() {
    union() {
        back_panel();
        bottom_lip();
    }
}

card_riser();
