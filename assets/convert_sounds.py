import subprocess,os,struct,glob

# BTW convert wav to mp3: ffmpeg -i input.wav -codec:a libmp3lame -b:a 330k output.mp3

sox = r"k:\progs\sox-14-4-2\sox.exe"

wav_files = glob.glob("sounds/*.wav")
outdir = "../sounds"

srcdir = "../src"


sampling_rate = 16000
# 512k version assets can be generated by tuning down sampling freq
# and changing it in the code as well
#sampling_rate = 12000

with open(os.path.join(srcdir,"sound_table.s"),"w") as fst:

    for wav_file in wav_files:
        wav_name = os.path.basename(wav_file)
        raw_file = os.path.join(outdir,os.path.splitext(wav_name)[0]+".raw")
        def get_sox_cmd(sr,output):
            return [sox,"--volume","1.0",wav_file,"--channels","1","--bits","8","-r",str(sr),"--encoding","signed-integer",output]
        used_sampling_rate = sampling_rate

        cmd = get_sox_cmd(used_sampling_rate,raw_file)

        subprocess.check_call(cmd)
        with open(raw_file,"rb") as f:
            contents = f.read()

        # compute max amplitude so we can feed the sound chip with a amped sound sample
        # and reduce the replay volume. this gives better sound quality than replaying at max volume
        signed_data = [x if x < 128 else x-256 for x in contents]
        maxsigned = max(signed_data)
        minsigned = min(signed_data)

        amp_ratio = max(maxsigned,abs(minsigned))/128

        fst.write("    SOUND_ENTRY {},2,SOUNDFREQ,{}\n".format(os.path.splitext(wav_name)[0],int(64*amp_ratio)))
        maxed_contents = [int(x/amp_ratio) for x in signed_data]

        signed_contents = bytes([x if x >= 0 else 256+x for x in maxed_contents])
        # pre-pad with 0W, used by ptplayer for idling
        if signed_contents[0] != b'\x00' and signed_contents[1] != b'\x00':
            # add zeroes
            signed_contents = struct.pack(">H",0) + signed_contents

        with open(raw_file,"wb") as f:
           f.write(signed_contents)

with open(os.path.join(srcdir,"sound_data.s"),"w") as fst:
    for wav_file in wav_files:
        fst.write("""{0}_raw
    incbin  "{0}.raw"
    even
{0}_raw_end
""".format(os.path.splitext(os.path.basename(wav_file))[0]))

