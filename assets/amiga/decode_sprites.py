

with open("sprites","rb") as f:
    contents = f.read()

SPRITE_Y = 0
SPRITE_CODE = 1
SPRITE_ATTR = 2
SPRITE_X = 3


for i in range(0,len(contents),4):
    block = contents[i:i+4]
    code = block[SPRITE_CODE] + ((block[SPRITE_ATTR] & 0x70)<<4)
    flipx = block[SPRITE_ATTR]>>7
    color = block[SPRITE_ATTR] & 0XF
    x = block[SPRITE_X]
    y = block[SPRITE_Y]
    ar = (x,y,code,color,flipx)
    if y:
        raw_code_clut = block[1]*256+block[2]
        print(f"num={i},x={x},y={y},code={code:04x},color={color},flipx={bool(flipx)}")
