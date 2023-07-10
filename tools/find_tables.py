import os,re

comment_re = ";"
prefix_len = len("01 08 14     ")

with open("../kchampv2_dump.bin","rb") as f:
    dump = f.read()

inst_dict = {}
with open("../src/karate_champ_z80.asm","rb") as f:
    for line in f:
        line = line.decode(errors="ignore")
        line = line.split(";")
        comment = ""
        if len(line)>1:
            comment = line[1].strip()
        line = line[0].strip()

        # decompose offset, opcodes
        toks = line.split(":")
        if len(toks)==2 and len(toks[0])==4:
            offset = int(toks[0],16)
            instruction = toks[1][prefix_len:]

            inst_toks = instruction.split()
            if inst_toks:
                inst_dict[offset] = {"tokens":inst_toks,"comment":comment}

nb_tables = 0
for offset,data in inst_dict.items():
    inst_toks = data["tokens"]
    if "immediate" in data["comment"]:
        pass
    if inst_toks[0]=="ld":
        ld_params = inst_toks[1].split(",")
        if (ld_params[0] in ["ix","iy","hl","de","bc"] and
        "(" not in ld_params[1] and "$" in ld_params[1]):
            try:
                value = int(ld_params[1][1:],16)
            except ValueError:
                continue

            if (value < 0x100 or (0xC000 <= value < 0xD000) or
                    value in [1,0x200,0x400]):
                pass
            else:
                print(f"{offset:04x}: load {value:04x}, {inst_toks}")
                nb_tables+=1

print(f"Unlabelled tables {nb_tables}")