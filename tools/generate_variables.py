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
            v = asm_file.extract_offset(a)
            if v is not None and (config.ram_start <= v < config.ram_end):
                # in RAM
                varlist[v] = a


for a in af["data_args"]:
    v = asm_file.extract_offset(a)
    if v is not None and (config.ram_start <= v < config.ram_end):
        # in RAM
        varlist[v] = a


anon_offsets = {k for k,v in varlist.items() if v.startswith("$")}

changed = False

for i,line in enumerate(af["raw"]):
    if line.strip().startswith(";"):
        continue
    # shortcut using regex, not config.ram_start. It's not generic!
    nline = re.sub("\$(C[0-9A-F]{3})",r"unknown_\1",line)
    if nline != line:
        af["raw"][i] = nline
        changed = True

if changed:
    asm_file.write(config.asm_file,af["raw"])

prev_offset = 0
next_mul = False
with open("kc_game_ram.asm","w") as f:
    lst = []
    variables = []
    next_align = False
    for k,v in sorted(varlist.items()):
        if prev_offset:
            sz = str(k-prev_offset)
            if next_mul:
                sz += "*STACK_RATIO"
                next_mul = False

            lst.append(f"\tds.b\t{sz}\n")
        if v.startswith("$"):
            v = f"unknown_{v[1:].upper()}"

        variables.append(v)
        if v.startswith("stack_"):
            if not next_mul:
                lst.append("\t.align\t2\n")
            next_mul = True


        lst.append(f"{v}:\n")


        prev_offset = k
    k = config.ram_end
    lst.append(f"\tds.b\t{k-prev_offset}\n")
    for k in sorted(variables):
        f.write(f"\t.global\t{k}\n")
    f.write("\n")
    f.write("STACK_RATIO = 4\n\n")
    f.writelines(lst)