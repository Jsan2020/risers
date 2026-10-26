// Wake split design: top lip printed flat, slides into dovetail rail
part      = "print";   // "assembled" | "print" | "body" | "lip"
test_mode = true;      // true = 30mm coupon slice, false = full riser

width           = test_mode ? 30 : 175;
back_height     = 70.5;
bottom_lip_depth= 20;
wall            = 2;

hex_size   = 15;
hex_gap    = 2.5;
border_x      = 4;
border_bottom = 6;

fillet_r = 1.5;

brand_text   = "BlueBytes";
version_text = "Wake v27";
tag_size     = 3.5;
tag_depth    = 0.5;
tag_font     = "Liberation Sans:style=Bold";
tag_margin_x = 10;
tag_margin_y = 6;

// rail + dovetail
rail_d    = 5;     // extra depth behind panel
rail_t    = 3;     // rail thickness at its free tip
dt_neck   = 2.6;   // tongue width at base
dt_h      = 1.0;   // tongue height (45 deg flanks)
dt_clear  = 0.2;   // clearance per side
dt_stop   = 2;     // solid end wall of the blind groove

lip_d      = wall + rail_d;
rail_top   = back_height - wall;
rail_z_tip = rail_top - rail_t;
rail_z0    = rail_z_tip - rail_d;   // 45 deg underside, prints without supports

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

module back_panel() {
    difference() {
        cube([width, wall, rail_top]);
        translate([border_x, -1, border_bottom])
            hex_pattern(width - 2 * border_x, rail_z0 - border_bottom);
    }
}

module rail() {
    rotate([90, 0, 90]) linear_extrude(width)
        polygon([[0.5, rail_z0], [0, rail_z0], [-rail_d, rail_z_tip],
                 [-rail_d, rail_top], [0.5, rail_top]]);
}

module groove() {
    mw = dt_neck / 2 + dt_clear;
    gd = dt_h + dt_clear;
    bw = mw + gd;
    yc = (wall - rail_d) / 2;
    translate([-1, 0, 0]) rotate([90, 0, 90]) linear_extrude(width - dt_stop + 1)
        polygon([[yc - mw, rail_top + 1], [yc - mw, rail_top],
                 [yc - bw, rail_top - gd], [yc + bw, rail_top - gd],
                 [yc + mw, rail_top], [yc + mw, rail_top + 1]]);
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

module bottom_lip() { rounded_lip(width, bottom_lip_depth); }

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

module body() {
    difference() {
        union() {
            back_panel();
            rail();
            if (!test_mode) bottom_lip();
        }
        groove();
        if (!test_mode) {
            outer_round(0, 0, fillet_r);
            tag_text(brand_text, width - border_x - tag_margin_x);
            tag_text(version_text, border_x + tag_margin_x);
        }
    }
}

module body_part() {
    if (test_mode)
        intersection() {
            body();
            translate([-1, -10, 50]) cube([width + 2, 30, 30]);
        }
    else body();
}

// local frame: plate on bed (z 0..wall), tongue pointing up
module lip_strip() {
    yc = lip_d / 2;
    nh = dt_neck / 2;
    rounded_lip(width, lip_d);
    rotate([90, 0, 90]) linear_extrude(width - dt_stop - dt_clear)
        polygon([[yc - nh, wall - 0.01], [yc + nh, wall - 0.01],
                 [yc + nh + dt_h, wall + dt_h], [yc - nh - dt_h, wall + dt_h]]);
}

module lip_placed() {
    translate([0, wall, back_height]) rotate([180, 0, 0]) lip_strip();
}

// coupon prints front face down; full body prints bottom lip down
module body_print() {
    if (test_mode) translate([0, 0, wall]) rotate([-90, 0, 0]) body_part();
    else body_part();
}

if (part == "assembled") { body_part(); lip_placed(); }
else if (part == "body") body_print();
else if (part == "lip") lip_strip();
else { body_print(); translate([0, -15, 0]) lip_strip(); }
