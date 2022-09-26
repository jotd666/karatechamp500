import bitplanelib,glob,os,collections
from PIL import Image

move_dir = "moves/weak_reverse_punch"
imglist = [(imgname,Image.open(imgname)) for imgname in glob.glob(os.path.join(move_dir,"*.png"))]

red = (255,0,0)
white = (255,)*3
for imgname,img in imglist:
    width,height = img.size
    if width == 64:
        width = 48
        img = img.crop((0,0,width,height))

    for x in range(width):
        for y in range(height):
            if img.getpixel((x,y))==red:
                img.putpixel((x,y),white)
    img.save(imgname)

