import os,re,bitplanelib,ast,json
from PIL import Image,ImageOps


import collections



this_dir = os.path.dirname(__file__)
src_dir = os.path.join(this_dir,"../../src/amiga")
ripped_tiles_dir = os.path.join(this_dir,"../tiles")
dump_dir = os.path.join(this_dir,"dumps")

NB_POSSIBLE_SPRITES = 1536  #64+64 alternate

rw_json = os.path.join(this_dir,"used_cluts.json")
if os.path.exists(rw_json):
    with open(rw_json) as f:
        used_cluts = json.load(f)
    # key as integer, list as set for faster lookup (not that it matters...)
    used_cluts = {int(k):set(v) for k,v in used_cluts.items()}
else:
    print("Warning: no {} file, no tile/clut filter, expect BIG graphics.68k file")
    used_cluts = None


dump_it = True

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


def dump_rgb_cluts(rgb_cluts,name):
    out = os.path.join(dump_dir,f"{name}_cluts.png")
    w = 16
    nb_clut_per_row = 4
    img = Image.new("RGB",(w*(nb_clut_per_row+1)*4,w*len(rgb_cluts)//nb_clut_per_row))
    x = 0
    y = 0
    row_count = 0
    for clut in rgb_cluts:
        # undo the clut correction so it's the same as MAME
        for color in [clut[0],clut[2],clut[1],clut[3]]:
            for dx in range(w):
                for dy in range(w):
                    img.putpixel((x+dx,y+dy),color)
            x += dx
        row_count += 1
        if row_count == 4:
            x = 0
            y += dy
            row_count = 0

    img.save(out)


# 32 colors 16+16 (alternate)
palette = block_dict["palette"]["data"]


##print(len({tuple(x) for x in palette}))
# looks that there are only 32 cluts for 16 colors totol

palette = [tuple(x) for x in palette]

with open(os.path.join(src_dir,"palette_.68k"),"w") as f:
    bitplanelib.palette_dump(palette,f,pformat=bitplanelib.PALETTE_FORMAT_ASMGNU)


character_codes_list = list()

# group palette 4 by 4
bg_cluts = [palette[i:i+4] for i in range(0,128,4)]

sprite_cluts = [palette[i:i+4] for i in range(128,256,4)]


for k,chardat in enumerate(block_dict["tile"]["data"]):
    # k < 0x100: normal tileset
    # k >= 0x100: alternate pack ice tileset
    img = Image.new('RGB',(8,8))

    character_codes = list()

    for cidx,colors in enumerate(bg_cluts[0:1]):
        if not used_cluts or (k in used_cluts and cidx in used_cluts[k]):
            d = iter(chardat)
            for i in range(8):
                for j in range(8):
                    v = next(d)
                    img.putpixel((j,i),colors[v])
            character_codes.append(bitplanelib.palette_image2raw(img,None,colors))
        else:
            character_codes.append(None)
    character_codes_list.append(character_codes)

    if dump_it:
        scaled = ImageOps.scale(img,5,0)
        scaled.save(os.path.join(dump_dir,f"char_{k:02x}.png"))


##with open(os.path.join(this_dir,"sprite_config.json")) as f:
##    sprite_config = {int(k):v for k,v in json.load(f).items()}

sprite_config = {i:{"name":"sprite"} for i in range(len(block_dict["sprite"]["data"]))}

sprites = collections.defaultdict(dict)

clut_index = 12  # temp


# pick a clut index with different colors
# it doesn't matter which one
for clut in sprite_cluts:
    if len(clut)==len(set(clut)):
        spritepal = clut
        break
else:
    # can't happen
    raise Exception("no way jose")


for k,data in sprite_config.items():
    sprdat = block_dict["sprite"]["data"][k]
    print(k)
    d = iter(sprdat)
    img = Image.new('RGB',(16,16))
    y_start = 0


    for i in range(16):
        for j in range(16):
            v = next(d)
            if j >= y_start:
                img.putpixel((j,i),spritepal[v])

    spr = sprites[k]
    spr["name"] = data['name']
    mirror = any(x in data["name"] for x in ("left","right"))

    right = None
    outname = f"{k:02x}_{clut_index}_{data['name']}.png"

    left = bitplanelib.palette_image2sprite(img,None,spritepal)
    if mirror:
        right = bitplanelib.palette_image2sprite(ImageOps.mirror(img),None,spritepal)

    spr["left"] = left
    spr["right"] = right

    if dump_it:
        scaled = ImageOps.scale(img,5,0)
        scaled.save(os.path.join(dump_dir,outname))



with open(os.path.join(src_dir,"graphics_.68k"),"w") as f:
    f.write("\t.global\tcharacter_table\n")
    f.write("\t.global\tsprite_table\n")


    f.write("character_table:\n")
    for i,c in enumerate(character_codes_list):
        # c is the list of the same character with 31 different cluts
        if c is not None:
            f.write(f"\t.long\tchar_{i}\n")
        else:
            f.write("\t.long\t0\n")
    for i,c in enumerate(character_codes_list):
        if c is not None:
            f.write(f"char_{i}:\n")
            # this is a table
            for j,cc in enumerate(c):
                if cc is None:
                    f.write(f"\t.word\t0\n")
                else:
                    f.write(f"\t.word\tchar_{i}_{j}-char_{i}\n")

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
            name = f"{sprite['name']}_{i:02x}"
            sprite_names[i] = name
            f.write(name)
        else:
            f.write("0")
        f.write("\n")

    for i in range(NB_POSSIBLE_SPRITES):
        sprite = sprites.get(i)
        if sprite:
            name = sprite_names[i]
            f.write(f"{name}:\n")
            for j in range(8):
                f.write("\t.long\t")
                f.write(f"{name}_{j}")
                f.write("\n")

    for i in range(NB_POSSIBLE_SPRITES):
        sprite = sprites.get(i)
        if sprite:
            name = sprite_names[i]
            for j in range(8):
                f.write(f"{name}_{j}:\n")

                for d in ["left","right"]:
                    bitmap = sprite[d]
                    if bitmap:
                        f.write(f"\t.long\t{name}_{j}_sprdata\n".replace(d,opposite[d]))
                    else:
                        # same for both
                        f.write(f"\t.long\t{name}_{j}_sprdata\n")

    f.write("\t.section\t.datachip\n")

    for i in range(NB_POSSIBLE_SPRITES):
        sprite = sprites.get(i)
        if sprite:
            name = sprite_names[i]
            for j in range(8):
                # clut is valid for this sprite

                for d in ["left","right"]:
                    bitmap = sprite[d]
                    if bitmap:
                        sprite_label = f"{name}_{j}_sprdata".replace(d,opposite[d])
                        f.write(f"{sprite_label}:\n\t.long\t0\t| control word")
                        bitplanelib.dump_asm_bytes(sprite[d],f,mit_format=True)
                        f.write("\t.long\t0\n")
