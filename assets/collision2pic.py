import bitplanelib,glob,os,collections
from PIL import Image

with open(r"C:\Users\Public\Documents\Amiga Files\WinUAE\matrix",'rb') as f:
    contents = f.read()

width = 160
height = 55
img = Image.new("RGB",(width,height))

palette = [(0,0,0),(255,255,255),(255,0,0)]
for y in range(height):
    for x in range(width):
        p = contents[x+y*width]

        img.putpixel((x,y),palette[p])
img.save("matrix.png")

