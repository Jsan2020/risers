"""Build Bambu Studio plate projects from STLs, reusing the profile in wake-v30/Wake-v30s.3mf.
usage: python3 tools/build_plates.py   (run from the repo root)
"""
import re, struct, zipfile, math, itertools, os
import numpy as np

BASE = "wake-v30/Wake-v30s.3mf"          # supplies the Wave Risers PETG process/printer settings
FULL = "wake-v30/wake_v30_flat_riser.stl"
EXT  = "wake-v30/extensions/wake_extension.stl"
BED, MARGIN, GAP = 256.0, 4.0, 4.0

def load_stl(fn):
    b = open(fn, "rb").read()
    if b[:5] == b"solid" and b"facet" in b[:400]:
        v = np.array(re.findall(rb"vertex\s+(\S+)\s+(\S+)\s+(\S+)", b), dtype=float).reshape(-1, 3, 3)
    else:
        n = struct.unpack("<I", b[80:84])[0]
        a = np.frombuffer(b[84:84 + 50 * n], dtype=np.dtype([("n", "<3f4"), ("v", "<9f4"), ("a", "<u2")]))
        v = a["v"].reshape(-1, 3, 3).astype(float)
    pts = v.reshape(-1, 3)
    mn, mx = pts.min(0), pts.max(0)
    c = (mn + mx) / 2
    uniq, inv = np.unique(np.round(pts - c, 5), axis=0, return_inverse=True)
    return dict(verts=uniq, tris=inv.reshape(-1, 3), size=mx - mn, center=c)

def obj_model(mesh, uid, cid):
    vs = "\n".join(f'     <vertex x="{x:.6g}" y="{y:.6g}" z="{z:.6g}"/>' for x, y, z in mesh["verts"])
    ts = "\n".join(f'     <triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in mesh["tris"])
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <resources>
  <object id="{cid}" p:UUID="{uid}" type="model">
   <mesh>
    <vertices>
{vs}
    </vertices>
    <triangles>
{ts}
    </triangles>
   </mesh>
  </object>
 </resources>
 <build/>
</model>
'''

def footprint(mesh, rot):
    w, d = mesh["size"][0], mesh["size"][1]
    return (d, w) if rot else (w, d)

def build(name, items, out):
    """items: list of (mesh_key, cx, cy, rot90)"""
    meshes = {"full": load_stl(FULL), "ext": load_stl(EXT)}
    # checks: inside bed with margin, no overlaps with at least GAP between footprints
    boxes = []
    for k, cx, cy, rot in items:
        w, d = footprint(meshes[k], rot)
        boxes.append((cx - w / 2, cx + w / 2, cy - d / 2, cy + d / 2))
    for i, (x0, x1, y0, y1) in enumerate(boxes):
        assert x0 >= MARGIN - 1e-6 and y0 >= MARGIN - 1e-6 and x1 <= BED - MARGIN + 1e-6 and y1 <= BED - MARGIN + 1e-6, (name, i, boxes[i])
    mingap = 1e9
    for (i, a), (j, b) in itertools.combinations(enumerate(boxes), 2):
        gx = max(b[0] - a[1], a[0] - b[1]); gy = max(b[2] - a[3], a[2] - b[3])
        gap = max(gx, gy); mingap = min(mingap, gap)
        assert gap >= GAP - 1e-6, (name, i, j, gap)
    zc = meshes["full"]["size"][2] / 2
    zin = zipfile.ZipFile(BASE)
    drop = lambda n: n.startswith("3D/Objects/") or n.endswith(".png") or n in (
        "3D/3dmodel.model", "3D/_rels/3dmodel.model.rels", "Metadata/model_settings.config", "Metadata/cut_information.xml")
    zout = zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED)
    for n in zin.namelist():
        if not drop(n):
            zout.writestr(n, zin.read(n))
    rels, res, build_items, objs, insts, cuts = [], [], [], [], [], []
    for k, (key, cx, cy, rot) in enumerate(items, start=1):
        m = meshes[key]; oid = 2 * k; cid = 2 * k - 1
        fname = "wake_v30_flat_riser.stl" if key == "full" else "wake_extension.stl"
        zout.writestr(f"3D/Objects/object_{k}.model", obj_model(m, f"{k:04x}0000-81cb-4c03-9d28-80fed5dfa1dc", cid))
        rels.append(f' <Relationship Target="/3D/Objects/object_{k}.model" Id="rel-{k}" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>')
        res.append(f'''  <object id="{oid}" p:UUID="{k:08x}-61cb-4c03-9d28-80fed5dfa1dc" type="model">
   <components>
    <component p:path="/3D/Objects/object_{k}.model" objectid="{cid}" p:UUID="{k:04x}0000-b206-40ff-9872-83e8017abed1" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>
   </components>
  </object>''')
        rot_s = "0 1 0 -1 0 0 0 0 1" if rot else "1 0 0 0 1 0 0 0 1"
        build_items.append(f'  <item objectid="{oid}" p:UUID="{k:08x}-b1ec-4553-aec9-835e5b724bb4" transform="{rot_s} {cx:.6f} {cy:.6f} {zc:.6f}" printable="1"/>')
        c = m["center"]
        objs.append(f'''  <object id="{oid}">
    <metadata key="name" value="{fname}"/>
    <metadata key="extruder" value="1"/>
    <metadata face_count="{len(m['tris'])}"/>
    <part id="{oid - 1 + 1000}" subtype="normal_part" uuid="{k:08x}-2275-4b44-b0ce-b2fc32cb2ca0">
      <metadata key="name" value="{fname}"/>
      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>
      <metadata key="source_file" value="{fname}"/>
      <metadata key="source_object_id" value="0"/>
      <metadata key="source_volume_id" value="0"/>
      <metadata key="source_offset_x" value="{c[0]:.6g}"/>
      <metadata key="source_offset_y" value="{c[1]:.6g}"/>
      <metadata key="source_offset_z" value="{c[2]:.6g}"/>
      <mesh_stat face_count="{len(m['tris'])}" edges_fixed="0" degenerate_facets="0" facets_removed="0" facets_reversed="0" backwards_edges="0"/>
    </part>
  </object>''')
        insts.append(f'''    <model_instance>
      <metadata key="object_id" value="{oid}"/>
      <metadata key="instance_id" value="0"/>
      <metadata key="identify_id" value="{100 + k}"/>
    </model_instance>''')
        cuts.append(f' <object id="{oid}">\n  <cut_id id="0" check_sum="1" connectors_cnt="0"/>\n </object>')
    base_model = zin.read("3D/3dmodel.model").decode()
    head = base_model.split(" <resources>")[0]
    head = re.sub(r' <metadata name="Thumbnail_[^"]*">[^<]*</metadata>\n', "", head)
    head = re.sub(r'(CreationDate|ModificationDate)">[^<]*<', r'\1">2026-11-18<', head)
    model = head + " <resources>\n" + "\n".join(res) + '\n </resources>\n <build p:UUID="2c7c17d8-22b5-4d84-8835-1976022ea369">\n' + "\n".join(build_items) + "\n </build>\n</model>\n"
    zout.writestr("3D/3dmodel.model", model)
    zout.writestr("3D/_rels/3dmodel.model.rels", '<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n' + "\n".join(rels) + "\n</Relationships>")
    ms = zin.read("Metadata/model_settings.config").decode()
    plate_head = re.search(r"<plate>.*?(?=<model_instance>)", ms, re.S).group(0)
    plate_head = re.sub(r'\s*<metadata key="(thumbnail_file|thumbnail_no_light_file|top_file|pick_file)"[^>]*/>', "", plate_head)
    zout.writestr("Metadata/model_settings.config", '<?xml version="1.0" encoding="UTF-8"?>\n<config>\n' + "\n".join(objs) + "\n  " + plate_head + "\n".join(insts) + "\n  </plate>\n</config>\n")
    zout.writestr("Metadata/cut_information.xml", '<?xml version="1.0" encoding="utf-8"?>\n<objects>\n' + "\n".join(cuts) + "\n</objects>\n")
    zout.close()
    return mingap

F = (175.0, 67.4); E = (79.375, 67.4)
# three full pieces stacked along y, even spacing
def full_stack(cx):
    ys = [4 + 33.7 + i * (3 * 0 + 67.4 + 8) + 14.9 for i in range(3)]   # 8 mm between, centred in 256
    return [("full", cx, y, False) for y in ys]

plates = {}
# A: 3 full stacked on the right, 1 full turned 90 deg on the left
a_cx = BED - MARGIN - F[0] / 2
plates["plate_A_4_full"] = full_stack(a_cx) + [("full", MARGIN + F[1] / 2, BED / 2, True)]
# B: 3 full stacked on the right, 3 extensions turned 90 deg on the left
ys_e = [BED / 2 - (E[0] + GAP), BED / 2, BED / 2 + (E[0] + GAP)]
plates["plate_B_3_full_3_ext"] = full_stack(a_cx) + [("ext", MARGIN + E[1] / 2 + 0.6, y, True) for y in ys_e]
# C: 9 extensions, 3 x 3
xs = [BED / 2 + (i - 1) * (E[0] + GAP + 0.5) for i in range(3)]
ys = [BED / 2 + (j - 1) * (E[1] + 8) for j in range(3)]
plates["plate_C_9_ext"] = [("ext", x, y, False) for y in ys for x in xs]

os.makedirs("projects", exist_ok=True)
for name, items in plates.items():
    g = build(name, items, f"projects/{name}.3mf")
    print(f"{name}: {len(items)} parts, min gap between parts {g:.1f} mm")
