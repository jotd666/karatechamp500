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

name_dict = {"score_{}".format(i):"score_{}".format((i+1)*100) for i in range(0,10)}

HIT_NONE = 0
HIT_VALID = 1
HIT_ATTACK = 2
HIT_BLOCK = 3

BLACK,WHITE,RED,GREEN,BLUE = (0,0,0),(255,255,255),(255,0,0),(0,255,0),(0,0,255)
hit_mask_dict = {v:i for i,v in enumerate((BLACK,WHITE,RED,GREEN))}
hit_mask_dict[BLUE] = HIT_NONE

outdir = "tiles"
hit_mask_dir = "hit_masks"

null = -1

# where to insert "FT_HIT" for moves that don't have a stopping point
# (negative frame counter)


def mirror(img):
    m = img.transpose(Image.FLIP_LEFT_RIGHT)
    return m
##
##    # now left-justify the image
##    # compute the first non-black point
##
##    found = False
##    for x in range(m.size[0]):
##        for y in range(m.size[1]):
##            if m.getpixel((x,y)) != (0,0,0):
##                found = True
##                break
##        if found:
##            break
##    img_mirror = Image.new("RGB",m.size)
##    img_mirror.paste(m,(-x,0,m.size[0]-x,m.size[1]))
##    return img_mirror

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

def extract_block(img,x=0,y=0,width=None,height=None):
    if not width:
        width = img.size[0]
    if not height:
        height = img.size[1]

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

    mask_palette = Image.new("RGB",(32,64))
    y = 0
    for rgb in [WHITE,RED,GREEN,BLUE]:
        for i in range(16):
            for x in range(32):
                mask_palette.putpixel((x,y),rgb)
            y += 1

    mask_palette_file = os.path.join(hit_mask_dir,"palette.png")
    mask_palette.save(mask_palette_file)

    moves_dir = "moves"
    sback = (192,192,0)     # background of level 2, uniform background, used for mask color

    height = 48
    moves_list = set(os.listdir(moves_dir))
    # walk/forward in priority
    walking_anims = ["walk_forward","forward","walk_backwards","backwards"]
    moves_list.difference_update(walking_anims)

    moves_list = walking_anims+sorted(moves_list)

    hit_dict = dict()

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
                mask.save(os.path.join(outdir,"{}_mask_{}_right.png".format(d,i)))
                img.save(os.path.join(outdir,"{}_{}_right.png".format(d,i)))
                mirror(img).save(os.path.join(outdir,"{}_{}_left.png".format(d,i)))
                mirror(mask).save(os.path.join(outdir,"{}_mask_{}_left.png".format(d,i)))

            blk = extract_block(img)
            existing = move_dict.get(blk)
            if existing:
                print("already existing bitmap for {} => {}".format(name,existing["name"]))
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

                img_mirror = mirror(img)
                mask_img_mirror = mirror(mask_img)

                create_bob(img_mirror,mask_img_mirror,"{}/{}_left.bin".format(sprites_dir,name))

                # save mask image in hit masks dir if doesn't exist, or load it/compare to see if still matches
                # the actual mask (which could have been updated)
                # we want those hit masks to be 100% the same shape as pics/masks
                # only with added logic information
                #
                # white: vulnerable
                # red: hit zone (can hurt other player)
                # blue: neutral (like part of leg/arm)
                # green: block zone (blocks opponent hits)

                hit_mask_filename = os.path.join(hit_mask_dir,name+".png")
                if os.path.exists(hit_mask_filename):
                    # load it and compare non-black colors, see if they match
                    hit_mask = Image.open(hit_mask_filename)
                    if hit_mask.size != mask_img.size:
                        raise Exception("{}: hit mask size {} doesn't match mask size {}".format(
                    name,hit_mask.size,mask_img.size))

                    # create hit matrix from hit mask color codes
                    hit_matrix = [[HIT_NONE]*hit_mask.size[0] for _ in range(hit_mask.size[1])]

                    for x in range(0,hit_mask.size[0]):
                        for y in range(hit_mask.size[1]):
                            hmp = hit_mask.getpixel((x,y))
                            nonblack1 = mask_img.getpixel((x,y)) != BLACK
                            nonblack2 = hmp != BLACK

                            if nonblack1 != nonblack2:
                                raise Exception("{}: hit maskdoesn't match mask (x={},y={})".format(name,x,y))
                            if nonblack1:
                                hit_matrix[y][x] = hit_mask_dict[hmp]

                    # rescale 50% to reduce mask size, hitbox will be accurate enough
                    # the rescaling has a priority on active hitboxes
                    hit_matrix_small = [[HIT_NONE]*(hit_mask.size[0]//2) for _ in range(hit_mask.size[1]//2)]
                    hit_list = []
                    for x in range(0,hit_mask.size[0]):
                        x2 = x//2
                        for y in range(hit_mask.size[1]):
                            y2 = y//2
                            # only HIT_VALID (hit target)
                            # is considered in matrix mask, disregard all other categories,
                            hit_type = hit_matrix[y][x]
                            if hit_type == HIT_VALID:
                                hit_matrix_small[y2][x2] = HIT_VALID
                            # if hit attack, store in hit list. The game scans hit list
                            # first and checks against hit matrix, this is way faster than
                            # computing matrix to matrix collision at each frame
                            elif hit_type == HIT_ATTACK:
                                hit_list.append((x,y))  # store in real coords, this is an offset
                            # other categories (block) are useless for the game (block = invisible)
                            # but needed to make sure that the logical mask matches the real graphical data
                            # when converting assets. Else it would be a nightmare to debug that

                    # dump hit matrix in sprites dir
                    with open(os.path.join(sprites_dir,name+"_mask.bin"),"wb") as f:
                        for hline in hit_matrix_small:
                            a = bytearray(hline)
                            f.write(a)
                    hit_dict[name] = hit_list
                else:
                    print("creating monochrome hitmask {}".format(hit_mask_filename))
                    mask_img.save(hit_mask_filename)


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

    # create mask frames in "existing" or reload them / associate them TODO

    def create_frame_sequence(suffix,x_sign):
        f.write("{}{}_frames:\n".format(name,suffix))

        prev_dx = 0
        prev_dy = 0

        for i,(frame,width,height,df,dx,dy) in enumerate(frame_list):
            f.write("\tdc.l\t{}{}\n".format(frame,suffix))
            f.write("\tdc.l\t{}_mask\n".format(frame))
            f.write("\tdc.l\t{}_hit_list\n".format(frame))
            # image size info, x/y variations, logical infos (padding ATM)
            row_size = ((width//8)+2)
            plane_size = row_size*height
            # plane_size is redundant but saves a multiplication by 48 in-game
            f.write("\tdc.w\t{},{},{},{},{},{}\n".format(plane_size,row_size,(dx - prev_dx)*x_sign,dy - prev_dy,df,int(i<3)))
            prev_dx = dx
            prev_dy = dy
        f.write("\tdc.l\t0,0,0,0\n")
        return True  # ATM ignore hit found


    with open("{}/{}_frames.s".format(source_dir,radix),"w") as f:
        f.write("""
    STRUCTURE   PlayerFrameSet,0
    APTR    right_frame_set
    APTR    left_frame_set
    UWORD   fs_animation_loops
    LABEL   PlayerFrameSet_SIZEOF

    STRUCTURE   PlayerFrame,0
    APTR    bob_data
    APTR    target_data
	APTR	hit_data
    UWORD   bob_plane_size
    UWORD   bob_nb_bytes_per_row
    UWORD   delta_x
    UWORD   delta_y
    UWORD   staying_frames
    UWORD   can_rollback
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
                hit_found = create_frame_sequence("_left",-1)
                if not hit_found:
                    print("Warning: no hit found for frame {}".format(name))
            else:
                create_frame_sequence("",1)
    # include frames only once (may be used more than once)
    frames_to_write = dict()
    for name,frame_list in sorted(rval.items()):
        create_mirror_objects = name != "win"
        if create_mirror_objects:
            for d in ["right","left","mask"]:
                for frame,*_ in frame_list:
                    frames_to_write["{}_{}:\n".format(frame,d)] = "\tincbin\t{}_{}.bin\n".format(frame,d)
        else:
            for frame in frame_list:
                frames_to_write["{}:\n".format(frame)] = "\tincbin\t{}.bin\n".format(frame)

    with open("{}/{}_bobs.s".format(source_dir,radix),"w") as f:
        for a,b in sorted(frames_to_write.items()):
            f.write(a)
            f.write(b)
    with open("{}/hit_lists.s".format(source_dir),"w") as f:
        for name,coords in sorted(hit_dict.items()):
            f.write("{}_hit_list:\n\tdc.w\t".format(name))
            for i,(x,y) in enumerate(coords):
                f.write("{},{}".format(x,y))
                f.write("," if (i==0 or i%8) else "\n\tdc.w\t")

            f.write("-1,-1\n")  # end

def process_tiles(json_file,out_asm_file=None,dump=False):
    with open(json_file) as f:
        tiles = json.load(f)

    default_width = tiles["width"]
    default_height = tiles["height"]
    default_horizontal = tiles["horizontal"]

    game_palette_8 = [tuple(x) for x in tiles["palette"]]

    master_blit_pad = tiles.get("blit_pad",True)
    master_generate_mask = tiles.get("generate_mask",False)

    x_offset = tiles["x_offset"]
    y_offset = tiles["y_offset"]

    sprite_page = tiles["source"]

    sprites = Image.open(sprite_page)

    binlist = []
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
                if x_size > 16:
                    raise Exception("{} (frame #{}) width (as sprite) should be <= 16, found {}".format(name,i,x_size))
                if sprite_palette:
                    pass
                    #bitplanelib.palette_dump(sprite_palette,"../{}/{}.s".format("src",name))
                else:
                    sprite_palette_offset = 16+(sprite_number//2)*4
                    sprite_palette = game_palette[sprite_palette_offset:sprite_palette_offset+4]
                bin_base = "{}/{}_{}.bin".format(sprites_dir,name,i) if nb_frames != 1 else "{}/{}.bin".format(sprites_dir,name)
                print("processing sprite {}...".format(name))

                if x_size < 16:
                    # make it at least 16
                    img = Image.new("RGB",(16,cropped_img.size[1]))
                    img.paste(cropped_img)
                    cropped_img = img

                bitplanelib.palette_image2sprite(cropped_img,bin_base,
                    sprite_palette,palette_precision_mask=0xF0)
            else:
                # blitter object
##                if x_size % 16:
##                    raise Exception("{} (frame #{}) with should be a multiple of 16, found {}".format(name,i,x_size))

                p = bitplanelib.palette_extract(cropped_img,palette_precision_mask=0xF0)
                # add 16 pixelsblit_pad
                img_x = x_size+16 if blit_pad else x_size
                img = Image.new("RGB",(img_x,cropped_img.size[1]))
                img.paste(cropped_img)

                used_palette = sprite_palette or game_palette_8

                namei = "{}_{}".format(name,i) if nb_frames!=1 else name

                print("processing bob {}, mask {}...".format(name,generate_mask))
                binname = "{}/{}".format(sprites_dir,name_dict.get(namei,namei))
                binlist.append(binname)

                if not generate_mask:
                    # if 1 plane, no mask, manual mask frames, save only 1 plane, else save all 4 planes
                    p = bitplanelib.palette_extract(img,palette_precision_mask=0xF0)
                    used_palette = p if len(p)==2 else used_palette

                bitplanelib.palette_image2raw(img,binname+".bin",used_palette,
                palette_precision_mask=0xF0,generate_mask=generate_mask)

        if out_asm_file:
            with open(out_asm_file,"w") as f:
                for n in binlist:
                    f.write("{0}:\n\tincbin\t{0}.bin\n".format(os.path.basename(n)))
    return game_palette_8

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

#bitplanelib.palette_to_image(palette,"palette.png")

# status panel
#bitplanelib.palette_image2raw("panel.png","{}/panel.bin".format(sprites_dir),
#        palette,palette_precision_mask=0xF0,blit_pad=True)

#process_backgrounds(palette)

process_tiles("sprites.json",os.path.join(source_dir,"other_bobs.s"))

#process_player_tiles()

process_fonts(dump_fonts)

