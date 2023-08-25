import os,re,bitplanelib,ast,json,glob
from PIL import Image,ImageOps


import collections


def ensure_empty(d):
    if os.path.exists(d):
        for p in glob.glob(os.path.join(d,"*.png")):
            os.remove(p)
    else:
        os.mkdir(d)

this_dir = os.path.dirname(__file__)
src_dir = os.path.join(this_dir,"../../src/amiga")
ripped_tiles_dir = os.path.join(this_dir,"../tiles")

NB_POSSIBLE_SPRITES = 1536  #64+64 alternate

with open(os.path.join(this_dir,"no_mirror.json")) as f:
    no_mirror_list = json.load(f)

no_mirror_sprites = set()
for nm in no_mirror_list:
    if nm.isdigit():
        no_mirror_sprites.add(nm)
    else:
        s,e = map(int,nm.split("-"))
        no_mirror_sprites.update(range(s,e+1))


# default: -2: several color configs
#          -1: only red & white color configs (player)
#          >=0: single color config
special_color_sprites = [254]*0x600

rw_json = os.path.join(this_dir,"used_tiles_and_sprites.json")
if os.path.exists(rw_json):
    with open(rw_json) as f:
        used_cluts = json.load(f)
    # key as integer, list as set for faster lookup (not that it matters...)
    used_tile_cluts_ = {int(k):set(v) for k,v in used_cluts["tiles"].items()}
    used_sprite_cluts = {int(k):set(v) for k,v in used_cluts["sprites"].items()}



    # add score points in 2 colors too
    for i in range(1009,1019):
        special_color_sprites[i] = 255

    used_tile_cluts = collections.defaultdict(set)
    used_tile_cluts.update(used_tile_cluts_)
else:
    print("Warning: no {} file, no tile/clut filter, expect BIG graphics.68k file")
    used_tile_cluts = None
    used_sprite_cluts = None


# all alphanum chars can use those cluts
# there are also special CLUTs for "KICK" chars (3rd line)
# including frame at the bottom! 0x35->0x37
alpha_clut = {0,
    2,
    14,
    17,
    18,
    19,
    21,
    22,
    23}
for k in range(10+26+1):
    used_tile_cluts[k].update(alpha_clut)


# special symbols in highscore table
for k in range(0x25,0x30):
    used_tile_cluts[k].update({0x15,0x16})

# 2P score frame (rest of tiles are logged in .json file)
for k in range(0xE0,0xEA+1):
    used_tile_cluts[k].add(0x12)
used_tile_cluts[0xD0].add(0x12)

wr_exceptions = {1023,1024,1068,0x83,0x84,0x5F}
# don't red/white some objects lost around player red/white frames
wr_exceptions.update(range(500,513+1))
wr_exceptions.update(range(900,916+1))
wr_exceptions.update(range(1000,1007+1))
wr_exceptions.update(range(1049,1049+4))  # THE END sprite
for k,v in used_sprite_cluts.items():
    if 0 < k < 1121 and k not in wr_exceptions:
        special_color_sprites[k] = 255

# player crying
for i in range(0x4CE,0x4D6):
    special_color_sprites[i] = 255
# player breaks planks
for i in range(0x5DB,0x600):
    special_color_sprites[i] = 255

for k,v in enumerate(special_color_sprites):
    if v==255:
        used_sprite_cluts[k] = {1,2}

# force girls sprites with proper CLUTs (too tedious to rip manually)
for girl_start_sprite,color in (
(0x588,2),   # level 1 (pier)
(0x5C0,2),   # level 2
(0x528,2),   # level 4 (bridge)
(0x5B0,2),   # level 5
(0x550,4),   # level 6 (field)
(0x5D0,2),   # level 7 (mill)
(0x598,1),   # level 8 (city)
(0x5A0,2),   # level 9 (tipee)
(0x5A8,4),   # level (??)
(0x5C8,1),   # level 11 (dojo)
(0x568,3),   # level 12 (moonlight)
):
    for i in range(girl_start_sprite,girl_start_sprite+8):
        used_sprite_cluts[i] = {color}

# if sprite is used with clut 1, then it's used with clut 2 (white/red)
#parasite_sprites = set(range(1034,1098))
#parasite_sprites.update(range(21,26))
parasite_sprites = set()

used_sprite_cluts = {k:v for k,v in used_sprite_cluts.items() if k not in parasite_sprites}

dump_tiles = True
dump_sprites = False

dump_dir = os.path.join(this_dir,"dumps")

if dump_tiles or dump_sprites:
    if not os.path.exists(dump_dir):
        os.mkdir(dump_dir)
    if dump_tiles:
        tile_dump_dir = os.path.join(dump_dir,"tiles")
        ensure_empty(tile_dump_dir)
    if dump_sprites:
        sprite_dump_dir = os.path.join(dump_dir,"sprites")
        ensure_empty(sprite_dump_dir)

def dump_asm_bytes(*args,**kwargs):
    bitplanelib.dump_asm_bytes(*args,**kwargs,mit_format=True)


opposite = {"left":"right","right":"left"}

block_dict = {}

# hackish convert of c gfx table to dict of lists
# (Thanks to Mark Mc Dougall for providing the ripped gfx as C tables)
with open(os.path.join(this_dir,"..","kchampvs2_gfx.c")) as f:
    block = []
    block_name = ""
    start_block = False

    for line in f:
        if "uint8" in line:
            # start group
            start_block = True
            if block:
                txt = "".join(block).strip().strip(";")
                block_dict[block_name] = {"size":size,"data":ast.literal_eval(txt)}
                block = []
            block_name = line.split()[1].split("[")[0]
            size = int(line.split("[")[2].split("]")[0])
        elif start_block:
            line = re.sub("//.*","",line)
            line = line.replace("{","[").replace("}","]")
            block.append(line)

    if block:
        txt = "".join(block).strip().strip(";")
        block_dict[block_name] = {"size":size,"data":ast.literal_eval(txt)}




# 256 colors but only 20 unique colors used! I guess that the lack
# of colors per sprite was a problem!
# conveniently, there are never more than 16 different colors on the screen
palette = block_dict["palette"]["data"]


#print(len({tuple(x) for x in palette}))

palette_256 = [tuple(x) for x in palette]

# base palette. It can't contain the 20 used colors, but the 2 last colors can be set dynamically
# and 2 other colors can be changed dynamically too and it works for all levels & backgrounds!
palette_16 = bitplanelib.palette_dcw2palette("""    dc.w    $0000,$0fff,$0fcc,$0bbb,$04cf,$0ffc,$000f,$0800
    dc.w    $080c,$0f00,$0c80,$0cc0,$0fc0,$0ff0,$0000,$0ccc""")
palette_16_rgb4 = [bitplanelib.to_rgb4_color(p) for p in palette_16]

# RGB4 dict contains the used 20 colors, as RGB4
rgb4_dict = {bitplanelib.round_color(p,0xF0):p for p in palette_256}

# there are 14 different setups (matching the 12 levels, title, and highscore palette)
# this table has been computed from a palette optmization done in the previous/given up version
# of my Karate Champ port (no transcode) where I noticed that there was never more than 16 simultaneous
# colors on screen for some reason
# for instance, the bull color only appears in levels where the background also has this color or has
# enough free color for the color to be used without using more than 16 colors. Same for some other colors.
#
# basically, the 14 first colors of the palette are used, 2 extra colors are per level, and 0 to 2 colors aren't used
# and can be replaced by colors that are used in this level

# load a dict of tile/code => level where it's used. It can be used in several levels it doesn't matter the same
# colors should be always at the same location

tile_code_per_level = collections.defaultdict(dict)
level_tiles = collections.defaultdict(collections.Counter)

level_tiles_dir = os.path.join(this_dir,"level_tiles")
for level_index in range(0,12):
    level_dir = os.path.join(level_tiles_dir,f"{level_index+1:02d}")
    os.stat(level_dir)
    for level_file in glob.glob(os.path.join(level_dir,"*.bin")):
        with open(level_file,"rb") as f:
            tiles = f.read(0x400)
            attributes = f.read(0x400)
            for tile_index,clut_index in zip(tiles,attributes):
                color_code = (clut_index>> 3) & 0x1f
                tile_code =  tile_index + ((clut_index & 7) << 8);
                tile_code_per_level[tile_code][color_code] = level_index
                level_tiles[level_index][(hex(tile_code),hex(color_code))] += 1  # for debug
                if tile_code not in used_tile_cluts:
                    used_tile_cluts[tile_code] = set()
                used_tile_cluts[tile_code].add(color_code)

# hardcode the letter cluts of plank breaking stage. No need to add more memory footprint
# for a color configuration not used elsewhere
for k in [ord(a)-55 for a in "PERFECTCHALLENGESTAGE"]+[0,2]:
    used_tile_cluts[k].add(20)
    tile_code_per_level[k][20] = 2

# very few colors on bonus stages need to be changed so we can always match the scenery
# 16-color palette. So very few compromises!
sprite_replacement_color_dict = {
(0xF0,0x80,0x80):(0xF0,0xC0,0xC0),  # bonzai leaves but also a color in planks
(0xA0,0xA0,0xA0):(0xB0,0xB0,0xB0)  # rock
}
# more for tiles
grayer = {(0xC0,0xC0,0xC0):(0xB0,0xB0,0xB0)}
greener = {(0x80,0xF0,0):(0,0xC0,0)}
# global compromise on a kind of gray very close to the other
# allowing us to keep 16 colors max in all configurations
tile_replacement_color_dict = {
(211,2) : grayer,  # point dot color 0xCCC isn't available everywhere, 0xBBB is
(0x5a6,2) : grayer,
(0x5a4,2) : grayer,
(0x5a3,2) : grayer,
(0x5AC,0x19) : greener,
(0x5AD,0x19) : greener
}


for x in range(0x54C,0x55D):
    tile_replacement_color_dict[x,0] = grayer
    tile_replacement_color_dict[x,0x1F] = grayer

params = [
[{},[0xCA3,0xCCC]],  # 0
[{},[0xCA3,0xCCC]], #1
[{},[0x0C0,0xCCC]], #2
[{0x80C:0xC0},[0xCA3,0x8F0]], #3
[{0x80C:0xC0},[0xCA3,0x8F0]], #4
[{},[0xCA3,0xCCC]], #5
[{0x80C:0xC0},[0xCA3,0x8F0]], #6
[{0x80C:0xC0,0xC80:0xCA3},[0x8F0,0xCCC]], #7
[{0xC80:0x0C0,0x80C:0xC0},[0xCA3,0xCCC]],  #8 wasteful 2 identical colors, but some tiles are shared!
[{},[0xC0,0xCA3]],   #9
[{0x80C:0xC0},[0xCA3,0xCCC]],  #10
[{},[0xCA3,0xCCC]],  #11
[{0xFC0:0xC0},[0xCA3,0x8F0]],  #12
[{},[0,0xCCC]],  #13
[{0xFC0:0x0C0,0x80C:0x0C0},[0xCA3,0x8F0]], #14 bonus girls same as level 4 with more green

]

contextual_palettes = [[repl.get(c,c) for c in palette_16_rgb4[:14]]+last_cols for repl,last_cols in params]

palette_16_rgb = [bitplanelib.rgb4_to_rgb_triplet(p) for p in palette_16_rgb4]
palettes_to_try = [[bitplanelib.rgb4_to_rgb_triplet(p) for p in cp] for cp in contextual_palettes]
if os.path.exists(dump_dir):
    with open(os.path.join(dump_dir,"palettes.json"),"w") as f:
        json.dump(palettes_to_try,f,indent=2)

palette_256_as_rgb4 = [bitplanelib.to_rgb4_color(x) for x in palette_256]
palette_256_rounded = [bitplanelib.round_color(x,0xF0) for x in palette_256]
# there aren't cluts in this game, but 256 colors = 4*32 groups of colors. The color code is a value 0-31
# so technically there's a clut table

clut_table = [palette_256_rounded[i:i+4] for i in range(0,256,4)]


# dump base palette
with open(os.path.join(src_dir,"palette.68k"),"w") as f:
    for c in palettes_to_try:
        bitplanelib.palette_dump(c,f,pformat=bitplanelib.PALETTE_FORMAT_ASMGNU)


character_codes_list = list()

# group palette 4 by 4


bg_cluts = clut_table[32:]

sprite_cluts = clut_table[:32]

global_missing = set()
levels_where_missing = set()

for k,chardat in enumerate(block_dict["tile"]["data"]):
    img = Image.new('RGB',(8,8))
    character_codes = list()

    for cidx,colors in enumerate(bg_cluts):

        tile_rep_dict = tile_replacement_color_dict.get((k,cidx)) or {}

        if used_tile_cluts is None or (k in used_tile_cluts and cidx in used_tile_cluts[k]):
            d = iter(chardat)
            for i in range(8):
                for j in range(8):
                    v = next(d)
                    cv = colors[v]
                    img.putpixel((j,i),tile_rep_dict.get(cv,cv))


            sd = tile_code_per_level.get(k)

            if sd is None:
                level = 0
            else:
                level = sd.get(cidx)
                if level is None:
                    level = 0   # base palette
                else:
                    level += 1  # level palette

            pal = palettes_to_try[level]
            try:
                bdata = bitplanelib.palette_image2raw(img,None,pal)
                character_codes.append(bdata)
            except (KeyError,bitplanelib.BitplaneException):
                repcolors = {tile_rep_dict.get(cv,cv) for cv in colors}
                missing = set(repcolors)-set(pal)
                global_missing.update(missing)
                levels_where_missing.add(level)
                msg = f"No matching palette for tile ${k:x}/{k} col ${cidx:x}, colors {repcolors} in level palette {level}, palette={pal}, missing={missing}"
                #raise Exception(msg)
                print(msg)
                character_codes.append(bytes(32))

            if dump_tiles:
                scaled = ImageOps.scale(img,5,0)
                scaled.save(os.path.join(tile_dump_dir,f"char_{k:02}_{cidx}.png"))
        else:
            character_codes.append(None)
    character_codes_list.append(character_codes)

if global_missing:
    print(f"Tile globally missing colors: {global_missing}, on levels: {levels_where_missing}")
##with open(os.path.join(this_dir,"sprite_config.json")) as f:
##    sprite_config = {int(k):v for k,v in json.load(f).items()}

sprite_config = {i:{"name":"sprite"} for i in range(len(block_dict["sprite"]["data"]))}

sprites = collections.defaultdict(dict)

side = 16
transparent = (202,0,202)


for k,chardat in enumerate(block_dict["sprite"]["data"]):
    img = Image.new('RGB',(side,side))

    sprite_codes = list()

    for cidx,colors in enumerate(sprite_cluts):
        if colors[0]==(0,0,0):      # if first color of clut is black it means transparent
            colors[0] = transparent

        if not used_sprite_cluts or (k in used_sprite_cluts and cidx in used_sprite_cluts[k]):
            d = iter(chardat)
            for i in range(side):
                for j in range(side):
                    v = next(d)
                    pc = sprite_replacement_color_dict.get(colors[v],colors[v])
                    img.putpixel((j,i),pc)

            for pal in palettes_to_try:
                try:
                    left = bitplanelib.palette_image2raw(img,None,pal,blit_pad=True,generate_mask=True,mask_color=transparent)
                    if k in no_mirror_sprites:
                        right = left
                    else:
                        right = bitplanelib.palette_image2raw(ImageOps.mirror(img),None,pal,blit_pad=True,generate_mask=True,mask_color=transparent)
                    sprite_codes.append([left,right])
                    break
                except bitplanelib.BitplaneException:
                    pass
            else:
                print("Warning: No matching palette for sprite {0} ({0:0x}), colors {1}".format(k,colors))
                sprite_codes.append(None)
            if dump_sprites:
                scaled = ImageOps.scale(img,5,0)
                scaled.save(os.path.join(sprite_dump_dir,f"sprite_{k:02}_{cidx}.png"))
        else:
            sprite_codes.append(None)
    if any(sprite_codes):
        sprites[k] = {"name":f"sprite_{k:02}","data":sprite_codes}



bitplane_cache = dict()
nb_bitplanes = 4+1

# 16*16 on 4 bitplanes with 16 bits blit padding
chunk_size = 16*4
with open(os.path.join(src_dir,"graphics.68k"),"w") as f:
    for x in ["special_color_sprites","character_table","sprite_table"]:
        f.write(f"\t.global\t{x}\n")


    f.write("character_table:\n")
    for i,c in enumerate(character_codes_list):
        # c is the list of the same character with 31 different cluts
        if any(c):
            f.write(f"\t.long\tchar_{i}\n")
        else:
            f.write("\t.long\t0\n")
    for i,c in enumerate(character_codes_list):
        if any(c):
            f.write(f"char_{i}:\n")
            # this is a table
            for j,cc in enumerate(c):
                if cc is None:
                    f.write(f"\t.byte\t0\n")
                else:
                    f.write(f"\t.byte\tchar_{i}_{j}_bptr-char_{i}\n")
            for j,cc in enumerate(c):
                if cc is not None:
                    f.write(f"char_{i}_{j}_bptr:\n")
                    f.write(f"\t.word\tchar_{i}_{j}-char_{i}_{j}_bptr\n")

            for j,cc in enumerate(c):
                if cc is not None:
                    f.write(f"char_{i}_{j}:")
                    bitplanelib.dump_asm_bytes(cc,f,mit_format=True)
    f.write("sprite_table:\n")

    sprite_names = [None]*NB_POSSIBLE_SPRITES
    for i in range(NB_POSSIBLE_SPRITES):
        sprite = sprites.get(i)
        f.write("\t.long\t")
        if sprite:
            name = f"{sprite['name']}"
            sprite_names[i] = name
            f.write(f"{name}")
        else:
            f.write("0")
        f.write("\n")

    plane_cache_id = 0
    for sprite_index in range(NB_POSSIBLE_SPRITES):
        sprite = sprites.get(sprite_index)
        # color table can be packed in 2 cases: either 2 colors red/white or one
        packed_color_table = special_color_sprites[sprite_index] == 255
        if sprite:
            name = sprite_names[sprite_index]
            f.write(f"{name}:\n")
            data = sprite["data"]

            # count, see if we have only 1 block
            nb_blocks = sum(bool(blocks) for blocks in data)
            if nb_blocks == 1:
                packed_color_table = True
                special_color_sprites[sprite_index] = next(i for i,blocks in enumerate(data) if blocks)

            # we have to reference bitplanes here or 0 if nothing to draw, just erase
            for i,blocks in enumerate(data):
                if blocks:
                    f.write(f"\t.word\t{name}_{i}-{name}\n")
                elif not packed_color_table:
                    f.write("\t.word\t0\n")

            for i,blocks in enumerate(data):
                if blocks:
                    f.write(f"{name}_{i}:\n")
                    for lr in ["left","right"]:
                        if lr=="right" and sprite_index in no_mirror_sprites:
                            lr = "left"
                        f.write(f"\t.word\t{name}_{lr}_{i}-{name}_{i}\n")


                    for lr,block in zip(["left","right"],blocks):
                        if lr=="right" and sprite_index in no_mirror_sprites:
                            break
                        f.write(f"{name}_{lr}_{i}:\n")
                        for j in range(0,nb_bitplanes):
                            plane = block[j*chunk_size:(j+1)*chunk_size]
                            plane_name = bitplane_cache.get(plane)
                            if plane_name:
                                pass
                            else:
                                plane_name = f"plane_{plane_cache_id:03d}"
                                plane_cache_id += 1
                                bitplane_cache[plane] = plane_name

                            if j==nb_bitplanes-1 and not any(plane):
                                # mask plane: make it zero if all zeroes, so game code
                                # detects it and skips the tile altogether
                                plane_name = "0x0"
                            f.write(f"\t.long   {plane_name}\n")

    f.write("* table of sprites that can only be white or red (players, scores) \nspecial_color_sprites:")
    bitplanelib.dump_asm_bytes(special_color_sprites,f,mit_format=True)

    f.write("\n\t.section\t.datachip\n")
    for plane,plane_name in sorted(bitplane_cache.items(),key=lambda d:d[1]):
        f.write(f"{plane_name}:")
        bitplanelib.dump_asm_bytes(plane,f,mit_format=True)