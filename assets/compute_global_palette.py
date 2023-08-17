import bitplanelib
from PIL import Image

common = set()
base = dict()
for i in range(1,13):
    img = Image.open("backgrounds/{:04d}.png".format(i))
    p = bitplanelib.palette_extract(img,0xf0)
    base[i] = set(p)
    common.update(p)

# common has 16 items, now we need to impose some ordering
# for black, red and white (blue is there too, because we need
# white to be color 1 and red to be color 3 so we can blit the characters
# using different bitplanes but using the same source

palette = [(0,0,0),(240, 240, 240),(0, 0, 240),(240,0,0)]
ps = set(palette)
# now add the other colors, the order doesn't matter for them
for c in common:
    if c not in ps:
        palette.append(c)
        ps.add(c)

# global
print(palette)
# remove some
ps.difference_update({(0xC0,0xC0,0xC0),(0xC0,0xA0,0x30)})

# print unused colors from global for each
for k,v in base.items():
    print(k,base[k],base[k]-ps,ps-base[k])