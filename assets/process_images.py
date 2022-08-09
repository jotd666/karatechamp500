import sys
sys.path.append(r"K:\jff\AmigaHD\PROJETS\arcade_remakes\karatechamp\assets")
from rip_frames import analyze_frames

analyze_frames("xxxx",0,3,"front_blow",x_max=200,y_min=160,zero_padded_count=False)
#analyze_frames("moves4",5,47,"crouch",zero_padded_count=True)
#analyze_frames("low_block_images",0,42,"low_block",zero_padded_count=True)
#analyze_frames("mb_images",0,57,"medium_block",zero_padded_count=True)
#analyze_frames("hb_images",0,68,"high_block",zero_padded_count=True)
#analyze_frames("winf",0,99,"win",height=64,width=32,zero_padded_count=True)
#analyze_frames("moves2",45,72,"walk",zero_padded_count=True)
#analyze_frames("moves2",96,111,"forward",zero_padded_count=True)
#analyze_frames("moves2",402,485,"lunge_punch_400",zero_padded_count=True)
#analyze_frames("sault_reverse",11,84,"sommersault",width=48,zero_padded_count=True)
#analyze_frames("sault_reverse",440,468,"walk_backwards",zero_padded_count=True)
#analyze_frames("sault_reverse",355,377,"backwards",width=48,zero_padded_count=True)

#analyze_frames("cpu_reverse_punch",54,126,"lunge_punch_1000",zero_padded_count=True)
#analyze_frames("moves2",647,708,"lunge_punch_600",zero_padded_count=True)
#analyze_frames("moves3",4,75,"sommersault",zero_padded_count=True)
#analyze_frames("moves3",556,640,"sommersault_back",zero_padded_count=True)
#analyze_frames("moves3",400,474,"reverse_punch",x_max = 210,zero_padded_count=True)
#analyze_frames("REVERSE",1,84,"weak_reverse_punch",y_min = 170,x_max = 168, width = 48, zero_padded_count=True)
#analyze_frames(".",99,172,"low_kick")
#analyze_frames(2070,2141,"weak_reverse_punch",max_x_search=200)
#small reverse punch: corner case
#3 blocks (regarder si bouge en x: corner case)
# new movie:
#move walk
#move guard
#sommersault f & b
#jump sans kick
#lunge 1 & 2 & 3 / reverse punche
#crouch
