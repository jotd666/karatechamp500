import os,re

prefix_len = len("01 08 14     ")

def read(filepath):
    inst_dict = {}
    labels = {}
    raw = []
    with open(filepath,"rb") as f:
        for line in f:
            line = line.decode(errors="ignore")
            raw.append(line)
            line = line.split(";")
            comment = ""
            if len(line)>1:
                comment = line[1].strip()
            line = line[0].strip()
            if line.endswith(":"):
                # label
                line = line.rstrip(":")
                offset = None
                if len(line)>5:
                    label_offset = line[-4]
                    try:
                        offset = int(label_offset,16)
                    except ValueError:
                        pass
                    labels[line] = offset
            # decompose offset, opcodes
            toks = line.split(":")
            if len(toks)==2 and len(toks[0])==4:
                offset = int(toks[0],16)
                instruction = toks[1][prefix_len:]

                inst_toks = instruction.split()
                if inst_toks:
                    inst_dict[offset] = {"tokens":inst_toks,"comment":comment}
    return {"raw":raw,"instructions":inst_dict,"labels":labels}


