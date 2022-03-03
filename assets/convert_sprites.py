import os,bitplanelib,json,subprocess
from PIL import Image

import collections
tile_width = 8
tile_height = 8
sprites_dir = "../sprites"
source_dir = "../src"

# debug options to get output as "modern" format (png/txt)
# to see what's being done
dump_tiles = True
dump_fonts = True

c_gray = (192,192,192)
b_gray = (0xB0,0xB0,0xB0)

outdir = "tiles"


def compute_palette():
    common = set()
    for i in range(1,13):
        img = Image.open("backgrounds/{:04d}.png".format(i))
        # remove status panel before extracting the palette
##        for x in range(24,176+24):
##            for y in range(64):
##                img.putpixel((x,y),(0,0,0))

        p = bitplanelib.palette_extract(img,0xf0)
        common.update(p)

    # common has 16 items, now we need to impose some ordering
    # for black, red and white (blue is there too, because we need
    # white to be color 1 and red to be color 3 so we can blit the characters
    # using different bitplanes but using the same source

    palette = [(0,0,0),(240, 240, 240),(240, 192, 192),(240,0,0)]

    # now add the other colors, the order doesn't matter for them
    # but we sort the source to avoid that it changes between runs of
    # this script

    # there are too many colors (1 too much) to do 16 colors. We could go dynamic
    # or we could merge ccc and bbb as bbb.
    # I don't know where c gray comes from, I have removed the panel and it still shows
    # well, doesn't matter

    common.remove(c_gray)

    palette += sorted(common - set(palette))


    return palette

def extract_block(img,x,y):
    return tuple(img.getpixel((x+i,y+j)) for j in range(tile_height) for i in range(tile_width))


def process_backgrounds(palette):
    for i in range(1,13):
        imgname = "backgrounds/{:04d}.png".format(i)
        img = Image.open(imgname)
        for x in range(24,176+24):
            for y in range(64):
                img.putpixel((x,y),(0,0,0))
        for x in range(img.size[0]):
            for y in range(img.size[1]):
                # replace 0xCCC by 0xBBB
                pix = tuple(c & 0xF0 for c in img.getpixel((x,y)))
                if pix == c_gray:
                    img.putpixel((x,y),b_gray)

        outfile = "{}/back_{:02d}.bin".format(sprites_dir,i)
        bitplanelib.palette_image2raw(img,outfile,
                palette,palette_precision_mask=0xF0)
        # compress the bitmaps
        subprocess.check_call(["propack","p",outfile,outfile+".rnc"])
        os.remove(outfile)


def process_tiles(json_file):
    rval = dict()
    with open(json_file) as f:
        tiles = json.load(f)

    default_width = tiles["width"]
    default_height = tiles["height"]
    default_horizontal = tiles["horizontal"]

    game_palette_8 = [tuple(x) for x in tiles["palette"]]

    player_palette = game_palette_8[:4]

    master_blit_pad = tiles.get("blit_pad",True)
    master_generate_mask = tiles.get("generate_mask",False)
    master_mask_color = tiles.get("mask_color_index",0)
    create_mirror_objects = tiles.get("create_mirror_objects",False)

    x_offset = tiles["x_offset"]
    y_offset = tiles["y_offset"]

    sprite_page = tiles["source"]

    sprites = Image.open(sprite_page)

    name_dict = {"scores_{}".format(i):"scores_"+n for i,n in enumerate(["100","200","300"])}
    # we first did that to get the palette but we need to control
    # the order of the palette


    for object in tiles["objects"]:

        if object.get("ignore"):
            continue
        generate_mask = object.get("generate_mask",master_generate_mask)

        blit_pad = object.get("blit_pad",master_blit_pad)
        gap = object.get("gap",0)
        name = object["name"]

        start_x = object["start_x"]+x_offset
        start_y = object["start_y"]+y_offset
        horizontal = object.get("horizontal",default_horizontal)
        width = object.get("width",default_width)
        height = object.get("height",default_height)


        nb_frames = object.get("frames",1)
        frame_list = []
        for i in range(nb_frames):
            if horizontal:
                x = i*(width+gap)+start_x
                y = start_y
            else:
                x = start_x
                y = i*(height+gap)+start_y

            area = (x, y, x + width, y + height)
            cropped_img = sprites.crop(area)
            if nb_frames == 1:
                cropped_name = os.path.join(outdir,"{}.png".format(name))
            else:
                cropped_name = os.path.join(outdir,"{}_{}.png".format(name,i))
            cropped_img.save(cropped_name)

            # save
            x_size = cropped_img.size[0]
            sprite_number = object.get("sprite_number")
            sprite_palette = object.get("sprite_palette")
            if sprite_palette:
                sprite_palette = [tuple(x) for x in sprite_palette]
            if sprite_number is not None:
                if x_size != 16:
                    raise Exception("{} (frame #{}) width (as sprite) should 16, found {}".format(name,i,x_size))
                if sprite_palette:

                    bitplanelib.palette_dump(sprite_palette,"{}/{}.s".format(source_dir,name))
                else:
                    sprite_palette_offset = 16+(sprite_number//2)*4
                    sprite_palette = game_palette[sprite_palette_offset:sprite_palette_offset+4]
                bin_base = "{}/{}_{}.bin".format(sprites_dir,name,i) if nb_frames != 1 else "{}/{}.bin".format(sprites_dir,name)
                print("processing sprite {}...".format(name))
                bitplanelib.palette_image2sprite(cropped_img,bin_base,
                    sprite_palette,palette_precision_mask=0xF0)
            else:
                # blitter object
##                if x_size % 16:
##                    raise Exception("{} (frame #{}) with should be a multiple of 16, found {}".format(name,i,x_size))

                p = bitplanelib.palette_extract(cropped_img,palette_precision_mask=0xF0)
                # add 16 pixelsblit_pad
                img_x = x_size+16 if blit_pad else x_size
                img = Image.new("RGB",(img_x,cropped_img.size[1]),(0,0,0))
                img.paste(cropped_img)

                used_palette = sprite_palette or game_palette_8

                namei = "{}_{}".format(name,i) if nb_frames!=1 else name

                print("processing bob {}, mask {}...".format(name,generate_mask))
                bn = name_dict.get(namei,namei)
                if create_mirror_objects:

                    contents = bitplanelib.palette_image2raw(img,"{}/{}_right.bin".format(sprites_dir,bn),used_palette,
                    palette_precision_mask=0xF0,generate_mask=generate_mask,mask_color_index=master_mask_color)
                    if generate_mask and dump_tiles:
                        sz = len(contents)//3
                        bitplanelib.bitplanes_raw2planarimage(contents[2*sz:],1,img.size[0],img.size[1],"tiles/{}_mask.png".format(bn))

                    img_mirror = Image.new("RGB",img.size)
                    for x in range(img.size[0]):
                        sx = img.size[0]-x-1
                        for y in range(img.size[1]):
                            img_mirror.putpixel((sx,y),img.getpixel((x,y)))

                    bitplanelib.palette_image2raw(img_mirror,"{}/{}_left.bin".format(sprites_dir,bn),used_palette,
                    palette_precision_mask=0xF0,generate_mask=generate_mask,mask_color_index=master_mask_color)
                else:
                    bitplanelib.palette_image2raw(img,"{}/{}.bin".format(sprites_dir,bn),used_palette,
                    palette_precision_mask=0xF0,generate_mask=generate_mask,mask_color_index=master_mask_color)

                frame_list.append(bn)
        rval[name] = frame_list
    radix = os.path.splitext(os.path.basename(json_file))[0]
    with open("{}/{}_frames.s".format(source_dir,radix),"w") as f:
        for name,frame_list in sorted(rval.items()):
            if create_mirror_objects:
                f.write("{}_left_frames:\n".format(name))
                for frame in frame_list:
                    f.write("\tdc.l\t{}_left\n".format(frame))
                f.write("\tdc.l\t{}\n".format(0))
                f.write("{}_right_frames:\n".format(name))
                for frame in frame_list:
                    f.write("\tdc.l\t{}_right\n".format(frame))
                f.write("\tdc.l\t{}\n".format(0))
            else:
                f.write("{}_frames:\n".format(name))
                for frame in frame_list:
                    f.write("\tdc.l\t{}\n".format(frame))
                f.write("\tdc.l\t{}\n".format(0))
    with open("{}/{}_bobs.s".format(source_dir,radix),"w") as f:
        for name,frame_list in sorted(rval.items()):
            if create_mirror_objects:
                for frame in frame_list:
                    f.write("{}_right:\n".format(frame))
                    f.write("\tincbin\t{}_right.bin\n".format(frame))
                for frame in frame_list:
                    f.write("{}_left:\n".format(frame))
                    f.write("\tincbin\t{}_left.bin\n".format(frame))
                f.write("\n")
            else:
                for frame in frame_list:
                    f.write("{}:\n".format(frame))
                    f.write("\tincbin\t{}.bin\n".format(frame))
                f.write("\n")
    return rval

def process_fonts(dump=False):
    json_file = "fonts.json"
    with open(json_file) as f:
        tiles = json.load(f)

    default_width = tiles["width"]
    default_height = tiles["height"]
    default_horizontal = tiles["horizontal"]

    x_offset = tiles["x_offset"]
    y_offset = tiles["y_offset"]

    sprite_page = tiles["source"]

    sprites = Image.open(sprite_page)


    # we first did that to get the palette but we need to control
    # the order of the palette



    for object in tiles["objects"]:
        if object.get("ignore"):
            continue
        name = object["name"]
        start_x = object["start_x"]+x_offset
        start_y = object["start_y"]+y_offset
        horizontal = object.get("horizontal",default_horizontal)
        width = object.get("width",default_width)
        height = object.get("height",default_height)

        nb_frames = object["frames"]
        for i in range(nb_frames):
            if horizontal:
                x = i*width+start_x
                y = start_y
            else:
                x = start_x
                y = i*height+start_y

            area = (x, y, x + width, y + height)
            cropped_img = sprites.crop(area)
            if dump:
                bn = "{}_{}.png".format(name,i) if nb_frames != 1 else name+".png"
                cropped_name = os.path.join(outdir,bn)
                cropped_img.save(cropped_name)

            # save
            x_size = cropped_img.size[0]

            # blitter object
            if x_size % 8:
                raise Exception("{} (frame #{}) with should be a multiple of 8, found {}".format(name,i,x_size))
            # pacman is special: 1 plane
            p = bitplanelib.palette_extract(cropped_img,palette_precision_mask=0xF0)
            # add 16 pixels if multiple of 16 (bob)
            img_x = x_size+16 if x_size%16==0 else x_size
            img = Image.new("RGB",(img_x,cropped_img.size[1]))
            img.paste(cropped_img)

            used_palette = p

            namei = "{}_{}".format(name,i) if nb_frames != 1 else name
            outfile = "{}/{}.bin".format(sprites_dir,name_dict.get(namei,namei))
            bitplanelib.palette_image2raw(img,outfile,used_palette,palette_precision_mask=0xF0)

# compute palette from background images
palette = compute_palette()
bitplanelib.palette_dump(palette,os.path.join(source_dir,"palette.s"),as_copperlist=False)

# status panel
bitplanelib.palette_image2raw("panel.png","{}/panel.bin".format(sprites_dir),
        palette,palette_precision_mask=0xF0,blit_pad=True)

#process_backgrounds(palette)

process_tiles("player.json")

#process_fonts(dump_fonts)

