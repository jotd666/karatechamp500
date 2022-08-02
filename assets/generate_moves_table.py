# generate moves tables and routine stubs

RIGHT_DIRECTION = 1
LEFT_DIRECTION = 1<<1
UP_DIRECTION = 1<<2
DOWN_DIRECTION = 1<<3
RIGHT_BUTTON = 1<<4
LEFT_BUTTON = 1<<5
UP_BUTTON = 1<<6
DOWN_BUTTON = 1<<7

KIAI_1 = "kiai_1_sound"
KIAI_2 = "kiai_2_sound"
SWOOSH = "kiai_2_sound"

sound_table = {'back_kick':KIAI_1,
 'back_round_kick_left':KIAI_2,
 'back_round_kick_right':KIAI_2,
 'foot_sweep_back':KIAI_1,
 'foot_sweep_front':KIAI_1,
 'front_kick':KIAI_1,
 'jumping_back_kick':KIAI_2,
 'jumping_side_kick':KIAI_2,
 'low_kick':SWOOSH,
 'lunge_punch_1000':KIAI_2,
 'lunge_punch_400':KIAI_1,
 'lunge_punch_600':KIAI_1,
 'reverse_punch_800': KIAI_2,
 'round_kick': KIAI_2
}

technique_name_dict = {"brk":"BACK ROUND KICK",
"lp":"LUNGE PUNCH",
"jbk":"JUMPING BACK KICK",
"jsk":"JUMPING SIDE KICK",
"fs":"FOOT SWEEP",
"bk":"BACK KICK",
"fk":"FRONT KICK",
"rk":"ROUND KICK",
"rp":"REVERSE PUNCH",
"lk":"LOW KICK"}

shared_dict = {LEFT_BUTTON|RIGHT_DIRECTION : ["back_round_kick_left","brk"],
RIGHT_BUTTON|LEFT_DIRECTION : ["back_round_kick_right","brk"]}

facing_right_dict = {RIGHT_DIRECTION : "move_forward",
LEFT_DIRECTION : "move_back",
UP_DIRECTION : "jump",
DOWN_DIRECTION : "crouch",
RIGHT_DIRECTION|RIGHT_BUTTON : ["lunge_punch_400","lp"],
LEFT_BUTTON|LEFT_DIRECTION : ["back_kick","bk"],
LEFT_BUTTON : ["back_kick","bk"],
LEFT_BUTTON|UP_DIRECTION : ["jumping_back_kick","jbk"],
LEFT_BUTTON|DOWN_DIRECTION : ["foot_sweep_back","fs"],
RIGHT_BUTTON|UP_DIRECTION : ["jumping_side_kick","jsk"],
RIGHT_BUTTON : ["front_kick","fk"],
UP_BUTTON : ["round_kick","rk"],
UP_DIRECTION|DOWN_BUTTON : "sommersault",
UP_DIRECTION|UP_BUTTON : "sommersault_back",
DOWN_BUTTON : ["low_kick","lk"],
DOWN_DIRECTION|RIGHT_BUTTON : ["foot_sweep_front","fs"],
DOWN_DIRECTION|UP_BUTTON : ["reverse_punch_800","rp"],
DOWN_DIRECTION|DOWN_BUTTON : ["foot_sweep_front","fs"],
RIGHT_DIRECTION|DOWN_BUTTON : ["low_kick","lk"],
LEFT_DIRECTION|DOWN_BUTTON : ["low_kick","lk"],
RIGHT_DIRECTION|UP_BUTTON : ["lunge_punch_1000","lp"],
LEFT_DIRECTION|UP_BUTTON : ["lunge_punch_600","lp"],
}

def change_dir(k):
    if k & RIGHT_DIRECTION:
        k &= (~RIGHT_DIRECTION)
        k |= LEFT_DIRECTION
    elif k & LEFT_DIRECTION:
        k &= (~LEFT_DIRECTION)
        k |= RIGHT_DIRECTION
    if k & RIGHT_BUTTON:
        k &= (~RIGHT_BUTTON)
        k |= LEFT_BUTTON
    elif k & LEFT_BUTTON:
        k &= (~LEFT_BUTTON)
        k |= RIGHT_BUTTON
    return k


facing_left_dict = {change_dir(k):v for k,v in facing_right_dict.items()}

# special case back round kicks directions don't depend on orientation...
for d in (facing_left_dict,facing_right_dict):
    d.update(shared_dict)

jump_moves = {v for v in facing_right_dict.values() if "jump" in v or "sault" in v}
# above 129 no combinations are viable
table = ["NULL"]*256
is_jump = [0]*256
sounds = [0]*256

for k,v in facing_right_dict.items():
    if isinstance(v,str):
        s = v
    else:
        s = v[0]
    is_jump[k] = int(s in jump_moves)
    sounds[k] = sound_table.get(s,0)
for v in {x for x in table if x != "NULL"}:
    print("{}:\n\trts".format(v))

with open("../src/move_tables.s","w") as f:
    # print the table
    for name,dct in [("right",facing_right_dict),("left",facing_left_dict)]:
        f.write("move_table_{}:\n".format(name))
        for k,s in dct.items():
            if isinstance(s,str):
                pass
            else:
                s = s[0]
            table[k] = "do_"+s

        max_items = 4

        for i,(j,t,s) in enumerate(zip(is_jump,table,sounds)):
            im8 = i%max_items
            if not im8:
                f.write("\tdc.l\t")
            f.write("{},{},{},0".format(t,j,s))
            if im8 < (max_items-1):
                f.write(",")
            else:
                f.write("\n")

    # print the table
    table = ["NULL"]*256
    for name,dct in [("right",facing_right_dict),("left",facing_left_dict)]:
        f.write("move_name_table_{}:\n".format(name))
        for k,s in dct.items():
            if isinstance(s,str):
                pass
            else:
                table[k] = s[1]+"_name"

        max_items = 8

        for i,t in enumerate(table):
            im8 = i%max_items
            if not im8:
                f.write("\tdc.l\t")
            f.write("{}".format(t))
            if im8 < (max_items-1):
                f.write(",")
            else:
                f.write("\n")

    f.write("\n")
    # unique technique words, not really to save space but to get separate strings
    # (because game prints the techniques one word per line)
    word_set = set()
    for v in technique_name_dict.values():
        word_set.update(v.split())

    for w in sorted(word_set):
        f.write('{}_word:\n\tdc.b\t"{}",0\n'.format(w.lower(),w))
    for k,v in technique_name_dict.items():
        f.write('{}_name:\n\tdc.l\t'.format(k))
        for w in v.split():
            f.write("{}_word,".format(w.lower()))
        f.write("0\n")
    f.write("\teven\n")
# make sure we didn't forget any viable combo
for i in range(0,5):
    for j in range(4,9):
        c1 = 0 if i == 4 else 1<<i
        c2 = 0 if j == 8 else 1<<j
        pos = c1|c2
        if pos and pos not in dct:
            print("missing {} aka {}|{}".format(pos,i,j))
