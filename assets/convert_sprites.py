# conversion script for sprites and backgrounds
# since we have to stick to 16 colors and the union of all background colors + sprites
# is slightly above 16 (18 I think), some tweaks had to be applied in-game with dynamic
# color change (in the end, the original system can only display 16 colors too so it must
# do the same thing)
#
# colors replacement are applied to the palette with unused colors
#
# note that bonus stages use colors that conflict (burgundy=bull, light gray=rock)
# so bonus stages cannot be played on any background
#
# also note: bitplanelib has been designed with more simple games in mind, with sprite sheets
# having black color as background (games like Pac-man, Pengo, Amidar, Scramble use black
# in the background. In that game, there's a lot of black which is used for
# real color, and my lib shown its limits when it comes to automatic mask computation which
# is not the first color of the palette. So some images containing black are generated with
# auto mask generation off, and are followed by the manually generated mask in the sprite sheet
# (rock => rock_mask). A special feature allows to generate 1 bitplane if the image only has 2
# colors, like the ones used for masks. And it works with minimal Gimp legwork (fortunately,
# it's a minority of sprites, the main characters also have black but a special processing has
# been applied to them, which I was too lazy to apply to the general sprites)

import os,bitplanelib,json,subprocess
from PIL import Image

import collections
tile_width = 8
tile_height = 8
sprites_dir = "../sprites"
source_dir = "../src"

NB_BACKGROUND_PICS = 14

# debug options to get output as "modern" format (png/txt)
# to see what's being done
dump_tiles = True
dump_fonts = True


name_dict = {"score_{}".format(i):"score_{}".format((i+1)*100) for i in range(0,10)}
info_dict = {}

HIT_NONE = 0
HIT_VALID = 1
HIT_FULL_ATTACK = 2
HIT_HALF_ATTACK = 3

BLACK,WHITE,RED,YELLOW,BLUE = (0,0,0),(255,255,255),(255,0,0),(255,255,0),(0,0,255)
hit_mask_dict = {v:i for i,v in enumerate((BLACK,WHITE,RED,YELLOW))}
hit_mask_dict[BLUE] = HIT_NONE


outdir = "tiles"
hit_mask_dir = "hit_masks"

null = -1

hn="HEIGHT_NONE"
hl="HEIGHT_LOW"
hm="HEIGHT_MEDIUM"
hh="HEIGHT_HIGH"

block_heights = [hn,hl,hm,hh]

bf = "BLOW_FRONT"
bs = "BLOW_STOMACH"
bl = "BLOW_LOW"
br = "BLOW_ROUND"
bb = "BLOW_BACK"
bn = "BLOW_NONE"

blow_types = [bn,bf,bs,bb,bl,br]
# left_shift is a manual x-offset make-up for left side (optional)
# height is the corresponding height of the block
# blow_type is the opponent hit animation
# back_blow_type is the opponent hit animation when players turn their backs on each other
move_param_dict = {
"back_kick":{"score":400,"height":hl,"blow_type":bb,"back_blow_type":bs},
"front_kick":{"score":200,"height":hl,"left_shift":12,"blow_type":bs,"back_blow_type":bb},
"back_round_kick":{"score":1000,"height":hh,"blow_type":bl},  # low is the same has high
"foot_sweep_back":{"score":200,"height":hn,"blow_type":bl},
"foot_sweep_front":{"score":200,"height":hn,"blow_type":bl},
"jumping_back_kick":{"score":1000,"height":hh,"blow_type":bb,"back_blow_type":bf},
"jumping_side_kick":{"score":1000,"height":hh,"blow_type":bf,"back_blow_type":bb},
"low_kick":{"score":200,"height":hn,"left_shift":12,"blow_type":bl},
"lunge_punch_1000":{"score":1000,"height":hh,"blow_type":bf,"back_blow_type":bb},
"lunge_punch_400":{"score":400,"height":hm,"blow_type":bs,"back_blow_type":bb},
"lunge_punch_600":{"score":600,"height":hh,"blow_type":bf,"back_blow_type":bb},
"reverse_punch_800":{"score":800,"height":hl,"blow_type":bs,"back_blow_type":bb},
"round_kick":{"score":600,"height":hn,"left_shift":12,"blow_type":br},  # round kick can't be blocked
"weak_reverse_punch":{"score":200,"height":hm,"blow_type":bs,"back_blow_type":bb},
"sommersault":{"score":0,"height":hn,"blow_type":bn,"back_blow_type":bn},
"sommersault_back":{"score":0,"height":hn,"blow_type":bn,"back_blow_type":bn},
}
# divide score by 100
for d in move_param_dict.values():
    d["score"] //= 100

# rgb colors replacement we can apply
base_rep = {(0, 192, 0):(128, 0, 192)}
color_replacement_dict = {3:base_rep,
4:base_rep | {(128,0,0):(0x80,0xF0,0x00)},  # for the rock light gray (evade)
6:base_rep,
7:base_rep | {(192, 160, 48):(192, 128, 0)},
10:base_rep,
12:{(0,192,0):(240, 192, 0)}  # can't use (128,0,0) as the bull uses it
}
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

def get_background_pic(i):
    imgname = "backgrounds/{:04d}.png".format(i)
    img = Image.open(imgname)
    if i == 0  or i > 12:
        # intro screens
        pass
    else:
        # remove status panel before extracting the palette
        for x in range(24,176+24):
            for y in range(64):
                img.putpixel((x,y),(0,0,0))

    replacement_colors = color_replacement_dict.get(i)
    if replacement_colors:
        # apply color change
        for x in range(img.size[0]):
            for y in range(img.size[1]):
                pix = img.getpixel((x,y))
                pix = bitplanelib.round_color(pix,0xF0)
                pix_rep = replacement_colors.get(pix)
                if pix_rep:
                    img.putpixel((x,y),pix_rep)
    return img

def process_girls():
    import convert_girl_sprites
    convert_girl_sprites.doit()

def compute_palettes():
    main_sprites = Image.open("sprites.png")
    common_palette = bitplanelib.palette_extract(main_sprites,0xf0)
    # 2 colors are remaining
    # common has 16 items, now we need to impose some ordering
    # for black, red and white (blue is there too, because we need
    # white to be color 1 and red to be color 3 so we can blit the characters
    # using different bitplanes but using the same source


    palette = [(0,0,0),   # black
    (240, 240, 240),  # white
    (240, 192, 192), # pink (players/referee)
    (240,0,0),  # red
    (0x40,0xC0,0xF0),  # cyan used for panel
    (0xF0,0xF0,0xC0),  # light gray for time
    (0x00,0x00,0xF0),  # referee
    ]
    specific_palette = {}
    palette_set = set(palette)
    # colors we need in each level
    imposed_palette = palette_set.copy()
    for c in common_palette:
        if c in palette_set:
            pass
        else:
            palette_set.add(c)
            palette.append(c)
    # find red in the palette
    red_index = palette.index((240,0,0))
    # swap with position 9 (imposed)
    palette[red_index],palette[9] = palette[9],palette[red_index]

    # special case for light gray: is in sprites (rocks) but should be last
    # and not active in all pics (else we go over 16 colors), so we're removing it
    # from the sprites palette for now
    light_gray = (0XC0,0xC0,0xC0)
    black = (0,0,0)
    palette.remove(light_gray)

    # palette should have 14 colors total

    # now find the specific palette (2 slots remaining)
    common = set()
    specific_colors_merged = set()
    lp = len(palette)
    for i in range(NB_BACKGROUND_PICS):

        img = get_background_pic(i)

        image_palette = set(bitplanelib.palette_extract(img,0xf0))

        # check which colors aren't in common palette
        specific_colors = image_palette.difference(palette_set)
        unused_shared_colors = palette_set.difference(image_palette).difference(imposed_palette)
        ls = len(specific_colors)
        if lp+ls > 16:
            # must replace colors when encoding image. We have to pick a color of the shared palette
            # which cannot appear in the stage. For instance, we can't pick 0x800 (burgundy) if there's "evade"
            # or "bull" stage because it's used there. In that case, we could choose a green instead (if not in the stage)

            specific_rgb = [("{:02x}"*3).format(*p) for p in unused_shared_colors]
            raise Exception("background #{}: should use less than 16 colors {}+{}: try to replace {} of {} color(s) by one of {}".format(
        i,lp,ls,lp+ls-16,specific_colors,unused_shared_colors))

        specific_palette[i] = list(specific_colors)

        # add light gray again, last position, if possible
        spal = specific_palette[i]
        if not spal:
            spal.append(black)      # pre-pad
        if len(spal)<2:
            spal.append(light_gray)

    # add light gray again, last position
    palette += [black,light_gray]
    return palette,specific_palette

def extract_block(img,x=0,y=0,width=None,height=None):
    if not width:
        width = img.size[0]
    if not height:
        height = img.size[1]

    return tuple(img.getpixel((x+i,y+j)) for j in range(height) for i in range(width))


def process_backgrounds(palette):
    for i in range(NB_BACKGROUND_PICS):
        img = get_background_pic(i)
        outfile = "{}/back_{:02d}.bin".format(sprites_dir,i)
        specific_palette = list(specific_palettes[i])

        bitplanelib.palette_image2raw(img,outfile,
                palette[0:14]+specific_palette,palette_precision_mask=0xF0)
        # compress the bitmaps
        subprocess.check_call(["propack","p",outfile,outfile+".rnc"])
        os.remove(outfile)


def process_player_tiles():
    rval = dict()
    move_dict = dict()

    player_palette = [(0,0,0),(240,240,240),(240,192,192),(96, 80, 80)]

    colors = [WHITE,RED,BLUE,YELLOW]
    mask_palette = Image.new("RGB",(32,len(colors)*16))
    y = 0
    for rgb in colors:
        for i in range(16):
            for x in range(32):
                mask_palette.putpixel((x,y),rgb)
            y += 1

    mask_palette_file = os.path.join(hit_mask_dir,"palette.png")
    mask_palette.save(mask_palette_file)

    moves_dir = "moves"
    sback = (192,192,0)     # background of level 2, uniform background, used for mask color

    height = 48
    moves_list = {x for x in os.listdir(moves_dir) if os.path.isdir(os.path.join(moves_dir,x))}

    # walk/forward in priority
    walking_anims = ["walk_forward","forward","walk_backwards","backwards"]
    moves_list.difference_update(walking_anims)

    moves_list = walking_anims+sorted(moves_list)

    hit_dict = dict()

    walking_anims = set(walking_anims)

    for d in moves_list:
        # load info
        info_file = os.path.join(moves_dir,d,"info.json")
        try:
            with open(info_file) as f:
                info = json.load(f)
        except json.decoder.JSONDecodeError as e:
            print("** decode error in "+info_file)
            raise

        deltas = info["deltas"]
        has_hit_mask = info.get("hit_mask",True)
        is_symmetrical = info.get("symmetrical",False)
        rollback_frame = info.get("rollback_frame",3)  # default rollback
        loops = info.get("loops",False)
        manual = info.get("manual",False)
        # make sure the properties are in the dict
        info["symmetrical"] = is_symmetrical
        info["hit_mask"] = has_hit_mask
        info["rollback_frame"] = int(rollback_frame)
        info["loops"] = loops
        info["manual"] = manual
        # store it for later
        info_dict[d] = info
        # process each image, without last image which is player guard
        images_list = sorted([x for x in os.listdir(os.path.join(moves_dir,d)) if x.endswith(".png")],
        key=lambda x: int(os.path.splitext(x)[0]))  # numeric sort
        frame_list = []
        dd = len(deltas)-len(images_list)
        if dd > 0:
            # more deltas than images, add the last image indefinitely so
            # zip doesn't run out of frames
            images_list += [images_list[-1]]*(dd)

        for i,((df,dx,dy),image_file) in enumerate(zip(deltas,images_list)):
            img = Image.open(os.path.join(moves_dir,d,image_file))
            width = img.size[0]
            height = img.size[1]  # 48 but in some cases (win animation) can be 64

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
                if not is_symmetrical:
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

                if not is_symmetrical:
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

                if has_hit_mask:
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
                        full_hit_list = []
                        half_hit_list = []
                        for x in range(0,hit_mask.size[0],2):
                            x2 = x//2
                            for y in range(0,hit_mask.size[1],2):
                                y2 = y//2
                                # only HIT_VALID (hit target)
                                # is considered in matrix mask, disregard all other categories,
                                hit_type = hit_matrix[y][x]
                                if hit_type == HIT_VALID:
                                    hit_matrix_small[y2][x2] = HIT_VALID
                                # if hit attack, store in hit list. The game scans hit list
                                # first and checks against hit matrix, this is way faster than
                                # computing matrix to matrix collision at each frame
                                elif hit_type == HIT_FULL_ATTACK:
                                    full_hit_list.append((x,y))  # store in real coords, this is an offset
                                elif hit_type == HIT_HALF_ATTACK:
                                    half_hit_list.append((x,y))  # store in real coords, this is an offset
                                # other categories (block) are useless for the game (block = invisible)
                                # but needed to make sure that the logical mask matches the real graphical data
                                # when converting assets. Else it would be a nightmare to debug that

                        # dump hit matrix in sprites dir
                        with open(os.path.join(sprites_dir,name+"_mask.bin"),"wb") as f:
                            for hline in hit_matrix_small:
                                a = bytearray(hline)
                                f.write(a)
                        # now, we have to make a different between well-connecting blow (full score awarded,
                        # possibly full/whole point if points > 500) from a average-connecting blow (half score
                        # awarded, half point)
                        #
                        # hit
                        hit_dict[name] = (full_hit_list,half_hit_list)
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

    def create_frame_sequence(suffix,real_suffix,x_sign):
        f.write("{}{}_frames:\n".format(name,suffix))

        prev_dx = 0
        prev_dy = 0

        for i,(frame,width,height,df,dx,dy) in enumerate(frame_list):
            f.write("\tdc.l\t{}{}\n".format(frame,real_suffix))  # bob_data
            if info_dict[name].get("hit_mask"):
                f.write("\tdc.l\t{}_mask\n".format(frame))  # target_data
                f.write("\tdc.l\t{}_full_hit_list\n".format(frame))  # hit_data
                f.write("\tdc.l\t{}_half_hit_list\n".format(frame))  # hit_data
            else:
                f.write("\tdc.l\t0\t; no hit mask\n")
                f.write("\tdc.l\t0,0\t; no hit lists\n")
            # image size info, x/y variations, logical infos (padding ATM)
            bob_nb_bytes_per_row = ((width//8)+2)   # blitter adds 16 bits
            plane_size = bob_nb_bytes_per_row*height
            # plane_size is redundant but saves a multiplication by 48 in-game
            #
            # can rollback in 3 first frames (that's a guess) unless that an amination
            # when player is hit
            rollback_frame = info_dict[name]["rollback_frame"]
            can_rollback = 0 if rollback_frame == -1 else int(i<rollback_frame)
            f.write("\tdc.w\t{},{},{},{},{},{},{},{}\n".format(plane_size,width,
                            height,bob_nb_bytes_per_row,(dx - prev_dx)*x_sign,dy - prev_dy,df,can_rollback))
            prev_dx = dx
            prev_dy = dy
        f.write("\tdc.l\t0,0,0,0\n")
        return True  # ATM ignore hit found

    def gen_mask_enums(lst):
        return "".join(["{} = {}<<2\n".format(h,i) for i,h in enumerate(lst)])

    heights = gen_mask_enums(block_heights)
    blows = gen_mask_enums(blow_types)

    with open("{}/{}_frames.s".format(source_dir,radix),"w") as f:
        f.write("""
    STRUCTURE   PlayerFrameSet,0
    APTR    right_frame_set
    APTR    left_frame_set
    UWORD   hit_score
    UWORD   hit_height
    UWORD   hit_left_shift
    UWORD   blow_type
    UWORD   back_blow_type
    UWORD   attack_id
    UWORD   animation_flags
    LABEL   PlayerFrameSet_SIZEOF

ANIM_LOOP_BIT = 0
ANIM_MANUAL_BIT = 1
ANIM_LOOP_FLAG = 1<<ANIM_LOOP_BIT
ANIM_MANUAL_FLAG = 1<<ANIM_MANUAL_BIT

{blows}

{heights}

    STRUCTURE   PlayerFrame,0
    APTR    bob_data
    APTR    target_data
	APTR	full_hit_data
	APTR	half_hit_data
    UWORD   bob_plane_size
    UWORD   bob_width
    UWORD   bob_height
    UWORD   bob_nb_bytes_per_row
    UWORD   delta_x
    UWORD   delta_y
    UWORD   staying_frames
    UWORD   can_rollback
    LABEL   PlayerFrame_SIZEOF


""".format(blows=blows,heights=heights))
        for name,frame_list in sorted(rval.items()):
            symmetrical = info_dict[name]["symmetrical"]
            f.write("{}_frames:\n".format(name))
            infd = info_dict[name]
            create_mirror_objects = not infd["symmetrical"]
            right_left_template = "\tdc.l\t{0}_right_frames,{0}_left_frames\n"
            f.write(right_left_template.format(name))
            aflags = []
            if infd["loops"]:
                aflags.append("ANIM_LOOP_FLAG")
            if infd["manual"]:
                aflags.append("ANIM_MANUAL_FLAG")
            if not aflags:
                aflags = ["0"]

            params = move_param_dict.get(name)
            if params:
                # the move is in move_param dict: generate an attack id name
                # (which must exist and be valued in the source, those values originate
                # from original arcade machine)
                params["attack_id"] = "ATTACK_"+name.upper()
            else:
                params = {"score":0,"height":hn,"left_shift":0,"attack_id":"ATTACK_NONE"}
            params["left_shift"] = params.get("left_shift",0)
            params["blow_type"] = params.get("blow_type",bn)
            params["back_blow_type"] = params.get("back_blow_type",params["blow_type"])
            f.write(("\tdc.w\t{score}\n\tdc.w\t{height}\n\tdc.w\t{left_shift}\n"+
            "\tdc.w\t{blow_type}\n\tdc.w\t{back_blow_type}\n\tdc.w\t{attack_id}\n").format(**params))
            f.write("\tdc.w\t{}\t\n".format("|".join(aflags)))
            create_frame_sequence("_right","_right",1)
            create_frame_sequence("_left","_right" if symmetrical else "_left",-1)

    # include frames only once (may be used more than once)
    frames_to_write = dict()
    for name,frame_list in sorted(rval.items()):
        symmetrical = info_dict[name]["symmetrical"]
        rl = ["right"] if symmetrical else ["right","left"]
        for d in rl+["mask"] if info_dict[name]["hit_mask"] else rl:
            # don't generate a left frame if no mirroring is needed, just point on the same pic

            for frame,*_ in frame_list:
                # include only once if symmetrical
                val = "\tincbin\t{}_{}.bin\n".format(frame,d)
                frames_to_write["{}_{}:\n".format(frame,d)] = val

    # write masks in a separate file, it can be in fast memory, unlike left/right data which is blitter input
    with open("{}/{}_bobs.s".format(source_dir,radix),"w") as f,open("{}/{}_bob_masks.s".format(source_dir,radix),"w") as fm:
        for a,b in sorted(frames_to_write.items()):
            if "mask:" in a:
                fm.write(a)
                fm.write(b)
            else:
                f.write(a)
                f.write(b)
    with open("{}/hit_lists.s".format(source_dir),"w") as f:
        for name,coord_lists in sorted(hit_dict.items()):
            for hl,coords in zip(("full","half"),coord_lists):
                f.write("{}_{}_hit_list:\n\tdc.w\t".format(name,hl))
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

    palette = tiles["palette"]

    # can be a json file
    if isinstance(palette,str):
        with open(palette) as f:
            palette = json.load(f)

    game_palette_8 = [tuple(x) for x in palette]

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
        force_all_bitplanes = object.get("force_all_bitplanes",False)

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

                namei = "{}_{}".format(name,i) if nb_frames!=1 else name
                namet = name_dict.get(namei,namei)

                bin_base = "{}/{}.bin".format(sprites_dir,namet)
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

                if not generate_mask and not force_all_bitplanes:
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
palette,specific_palettes = compute_palettes()

# dump as json so it can be inserted in .json sprite description sheets
with open("palette.json","w") as f:
    json.dump([list(x) for x in palette],f,indent=2)

# pad to 16
padded_palette = palette + [(0,0,0)]*(16-len(palette))

bitplanelib.palette_dump(padded_palette,os.path.join(source_dir,"palette.s"),as_copperlist=False)

with open(os.path.join(source_dir,"background_palette.s"),"w") as f:
    f.write("""    STRUCTURE   SpecificPalette,0
	ULONG	color_change_1
	ULONG	color_change_2
    UWORD   bg_color_14
    UWORD   bg_color_15
    LABEL   SpecificPalette_SIZEOF

""")

    # create a specific palette table for backgrounds
    for i,colors in sorted(specific_palettes.items()):
        cl = colors + [(0,0,0)]*(2-len(colors))    # padding
        # kludge to artificially make 0xccc color appear last, like other background pics
        # so light gray color is available in that position (overwriting 0x8F0,
        # but burgundy is manually replaced by 0x8F0)
        # all other background pics which can run "evade" have 0xccc as extra last color
        if i==4:
            cl[-1] = (0xC0,)*3
        f.write("pl{}_palette_data:\n".format(i))
        rd = color_replacement_dict.get(i) or {}
        items = [["${:x}".format(bitplanelib.to_rgb4_color(z)) for z in x] for x in rd.items()]
        items = items + [("-1","-1")]*(2-len(items))   # padding
        for t in items:
            f.write("\tdc.w\t")
            f.write(",".join(t))
            f.write("\n")
        for c in cl:
            f.write("\tdc.w\t${:x}\n".format(bitplanelib.to_rgb4_color(c)))


#bitplanelib.palette_to_image(palette,"palette.png")


# all below must be uncommented to generate everything
# comment out to save time if you know that there were no changes in such or such

# status panel
bitplanelib.palette_image2raw("panel.png","{}/panel.bin".format(sprites_dir),
        palette,palette_precision_mask=0xF0,blit_pad=True)

#process_backgrounds(palette)

process_tiles("sprites.json",os.path.join(source_dir,"other_bobs.s"))

process_player_tiles()

process_girls()

process_fonts(dump_fonts)

