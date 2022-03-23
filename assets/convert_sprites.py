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

    # now another requirement: due to sprite reuse between white and red player, put the red color
    # as color 9, swap it with color 3

    palette[3],palette[9] = palette[9],palette[3]

    return palette

def extract_block(img,x,y,width,height):
    return tuple(img.getpixel((x+i,y+j)) for j in range(height) for i in range(width))


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


def process_player_tiles():
    rval = dict()
    move_dict = dict()

    player_palette = [(0,0,0),(240,240,240),(240,192,192),(96, 80, 80)]

    moves_dir = "moves"
    sback = (192,192,0)     # background of level 2, uniform background, used for mask color

    height = 48
    moves_list = set(os.listdir(moves_dir))
    # walk/forward in priority
    walking_anims = ["walk_forward","forward","walk_backwards","backwards"]
    moves_list.difference_update(walking_anims)

    moves_list = walking_anims+sorted(moves_list)

    walking_anims = set(walking_anims)

    for d in moves_list[0:-1]:
        # load info
        with open(os.path.join(moves_dir,d,"info.json")) as f:
            info = json.load(f)
        deltas = info["deltas"]
        # process each image, without last image which is player guard
        images_list = sorted([x for x in os.listdir(os.path.join(moves_dir,d)) if x.endswith(".png")],
        key=lambda x: int(os.path.splitext(x)[0]))
        frame_list = []

        for i,((df,dx,dy),image_file) in enumerate(zip(deltas,images_list)):
            img = Image.open(os.path.join(moves_dir,d,image_file))
            width = img.size[0]
            if height != img.size[1]:
                raise Exception("{} height != {}".format(image_file,height))
            mask = Image.new("RGB",img.size)
            # we need to generate mask manually then remove the color so picture conversion
            # won't generate active bitplanes for it (it has to be index 0 of palette)
            # that's the cornercase when part of the sprites are black, which is rare, but annoying
            for x in range(width):
                for y in range(img.size[1]):
                    p = tuple(0xF0 & c for c in img.getpixel((x,y)))
                    if p == sback:
                        mask.putpixel((x,y),(0,0,0))
                        # remove background color now that we have the mask
                        img.putpixel((x,y),(0,0,0))
                    else:
                        mask.putpixel((x,y),(255,255,255))

            name = "{}_{}".format(d,i)
            if dump_tiles:
                mask.save(os.path.join(outdir,"{}_mask_{}.png".format(d,i)))
                img.save(os.path.join(outdir,"{}_{}.png".format(d,i)))

            blk = extract_block(img,0,0,width,height)
            existing = move_dict.get(blk)
            if existing:
                print("already {} : {}".format(name,existing["name"]))
                name = existing['name']
                width = existing["width"]
                height = existing["height"]
            else:
                move_dict[blk] = {"name":name,"width":width,"height":height}

                print("processing bob {}...".format(name))

                mask_img = mask

                def create_bob(bob_data,bob_mask_data,outfile):
                    # data, no mask
                    contents = bitplanelib.palette_image2raw(bob_data,None,player_palette,
                    palette_precision_mask=0xF0,generate_mask=False,blit_pad=True)
                    # append (almost) manually created mask
                    contents += bitplanelib.palette_image2raw(bob_mask_data,None,((0,0,0),(255,255,255)),
                    palette_precision_mask=0xFF,generate_mask=False,blit_pad=True)

                    with open(outfile,"wb") as f:
                        f.write(contents)
                    return contents

                create_bob(img,mask_img,"{}/{}_right.bin".format(sprites_dir,name))

                img_mirror = Image.new("RGB",img.size)
                mask_img_mirror = Image.new("RGB",img.size)
                for x in range(img.size[0]):
                    sx = img.size[0]-x-1
                    for y in range(img.size[1]):
                        img_mirror.putpixel((sx,y),img.getpixel((x,y)))
                        mask_img_mirror.putpixel((sx,y),mask_img.getpixel((x,y)))

                create_bob(img_mirror,mask_img_mirror,"{}/{}_left.bin".format(sprites_dir,name))

            frame_list.append([name,width,height,df,dx,dy])

        #frame_list[-1][1] = 0       # last frame should not be repeated
        # shift number of staying frames because the info extracted gives the
        # frame number when the next frame appears, this should be converted into
        # number of staying frames in the previous entry. And last item bears 0

        shifted_frame_list = []
        i = iter(frame_list)
        prev_frame,prev_width,prev_height,_,prev_dx,prev_dy = next(i)  # skip it, it's zero
        for frame,width,height,df,dx,dy in i:
            shifted_frame_list.append([prev_frame,prev_width,prev_height,df,prev_dx,prev_dy])
            prev_dx = dx
            prev_dy = dy
            prev_frame = frame
            prev_height = height
            prev_width = width

        rval[d] = shifted_frame_list
    radix = "player"


    def create_frame_sequence(suffix,x_sign):
        f.write("{}{}_frames:\n".format(name,suffix))

        prev_dx = 0
        prev_dy = 0
        for i,(frame,width,height,df,dx,dy) in enumerate(frame_list):
            f.write("\tdc.l\t{}{}\n".format(frame,suffix))
            # image size info, x/y variations, logical infos (padding ATM)
            row_size = ((width//8)+2)
            plane_size = row_size*height
            frame_type = "FT_NORMAL"
            # if permanent frame then it's hitting
            if df<0:
                frame_type = "FT_HIT"
            # plane_size is redundant but saves a multiplication by 48
            f.write("\tdc.w\t{},{},{},{},{},{},{},0,0\n".format(plane_size,row_size,(dx - prev_dx)*x_sign,dy - prev_dy,df,int(i<3),frame_type))
            prev_dx = dx
            prev_dy = dy
        f.write("\tdc.l\t0,0,0,0\n")

    with open("{}/{}_frames.s".format(source_dir,radix),"w") as f:
        f.write("""
    STRUCTURE   PlayerFrameSet,0
    APTR    right_frame_set
    APTR    left_frame_set
    UWORD   fs_animation_loops
    LABEL   PlayerFrameSet_SIZEOF

    STRUCTURE   PlayerFrame,0
    APTR    bob_data
    UWORD   bob_plane_size
    UWORD   bob_nb_bytes_per_row
    UWORD   delta_x
    UWORD   delta_y
    UWORD   staying_frames
    UWORD   can_rollback
    UWORD   frame_type
    UWORD   hitbox_x
    UWORD   hitbox_y
    LABEL   PlayerFrame_SIZEOF

FT_NORMAL = 0
FT_HIT = 1
FT_BLOCK = 2

""")
        for name,frame_list in sorted(rval.items()):
            f.write("{}_frames:\n".format(name))
            create_mirror_objects = name != "win"
            if create_mirror_objects:
                f.write("\tdc.l\t{0}_right_frames,{0}_left_frames\n".format(name))
                iwa = name in walking_anims
                f.write("\tdc.w\t{}\t; {}\n".format(int(iwa),"looping" if iwa else "runs once"))
                create_frame_sequence("_right",1)
                create_frame_sequence("_left",-1)
            else:
                create_frame_sequence("",1)
    # include frames only once (may be used more than once)
    frames_to_write = dict()
    for name,frame_list in sorted(rval.items()):
        create_mirror_objects = name != "win"
        if create_mirror_objects:
            for d in ["right","left"]:
                for frame,*_ in frame_list:
                    frames_to_write["{}_{}:\n".format(frame,d)] = "\tincbin\t{}_{}.bin\n".format(frame,d)
        else:
            for frame in frame_list:
                frames_to_write["{}:\n".format(frame)] = "\tincbin\t{}.bin\n".format(frame)

    with open("{}/{}_bobs.s".format(source_dir,radix),"w") as f:
        for a,b in sorted(frames_to_write.items()):
            f.write(a)
            f.write(b)


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

process_player_tiles()

#process_fonts(dump_fonts)

