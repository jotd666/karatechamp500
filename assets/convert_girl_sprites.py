import glob,os,json,bitplanelib
from PIL import Image

def generate_mask_and_image(img,rgbmask):
    mask = Image.new("RGB",img.size)
    for x in range(img.size[0]):
        for y in range(img.size[1]):
            p = tuple(0xF0 & c for c in img.getpixel((x,y)))
            if p == rgbmask:
                mask.putpixel((x,y),(0,0,0))
                # remove background color now that we have the mask
                img.putpixel((x,y),(0,0,0))
            else:
                mask.putpixel((x,y),(255,255,255))

    return mask,img

dump = True
max_level = 12

def doit():
    sprites_dir = "../sprites"
    if dump:
        outdir = "tiles/girls"
        if not os.path.exists(outdir):
            os.mkdir(outdir)
    palette = bitplanelib.palette_load_from_json("palette.json")


    maskrgb = (0,0xC0,0)
    img = Image.open("girls.png")
    # each girl is in one row with dedicated frames
    # no need for json to describe this would be copy/paste...
    # plus the png is on green background and using bitplanelib mask
    # generation is very difficult if the background doesn't match the
    # palette... (same as player moves)
    mask,img = generate_mask_and_image(img,maskrgb)

    img_frame,mask_frame = (Image.new("RGB",(16,16)) for _ in range(2))

    frame_name = ["top_front","top_left","top_right","top_end_win","top_end_lose","legs_front","legs_end"]
    bin_files = []
    for stage in range(1,max_level+1):
        print("Processing stage {} girl".format(stage))
        for girl_frame,gfn in enumerate(frame_name):
            print("=> frame {}".format(girl_frame))
            y = (stage-1)*16
            x = girl_frame*16
            img_frame.paste(img,(-x,-y))
            mask_frame.paste(mask,(-x,-y))
            data = bitplanelib.palette_image2raw(img_frame,None,palette,
                    generate_mask=False,blit_pad=True,palette_precision_mask=0xF0)
            data += bitplanelib.palette_image2raw(mask_frame,None,((0,0,0),(255,255,255)),
                    generate_mask=False,blit_pad=True)

            fn = "girl_{}_{}".format(stage,gfn)
            bin_files.append(fn)
            with open(os.path.join(sprites_dir,fn+".bin"),"wb") as f:
                f.write(data)
            if dump:

                img_frame.save(os.path.join(outdir,"girl_{}_{}.png".format(stage,gfn)))
                mask_frame.save(os.path.join(outdir,"girl_mask_{}_{}.png".format(stage,gfn)))

    with open(os.path.join("../src/girl_bobs.s"),"w") as f:
        f.write("""\tSTRUCTURE   GirlParams,0
\tAPTR\ttop_front_frame
\tAPTR\ttop_left_frame
\tAPTR\ttop_right_frame
\tAPTR\ttop_end_win_frame
\tAPTR\ttop_end_lose_frame
\tAPTR\tlegs_front_frame
\tAPTR\tlegs_end_frame
\tLABEL\tGirlParams_SIZEOF


""")

        for i in range(1,max_level+1):
            f.write("girl_{}_frames:\n".format(i))
            for fn in frame_name:
                f.write("\tdc.l\tgirl_{}_{}_frame\n".format(i,fn))
            f.write("\n")
        for bf in bin_files:
            f.write("{0}_frame:\n\tincbin\t{0}.bin\n".format(bf))

if __name__ == "__main__":
    doit()
