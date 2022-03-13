# generate moves tables and routine stubs

RIGHT_DIRECTION = 1
LEFT_DIRECTION = 1<<1
UP_DIRECTION = 1<<2
DOWN_DIRECTION = 1<<3
RIGHT_BUTTON = 1<<4
LEFT_BUTTON = 1<<5
UP_BUTTON = 1<<6
DOWN_BUTTON = 1<<7

dct = {RIGHT_DIRECTION : "move_forward",
LEFT_DIRECTION : "move_back",
UP_DIRECTION : "jump",
DOWN_DIRECTION : "crouch",
RIGHT_DIRECTION|RIGHT_BUTTON : "lunge_punch_400",
LEFT_BUTTON|LEFT_DIRECTION : "back_kick",
LEFT_BUTTON : "back_kick",
LEFT_BUTTON|UP_DIRECTION : "jumping_back_kick",
LEFT_BUTTON|DOWN_DIRECTION : "foot_sweep_back",
LEFT_BUTTON|RIGHT_DIRECTION : "back_round_kick_left",
RIGHT_BUTTON|LEFT_DIRECTION : "back_round_kick_right",
RIGHT_BUTTON|UP_DIRECTION : "jumping_side_kick",
RIGHT_BUTTON : "front_kick",
UP_BUTTON : "round_kick",
UP_DIRECTION|DOWN_BUTTON : "sommersault",
UP_DIRECTION|UP_BUTTON : "sommersault_back",
DOWN_BUTTON : "low_kick",
DOWN_DIRECTION|RIGHT_BUTTON : "foot_sweep_front",
DOWN_DIRECTION|UP_BUTTON : "reverse_punch_800",
DOWN_DIRECTION|DOWN_BUTTON : "foot_sweep_front",
RIGHT_DIRECTION|DOWN_BUTTON : "low_kick",
LEFT_DIRECTION|DOWN_BUTTON : "low_kick",
RIGHT_DIRECTION|UP_BUTTON : "lunge_punch_1000",
LEFT_DIRECTION|UP_BUTTON : "lunge_punch_600",
}

# above 129 no combinations are viable
table = ["NULL"]*256
for k,v in dct.items():
    table[k] = "do_"+v
for v in {x for x in table if x != "NULL"}:
    print("{}:\n\trts".format(v))

# print the table

for i,t in enumerate(table):
    im8 = i%8
    if not im8:
        print("\tdc.l\t",end="")
    print(t,end="")
    if im8 < 7:
        print(",",end="")
    else:
        print("")

# make sure we didn't forget any viable combo
for i in range(0,5):
    for j in range(4,9):
        c1 = 0 if i == 4 else 1<<i
        c2 = 0 if j == 8 else 1<<j
        pos = c1|c2
        if pos and pos not in dct:
            print("missing {} aka {}|{}".format(pos,i,j))
