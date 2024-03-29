#added by python script

PROGNAME = karate_champ
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
WHDLOADER = ../$(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
MAIN = ..\$(PROGNAME)


ifdef RELEASE_BUILD
SYMBOLS = -nosym
endif


all: $(MAIN) $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)

$(MAIN) : $(PROGNAME).s computer_ai.s ptplayer.s player_frames.s move_tables.s other_bobs.s girl_bobs.s
	vasmm68k_mot $(SYMBOLS) -phxass -opt-allbra -wfail -Fhunkexe -kick1hunks -maxerrors=0 -I$(HDBASE)/amiga39_JFF_OS/include -o $(MAIN) $(PROGNAME).s
