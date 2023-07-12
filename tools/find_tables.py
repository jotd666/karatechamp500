import os
import asm_file

import config

with open(config.binary_file,"rb") as f:
    dump = f.read()

inst_dict = {}
table_set = set()

af = asm_file.read(config.asm_file)

inst_dict = af["instructions"]

nb_tables = 0
lst = list()

for offset,data in inst_dict.items():
    inst_toks = data["tokens"]
    if "immediate" in data["comment"] or "offset" in data["comment"]:
        continue
    if inst_toks[0]=="ld":
        ld_params = inst_toks[1].split(",")
        if (ld_params[0] in ["ix","iy","hl","de"] and
        "(" not in ld_params[1] and "$" in ld_params[1]):
            try:
                value = int(ld_params[1][1:],16)
            except ValueError:
                continue

            if (value in table_set or value < 0x2000 or (0xC000 <= value < 0xE000) or
                    value in [1,0x200,0x400]):
                pass
            else:
                lst.append([f"{value:04x}",f"{offset:04x}",inst_toks])

                nb_tables+=1

for x,y,z in sorted(lst):
    print(f"{x} loaded at {y}: {z}")
print(f"Unlabelled tables {nb_tables}")