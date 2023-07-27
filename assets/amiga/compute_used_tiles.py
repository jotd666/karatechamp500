import json,os,collections

dump_dir = r"C:\Users\Public\Documents\Amiga Files\WinUAE"
clut_tile_dump = os.path.join(dump_dir,"used_tiles")
clut_sprite_dump = os.path.join(dump_dir,"used_tiles")

this_dir = os.path.dirname(__file__)

rw_json = os.path.join(this_dir,"used_tiles_and_sprites.json")

with open(clut_tile_dump,"rb") as f:
    tile_dump = f.read()
with open(clut_sprite_dump,"rb") as f:
    sprite_dump = f.read()

used_cluts_ = dict()
if os.path.exists(rw_json):
    with open(rw_json) as f:
        used_cluts_ = json.load(f)

used_cluts = {"tiles":collections.defaultdict(set), "sprites":collections.defaultdict(set)}
for kn,tv in used_cluts_.items():
    for k,v in tv.items():
        used_cluts[kn][int(k)] = set(v)

# all alphanum chars can use those cluts
alpha_clut = {0,
    2,
    14,
    17,
    18,
    19,
    22}
for k in range(10+26+1):
    used_cluts["tiles"][k].update(alpha_clut)


for tile_index in range(256):
    offset = tile_index*256
    for clut_index in range(256):
        if tile_dump[offset+clut_index]:
            color_code = (clut_index>> 3) & 0x1f
            tile_code =  tile_index + ((clut_index & 7) << 8);
            used_cluts["tiles"][tile_code].add(color_code)

for sprite_index in range(256):
    offset = sprite_index*256
    for attr in range(256):
        if sprite_dump[offset+attr]:
            color_code = attr& 0xF
            bank = ((attr & 0x60) >> 5)
            print(bank)
            tile_code = tile_index + ((attr & 0x10) << 4)
            used_cluts["sprites"][tile_code].add(color_code)

for k in ["tiles","sprites"]:
    used_cluts[k] = {k:sorted(v) for k,v in sorted(used_cluts[k].items())}

with open(rw_json,"w") as f:
   json.dump(used_cluts,f,indent=2)
