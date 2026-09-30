# Print-in-Place Knuckle Hinge — POC Notes

## Goal
Prototype a print-in-place hinge mechanism (inspired by a reference card-riser
product) so the riser's "lip" and "backplate" can print flat and fold up to a
hard 90° stop, instead of printing at an angle and needing supports.

## Software / tools used
- **OpenSCAD** (headless, run via CLI in a Linux sandbox — `openscad --render -o out.png/stl file.scad`)
  used for all modeling, manifold checks (`--render`, checking for `Simple: yes`),
  and STL export. No local OpenSCAD install needed on your end for any of this.
- **Three.js**, embedded in a self-contained published HTML page, for an
  in-chat orbitable 3D STL preview (later found unreliable in-browser, likely
  CDN-blocking — Babylon.js Sandbox at sandbox.babylonjs.com was noted as a
  no-setup fallback / drag-and-drop alternative).
- Reference photos of an existing card riser (interleaved-tab spine hinge)
  used to sanity-check tab proportions and stop-feature size.

## Key discoveries, in order encountered
1. **Terminology**: this style of joint is a *knuckle hinge* (interleaved
   "teeth"/knuckles + through-pin). A feature that hard-limits rotation is a
   *hinge stop*.
2. **Round vs. flat knuckles**: first pass used round cylindrical knuckles;
   switched to flush rectangular tabs to match the reference photos.
3. **Critical bug — open C-shaped pin holes**: making knuckles flush/flat-sided
   meant each tooth only wrapped *half* the pin's circumference (open toward
   the axis gap). The pin had nothing stopping it sliding out sideways —
   confirmed by cross-section renders. Fix: each knuckle needs a small
   fully-round boss (closed 360° loop of material) around the pin, even if
   the rest of the tab stays flat.
4. **"Object may not be a 2-manifold" (F6 warning)**: caused by shapes that
   are exactly tangent (touching along a zero-width line/plane) instead of
   truly overlapping in volume — e.g. a knuckle cylinder exactly tangent to
   the flat slab face. Fixed with a tiny (`eps`) deliberate overlap wherever
   two solids meet at a shared boundary.
5. **Knuckle boss poking past the plate surface**: a boss radius bigger than
   half the plate thickness bulges out the top/bottom faces instead of
   sitting flush. Fixed by clipping the boss to the plate's thickness.
6. **Exact 90° stop via body contact alone (no separate tab)**: derived the
   condition geometrically and verified it empirically (boolean-intersection
   sweeps across angles, not just eyeballing renders):
   - Contact between the fixed plate's face and the rotating plate's inner
     corner happens exactly at 90° only when `recede == plate_thickness / 2`
     (`recede` = how far the plate body is set back from the pivot axis).
   - `recede` also has to be ≥ `pin_hole_radius + wall_thickness` so there's
     enough material around the pin hole.
   - These two requirements compete for the same budget — thin plates with a
     wide pin can't hit both at once, which is why plate thickness and pin
     diameter both had to move (see final spec below).
7. **A large stop tab looked "massive" next to the reference** — the
   reference's raised feature was a thin low ridge, likely just a
   registration nub, not a structural stop block. Once the exact-90°
   body-contact stop was working, the separate tab was removed entirely.
8. **Discorectangle (stadium-shaped) knuckle** instead of a plain circular
   boss — implemented as a `hull()` of two circles. At the thickness/pin
   sizes in play here the "straight" section of the stadium is small
   (~0.2mm) because the same tight budget from #6 limits how elongated it
   can be without either poking past the plate face or losing wall margin.
9. **Print-in-place fusing**: first physical print didn't hinge at all —
   almost certainly the gap between interleaved segments (`knuckle_gap`,
   originally 0.6mm) was small enough for oozing/first-layer squish to bridge
   and weld the segments solid. Widened to 1.2mm.
10. **"Still touching" — turned out to be a viewing-angle illusion**: a
    screenshot looking nearly *down the length* of the hinge made adjacent
    round-capped knuckles look continuous, because the curved knuckle surface
    visually occludes the real gap from that angle. A true top-down or
    side-on view (and a direct boolean-intersection check) confirmed a real,
    clean gap was present the whole time. Lesson: verify gaps with geometry
    checks or a revealing camera angle, not a single grazing-angle screenshot.
11. **Printing the two leaves as fully separate STL files** (rather than one
    file with the parts merely spaced apart) was the final, most robust
    answer to the fusing risk — removes any reliance on gap size or printer
    tuning entirely.

## Final spec (current state)
- 3 knuckles total, pattern A–B–A (plate A owns the two outer knuckles,
  plate B owns the middle one).
- Plate size: 20mm × ~19–20mm footprint, **4mm thick**.
- Pin: **1mm rod** (brass rod or steel wire recommended over 1.75mm filament —
  filament was too fat for the wall-thickness budget at this scale),
  inserted by hand after printing.
- `knuckle_gap` (Y clearance between interleaved segments): **1.2mm**.
- `wall` (material around the pin hole): **1.0mm**.
- Stop mechanism: pure body-contact at exactly 90°, no separate stop tab.
- Knuckle boss shape: discorectangle (stadium), fully enclosing the pin hole.
- Delivered as **two independent STL files** (plate A, plate B) — not
  combined on one virtual bed — for printing.

## Open items / things to revisit
- Confirm the 1mm-pin fit in hand (brass rod vs. steel wire vs. filament) —
  clearance was tuned on paper, not yet print-tested at time of writing.
- If the discorectangle knuckle needs to look more pronounced, plate
  thickness would need to increase past 4mm to free up more budget.
- Once the mechanism is confirmed on a physical print, this same approach
  (interleaved knuckles + exact-90° body stop) can be scaled up to the real
  riser dimensions.
