import glob,os,json
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


def doit():
    if dump:
        outdir = "tiles/girls"
        if not os.path.exists(outdir):
            os.mkdir(outdir)
    with open("palette.json") as f:
        palette = json.load(f)

    maskrgb = (0,0xC0,0)
    img = Image.open("girls.png")
    # each girl is in one row with dedicated frames
    # no need for json to describe this would be copy/paste...
    # plus the png is on green background and using bitplanelib mask
    # generation is very difficult if the background doesn't match the
    # palette... (same as player moves)
    mask,img = generate_mask_and_image(img,maskrgb)

    img_frame,mask_frame = (Image.new("RGB",(16,16)) for _ in range(2))

    for stage in range(0,1):
        for girl_frame in range(6):
            y = stage*16
            x = girl_frame*16
            img_frame.paste(img,(-x,-y))
            mask_frame.paste(mask,(-x,-y))
            if dump:
                img_frame.save(os.path.join(outdir,"girl_{}_{}.png").format(stage,girl_frame))
                mask_frame.save(os.path.join(outdir,"girl_mask_{}_{}.png").format(stage,girl_frame))

##
##        clipped = img.crop((x_min,y_min,x_max,y_max))

if __name__ == "__main__":
    doit()
