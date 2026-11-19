# Print plan: one full set (39 full risers + 13 extensions)

Parts per plate are in `projects/`. Times are Bambu Studio estimates (Wave Risers PETG, Generic PETG filament, 0.12 mm).

| Plate | Contents | X1C | A1 (timelapse on) | Filament |
|---|---|---|---|---|
| A | 4 full | 7h11m | 7h23m | 83 g |
| B | 3 full + 3 ext | 7h57m | 8h12m | 92 g |
| B2 | 3 full + 2 ext + 1 bottom piece | same as B | same as B | 92 g |
| C | 9 ext (not used in this plan) | 7h49m | 8h02m | 90 g |

## Plan: 11 plates, the minimum
- **X1C:** 6 x plate A = 24 full. About 43h06m, 5 plate swaps between prints.
- **A1 (use the "@A1" process profile):** 4 x plate B + 1 x plate B2 = 15 full + 14 standard ext + 1 bottom piece. About 41h00m (about 40h25m with timelapse off), 4 swaps between prints.
- Total: 39 full, 14 standard + 1 bottom extension (need 12 standard + 1 bottom, so 2 spare).
- Wall-clock: about 43 hours (the X1C finishes last). Filament: about 960 g.

## Why this split
11 plates only works as 6 x A + 5 x B (4 full per A, 3 full + 3 ext per B). Of all ways to split those between the two printers, 6 A on the X1C and 5 B on the A1 gives the shortest finish. Print time scales with volume, and the A1 is about 2% slower than the X1C.

## Layout rules (tools/build_plates.py)
- 256 x 256 bed, 4 mm margin, 4 mm minimum gap between parts.
- X1C front-left exclusion corner is 18 x 28 mm; the builder keeps parts out of it (2 mm extra).
