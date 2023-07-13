import os,re
import asm_file

import config


af = asm_file.read(config.asm_file)

inst_dict = af["instructions"]

# collect variables
varlist = dict()

for i,inst in af["instructions"].items():
    toks = inst["tokens"]
    if len(toks)>1:
        arg = [x.strip("()") for x in toks[1].split(",")]
        for a in arg:
            v = None
            if a.startswith("$"):
                v = int(a[1:],16)
            elif len(a)>5 and "_" in a:
                offset = a.split("_")[-1]
                try:
                    v = int(offset,16)
                except ValueError:
                    pass
            if v is not None and (0xD000 > v >= 0xC000):
                # in RAM
                varlist[v] = a

anon_offsets = {k for k,v in varlist.items() if v.startswith("$")}

changed = False

for i,line in enumerate(af["raw"]):
    if line.strip().startswith(";"):
        continue
    nline = re.sub("\$(C[0-9A-F]{3})",r"unknown_\1",line)
    if nline != line:
        af["raw"][i] = nline
        changed = True

if changed:
    asm_file.write(config.asm_file,af["raw"])

prev_offset = 0
with open("kc_game_ram.asm","w") as f:
    for k,v in sorted(varlist.items()):
        if prev_offset:
            f.write(f"\tds.b\t{k-prev_offset}\n")
        if v.startswith("$"):
            v = f"unknown_{v[1:]}"
        f.write(f"{v}:\n")
        prev_offset = k
    k = 0xD000
    f.write(f"\tds.b\t{k-prev_offset}\n")
