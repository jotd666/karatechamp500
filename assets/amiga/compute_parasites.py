import glob,os,json,collections

# I don't know why but the game has a tendency to use unused sprites briefly or with wrong clut
# scan the manually filled "sprites/parasite" dir and ban those sprite/tile combinations

this_dir = os.path.dirname(__file__)
unused_tile_cluts = collections.defaultdict(set)
unused_sprite_cluts = collections.defaultdict(set)

rw_json = os.path.join(this_dir,"parasite_tiles_and_sprites.json")
if os.path.exists(rw_json):
    with open(rw_json) as f:
        parasite = json.load(f)
    # key as integer, list as set for faster lookup (not that it matters...)
    unused_tile_cluts_ = {int(k):set(v) for k,v in parasite["tiles"].items()}
    unused_sprite_cluts_ = {int(k):set(v) for k,v in parasite["sprites"].items()}
    for k,v in unused_tile_cluts_:
        unused_tile_cluts[k] = v
    for k,v in unused_sprite_cluts_.items():
        unused_sprite_cluts[k] = v


pdir = os.path.join(this_dir,"dumps","sprites","parasite","*.png")
for p in glob.glob(pdir):
    pname = os.path.basename(os.path.splitext(p)[0]).split("_")[1:]
    unused_sprite_cluts[int(pname[0])].add(int(pname[1]))

unused_sprite_cluts = {k:list(v) for k,v in unused_sprite_cluts.items()}
unused_tile_cluts = {k:list(v) for k,v in unused_tile_cluts.items()}

with open(rw_json,"w") as f:
    json.dump({"sprites":unused_sprite_cluts,"tiles":unused_tile_cluts},f,indent=2)