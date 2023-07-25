import os,re,bitplanelib,ast,json
from PIL import Image,ImageOps


import collections



this_dir = os.path.dirname(__file__)
src_dir = os.path.join(this_dir,"../../src/amiga")
ripped_tiles_dir = os.path.join(this_dir,"../tiles")
dump_dir = os.path.join(this_dir,"dumps")

NB_POSSIBLE_SPRITES = 1536  #64+64 alternate

rw_json = os.path.join(this_dir,"used_tiles.json")
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

params = [
[{},[0,0xCCC]],  # 0
[{},[0xCA3,0xCCC]], #1
[{},[0x0C0,0xCCC]], #2
[{0xC0:0x80C},[0xCA3,0x8F0]], #3
[{0xC0:0x80C,0x800:0x8F0},[0xCA3,0xCCC]], #4
[{},[0xCA3,0xCCC]], #5
[{0xC0:0x80C},[0xCA3,0x8F0]], #6
[{0xC0:0x80C,0xCA3:0xC80},[0x8F0,0xCCC]], #7
[{},[0xCA3,0xCCC]],  #8
[{},[0xC0,0xCA3]],   #9
[{0xC0:0x80C},[0xCA3,0xCCC]],  #10
[{},[0xCA3,0xCCC]],  #11
[{0xC0:0xFC0},[0xCA3,0x8F0]],  #12
[{},[0,0xCCC]],  #13
]
# invert mapping, data entered is reversed, but I don't want to swap it manually
params = [[{v:k for k,v in d.items()},c] for d,c in params]

palettes_to_try = [[repl.get(c,c) for c in palette_16_rgb4[:14]+last_cols] for repl,last_cols in params]

palette_256_as_rgb4 = [bitplanelib.to_rgb4_color(x) for x in palette_256]
palette_256_rounded = [bitplanelib.round_color(x,0xF0) for x in palette_256]
# there aren't cluts in this game, but 256 colors = 4*32 groups of colors. The color code is a value 0-31
# so technically there's a clut table

clut_table = [palette_256_rounded[i:i+4] for i in range(0,256,4)]
print(clut_table)
# dump base palette
with open(os.path.join(src_dir,"palette.68k"),"w") as f:
    bitplanelib.palette_dump(palette_16,f,pformat=bitplanelib.PALETTE_FORMAT_ASMGNU)


character_codes_list = list()

# group palette 4 by 4
bg_cluts = clut_table[:128]

sprite_cluts = clut_table[:128]


for k,chardat in enumerate(block_dict["tile"]["data"]):
    img = Image.new('RGB',(8,8))

    character_codes = list()

    for cidx,colors in enumerate(bg_cluts):
        if not used_cluts or (k in used_cluts and cidx in used_cluts[k]):
            d = iter(chardat)
            for i in range(8):
                for j in range(8):
                    v = next(d)
                    img.putpixel((j,i),colors[v])
            character_codes.append(bitplanelib.palette_image2raw(img,None,colors))
            if dump_it:
                scaled = ImageOps.scale(img,5,0)
                scaled.save(os.path.join(dump_dir,f"char_{k:02x}_{cidx}.png"))
        else:
            character_codes.append(None)
    character_codes_list.append(character_codes)



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
        #scaled.save(os.path.join(dump_dir,outname))



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
