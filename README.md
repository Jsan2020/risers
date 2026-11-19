# BlueBytes card risers

OpenSCAD designs for 3D-printed Pokemon card risers (Bambu Lab X1 Carbon, 0.4 mm nozzle, 0.12 mm layers).

## Current design: Wake v30 (`wake-v30/`)
- `wake_v30_flat_riser.scad` / `.stl`: one-piece flat riser, 175 mm wide. Plate on the bed, lip standing up, two wall tabs resting in slots of the riser below.
- `Wake-v30s.3mf`: latest Bambu Studio project.
- `iron_modifiers.stl`: boxes marking the engraved text for the ironing modifier.
- `extensions/`: 3 1/8 in (79.375 mm) wide pieces, one tab/slot, no W, no engraving.
  - `wake_extension.scad` / `.stl`: standard extension. Set `bottom_piece = true` for the bottom piece.
  - `wake_extension_bottom_piece.scad` / `.stl`: bottom piece, 1/4 in radius on the free-edge corner at max x, to clear the case's rounded inner corner. Print one per set.

## Plate projects (`projects/`)
Bambu Studio projects with the Wave Risers PETG profile, for the X1C. Rebuild with `python3 tools/build_plates.py`.
- `plate_A_4_full.3mf`: 4 full risers (3 along the 175 mm side, 1 turned 90 degrees).
- `plate_B_3_full_3_ext.3mf`: 3 full risers plus 3 extensions turned 90 degrees.
- `plate_C_9_ext.3mf`: 9 extensions, 3 x 3.
Plan for a set of 39 full + 13 extensions: 6 x plate A + 5 x plate B (11 plates).

## Other
- `case/`: case v1, side-sliding sleeve for a shingled stack.
- `hinge-poc/`: print-in-place hinge experiment and notes.
- `print-profiles/`: Polymaker PETG profiles for Bambu Studio.
- `history/`: milestone designs, oldest first (card riser, split, modular, v5/v6, first flat).

Browser-download duplicates like `(1)`, `(2)` were left out on purpose. Commit dates follow the original file modified times.
