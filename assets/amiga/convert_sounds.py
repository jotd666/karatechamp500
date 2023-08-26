import subprocess,os,struct,glob,tempfile
import shutil

sox = "sox"
gamename = "karate_champ"

if not shutil.which("sox"):
    raise Exception("sox command not in path, please install it")
# BTW convert wav to mp3: ffmpeg -i input.wav -codec:a libmp3lame -b:a 330k output.mp3

#wav_files = glob.glob("sounds/*.wav")

this_dir = os.path.dirname(__file__)
sound_dir = os.path.join(this_dir,"..","sounds")

this_dir = os.path.dirname(__file__)
src_dir = os.path.join(this_dir,"../../src/amiga")
outfile = os.path.join(src_dir,"sounds.68k")
sndfile = os.path.join(src_dir,"sound_entries.68k")

hq_sample_rate = 11025


START_FIGHT_MUSIC = 0
LOSE_FIGHT_MUSIC = 1
WIN_FIGHT_MUSIC = 2
MAIN_THEME_MUSIC = 3

music_vol = 12

EMPTY_SND = "EMPTY_SND"
sound_dict = {
"INTRO_TUNE_SND"              :{"index":1,"pattern":MAIN_THEME_MUSIC,"loops":True,"volume":music_vol},
"LOSE_TUNE_SND"              :{"index":2,"pattern":LOSE_FIGHT_MUSIC,"loops":False,"ticks":188,"volume":music_vol},
"START_TUNE_SND"              :{"index":3,"pattern":START_FIGHT_MUSIC,"loops":False,"volume":music_vol},
"WIN_TUNE_SND"             :{"index":0x04,"pattern":WIN_FIGHT_MUSIC,"loops":False,"volume":music_vol},
"BLOW_SND"               :{"index":0x11,"channel":0,"sample_rate":hq_sample_rate},
"KIAI_1_SND"             :{"index":0x21,"channel":0,"loops":False,"sample_rate":hq_sample_rate},
"KIAI_2_SND"             :{"index":0x22,"channel":0,"loops":False,"sample_rate":hq_sample_rate},
"SECOND_SND"             :{"index":0x08,"channel":0,"loops":False,"sample_rate":hq_sample_rate},
"STOP_SND"             :{"index":0x24,"channel":0,"loops":False,"sample_rate":hq_sample_rate},
"SWOOSH_1_SND"             :{"index":0x15,"channel":1,"loops":False,"sample_rate":hq_sample_rate},
"SWOOSH_2_SND"             :{"index":0x16,"channel":1,"loops":False,"sample_rate":hq_sample_rate},
"JUDGE_SND"             :{"index":0x28,"channel":0,"loops":False,"sample_rate":hq_sample_rate},
"FULL_POINT_SND"             :{"index":0x27,"channel":3,"loops":False,"sample_rate":hq_sample_rate},
"HALF_POINT_SND"             :{"index":0x26,"channel":3,"loops":False,"sample_rate":hq_sample_rate},
"BULL_SND"             :{"index":0x14,"channel":3,"loops":False,"sample_rate":hq_sample_rate},
"FALL_SND"             :{"index":0x10,"channel":2,"loops":False,"sample_rate":hq_sample_rate},
"EVADE_SND"             :{"index":0x13,"channel":0,"loops":False,"sample_rate":hq_sample_rate},
"BEGIN_SND"             :{"index":0x25,"channel":0,"loops":False,"sample_rate":hq_sample_rate},
"CREDIT_SND"               :{"index":0x20,"channel":0,"sample_rate":hq_sample_rate},


}

max_sound = max(x["index"] for x in sound_dict.values())+1
sound_table = [""]*max_sound
sound_table_set_1 = ["\t.long\t0,0"]*max_sound




snd_header = rf"""
# sound tables
#
# the "sound_table" table has 8 bytes per entry
# first word: 0: no entry, 1: sample, 2: pattern from music module
# second word: 0 except for music module: pattern number
# longword: sample data pointer if sample, 0 if no entry and
# 2 words: 0/1 noloop/loop followed by duration in ticks
#
FXFREQBASE = 3579564

    .macro    SOUND_ENTRY    sound_name,size,channel,soundfreq,volume,priority
\sound_name\()_sound:
    .long    \sound_name\()_raw
    .word   \size
    .word   FXFREQBASE/\soundfreq,\volume
    .byte    \channel
    .byte    \priority
    .endm

"""

def write_asm(contents,fw):
    n=0
    for c in contents:
        if n%16 == 0:
            fw.write("\n\t.byte\t0x{:x}".format(c))
        else:
            fw.write(",0x{:x}".format(c))
        n += 1
    fw.write("\n")

music_module_label = f"{gamename}_tunes"

raw_file = os.path.join(tempfile.gettempdir(),"out.raw")
with open(sndfile,"w") as fst,open(outfile,"w") as fw:
    fst.write(snd_header)

    fw.write("\t.section\t.datachip\n")
    fw.write("\t.global\t{}\n".format(music_module_label))

    for wav_file,details in sound_dict.items():
        wav_name = os.path.basename(wav_file).lower()[:-4]
        if details.get("channel") is not None:
            fw.write("\t.global\t{}_raw\n".format(wav_name))


    for wav_entry,details in sound_dict.items():
        sound_index = details["index"]
        channel = details.get("channel")
        if channel is None:
            # if music loops, ticks are set to 1 so sound orders only can happen once (else music is started 50 times per second!!)

            sound_table_set_1[sound_index] = "\t.word\t{},{},{}\n\t.byte\t{},{}".format(2,details["pattern"],details.get("ticks",0),details["volume"],int(details["loops"]))
        else:
            wav_name = os.path.basename(wav_entry).lower()[:-4]
            wav_file = os.path.join(sound_dir,wav_name+".wav")

            def get_sox_cmd(sr,output):
                return [sox,"--volume","1.0",wav_file,"--channels","1","--bits","8","-r",str(sr),"--encoding","signed-integer",output]


            used_sampling_rate = details["sample_rate"]
            used_priority = details.get("priority",1)

            cmd = get_sox_cmd(used_sampling_rate,raw_file)

            subprocess.check_call(cmd)
            with open(raw_file,"rb") as f:
                contents = f.read()

            # compute max amplitude so we can feed the sound chip with an amped sound sample
            # and reduce the replay volume. this gives better sound quality than replaying at max volume
            # (thanks no9 for the tip!)
            signed_data = [x if x < 128 else x-256 for x in contents]
            maxsigned = max(signed_data)
            minsigned = min(signed_data)

            amp_ratio = max(maxsigned,abs(minsigned))/128
            amp_ratio_64 = 64*amp_ratio*(64/38)
            print(wav_name,amp_ratio_64)
            wav = os.path.splitext(wav_name)[0]
            sound_table[sound_index] = "    SOUND_ENTRY {},{},{},{},{},{}\n".format(wav,len(signed_data)//2,channel,used_sampling_rate,int(amp_ratio_64),used_priority)
            sound_table_set_1[sound_index] = f"\t.word\t1,{int(details.get('loops',0))}\n\t.long\t{wav}_sound"

            if amp_ratio > 0:
                maxed_contents = [int(x/amp_ratio) for x in signed_data]
            else:
                maxed_contents = signed_data

            signed_contents = bytes([x if x >= 0 else 256+x for x in maxed_contents])
            # pre-pad with 0W, used by ptplayer for idling
            if signed_contents[0] != b'\x00' and signed_contents[1] != b'\x00':
                # add zeroes
                signed_contents = struct.pack(">H",0) + signed_contents

            contents = signed_contents
            # align on 16-bit
            if len(contents)%2:
                contents += b'\x00'
            # pre-pad with 0W, used by ptplayer for idling
            if contents[0] != b'\x00' and contents[1] != b'\x00':
                # add zeroes
                contents = b'\x00\x00' + contents

            fw.write("{}_raw:   | {} bytes".format(wav,len(contents)))

            if len(contents)>65530:
                raise Exception(f"Sound {wav_entry} is too long")
            write_asm(contents,fw)

    # make sure next section will be aligned
    with open(os.path.join(sound_dir,f"{gamename}_conv.mod"),"rb") as f:
        contents = f.read()
    fw.write("{}:".format(music_module_label))
    write_asm(contents,fw)
    fw.write("\t.align\t8\n")


    fst.writelines(sound_table)
    fst.write("\n\t.global\t{0}\n\n{0}:\n".format("sound_table_set_1"))
    for i,st in enumerate(sound_table_set_1):
        fst.write(st)
        fst.write(" | {}\n\n".format(i))

