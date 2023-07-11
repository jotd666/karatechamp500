import asm_file
import re

import config

def get_line_offset(line):
    label_offset = None
    line = re.sub(";.*","",line.strip())
    if line.endswith(":"):
        label = line.rstrip(":")
        label_offset = af["labels"].get(label)
    else:
        toks = line.split(":")
        if len(toks)>1:
            label_offset = int(toks[0],16)
    return label_offset

with open(config.binary_file,"rb") as f:
    dump = f.read()

af = asm_file.read(config.asm_file)
label_offset = None

for i,line in enumerate(af["raw"]):
    line = re.sub(";.*","",line.strip())
    if line.startswith("%%DC"):
        size = line[-1].lower()
        # use offset of the line, compute next label line
        for j in range(i+1,len(af["raw"])):
            next_label_offset = get_line_offset(af["raw"][j])
            if next_label_offset is not None:
                break

        data = []
        length = next_label_offset - label_offset
        pos = 0
        max_items_per_row = {"b":8,"w":1}[size]
        size_in_bytes = {"b":1,"w":2}[size]

        for j in range(0,length,size_in_bytes):
            if pos==0:
                data.append(f"\tdc.{size}\t")
            else:
                data.append(",")
            if size_in_bytes == 1:
                value = dump[label_offset+j]
                data.append(f"0x{value:02x}")
            else:
                value = dump[label_offset+j] + 256*dump[label_offset+j+1]
                data.append(f"0x{value:04x}")

            pos += 1
            if pos == max_items_per_row:
                pos = 0
                data.append("\n")
        if data:
            if data[-1] != "\n":
                data.append("\n")
            af["raw"][i] = "".join(data)
        else:
            print(f"{i+1}: wrong %DCx")
    else:
        lof = get_line_offset(line)
        if lof is not None:
            label_offset = lof

asm_file.write("out.asm",af["raw"])