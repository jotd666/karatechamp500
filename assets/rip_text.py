with open("kchampv2.bin","rb") as f:
    contents = f.read()

td = {i:chr(i+ord('0')) for i in range(10)} | \
     {i+10:chr(i+ord('A')) for i in range(0,26)}
td[0x3C] = ' '
td[0xFE] = '\n'
td[0xFF] = '\n\n'

with open("kchampv2.txt","w") as f:
    for i in contents:
        c = td.get(i)
        if c:
            f.write(c)

td[0xFE] = '#'
td[0xFF] = '\n'

# dump preserving offsets
with open("kchampv2_ascii.bin","wb") as f:
    for i in contents:
        c = td.get(i,".")
        f.write(c.encode())

