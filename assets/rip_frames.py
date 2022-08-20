import glob,os,json
from PIL import Image


def blank_zones(image_in,image_out,zones,bgcolor = (204,204,0)):
    img = Image.open(image_in)
    for x,y,w,h in zones:
        for i in range(x,x+w):
            for j in range(y,y+h):
                img.putpixel((i,j),bgcolor)
    img.save(image_out)

# default parameters are configured for a real image per image capture of level 2 2 player fight
# images must be called "moves<frome number>.png". frame number can be zero padded to 4 digits.

def analyze_frames(frames_directory,start,end,output_directory,prefix="",is_jump=False,x_min = 0,
                    x_max = 160, y_min = 130, y_max = 228, bgcolor = (204,204,0), width = 64, height = 48,zero_padded_count = False):
    previous = None
    prev_idx = start
    outdir = output_directory
    y_size = y_max - y_min

    if not os.path.exists(outdir):
        os.mkdir(outdir)

    deltas = []
    for idx in range(start,end):
        if zero_padded_count:
            bn = "{}{:04d}.png".format(prefix,idx)
        else:
            bn = "{}{}.png".format(prefix,idx)

        imgname = os.path.join(frames_directory,bn)

        img = Image.open(imgname)

        clipped = img.crop((x_min,y_min,x_max,y_max))

        # compute min x and max y for each frame (bounding box)
        min_x = clipped.size[0]
        max_y = 0

        max_x_search = x_max - x_min

        for i in range(max_x_search):
            for j in range(clipped.size[1]):
                pix = clipped.getpixel((i,j))[0:3]  # remove alpha if any
                if pix != bgcolor:
                    if i < min_x:
                        min_x = i
                    if j > max_y:
                        max_y = j
        max_y += 1
        frame = clipped.crop((min_x,max_y-height,min_x+width,max_y))
        if not previous or list(previous.getdata()) != list(frame.getdata()):
            #clipped.save(os.path.join(outdir,"{}.png".format(idx)))
            frame.save(os.path.join(outdir,"{}.png".format(idx)))
            deltas.append([idx-prev_idx,min_x,max_y])
            prev_idx = idx
        previous = frame
    x_start,y_end = deltas[0][1:]
    deltas = [[s,x-x_start,y-y_end] for s,x,y in deltas]
    with open(os.path.join(outdir,"info.json"),"w") as f:
        json.dump({"name":output_directory,"deltas":deltas},f)


#analyze_frames(2070,2141,"weak_reverse_punch",max_x_search=200)
#small reverse punch: corner case
#3 blocks (regarder si bouge en x: corner case)
# new movie:
#move walk
#move guard
#sommersault f & b
#jump sans kick
#lunge 1 & 2 & 3 / reverse punche
#crouch
