import os,re
import asm_file

import config


af = asm_file.read(config.asm_file)

labels = af["label_offsets"]

offset_re = re.compile("\$([A-F0-9]{4})",flags=re.I)
label_re = re.compile("^([A-F0-9]{4}):",flags=re.I)

def replacer(m,labels):
    offset = int(m.group(1),16)
    label = labels.get(offset)
    if label:
        return label
    return "$"+m.group(1)

def offset_rep(m):
    return replacer(m,labels)
def label_rep(m):
    return replacer(m,restricted_labels)+":"

lines = af["raw"]
for i,line in enumerate(lines):
    new_line = offset_re.sub(offset_rep,line)
    #new_line = label_re.sub(label_rep,line)
    lines[i] = new_line

af = asm_file.write(config.asm_file,lines)

