import bitplanelib,glob,os,collections
from PIL import Image

for move_dir in glob.glob("moves/jump"):
    imglist = [(imgname,Image.open(imgname)) for imgname in glob.glob(os.path.join(move_dir,"*.png"))]
    dims = set(img.size for _,img in imglist)
    if len(dims) != 1:
        dims = [max(dims)]
    width,height = next(iter(dims))   # sole element of set
    # now for each image check if uniform (pick top right corner for instance)
    background_pixel = imglist[0][1].getpixel((imglist[0][1].size[0]-1,0))

    for imgname,img in imglist:
        if width == 64:
            r = [48,32]
        elif width == 48:
            r = [32]
        else:
            continue
        # try to reduce image
        min_width = 64

        for tw in r:
            possible = True
            for x in range(tw,width):
                for y in range(height):
                    try:
                        if img.getpixel((x,y))!=background_pixel:
                            possible = False
                            break
                    except IndexError:
                        possible = False
                        break
                if not possible:
                    break
            else:
                min_width = tw

        if min_width < width:
            print("{} => {} possible on {}".format(width,min_width,imgname))
            new_img = img.crop((0,0,min_width,height))
            new_img.save(imgname)

