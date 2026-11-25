# BlueBytes card risers

OpenSCAD designs for 3D-printed Pokemon card risers (Bambu Lab X1 Carbon, 0.4 mm nozzle, 0.12 mm layers).

## Branches
- `main`: generic risers (Bedrock).
- `Wake`: the Wake set (W corner mark, "Wake v30" engraving), kept as it was printed.

## Current design: Bedrock v1 (`bedrock-v1/`)
Same part as Wake v30, with no corner mark (the W hex is a plain open hex) and "Bedrock v1" engraved instead of "Wake v30".
- `bedrock_v1_flat_riser.scad` / `.stl`: one-piece flat riser, 175 mm wide. Plate on the bed, lip standing up, two wall tabs resting in slots of the riser below.
  `corner_mark` can put letters in the corner hex: `""` (default, none), `"B"`, `"BB"` or `"W"`.
- `iron_modifiers.stl`: boxes marking the engraved text for the ironing modifier.
- `extensions/`: 3 1/8 in (79.375 mm) wide pieces, one tab/slot, no corner mark, no engraving.
  - `bedrock_extension.scad` / `.stl`: standard extension. Set `bottom_piece = true` for the bottom piece.
  - `bedrock_extension_bottom_piece.scad` / `.stl`: bottom piece, 1/4 in radius on the free-edge corner at max x, to clear the case's rounded inner corner. Print one per set.

## Plate projects (`projects/`)
Bambu Studio projects for the X1C: Wave Risers PETG process profile plus the stock **Bambu PETG Basic** filament preset. `projects/matte/` holds the same plates with stock **Bambu PETG Matte**.
Rebuild with `python3 tools/build_plates.py` (Basic) or `python3 tools/build_plates.py --filament matte`. The builder reads the presets from the local Bambu Studio install, so the projects follow Bambu's own updates.
- `plate_D_1_full.3mf`: 1 full riser, centred (test print).
- `plate_A_4_full.3mf`: 4 full risers (3 along the 175 mm side, 1 turned 90 degrees).
- `plate_B_3_full_3_ext.3mf`: 3 full risers plus 3 extensions turned 90 degrees.
- `plate_C_9_ext.3mf`: 9 extensions, 3 x 3.
Plan for a set of 39 full + 13 extensions: 6 x plate A + 5 x plate B (11 plates).

## Other
- `case/`: case v1, side-sliding sleeve for a shingled stack.
- `hinge-poc/`: print-in-place hinge experiment and notes.
- `print-profiles/`: `plate_settings_base.3mf` (the Wake v30 slicer project; the plate builder takes its process and printer settings) and older Polymaker PETG profiles (not used; see Filament below).
- `history/`: milestone designs, oldest first (card riser, split, modular, v5/v6, first flat).

Browser-download duplicates like `(1)`, `(2)` were left out on purpose. Commit dates follow the original file modified times.

## Filament
Use the stock Bambu presets, unmodified. No custom filament profile.
| | X1C nozzle (first layer) | A1 nozzle | Fans | Bed |
|---|---|---|---|---|
| Bambu PETG Basic | 255 (245) | 245 | 20-40 % (A1 30-50) | 70 |
| Bambu PETG Matte | 250 (245) | 235 | 20-40 % (A1 30-50) | 70 |
- When a plate goes to the A1, switch the printer in Bambu Studio; the stock preset changes to its A1 version on its own.
- Matte is denser (1.37 vs 1.25 g/cm3): same parts, about 10% more filament by weight.
