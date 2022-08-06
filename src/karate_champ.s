	include	"exec/types.i"
	include	"exec/memory.i"
	include	"exec/libraries.i"
	include	"exec/execbase.i"

	include "dos/dos.i"
	include "dos/var.i"
	include "dos/dostags.i"
	include "dos/dosextens.i"
	include "intuition/intuition.i"
	include	"hardware/cia.i"
	include	"hardware/custom.i"
	include	"hardware/intbits.i"
	include	"graphics/gfxbase.i"
	include	"graphics/videocontrol.i"
	include	"graphics/view.i"
	include	"devices/console.i"
	include	"devices/conunit.i"
	include	"libraries/lowlevel.i"
	INCLUDE	"workbench/workbench.i"
	INCLUDE	"workbench/startup.i"
	
	include "lvo/exec.i"
	include "lvo/dos.i"
	include "lvo/lowlevel.i"
	include "lvo/graphics.i"
	
    
    include "whdload.i"
    include "whdmacros.i"

    incdir "../sprites"
    incdir "../sounds"


INTERRUPTS_ON_MASK = $E038

    STRUCTURE   SpritePalette,0
    UWORD   color0
    UWORD   color1
    UWORD   color2
    UWORD   color3
    LABEL   SpritePalette_SIZEOF
    
    STRUCTURE   LevelParams,0
	APTR	background_picture
    UWORD   p1_init_xpos
    UWORD   p1_init_ypos
    UWORD   p2_init_xpos
    UWORD   p2_init_ypos
	UWORD	referee_xpos
	UWORD	referee_ypos
	UWORD	referee_max_xdelta
	UWORD	referee_min_xdelta
    LABEL   LevelParams_SIZEOF
   
	
	STRUCTURE Character,0
    ULONG   character_id
	UWORD	xpos
	UWORD	ypos
    UWORD   frame
	UWORD	direction   ; sprite orientation
	UWORD	previous_xpos
	UWORD	previous_ypos
	UWORD	previous_bubble_xpos
	UWORD	previous_bubble_ypos
	UWORD	previous_bubble_width
	UWORD	previous_bubble_height
	LABEL	Character_SIZEOF
	
	; do not change field order, there are some optimizations
	; with grouped fields
	; insert required fields in the end of the structure!!
	STRUCTURE	Referee,0
	STRUCT	_referee_base,Character_SIZEOF
	UWORD	bubble_type
	UWORD	bubble_timer
	UWORD	walk_timer
	UWORD	min_xpos
	UWORD	max_xpos
	UBYTE	hand_red_or_japan_flag	; 0, 1 (red) or 3 (japan)
	UBYTE	hand_white_flag	; 0 or 1 (white)
	LABEL	Referee_SIZEOF
	
	STRUCTURE	Player,0
	STRUCT	_player_base,Character_SIZEOF
	APTR	opponent
	APTR	score_table
	APTR	score_sprite
	ULONG	frame_set
	ULONG	current_move_callback
	ULONG	animation_struct
	ULONG	current_move_name
	ULONG	joystick_state
	ULONG	score
	UWORD	block_lock
	UWORD	previous_direction   ; previous sprite orientation
	UWORD	current_frame_countdown
	UWORD	scored_points
	UWORD	current_hit_height	; copied from hit_height
    UBYTE   move_controls
	UBYTE	attack_controls
    UBYTE   is_jumping
	UBYTE	rollback
	UBYTE	rollback_lock
	UBYTE	animation_loops
	UBYTE	sound_playing
	UBYTE	turn_back_flag
	UBYTE	skip_frame_reset
	UBYTE	is_cpu			; 1: controlled by A.I.
    LABEL   Player_SIZEOF
    
    
    ;Exec Library Base Offsets


;graphics base

StartList = 38

Execbase  = 4


; ******************** start test defines *********************************

; ---------------debug/adjustable variables

; if set skips intro, game starts immediately
DIRECT_GAME_START
; practice has only 1 move
;SHORT_PRACTICE
; repeat a long time just to test moves
;REPEAT_PRACTICE = 10



; do NOT change those enums without changing the update/draw function tables
GM_NORMAL = 0
GM_PRACTICE = 1<<2
GM_BULL = 2<<2
GM_BREAK = 3<<2
GM_EVADE = 3<<2

; do NOT change those enums without changing the update/draw function tables
BUBBLE_NONE = 0
BUBBLE_VERY_GOOD = 1<<2
BUBBLE_WHITE = 2<<2
BUBBLE_RED = 3<<2
BUBBLE_STOP = 4<<2
BUBBLE_JUDGE = 5<<2
BUBBLE_BEGIN = 6<<2
BUBBLE_BETTER_LUCK = 7<<2
BUBBLE_MY_HERO = 8<<2


; do NOT change those enums without changing the update/draw function tables
REFEREE_LEFT_LEG_DOWN = 0
REFEREE_RIGHT_LEG_DOWN = 1<<2
REFEREE_LEGS_DOWN = 2<<2

; test bonus screen 
;BONUS_SCREEN_TEST

;HIGHSCORES_TEST

; 
;START_SCORE = 1000/10
;START_LEVEL = 10

; temp if nonzero, then records game input, intro music doesn't play
; and when one life is lost, blitzes and a0 points to move record table
; a1 points to the end of the table
; 100 means 100 seconds of recording at least (not counting the times where
; the player (me :)) isn't pressing any direction at all.
;RECORD_INPUT_TABLE_SIZE = 100*ORIGINAL_TICKS_PER_SEC
; 1 or 2, 2 is default, 1 is to record level 1 demo moves
;INIT_DEMO_LEVEL_NUMBER = 1
; set this to create full colision matrix & blitz with a0 loaded with
; matrix: S matrix ra0 !160*!55
;DEBUG_COLLISIONS

; ******************** end test defines *********************************

; don't change the values below, change them above to test!!

	IFD	HIGHSCORES_TEST
DEFAULT_HIGH_SCORE = 2000/10
	ELSE
DEFAULT_HIGH_SCORE = 20000/10
	ENDC
NB_HIGH_SCORES = 10

	
	IFND	START_SCORE
START_SCORE = 0
	ENDC

	IFND	START_LEVEL
		IFD		RECORD_INPUT_TABLE_SIZE
START_LEVEL = INIT_DEMO_LEVEL_NUMBER
		ELSE
START_LEVEL = 1
		ENDC
	ENDC
	
NULL = 0

; in 1/60 seconds aka frames
PRACTICE_SKIP_MESSAGE_LEN = 210
PRACTICE_WAIT_BEFORE_NEXT_MOVE = 45
PRACTICE_MOVE_DURATION = PRACTICE_WAIT_BEFORE_NEXT_MOVE*2

START_ROUND_NB_TICKS = 110

NB_RECORDED_MOVES = 100

COLLISION_NB_COLS = NB_BYTES_PER_LINE*4
COLLISION_NB_ROWS = 110/2

WINUAE_PAD_CONTROLS

	IFD	WINUAE_PAD_CONTROLS
JPB_BTN_ADOWN = JPB_BTN_GRN
JPB_BTN_AUP = JPB_BTN_BLU
JPB_BTN_ARIGHT = JPB_BTN_YEL
JPB_BTN_ALEFT = JPB_BTN_RED
JPF_BTN_ADOWN = JPF_BTN_GRN
JPF_BTN_AUP = JPF_BTN_BLU
JPF_BTN_ARIGHT = JPF_BTN_YEL
JPF_BTN_ALEFT = JPF_BTN_RED
	ELSE
; CD32 button position that match original arcade controls best
JPB_BTN_ADOWN = JPB_BTN_RED
JPB_BTN_AUP = JPB_BTN_YEL
JPB_BTN_ARIGHT = JPB_BTN_BLU
JPB_BTN_ALEFT = JPB_BTN_GRN
JPF_BTN_ADOWN = JPF_BTN_RED
JPF_BTN_AUP = JPF_BTN_YEL
JPF_BTN_ARIGHT = JPF_BTN_BLU
JPF_BTN_ALEFT = JPF_BTN_GRN
	ENDC
	
; 8 bits for directions+buttons
; do NOT change order of bits, move_table has been
; computed with those values (in generate_move_tables.py script)
CTB_RIGHT = 0
CTB_LEFT = 1
CTB_UP = 2
CTB_DOWN = 3


	
; --------------- end debug/adjustable variables

; actual nb ticks (PAL)
NB_TICKS_PER_SEC = 50
; game logic ticks
ORIGINAL_TICKS_PER_SEC = 60


NB_BYTES_PER_LINE = 40
NB_BYTES_PER_BACKBUFFER_LINE = 28
BOB_16X16_PLANE_SIZE = (16/8+2)*16
BOB_64X48_PLANE_SIZE = (64/8+2)*48		; 64x48 pixels
BOB_8X8_PLANE_SIZE = 16
NB_LINES = 256
SCREEN_PLANE_SIZE = NB_BYTES_PER_LINE*NB_LINES
BACKBUFFER_PLANE_SIZE = NB_BYTES_PER_BACKBUFFER_LINE*NB_LINES
NB_PLANES = 4


; messages from update routine to display routine
MSG_NONE = 0
MSG_SHOW = 1
MSG_HIDE = 2

BONUS_TEXT_TIMER = ORIGINAL_TICKS_PER_SEC*4
PLAYER_KILL_TIMER = ORIGINAL_TICKS_PER_SEC*2
ENEMY_KILL_TIMER = ORIGINAL_TICKS_PER_SEC*2
GAME_OVER_TIMER = ORIGINAL_TICKS_PER_SEC*3

; direction enumerates, 0:right, 4:left to directly load properly oriented sprites
RIGHT = 0
LEFT = 1<<2


; possible direction bits, clockwise
DIRB_RIGHT = 0
DIRB_DOWN = 1
DIRB_LEFT = 2
DIRB_UP = 3
; direction masks
DIRF_RIGHT = 1<<DIRB_RIGHT
DIRF_DOWN = 1<<DIRB_DOWN
DIRF_LEFT = 1<<DIRB_LEFT
DIRF_UP = 1<<DIRB_UP

; states, 4 by 4, starting by 0

STATE_PLAYING = 0
STATE_GAME_OVER = 1*4
STATE_BONUS_SCREEN = 2*4
STATE_NEXT_LEVEL = 3*4
STATE_LIFE_LOST = 4*4
STATE_INTRO_SCREEN = 5*4
STATE_GAME_START_SCREEN = 6*4

X_MIN = 20
X_MAX = 200
GUARD_X_DISTANCE = 60		; to confirm
MIN_FRONT_KICK_DISTANCE = 20 ; to confirm

; jump table macro, used in draw and update
DEF_STATE_CASE_TABLE:MACRO
    move.w  current_state(pc),d0
    lea     .case_table(pc),a0
    move.l     (a0,d0.w),a0
    jmp (a0)
    
.case_table
    dc.l    .playing
    dc.l    .game_over
    dc.l    .bonus_screen
    dc.l    .next_level
    dc.l    .life_lost
    dc.l    .intro_screen
    dc.l    .game_start_screen

    ENDM
    
; write current PC value to some address
LOGPC:MACRO
     bsr    .next_\1
.next_\1
      addq.l    #6,(a7) ; skip this & next instruction
      move.l    (a7)+,$\1
      ENDM

MUL_TABLE:MACRO
mul\1_table
	rept	256
	dc.w	REPTN*\1
	endr
    ENDM
    
ADD_XY_TO_A1_40:MACRO
    lea mul40_table(pc),\1
    add.w   d1,d1
    lsr.w   #3,d0
    add.w  (\1,d1.w),a1
    add.w   d0,a1       ; plane address
    ENDM

ADD_XY_TO_A1_28:MACRO
    lea mul28_table(pc),\1
    add.w   d1,d1
    lsr.w   #3,d0
    add.w  (\1,d1.w),a1
    add.w   d0,a1       ; plane address
    ENDM


    
Start:
        ; if D0 contains "WHDL"
        ; A0 contains resload
        
    cmp.l   #'WHDL',D0
    bne.b   .standard
    move.l a0,_resload
    move.b  d1,_keyexit
    ;move.l  a0,a2
    ;lea	_tags(pc),a0
    ;jsr	resload_Control(a2)

    bsr load_highscores
    
    bra.b   .startup
.standard
    ; open dos library, graphics library
    move.l  $4.W,a6
    lea dosname(pc),a1
    moveq.l #0,d0
    jsr _LVOOpenLibrary(a6)
    move.l  d0,_dosbase
    lea graphicsname(pc),a1
    moveq.l #0,d0
    jsr _LVOOpenLibrary(a6)
    move.l  d0,_gfxbase

    bsr load_highscores

    ; check if "floppy" file is here
    
    move.l  _dosbase(pc),a6
    move.l   #floppy_file,d1
    move.l  #MODE_OLDFILE,d2
    jsr     _LVOOpen(a6)
    move.l  d0,d1
    beq.b   .no_floppy
    
    ; "floppy" file found
    jsr     _LVOClose(a6)
    ; wait 2 seconds for floppy drive to switch off
    move.l  #100,d1
    jsr     _LVODelay(a6)
.no_floppy
	; stop cdtv device if found, avoids that cd device
	; sends spurious interrupts
    move.l  #CMD_STOP,d0
    bsr send_cdtv_command
.startup

    lea  _custom,a5
    bsr		_detect_controller_types
    

; no multitask
    tst.l   _resload
    bne.b   .no_forbid
    move.l  _gfxbase(pc),a4
    move.l StartList(a4),gfxbase_copperlist

    move.l  4,a6
    jsr _LVOForbid(a6)
    
	sub.l	A1,A1
	jsr	_LVOFindTask(a6)		;find ourselves
	move.l	D0,A0
	move.l	#-1,pr_WindowPtr(A0)	; no more system requesters (insert volume, write protected...)

    
.no_forbid
    
;    sub.l   a1,a1
;    move.l  a4,a6
;    jsr (_LVOLoadView,a6)
;    jsr (_LVOWaitTOF,a6)
;    jsr (_LVOWaitTOF,a6)

    move.w  #STATE_INTRO_SCREEN,current_state
    
    
    IFND    RECORD_INPUT_TABLE_SIZE
    ; uncomment to test demo mode right now
    ;;st.b    demo_mode
    ENDC
    

    bsr init_sound
    
    ; shut off dma
    lea _custom,a5
    move.w  #$7FFF,(intena,a5)
    move.w  #$7FFF,(intreq,a5)
    move.w #$03E0,dmacon(A5)

    bsr init_interrupts
    ; intro screen
    
    
    moveq #NB_PLANES-1,d4
    lea	bitplanes,a0              ; adresse de la Copper-List dans a0
    move.l #screen_data,d1
    move.w #bplpt,d3        ; premier registre dans d3

		; 8 bytes per plane:32 + end + bplcontrol
.mkcl:
    move.w d3,(a0)+           ; BPLxPTH
    addq.w #2,d3              ; next register
    swap d1
    move.w d1,(a0)+           ; 
    move.w d3,(a0)+           ; BPLxPTL
    addq.w #2,d3              ; next register
    swap d1
    move.w d1,(a0)+           ; 
    add.l #SCREEN_PLANE_SIZE,d1       ; next plane of maze

    dbf d4,.mkcl
    

    lea game_palette,a0
    lea _custom+color,a1
    move.w  #15,d0
.copy
    move.w  (a0)+,(a1)+
    dbf d0,.copy
	; 2 more colors for score sprites (white & red)
	move.w	#$FFF,(2,a1)
	move.w	#$F00,(10,a1)
;COPPER init
		
    move.l	#coplist,cop1lc(a5)
    clr.w copjmp1(a5)

;playfield init
	
	; one of ross' magic value so the screen is centered
    move.w #$30a1,diwstrt(a5)
    move.w #$3081,diwstop(a5)	; was 3091 for scramble here it's narrower
    move.w #$0048,ddfstrt(a5)
    move.w #$00B8,ddfstop(a5)


    move.w #$4200,bplcon0(a5) ; 4 bitplanes
    clr.w bplcon1(a5)                     ; no scrolling
    move.w #$24,bplcon2(a5)                     ; no sprite priority
	; bplmod needs to be altered because
	; of special arcade resolution & centering
    move.w #10,d0
	move.w	d0,bpl1mod(a5)
    move.w	d0,bpl2mod(a5)

intro:
    lea _custom,a5
    move.w  #$7FFF,(intena,a5)
    move.w  #$7FFF,(intreq,a5)

    
    bsr hide_sprites

    bsr clear_screen
    
    bsr draw_score

    clr.l  state_timer
    clr.w  vbl_counter

   
    bsr wait_bof
    ; init sprite, bitplane, whatever dma
    move.w #$83E0,dmacon(a5)
    move.w #INTERRUPTS_ON_MASK,intena(a5)    ; enable level 6!!
    
    IFD DIRECT_GAME_START
	move.w	#1,cheat_keys	; enable cheat in that mode, we need to test the game
    bra.b   .restart
    ENDC
 	lea		player_1(pc),a4
   
.intro_loop    
    cmp.w   #STATE_INTRO_SCREEN,current_state
    bne.b   .out_intro
    tst.b   quit_flag
    bne.b   .out
    move.l  joystick_state(a4),d0
    btst    #JPB_BTN_RED,d0
    beq.b   .intro_loop
    clr.b   demo_mode
.out_intro    


    clr.l   state_timer
    move.w  #STATE_GAME_START_SCREEN,current_state
    
.release
    move.l  joystick_state(a4),d0
    btst    #JPB_BTN_RED,d0
    bne.b   .release

    tst.b   demo_mode
    bne.b   .no_credit
    ;lea credit_sound(pc),a0
    ;bsr play_fx

.game_start_loop
    bsr random      ; so the enemies aren't going to do the same things at first game
    move.l  joystick_state(a4),d0
    tst.b   quit_flag
    bne.b   .out
    btst    #JPB_BTN_RED,d0
    beq.b   .game_start_loop

.no_credit

.wait_fire_release
    move.l  joystick_state(a4),d0
    btst    #JPB_BTN_RED,d0
    bne.b   .wait_fire_release    
.restart    
    lea _custom,a5
    move.w  #$7FFF,(intena,a5)
    
    bsr init_new_play

.new_level
    bsr clear_screen  
    bsr init_level
    lea _custom,a5
    move.w  #$7FFF,(intena,a5)

    bsr wait_bof
    
    ;;bsr draw_score
    bsr hide_sprites
	
	bsr	draw_background_pic
	bsr	draw_panel
	

    bra.b   .normal_level
	
    bsr init_players_and_referee

    bsr wait_bof

    move.w  #STATE_BONUS_SCREEN,current_state
    move.w #INTERRUPTS_ON_MASK,intena(a5)
    
    bra.b   .mainloop
.normal_level    
    ; for debug
    ;;bsr draw_bounds
    
    bsr hide_sprites

    ; enable copper interrupts, mainly
    moveq.l #0,d0
    bra.b   .from_level_start
.new_life
    moveq.l #1,d0
.from_level_start
    bsr init_players_and_referee
    
    bsr wait_bof

    move.w  #STATE_PLAYING,current_state
    move.w #INTERRUPTS_ON_MASK,intena(a5)
.mainloop
    tst.b   quit_flag
    bne.b   .out
    DEF_STATE_CASE_TABLE
    
.game_start_screen
.intro_screen       ; not reachable from mainloop
    bra.b   intro
.bonus_screen
.playing
    bra.b   .mainloop

.game_over
    bra.b   .mainloop
.next_level
    add.w   #1,level_number
    bra.b   .new_level
.life_lost
    IFD    RECORD_INPUT_TABLE_SIZE
    lea record_input_table,a0
    move.l  record_data_pointer(pc),a1
    ; pause so debugger can grab data
    blitz
    ENDC

    tst.b   demo_mode
    beq.b   .no_demo
    ; lose one life in demo mode: return to intro
    move.w  #STATE_GAME_OVER,current_state
    move.l  #1,state_timer
    bra.b   .game_over
.no_demo
   

    ; game over: check if score is high enough 
    ; to be inserted in high score table
	lea	player_1,a4		; which player???
    move.l  score(a4),d0
    lea     hiscore_table(pc),a0
    moveq.w  #NB_HIGH_SCORES-1,d1
    move.w   #-1,high_score_position
.hiloop
    cmp.l  (a0)+,d0
    bcs.b   .lower
    ; higher or equal to a score
    ; shift all scores below to insert ours
    st.b    highscore_needs_saving
    move.l  a0,a1
    subq.w  #4,a0
    move.l  a0,a2   ; store for later
    tst.w   d1
    beq.b   .storesc    ; no lower scores: exit (else crash memory!)
	move.w	d1,d2
	; set a0 and a1 at the end of the score memory
	subq.w	#1,d2
	lsl.w	#2,d2
	add.w	d2,a1
	add.w	d2,a0	
    move.w  d1,d2       ; store insertion position
	addq.w	#4,a0
	addq.w	#4,a1
.hishift_loop
    move.l  -(a0),-(a1)
    dbf d2,.hishift_loop
.storesc
    move.l  d0,(a2)
    ; store the position of the highscore just obtained
    neg.w   d1
    add.w   #NB_HIGH_SCORES-1,d1
    move.w  d1,high_score_position
    bra.b   .hiout
.lower
    dbf d1,.hiloop
.hiout    
        ; high score

    ; save highscores if whdload
    tst.b   highscore_needs_saving
    beq.b   .no_save
    tst.l   _resload
    beq.b   .no_save
    tst.w   cheat_keys
    bne.b   .no_save
    bsr     save_highscores
.no_save
    ; 3 seconds
    move.l  #GAME_OVER_TIMER,state_timer
    move.w  #STATE_GAME_OVER,current_state
    bra.b   .game_over
.out      
    ; quit
    tst.l   _resload
    beq.b   .normal_end
    
    ; quit whdload
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
    
.normal_end
    bsr     restore_interrupts
    bsr     wait_blit
    bsr     finalize_sound
	; restart CDTV device
    move.l  #CMD_START,d0
    bsr send_cdtv_command

    bsr     save_highscores

    lea _custom,a5
    move.l  _gfxbase,a1
    move.l  gfxbase_copperlist,StartList(a1) ; adresse du début de la liste
    move.l  gfxbase_copperlist,cop1lc(a5) ; adresse du début de la liste
    clr.w  copjmp1(a5)
    ;;move.w #$8060,dmacon(a5)        ; réinitialisation du canal DMA
    
    move.l  4.W,A6
    move.l  _gfxbase,a1
    jsr _LVOCloseLibrary(a6)
    move.l  _dosbase,a1
    jsr _LVOCloseLibrary(a6)
    
    jsr _LVOPermit(a6)                  ; Task Switching autorisé
    moveq.l #0,d0
    rts

wait_bof
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#260<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#260<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
	rts    
    
clear_debug_screen
    movem.l d0-d1/a1,-(a7)
    lea	screen_data+SCREEN_PLANE_SIZE*3,a1 
    move.w  #NB_LINES-1,d1
.c0
    move.w  #NB_BYTES_PER_LINE/4-1,d0
.cl
    clr.l   (a1)+
    dbf d0,.cl
    
    dbf d1,.c0
    movem.l (a7)+,d0-d1/a1
    rts
    
clear_screen
    lea screen_data,a1
    moveq.l #3,d0
.cp
    move.w  #(NB_BYTES_PER_LINE*NB_LINES)/4-1,d1
    move.l  a1,a2
.cl
    clr.l   (a2)+
    dbf d1,.cl
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf d0,.cp
    rts
    


    
clear_playfield_planes
    lea screen_data,a1
    bsr clear_playfield_plane
    add.w   #SCREEN_PLANE_SIZE,a1
    bsr clear_playfield_plane
    add.w   #SCREEN_PLANE_SIZE,a1
    bsr clear_playfield_plane
    add.w   #SCREEN_PLANE_SIZE,a1
    bra clear_playfield_plane
    
; < A1: plane start
clear_playfield_plane
    movem.l d0-d1/a0-a1,-(a7)
    move.w #NB_LINES-1,d0
.cp
    move.w  #NB_BYTES_PER_LINE/4-1,d1
    move.l  a1,a0
.cl
    clr.l   (a0)+
    dbf d1,.cl
    clr.w   (a0)
    add.l   #NB_BYTES_PER_LINE,a1
    dbf d0,.cp
    movem.l (a7)+,d0-d1/a0-a1
    rts

    
init_new_play:
	clr.b	previous_move
    clr.l   state_timer
	clr.l	current_move_key_last_jump
	clr.l	current_move_key
	
	move.w	#GM_PRACTICE,level_type
	
    clr.b    music_played
    move.w  #START_LEVEL-1,level_number
 
    ; global init at game start
	
	tst.b	demo_mode
	beq.b	.no_demo
	; toggle demo
	move.w	demo_level_number(pc),d0
	move.w	d0,level_number
	btst	#0,d0
	beq.b	.demo_level_1
	;lea		demo_moves_2,a0
	;lea		demo_moves_2_end,a1
	bra.b	.rset
.demo_level_1	
	;lea		demo_moves_1,a0
	;lea		demo_moves_1_end,a1
.rset
	move.l	a0,record_data_pointer
	move.l	a1,record_data_end
	
.no_demo
	bsr		new_player
	; random practice sequence
	bsr		random
	and.w	#7,d0
	add.w	d0,d0
	add.w	d0,d0
	lea		practice_tables(pc),a0
	move.l	(a0,d0.w),picked_practice_table
	clr.l	current_practice_move_timer
	move.l	#PRACTICE_WAIT_BEFORE_NEXT_MOVE,next_practice_move_timer
	clr.w	practice_move_index
    rts

new_player
    move.l  #0,score(a4)
	rts
	
init_level:
	clr.l	state_timer
	lea		init_level_type_table(pc),a0
	move.w	level_type(pc),d0
	move.l	(a0,d0.w),a0
	jsr		(a0)
    rts
	

draw_background_pic
	move.w	level_number(pc),d0
	cmp.w	loaded_level(pc),d0
	beq.b	.unpacked
	move.w	d0,loaded_level
	add.w	d0,d0
	add.w	d0,d0
	lea	level_params_table,a0
	move.l	(a0,d0.w),a0
	move.l	background_picture(a0),a0
	lea	backbuffer,a1
	bsr	Unpack
.unpacked
	lea	backbuffer,a0
	move.w	#NB_BYTES_PER_BACKBUFFER_LINE,d2
	clr.w	d0
	clr.w	d1
	moveq.w	#NB_PLANES-1,d7
	lea		screen_data,a2
	moveq.l	#-1,d3
	move.w	#256,d4
.loop
	clr.w	d0
	clr.w	d1
	move.l	a2,a1
    bsr blit_plane_any
	add.w	#SCREEN_PLANE_SIZE,a2
	add.w	#BACKBUFFER_PLANE_SIZE,a0
	dbf		d7,.loop
	
	
	cmp.w	#GM_PRACTICE,level_type	
	bne.b	.no_practice
	; trash the bottom of the level

	bsr		draw_joys
	lea		techniques,a0
	move.w	#64/8+2,d2
	move.w	#24,d3
	move.w	#160,d0
	move.w	#224,d1
	bsr		blit_4_planes
	move.w	#224+24,d1
	move.w	#8,d3
	bsr		erase_4_planes
	
.no_practice
	rts
    
PANEL_PLANE_SIZE = (176/8+2)*64
PANEL_WIDTH = 176/8+2
PANEL_X = 24

draw_joys:
	lea	_custom,a5
	moveq	#0,d0
	move.w	#256-32,d1
	move.w	#8,d2
	move.w	#32,d3
	bsr		erase_4_planes
	

	; blit control sprite
	lea		controls,a0
	move.w	#6,d2
	move.w	#32,d3
	move.w	#72,d0
	move.w	#224,d1
	bsr		blit_4_planes
	move.w	#120,d0
	move.w	#224,d1
	bra		blit_4_planes

; what: erases 4 plane rectangle
; < D0: x
; < D1: y
; < D2: width (+2 bytes)
; < D3: height

erase_4_planes:
	movem.l	a2-a3/d3-d4/d7,-(a7)
	moveq.w	#NB_PLANES-1,d7
	lea		screen_data,a2
	move.l	d3,d4
	moveq.l	#-1,d3
	movem.l	d0-d4,-(a7)
.clrloop
	move.l	a2,a1
	move.l	a2,a3
	bsr		clear_plane_any_blitter_internal	
	lea		(SCREEN_PLANE_SIZE,a3),a2
	movem.l	(a7),d0-d4
	dbf		d7,.clrloop
	add.w	#20,a7
	movem.l	(a7)+,a2-a3/d3-d4/d7
	rts
	
draw_panel
	lea	panel,a0
	move.w	#PANEL_WIDTH,d2
	moveq.l	#-1,d3
	move.w	#64,d4
	move.w	#NB_PLANES-1,d7
	lea		screen_data,a4
	lea		panel_mask,a3
	lea		_custom,a5
.loop
	moveq.w	#0,d1
	move.w	#PANEL_X,d0
	move.l	a4,a1
	move.l	a1,a2  
	movem.l d2-d7/a2-a4,-(a7)
    bsr blit_plane_any_internal_cookie_cut	
	movem.l (a7)+,d2-d7/a2-a4
	add.w	#SCREEN_PLANE_SIZE,a4
	add.w	#PANEL_PLANE_SIZE,a0
	dbf		d7,.loop
	
	; current level
	move.w	level_number(pc),d0
	add.w	d0,d0
	add.w	d0,d0
	lea		pos_table(pc),a0
	move.l	(a0,d0.w),a0
	move.w	#PANEL_X+24,d0
	move.w	#8,d1
	move.w	#$F00,d2
	bsr		write_color_string
	
	cmp.w	#GM_PRACTICE,level_type
	bne.b	.no_practice
	lea		practice,a0
	move.w	#64/8+2,d2
	move.w	#16,d3
	move.w	#32,d0
	move.w	#40,d1
	bsr		blit_4_planes_cookie_cut	
	bra.b	.hiscore
.no_practice
	cmp.w	#GM_EVADE,level_type
	bne.b	.no_evade
	lea		evade,a0
	move.w	#64/8+2,d2
	move.w	#24,d3
	move.w	#32,d0
	move.w	#38,d1
	bsr		blit_4_planes_cookie_cut
	bra.b	.hiscore
.no_evade
	nop
.hiscore
	; draw "HISCORE"
	move.w	#136,d0
	move.w	#8,d1
    move.w  #$0fff,d2
    lea hiscore_string(pc),a0
    bsr write_blanked_color_string

	; draw trailing "0"
	move.w	#136+6*8,d0
	move.w	#16,d1
    move.w  #$0fff,d2
    lea zero_string(pc),a0
    bsr write_color_string
	rts
		
; draw score with titles and extra 0
draw_score:
	tst.b	score_update_message
	beq.b	.no_update
	clr.b	score_update_message
	move.w	#104,d0
	move.w	#40,d1
	clr.l	d2
	move.w	time_left(pc),d2
    move.w  #2,d3
	; timer 30-00
    move.w  #$FFF,d4
	bsr write_blanked_color_decimal_number
	cmp.w	#10,d2
	bcc.b	.more
	lea		.zero(pc),a0
    move.w  d4,d2
	bsr write_blanked_color_string
	
.more
	
	bsr		draw_high_score

	lea		player_1,a4
	tst.b	is_cpu(a4)
	bne.b	.p1_cpu
    move.w  #136,d0
    move.w  #32,d1
	move.l	score(a4),d2
    move.w  #6,d3
    move.w  #$FFF,d4    
    bsr write_blanked_color_decimal_number
.p1_cpu
	; draw points
	move.w	scored_points(a4),d1
	moveq	#0,d0
	bsr		draw_2_upper_points

	moveq	#8,d0
	bsr		draw_lower_point
	
	lea		player_2,a4
	tst.b	is_cpu(a4)
	bne.b	.p2_cpu
    move.w  #136,d0
    move.w  #32+16,d1
	move.l	score(a4),d2
    move.w  #6,d3
    move.w  #$FFF,d4    
    bsr write_color_decimal_number

.p2_cpu
	move.w	scored_points(a4),d1
	move.w	#40,d0
	bsr		draw_2_upper_points

	moveq	#40,d0
	bsr		draw_lower_point
.no_update	
	rts
.zero
		dc.b	"0",0
		even

POINT_SCORED_COLOR = $0ff0
POINT_EMPTY_COLOR = $bbb

; < D0: lower shift
; < D1: number of points
draw_2_upper_points
	move.w	#POINT_EMPTY_COLOR,d2	
	lea		one_ellipse(pc),a0
	move.w	d1,d4
	cmp.w	#2,d4
	bcs.b	.h1
	move.w	#POINT_SCORED_COLOR,d2	
.h1
	add.w	#40,d0
	move.w	d0,d3
	move.w	#16,d1
	bsr		write_color_string
	
	move.w	#POINT_EMPTY_COLOR,d2	
	cmp.w	#4,d4
	bcs.b	.h2
	move.w	#POINT_SCORED_COLOR,d2	
.h2

	sub.w	#8,d3
	move.w	d3,d0
	bra		write_color_string
	
draw_lower_point
	move.w	#POINT_SCORED_COLOR,d2
	btst	#0,d1
	bne.b	.score
	move.w	#POINT_EMPTY_COLOR,d2	
.score
	lea		one_ellipse(pc),a0
	add.w	#32,d0
	move.w	d0,d3
	move.w	#24,d1
	bra		write_color_string
one_ellipse
		dc.b	"o",0
 		even
   
; < D2 score
; trashes D0-D3
draw_current_score:
    move.w  #232+16,d0
    move.w  #24,d1
    move.w  #6,d3
    move.w  #$FFF,d4
    bra write_color_decimal_number
    

store_sprite_copperlist    
    move.w  d0,(6,a0)
    swap    d0
    move.w  d0,(2,a0)
    rts
    
hide_sprites:
    moveq.w  #7,d1
    lea  sprites,a0
    lea empty_sprite,a1
.emptyspr

    move.l  a1,d0
    bsr store_sprite_copperlist
    addq.l  #8,a0
    dbf d1,.emptyspr
    rts

; what: initialize base player properties before each round
; < A4 struct
init_player_common
	clr.w	block_lock(a4)
	clr.l	joystick_state(a4)
	clr.b	turn_back_flag(a4)
	clr.l	previous_xpos(a4)	; x and y
	clr.l	animation_struct(a4)
	clr.b	skip_frame_reset(a4)
    ; no moves (zeroes direction flags)
    clr.w  move_controls(a4)  	; and attack controls
	rts
	
init_players_and_referee:
    lea player_1(pc),a4
	move.l	#player_2,opponent(a4)
	move.l	#score_table_white,score_table(a4)
	move.l	#score_sprite_white,score_sprite(a4)
	move.b	#0,character_id(a4)
	bsr		init_player_common
	clr.b	is_cpu(a4)
	move.w 	#RIGHT,direction(a4)
	move.l	a4,d0
	
    lea player_2(pc),a4
	move.l	#score_table_red,score_table(a4)
	move.l	#score_sprite_red,score_sprite(a4)
	move.l	d0,opponent(a4)
	bsr		init_player_common
	move.b	#1,character_id(a4)
	st.b	is_cpu(a4)			; ATM 1 player mode
	clr.b	is_cpu(a4)
	move.w 	#RIGHT,direction(a4)
	move.w	level_number(pc),d0
	beq.b	.pract
	move.w 	#LEFT,direction(a4)
.pract	
	add.w	d0,d0
	add.w	d0,d0
	lea		level_params_table,a1
	move.l		(a1,d0.w),a1
	
	lea		walk_forward_frames,a0
	bsr		load_walk_frame


    lea player_1(pc),a4
    move.w	p1_init_xpos(a1),xpos(a4)
    move.w	p1_init_ypos(a1),d6		; save for p2 y
	
	move.w	d6,ypos(a4)
 	lea		walk_forward_frames,a0
	bsr		load_walk_frame 

	lea player_2(pc),a4
    move.w	p2_init_xpos(a1),xpos(a4)
    move.w	p2_init_ypos(a1),ypos(a4)
	bne.b	.no_zero
	move.w	d6,ypos(a4)		; 0 means same y as p1
.no_zero
	sub.w	#50,d6	; margin y where players can't go
	move.w	d6,level_players_y_min

 	lea		walk_forward_frames,a0
	bsr		load_walk_frame 

	lea	referee(pc),a4
	; init referee
	move.w	referee_xpos(a1),xpos(a4)
	move.w	referee_ypos(a1),ypos(a4)
	move.w	xpos(a4),max_xpos(a4)
	move.w	referee_max_xdelta(a1),d0
	add.w	d0,max_xpos(a4)
	move.w	xpos(a4),min_xpos(a4)
	move.w	referee_min_xdelta(a1),d0
	add.w	d0,min_xpos(a4)
	clr.w	walk_timer(a4)
	move.b	#2,character_id(a4)
	move.w	#REFEREE_LEGS_DOWN,frame(a4)
	move.w	#RIGHT,direction(a4)
	clr.l	previous_bubble_xpos(a4)
	clr.w	bubble_type(a4)
	clr.w	bubble_timer(a4)
	clr.w	hand_red_or_japan_flag(a4)	; both hands
	clr.l	previous_xpos(a4)	; x and y

	; no score displayed
	clr.w	current_score_x
	; controls are active
	clr.b	controls_blocked_flag
	; level is not over
	clr.b	level_completed_flag
	
	move.w	#30,time_left
	move.w	#ORIGINAL_TICKS_PER_SEC,time_ticks
	st.b	score_update_message
	
    
    move.w  #ORIGINAL_TICKS_PER_SEC,D0   
    tst.b   music_played
    bne.b   .played
    st.b    music_played


    IFD    RECORD_INPUT_TABLE_SIZE
    ELSE
    IFND     DIRECT_GAME_START
    tst.b   demo_mode
    beq.b   .no_demo
    ENDC

.no_demo
    ENDC
.played
    IFD    RECORD_INPUT_TABLE_SIZE
    move.l  #record_input_table,record_data_pointer ; start of table
    move.l  #-1,prev_record_joystick_state	; impossible previous value, force record
    clr.l   previous_random
    ENDC

    clr.w   record_input_clock                      ; start of time
    


    rts

; < a0: frame right/left
; < a4: player structure (updated)
; trashes: D0,D1
load_walk_frame:
    clr.b	is_jumping(a4)  
	clr.b	rollback_lock(a4)
	clr.b	sound_playing(a4)
    clr.w	frame(a4)
	clr.b	rollback(a4)
	clr.l	current_move_callback(a4)	
	clr.w	current_frame_countdown(a4)
	move.w	direction(a4),d0
	; store previous direction, just in case we use back round kick
	; so previous_direction still points to the proper move table
	; even if player turns around
	move.w	d0,previous_direction(a4)
	move.l	a0,animation_struct(a4)
	move.l	(a0,d0.w),frame_set(a4)	
	move.w	(fs_animation_loops,a0),d0
	move.b	d0,animation_loops(a4)
	rts

	
    
DEBUG_X = 24     ; 232+8
DEBUG_Y = 24

        
draw_debug
    lea player_1(pc),a2
    move.w  #DEBUG_X,d0
    move.w  #DEBUG_Y,d1
    lea	screen_data+SCREEN_PLANE_SIZE,a1 
    lea .p1x(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w xpos(a2),d2
    move.w  #5,d3
    bsr write_decimal_number
    move.w  #DEBUG_X,d0
    add.w  #8,d1
    move.l  d0,d4
    lea .p1y(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w ypos(a2),d2
    move.w  #3,d3
    bsr write_decimal_number
    move.l  d4,d0
    ;;
    add.w  #8,d1
    lea .cmc(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w current_frame_countdown(a2),d2
    move.w  #5,d3
    bsr write_decimal_number

    move.w  #DEBUG_X,d0
    add.w  #8,d1
    move.l  d0,d4
    lea .ctrl(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w player+move_controls(pc),d2
    move.w  #4,d3
    bsr write_hexadecimal_number
	
    move.w  #DEBUG_X,d0
    add.w  #8,d1
    move.l  d0,d4
    lea .frame_count(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w player+frame(pc),d2
	divu	#PlayerFrame_SIZEOF,d2
	and.l	#$FFFF,d2
    move.w  #3,d3
    bsr write_hexadecimal_number
	
	IFEQ	1
    move.w  #DEBUG_X,d0
    add.w  #8,d1
    move.l  d0,d4
    lea .pv(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w previous_valid_direction+2(pc),d2
    move.w  #3,d3
    bsr write_decimal_number
    move.l  d4,d0
	ENDC
 

    rts
    
.p1x
        dc.b    "P1X ",0
.p1y
        dc.b    "P1Y ",0
.cmc
		dc.b	"CMC ",0
.ctrl
		dc.b	"CTRL ",0
.frame_count
		dc.b "FCNT ",0
.tx
        dc.b    "TX ",0
.ty
        dc.b    "TY ",0

.pmi
        dc.b    "PMI ",0
.tmi
        dc.b    "TMI ",0

        even

draw_enemies:

    rts

 
draw_all
    DEF_STATE_CASE_TABLE

; draw intro screen
.intro_screen
    bra.b   draw_intro_screen
; draw bonus screen
.bonus_screen
	rts

	
.game_start_screen
    tst.l   state_timer
    beq.b   draw_start_screen
    rts
    
.life_lost
.next_level

    ; don't do anything
    rts
PLAYER_ONE_X = 72
PLAYER_ONE_Y = 102-14

    
.game_over
    cmp.l   #GAME_OVER_TIMER,state_timer
    bne.b   .draw_complete
    bsr hide_sprites

    move.w  #72,d0
    move.w  #136,d1
    move.w  #$0f00,d2   ; red
    lea player_one_string(pc),a0
    bsr write_color_string
    move.w  #72,d0
    add.w   #16,d1
    lea game_over_string(pc),a0
    bsr write_color_string
    
    bra.b   .draw_complete
.playing
	bsr	draw_score

	move.w	level_type(pc),d0
	lea		draw_level_type_table(pc),a0
	move.l	(a0,d0.w),a0
	jsr		(a0)
	   
    
.after_draw
        

    
    ; handle highscore in draw routine eek
    move.l  high_score(pc),d4
    cmp.l   d2,d4
    bcc.b   .no_score_update
    
    move.l  d2,high_score
    bsr draw_high_score
.no_score_update
.draw_complete
    rts

stop_sounds
    lea _custom,a6
    clr.b   music_playing
    bra _mt_end

draw_level_type_table
	dc.l	draw_normal
	dc.l	draw_practice
	dc.l	draw_bull
	dc.l	draw_break
	dc.l	draw_evade

draw_practice:
	; draw moves names & controls
	tst.b	current_move_key_message
	bmi.b	.erase_move_message
	bne.b	.draw_move_message
	
	; draw normal if message has been read
	move.l	state_timer(pc),d0
	beq.b	.draw_practice_message
	cmp.l	#PRACTICE_SKIP_MESSAGE_LEN,d0
	beq.b	.erase_practice_message
	bcc.b	draw_normal
.draw_practice_message:
	
	bsr	draw_referee

	; draw message. This is suboptimal but works
	lea		practice_message_list(pc),a1
.loop
	move.w	(a1)+,d0
	bmi.b	.out_msg
	move.w	(a1)+,d1
	move.l	(a1)+,a0
	move.w	#$ffc,d2
	move.w	d0,d3
	bsr		write_blanked_color_string
	move.w	d3,d0
	move.l	(a1)+,a0
	; remove characters
	moveq	#$0,d2
	bsr		write_color_string
	; add characters
	move.w	d3,d0
	move.w	#$f00,d2
	bsr		write_color_string
	bra.b	.loop
.out_msg

	rts

	
UP_ARROW_Y = 256-32+2
ARROW_LEFT_X = 84
ARROW_VERT_TO_HORIZ_X_SHIFT = 11
ARROW_HORIZ_LEFT_X = ARROW_LEFT_X-ARROW_VERT_TO_HORIZ_X_SHIFT
ARROW_RIGHT_X = ARROW_LEFT_X+48
ARROW_HORIZ_RIGHT_X = ARROW_RIGHT_X-ARROW_VERT_TO_HORIZ_X_SHIFT
DOWN_ARROW_Y = UP_ARROW_Y+22
HORIZ_ARROW_Y = UP_ARROW_Y+10
ARROW_HORIZ_X_SHIFT = 24

.draw_move_message
	move.l	current_move_key_last_jump(pc),d4
	bne.b	.last
	move.l	current_move_key(pc),d4
.last
	moveq.w	#4,d2
	moveq.w	#8,d3
	move.w	#ARROW_LEFT_X,d0
	move.w	#UP_ARROW_Y,d1
	; up arrows
	lea	up_arrow,a0
	btst	#JPB_BTN_UP,d4
	beq.b	.no_dir_up
	bsr		blit_4_planes_cookie_cut
.no_dir_up
	btst	#JPB_BTN_AUP,d4
	beq.b	.no_tech_up
	move.w	#ARROW_RIGHT_X,d0
	bsr		blit_4_planes_cookie_cut
.no_tech_up
	; down arrows
	lea	down_arrow,a0
	move.w	#ARROW_LEFT_X,d0
	move.w	#DOWN_ARROW_Y,d1
	btst	#JPB_BTN_DOWN,d4
	beq.b	.no_dir_down
	bsr		blit_4_planes_cookie_cut
.no_dir_down
	btst	#JPB_BTN_ADOWN,d4
	beq.b	.no_tech_down
	move.w	#ARROW_RIGHT_X,d0
	bsr		blit_4_planes_cookie_cut
.no_tech_down
	; left arrows
	lea	left_arrow,a0
	move.w	#ARROW_HORIZ_LEFT_X,d0
	move.w	#HORIZ_ARROW_Y,d1
	btst	#JPB_BTN_LEFT,d4
	beq.b	.no_dir_left
	bsr		blit_4_planes_cookie_cut
.no_dir_left
	btst	#JPB_BTN_ALEFT,d4
	beq.b	.no_tech_left
	move.w	#ARROW_HORIZ_RIGHT_X,d0
	bsr		blit_4_planes_cookie_cut
.no_tech_left
	; right arrows
	lea	right_arrow,a0
	move.w	#ARROW_HORIZ_RIGHT_X+ARROW_HORIZ_X_SHIFT,d0
	move.w	#HORIZ_ARROW_Y,d1
	btst	#JPB_BTN_RIGHT,d4
	beq.b	.no_dir_right
	bsr		blit_4_planes_cookie_cut
.no_dir_right
	btst	#JPB_BTN_ARIGHT,d4
	beq.b	.no_tech_right
	move.w	#ARROW_HORIZ_RIGHT_X+ARROW_HORIZ_X_SHIFT,d0
	bsr		blit_4_planes_cookie_cut
.no_tech_right
	; now the technique name
	move.l	d4,d0
	bsr		decode_technique_name
	tst.l	d0
	beq.b	.no_tech	; should not happen!!
	move.l	d0,a1
	move.w	#256-24,d1
.wl
	move.l	(a1)+,d3
	beq.b	.no_tech
	; display word
	move.l	d3,a0
	move.w	#8,d0
	move.w	#$FFF,d2
	bsr		write_color_string
	add.w	#8,d1
	bra.b	.wl
.no_tech
	clr.b	current_move_key_message	; ack
	rts
	
.erase_move_message
	clr.b	current_move_key_message	; ack
	bra	draw_joys	

.erase_practice_message
	move.w	#32,D0
	move.w	#112,d1
	move.w	#20*8,d2
	move.w	#40,d3
	bsr		restore_background

	rts

; < a4 character structure
erase_bubble
	move.w	previous_bubble_xpos(a4),d0
	beq.b	.no_erase
	move.w	previous_bubble_ypos(a4),d1
	move.w	previous_bubble_width(a4),d2
	move.w	previous_bubble_height(a4),d3
	addq.w	#8,d3	; bubble leg
	bra		restore_background
.no_erase
	rts
	
draw_red_bubble
	lea	red_bubble,a0
	lea	red_right_bubble_leg,a1
	move.w	#6,d2
	clr.w	d4
	bra		draw_bubble

draw_no_bubble
	rts
	
draw_judge_bubble
	lea	judge_bubble,a0
	bra		draw_32_white_bubble

draw_stop_bubble
	lea	stop_bubble,a0
	bra		draw_32_white_bubble
draw_begin_bubble
	lea	begin_bubble,a0
	bra		draw_32_white_bubble
	

draw_32_white_bubble
	lea	white_right_bubble_leg,a1
	move.w	#6,d2
	clr.w	d4
	bra		draw_bubble

draw_very_good_bubble
	lea	very_good_bubble,a0
	lea	white_right_bubble_leg,a1
	move.w	#8,d2
	clr.w	d4
	bra		draw_bubble
	
draw_better_luck_bubble
	lea	better_luck_bubble,a0
	lea	white_right_bubble_leg,a1
	move.w	#12,d2
	clr.w	d4
	bra		draw_bubble
	
draw_my_hero_bubble
	lea	my_hero_bubble,a0
	lea	yellow_right_bubble_leg,a1
	move.w	#12,d2
	clr.w	d4
	bra		draw_bubble
	
; what: generic bubble draw (to the right)
; < a0: bubble bitmap
; < a1: bubble leg bitmap
; < d2: bubble width (nb bytes, inc mask)
; < d4: bubble leg x offset
; < a4: character structure

draw_bubble
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	move.w	#16,d3		; height is always 16
	add.w	#16,d0
	sub.w	#24,d1
	move.w	d0,previous_bubble_xpos(a4)
	move.w	d1,previous_bubble_ypos(a4)
	move.w	d3,previous_bubble_height(a4)
	bsr		blit_4_planes_cookie_cut
	lsl.w	#3,d2	; times 8
	move.w	d2,previous_bubble_width(a4)
	move.l	a1,a0
	add.w	#16,d1
	add.w	d4,d0
	move.w	#4,d2
	move.w	#8,d3
	bra		blit_4_planes_cookie_cut
	
; what: draw "white" bubble (the only one to the left)
draw_white_bubble
	lea	white_bubble,a0
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	sub.w	#24,d0
	sub.w	#24,d1
	move.w	#6,d2
	move.w	#16,d3
	move.w	d0,previous_bubble_xpos(a4)
	move.w	d1,previous_bubble_ypos(a4)
	move.w	d3,previous_bubble_height(a4)
	bsr		blit_4_planes_cookie_cut
	lsl.w	#3,d2	; times 8
	move.w	d2,previous_bubble_width(a4)
	lea	white_left_bubble_leg,a0
	add.w	#8,d0
	add.w	#16,d1
	move.w	#4,d2
	move.w	#8,d3
	bra		blit_4_planes_cookie_cut
	
draw_evade
draw_break
draw_bull
	tst.l	state_timer
	bne.b	.no_update
	bsr		clear_screen
	lea		demo_message(pc),a0
	move.w	#16,d0
	move.w	#80,d1
	move.w	#$FFF,d2
	bsr		write_color_string
	lea		demo_message_2(pc),a0
	move.w	#16,d0
	move.w	#96,d1
	move.w	#$FFF,d2
	bsr		write_color_string
.no_update
	rts
	
demo_message
	dc.b	"END OF KARATE CHAMP DEMO",0
demo_message_2
	dc.b	" STAY TUNED FOR UPDATES",0
	even
	
draw_normal:
	bsr	erase_referee
	lea	player_1(pc),a4
	bsr	erase_player
	lea	player_2(pc),a4
	bsr	erase_player

	bsr	draw_referee
	lea	player_1(pc),a4
    bsr draw_player
	lea	player_2(pc),a4
    bsr draw_player
	rts
	
; < D2: highscore
draw_high_score
    move.w  #136,d0
    move.w  #16,d1
	move.l	hiscore_table(pc),d2
    move.w  #6,d3
    move.w  #$FFF,d4    
    bra write_color_decimal_number


CONTROL_TEST:MACRO
	btst	#JPB_BTN_\1,d0
	beq.b	.no_\1
	bset	#CTB_\2,d1
	bra.b	\3
.no_\1
    ENDM
	
; < D0: control bits
; > D0: pointer on words list for technique (or 0)
; trashes: D1,A0
decode_technique_name	
	moveq.l	#0,d1
	CONTROL_TEST	ADOWN,DOWN,.out2
	CONTROL_TEST	AUP,UP,.out2
	CONTROL_TEST	ARIGHT,RIGHT,.out2
	CONTROL_TEST	ALEFT,LEFT,.out2
.out2
	lsl.w	#4,d1	; shift moves
	CONTROL_TEST	DOWN,DOWN,.out1
	CONTROL_TEST	UP,UP,.out1
	CONTROL_TEST	RIGHT,RIGHT,.out1
	CONTROL_TEST	LEFT,LEFT,.out1
.out1
	; D1.B holds table index for move name
	add.w	d1,d1
	add.w	d1,d1
	lea		move_name_table_right,a0	; ATM right is ok
	move.l	(a0,d1.w),d0
	rts
	
; < A4: player structure
; < D0: score (/10)
; trashes: D0,D1
add_to_score:
	tst.b	demo_mode
    
	st.b	score_update_message
    add.l   d0,score(a4)
    rts
    
; < A4: player structure
; < D0: points (1 or 2)
; trashes: D0,D1
add_to_points:
	move.w	scored_points(a4),d1
	add.w	d0,d1
	cmp.w	#6,d1
	bcc.b	.not_maxed
	move.w	#5,d1
.not_maxed
	move.w	d1,scored_points(a4)
	rts
	
random:
    move.l  previous_random(pc),d0
	;;; EAB simple random generator
    ; thanks meynaf
    mulu #$a57b,d0
    addi.l #$bb40e62d,d0
    rol.l #6,d0
    move.l  d0,previous_random
    rts

    
draw_start_screen
    bsr hide_sprites
    bsr clear_screen
    
    bsr draw_title
    
	
    lea .psb_string(pc),a0
    move.w  #48,d0
    move.w  #96,d1
    move.w  #$0F0,d2
    bsr write_color_string
    
    lea .opo_string(pc),a0
    move.w  #48+16,d0
    move.w  #116,d1
    move.w  #$0f00,d2
	

    
    rts
    
.psb_string
    dc.b    "PUSH START BUTTON",0
.opo_string:
    dc.b    "1 PLAYER ONLY",0
    even
    
practice_message_list
	dc.w	56,112
	dc.l	blank_13_message
	dc.l	if_you_do_not_message 
	dc.w	32,112+16
	dc.l	blank_19_message
	dc.l	want_practice_press_message 
	dc.w	32,112+32
	dc.l	blank_19_message
	dc.l	player_start_button_message 
	dc.w	-1
	
INTRO_Y_SHIFT=68
ENEMY_Y_SPACING = 24

draw_intro_screen
    tst.b   intro_state_change
    beq.b   .no_change
    clr.b   intro_state_change
    move.b  intro_step(pc),d0
    cmp.b   #1,d0
    beq.b   .init1
    cmp.b   #2,d0
    beq.b   .init2
    cmp.b   #3,d0
    beq.b   .init3
    bra.b   .no_change  ; should not be reached
.init1    
    bsr clear_screen
    bsr hide_sprites
    
    rts
.init2
    bsr hide_sprites
    bsr clear_screen
    bsr draw_score
    ; high scores
    
;    move.w  #40,d0
;    move.w  #8,d1
;    lea .score_ranking(pc),a0
;    move.w  #$0F0,d2
;    bsr     write_color_string
    
    ; write high scores & position
    move.w  #24,D1

.ws
    move.w  #$FFF,d2    ; color
    move.l  (a3)+,a0
    move.w  #32,d0
    bsr write_color_string
    
    move.w  d2,d4
    move.w  #64,d0
    move.l  (a4)+,d2
    move.w  #7,d3
    bsr write_color_decimal_number
    

    
    add.w   #16,d1
    dbf d5,.ws
    
    rts
    
.init3
    bsr clear_screen
    ; characters
	rts
    

.no_change
    rts


pos_table  
    dc.l    pos1		; practice
    dc.l    pos1
    dc.l    pos2
    dc.l    pos3
    dc.l    pos4
    dc.l    pos5
    dc.l    pos6
    dc.l    pos7
    dc.l    pos8
    dc.l    pos9
    dc.l    pos10

pos1
   dc.b    "1ST",0
pos2
   dc.b    "2ND",0
pos3
   dc.b    "3RD",0
pos4
   dc.b    "4TH",0
pos5
   dc.b    "5TH",0
pos6
   dc.b    "6TH",0
pos7
   dc.b    "7TH",0
pos8
   dc.b    "8TH",0
pos9
   dc.b    "9TH",0
pos10
    dc.b    "10G",0
pos10plus
	dc.b	"CMP",0
    even

time_left
	dc.w	0
time_ticks
	dc.w	0
	
high_score_position
    dc.w    0
high_score_highlight_y
    dc.w    0
high_score_highlight_timer
    dc.w    0
high_score_highlight_color_index
    dc.w    0
high_score_highlight_color_table
    dc.w    $0FF
    dc.w    $0F0
    dc.w    $FF0
    dc.w    $FFF
high_score
    dc.l    DEFAULT_HIGH_SCORE
	dc.l	$DEADBEEF
hiscore_table:
    REPT    NB_HIGH_SCORES
	IFD		HIGHSCORES_TEST
    dc.l    (DEFAULT_HIGH_SCORE/10)*(10-REPTN)   ; decreasing score for testing	
	ELSE
    dc.l    DEFAULT_HIGH_SCORE
	ENDC
    ENDR
	dc.l	$DEADBEEF
	
intro_frame_index
    dc.w    0
intro_step
    dc.b    0
intro_state_change
    dc.b    0
    even
    
draw_title
	rts


; what: clears a plane of any width (not using blitter, no shifting, start is multiple of 8), 16 height
; args:
; < A1: dest (must be even)
; < D0: X (multiple of 8)
; < D1: Y
; < D2: width in bytes (not blit width, can be odd and all)
; trashes: none

clear_plane_any_cpu:
    move.w  d3,-(a7)
    move.w  #16,d3
    bsr     clear_plane_any_cpu_any_height
    move.w  (a7)+,d3
    rts
    
clear_plane_any_cpu_any_height 
    movem.l d0-D3/a0-a2,-(a7)
    subq.w  #1,d3
    bmi.b   .out
    lea mul40_table(pc),a2
    add.w   d1,d1
    beq.b   .no_add
    move.w  (a2,d1.w),d1
    add.w   d1,a1
.no_add

    lsr.w   #3,d0
    add.w   d0,a1
	move.l	a1,d1
    btst    #0,d1
    bne.b   .odd
    cmp.w   #4,d2
    bcs.b   .odd
	btst	#0,d2
	bne.b	.odd
	btst	#1,d2
	beq.b	.even
.odd    
    ; odd address
    move.w  d3,d0
    subq.w  #1,d2
.yloop
    move.l  a1,a0
    move.w  d2,d1   ; reload d1
.xloop
    clr.b   (a0)+
    dbf d1,.xloop
    ; next line
    lea   (NB_BYTES_PER_LINE,a1),a1
    dbf d0,.yloop
.out
    movem.l (a7)+,d0-D3/a0-a2
    rts

.even
    ; even address, big width: can use longword erase
    move.w  d3,d0
    lsr.w   #2,d2
    subq.w  #1,d2
.yloop2
    move.l  a1,a0
    move.w  d2,d1
.xloop2
    clr.l   (a0)+
    dbf d1,.xloop2
    ; next line
    add.w   #NB_BYTES_PER_LINE,a1
    dbf d0,.yloop2
    bra.b   .out
    
; what: clears a plane of any width (using blitter), 16 height
; args:
; < A1: dest
; < D0: X (not necessarily multiple of 8)
; < D1: Y
; < D2: rect width in bytes (2 is added)
; trashes: none
    
clear_plane_any_blitter:
    movem.l d0-d6/a1/a5,-(a7)
    lea _custom,a5
    moveq.l #-1,d3
    move.w  #16,d4
    bsr clear_plane_any_blitter_internal
    movem.l (a7)+,d0-d6/a1/a5
    rts


;; C version
;;   UWORD minterm = 0xA;
;;
;;    if (mask_base) {
;;      minterm |= set_bits ? 0xB0 : 0x80;
;;    }
;;    else {
;;      minterm |= set_bits ? 0xF0 : 0x00;
;;    }
;;
;;    wait_blit();
;;
;;    // A = Mask of bits inside copy region
;;    // B = Optional bitplane mask
;;    // C = Destination data (for region outside mask)
;;    // D = Destination data
;;    custom.bltcon0 = BLTCON0_USEC | BLTCON0_USED | (mask_base ? BLTCON0_USEB : 0) | minterm;
;;    custom.bltcon1 = 0;
;;    custom.bltbmod = mask_mod_b;
;;    custom.bltcmod = dst_mod_b;
;;    custom.bltdmod = dst_mod_b;
;;    custom.bltafwm = left_word_mask;
;;    custom.bltalwm = right_word_mask;
;;    custom.bltadat = 0xFFFF;
;;    custom.bltbpt = (APTR)mask_start_b;
;;    custom.bltcpt = (APTR)dst_start_b;
;;    custom.bltdpt = (APTR)dst_start_b;
;;    custom.bltsize = (height << BLTSIZE_H0_SHF) | width_words;
;;  }
  
; < A5: custom
; < D0,D1: x,y
; < A1: plane pointer
; < D2: width in bytes (inc. 2 extra for shifting)
; < D3: blit mask
; < D4: blit height
; trashes D0-D6 and A2
; > A1: even address where blit was done
clear_plane_any_blitter_internal:
    ; pre-compute the maximum of shit here
    lea mul40_table(pc),a2
    add.w   d1,d1
    beq.b   .d1_zero    ; optim
    move.w  (a2,d1.w),d1
    swap    d1
    clr.w   d1
    swap    d1
.d1_zero
    move.l  #$030A0000,d5   ; minterm useC useD & rect clear (0xA) 
    move    d0,d6
    beq.b   .d0_zero
    and.w   #$F,d6
    and.w   #$1F0,d0
    lsr.w   #3,d0
    add.w   d0,d1

    swap    d6
    clr.w   d6
    lsl.l   #8,d6
    lsl.l   #4,d6
    or.l    d6,d5            ; add shift
.d0_zero    
    add.l   d1,a1       ; plane position (always even)

	move.w #NB_BYTES_PER_LINE,d0
    sub.w   d2,d0       ; blit width

    lsl.w   #6,d4
    lsr.w   #1,d2
    add.w   d2,d4       ; blit height


    ; now just wait for blitter ready to write all registers
	bsr	wait_blit
    
    ; blitter registers set
    move.l  d3,bltafwm(a5)
	move.l d5,bltcon0(a5)	
    move.w  d0,bltdmod(a5)	;D modulo
	move.w  #-1,bltadat(a5)	;source graphic top left corner
	move.l a1,bltcpt(a5)	;destination top left corner
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
    rts

    
init_sound
    ; init phx ptplayer, needs a6 as custom, a0 as vbr (which is zero)
    sub.l   a0,a0
    moveq.l #1,d0
    lea _custom,a6
    jsr _mt_install_cia
    rts
    
init_interrupts
    lea _custom,a6
    sub.l   a0,a0

    move.w  (dmaconr,a6),saved_dmacon
    move.w  (intenar,a6),saved_intena

    sub.l   a0,a0
    ; assuming VBR at 0
    lea saved_vectors(pc),a1
    move.l  ($8,a0),(a1)+
    move.l  ($c,a0),(a1)+
    move.l  ($10,a0),(a1)+
    move.l  ($68,a0),(a1)+
    move.l  ($6C,a0),(a1)+

    lea   exc8(pc),a1
    move.l  a1,($8,a0)
    lea   excc(pc),a1
    move.l  a1,($c,a0)
    lea   exc10(pc),a1
    move.l  a1,($10,a0)
    lea   exc28(pc),a1
    move.l  a1,($28,a0)
    lea   exc2f(pc),a1
    move.l  a1,($2c,a0)
    
    lea level2_interrupt(pc),a1
    move.l  a1,($68,a0)
    
    lea level3_interrupt(pc),a1
    move.l  a1,($6C,a0)
    
    
    rts
    
FATAL_EXC:MACRO
	movem.l	D0-a6,$100.W
	lea	.\1(pc),a0
	bra.b	lockup
	ENDM
	
exc8
	FATAL_EXC	bus_error
.bus_error:
    dc.b    "BUS ERROR AT ",0
    even
excc
    FATAL_EXC	address_error
.address_error:
    dc.b    "ADDRESS ERROR AT ",0
    even
exc28
    FATAL_EXC	linea_error
    bra.b lockup
.linea_error:
    dc.b    "LINEA ERROR AT ",0
    even
exc2f
    FATAL_EXC	linef_error
    bra.b lockup
.linef_error:
    dc.b    "LINEF ERROR AT ",0
    even

exc10
    FATAL_EXC	illegal_error
    bra.b lockup
.illegal_error:
    dc.b    "ILLEGAL INSTR AT ",0
    even

lockup
	lea	screen_data,a1
	moveq.w	#3,d3
.cploop
	clr.l	D0
	clr.l	D1
	move.w	#38,d2
	bsr	clear_plane_any_blitter
	add.w	#SCREEN_PLANE_SIZE,a1
	dbf		d3,.cploop
	bsr	wait_blit
    move.l  (2,a7),d3
    move.w  #$FFF,d2
    clr.w   d0
    clr.w   d1
    bsr write_color_string

    lsl.w   #3,d0
    lea screen_data,a1
    move.l  d3,d2
    moveq.w #8,d3
    bsr write_hexadecimal_number    
.lockup
    bra.b   .lockup
	
finalize_sound
    bsr stop_sounds
    ; assuming VBR at 0
    sub.l   a0,a0
    lea _custom,a6
    jsr _mt_remove_cia
    move.w  #$F,dmacon(a6)   ; stop sound
    rts
    
restore_interrupts:
    ; assuming VBR at 0
    sub.l   a0,a0
    
    lea saved_vectors(pc),a1
    move.l  (a1)+,($8,a0)
    move.l  (a1)+,($c,a0)
    move.l  (a1)+,($10,a0)
    move.l  (a1)+,($68,a0)
    move.l  (a1)+,($6C,a0)


    lea _custom,a6

    move.w  saved_dmacon,d0
    bset    #15,d0
    move.w  d0,(dmacon,a6)
    move.w  saved_intena,d0
    bset    #15,d0
    move.w  d0,(intena,a6)


    rts
    
saved_vectors
        dc.l    0,0,0   ; some exceptions
        dc.l    0   ; keyboard
        dc.l    0   ; vblank
        dc.l    0   ; cia b
saved_dmacon
    dc.w    0
saved_intena
    dc.w    0

; what: level 2 interrupt (keyboard)
; args: none
; trashes: none
;
; cheat keys
; F1: skip level
; F2: toggle invincibility
; F3: toggle infinite lives
; F4: show debug info
; F5: re-draw background pic
; F6: draw hit zones
; left-ctrl: fast-forward (no player controls during that)
; when going away:
; * reverse: medium block (shuto-uke)
; * forward: high block (utchi-uke)
; * rev+fwd: low block (gedan-barai)
 
level2_interrupt:
	movem.l	D0/A0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
    
    lea keyboard_table(pc),a0
	
    bclr    #7,d0
    seq (a0,d0.w)       ; updates keyboard table
    bne.b   .no_playing     ; we don't care about key release
    ; cheat key activation sequence
    move.l  cheat_sequence_pointer(pc),a0
    cmp.b   (a0)+,d0
    bne.b   .reset_cheat
    move.l  a0,cheat_sequence_pointer
    tst.b   (a0)
    bne.b   .cheat_end
    move.w  #$0FF,_custom+color    
    st.b    cheat_keys
	; in case cheat is enabled after a legit hiscore
	clr.b	highscore_needs_saving
.reset_cheat
    move.l  #cheat_sequence,cheat_sequence_pointer
.cheat_end
    
    cmp.b   #$45,d0
    bne.b   .no_esc
    cmp.w   #STATE_INTRO_SCREEN,current_state
    beq.b   .no_esc
    cmp.w   #STATE_GAME_START_SCREEN,current_state
    beq.b   .no_esc
    move.l  #1,state_timer
    move.w  #STATE_GAME_OVER,current_state
.no_esc
    
    cmp.w   #STATE_PLAYING,current_state
    bne.b   .no_playing
    tst.b   demo_mode
    bne.b   .no_pause
    cmp.b   #$19,d0
    bne.b   .no_pause
	; in that game we need pause even if music
	; is playing, obviously
;    tst.b   music_playing
;    bne.b   .no_pause
    bsr	toggle_pause
.no_pause
    tst.w   cheat_keys
    beq.b   .no_playing
        
    cmp.b   #$50,d0
    seq.b   level_completed_flag

    cmp.b   #$51,d0
    bne.b   .no_invincible
    eor.b   #1,invincible_cheat_flag
    move.b  invincible_cheat_flag(pc),d0
    beq.b   .x
    move.w  #$F,d0
.x
    and.w   #$FF,d0
    or.w  #$0F0,d0
    move.w  d0,_custom+color
    bra.b   .no_playing
.no_invincible
    cmp.b   #$52,d0
    bne.b   .no_infinite_lives

    and.w   #$FF,d0
    or.w  #$0F0,d0
    move.w  d0,_custom+color
    bra.b   .no_playing
.no_infinite_lives
    cmp.b   #$53,d0     ; F4
    bne.b   .no_debug
    ; show/hide debug info
    eor.b   #1,debug_flag
    ; clear left part of white plane screen
    bsr     clear_debug_screen
    bra.b   .no_playing
.no_debug
    cmp.b   #$54,d0     ; F5
    bne.b   .no_redraw
   
	movem.l	d0-a6,-(a7)
    bsr     draw_background_pic
	bsr		draw_panel
	movem.l	(a7)+,d0-a6
    bra.b   .no_playing
.no_redraw
    cmp.b   #$55,d0     ; F5
    bne.b   .toggle_hit_zones
	eor.b   #1,draw_hit_zones_flag
    bra.b   .no_playing
.toggle_hit_zones
.no_playing

    cmp.b   _keyexit(pc),d0
    bne.b   .no_quit
    st.b    quit_flag
.no_quit

	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a0/a5
	move.w	#8,_custom+intreq
	rte
	
toggle_pause
	eor.b   #1,pause_flag
	beq.b	.out
	bsr		stop_sounds
	move.w	#1,start_music_countdown	; music will resume when unpaused
.out
	rts
	
    
; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

    
; what: level 3 interrupt (vblank/copper)
; args: none
; trashes: none
    
level3_interrupt:
    movem.l d0-a6,-(a7)
    lea  _custom,a5
    move.w  (intreqr,a5),d0
    btst    #5,d0
    bne.b   .vblank
    move.w  (intreqr,a5),d0
    btst    #4,d0
    beq.b   .blitter
    tst.b   demo_mode
    bne.b   .no_pause
    tst.b   pause_flag
    bne.b   .outcop
.no_pause
    ; copper
    bsr draw_all
    tst.b   debug_flag
    beq.b   .no_debug
    bsr draw_debug
.no_debug
    bsr update_all
    move.w  vbl_counter(pc),d0
    addq.w  #1,d0
    cmp.w   #5,d0
    bne.b   .normal
    ; update a second time, simulate 60Hz
    bsr update_all
    moveq.w #0,d0    
.normal
    move.w  d0,vbl_counter
	tst.w	cheat_keys
	beq.b	.outcop
	; check left CTRL
	move.b	$BFEC01,d0
	ror.b	#1,d0
	not.b	d0
	cmp.b	#$63,d0
	beq.b	.no_pause
.outcop
    move.w  #$0010,(intreq,a5) 
    movem.l (a7)+,d0-a6
    rte    
.vblank
	
    moveq.l #1,d0
    bsr _read_joystick
    
    btst    #JPB_BTN_PLAY,d0
    beq.b   .no_second
    move.l  player_1+joystick_state(pc),d2
    btst    #JPB_BTN_PLAY,d2
    bne.b   .no_second

    ; no pause if not in game
    cmp.w   #STATE_PLAYING,current_state
    bne.b   .no_second
    tst.b   demo_mode
    bne.b   .no_second
    
    bsr		toggle_pause
.no_second

    move.l  d0,player_1+joystick_state
	; player 2
	lea		player_2(pc),a4
	tst.b	is_cpu(a4)
	bne.b	.cpu
    moveq.l #0,d0
	
	tst.b	controller_joypad_0
	beq.b	.no_joy2
	
    bsr _read_joystick
    btst    #JPB_BTN_PLAY,d0
    beq.b   .store_p2_controls
    move.l  joystick_state(a4),d2
    btst    #JPB_BTN_PLAY,d2
    bne.b   .store_p2_controls

    ; no pause if not in game
    cmp.w   #STATE_PLAYING,current_state
    bne.b   .store_p2_controls
    tst.b   demo_mode
    bne.b   .store_p2_controls
    
    bsr		toggle_pause
	bra.b	.store_p2_controls
.no_joy2

	; keyboard for player 2
    lea keyboard_table(pc),a0
    tst.b   ($40,a0)    ; up key
    beq.b   .no_fire
    bset    #JPB_BTN_RED,d0
.no_fire 
    tst.b   ($4C,a0)    ; up key
    beq.b   .no_up
    bset    #JPB_BTN_AUP,d0
    bra.b   .no_down
.no_up    
    tst.b   ($4D,a0)    ; down key
    beq.b   .no_down
	; set DOWN
    bset    #JPB_BTN_ADOWN,d0
.no_down    
    tst.b   ($4F,a0)    ; left key
    beq.b   .no_left
	; set LEFT
    bset    #JPB_BTN_ALEFT,d0
    bra.b   .no_right   
.no_left
    tst.b   ($4E,a0)    ; right key
    beq.b   .no_right
	; set RIGHT
    bset    #JPB_BTN_ARIGHT,d0
.no_right    
    tst.b   ($3E,a0)    ; "8" key
    beq.b   .no_up_2
    bset    #JPB_BTN_UP,d0
    bra.b   .no_down_2
.no_up_2
    tst.b   ($1E,a0)    ; "2" key
    beq.b   .no_down_2
	; set DOWN
    bset    #JPB_BTN_DOWN,d0
.no_down_2
    tst.b   ($2D,a0)    ; "4" key
    beq.b   .no_left_2
	; set LEFT
    bset    #JPB_BTN_LEFT,d0
    bra.b   .no_right_2
.no_left_2
    tst.b   ($2F,a0)    ; "6" key
    beq.b   .no_right_2
	; set RIGHT
    bset    #JPB_BTN_RIGHT,d0
.no_right_2   
.store_p2_controls
    move.l  d0,joystick_state(a4)
	
.cpu
    move.w  #$0020,(intreq,a5)
    movem.l (a7)+,d0-a6
    rte
.blitter
    move.w  #$0040,(intreq,a5) 
    movem.l (a7)+,d0-a6
    rte

vbl_counter:
    dc.w    0


; what: updates game state
; args: none
; trashes: potentially all registers

update_all

    DEF_STATE_CASE_TABLE

.intro_screen
    bra update_intro_screen
    
    ; update_bonus_screen
.bonus_screen
	rts
   
    
    
.game_start_screen
    tst.l   state_timer
    bne.b   .out
    addq.l   #1,state_timer
.out

    rts
    
.life_lost
    rts

.bonus_level_completed
    bsr hide_sprites
    bsr     stop_sounds
.next_level
     move.w  #STATE_NEXT_LEVEL,current_state
     
     rts
     
.game_over
    cmp.l   #GAME_OVER_TIMER,state_timer
    bne.b   .no_first
    bsr stop_sounds
    moveq.l  #10,d0
    bsr     play_music
.no_first
    tst.l   state_timer
    bne.b   .cont
    bsr stop_sounds
    move.w  #STATE_INTRO_SCREEN,current_state
.cont
    subq.l  #1,state_timer
    rts
    ; update
.playing
	tst.l	state_timer
	bne.b	.no_first_tick
	; initialize some variables
	
.no_first_tick
	addq.l	#1,state_timer
    ; for demo mode
    addq.w  #1,record_input_clock

	move.w	level_type(pc),d0
	lea		update_level_type_table(pc),a0
	move.l	(a0,d0.w),a0
	jmp		(a0)
	
update_normal:
	; TODO start music timer on first round
	move.w	start_round_timer(pc),d0
	beq.b	.normal
	subq.w	#1,d0
	move.w	d0,start_round_timer
	beq.b	.go_normal
	; check if we must display "begin" bubble
	cmp.w	#START_ROUND_NB_TICKS-50,d0
	beq.b	.display_begin
	rts
.display_begin
	lea	referee(pc),a4
	move.w	#BUBBLE_BEGIN,bubble_type(a4)
	move.w	#NB_TICKS_PER_SEC,bubble_timer(a4)
	lea		begin_sound,a0
	bsr		play_fx
	rts
.go_normal
	; start round
	lea	referee(pc),a4
	move.w	#REFEREE_LEFT_LEG_DOWN,frame(a4)
.normal
	tst.w	time_left
	beq.b	.no_sec		; zero: no more timer update
	subq.w	#1,time_ticks
	bne.b	.no_sec
	move.w	#ORIGINAL_TICKS_PER_SEC,time_ticks
	st.b	score_update_message
	subq.w	#1,time_left
	bne.b	.no_sec
	; out of time
	lea	referee(pc),a4
	move.w	#REFEREE_LEGS_DOWN,frame(a4)
	move.w	#BUBBLE_STOP,bubble_type(a4)
	; both arms & flags
	move.b	#1,hand_red_or_japan_flag(a4)	; 0, 1 (red) or 3 (japan)
	move.b	#1,hand_white_flag(a4)
	move.w	#NB_TICKS_PER_SEC*2,bubble_timer(a4)
	lea		stop_sound,a0
	bsr		play_fx
	; block the controls (jump moves can finish or that would be silly)
	st.b	controls_blocked_flag
.no_sec
	bsr	update_referee
    lea     player_1(pc),a4
    bsr update_player
    lea     player_2(pc),a4
    bsr update_player
.wait
    rts
	
update_bull
	bsr		update_active_player
	rts
update_evade
	bsr		update_active_player
	rts
update_break
	rts
	
update_referee
	lea	referee(pc),a4
	; check bubble & timer
	tst.w	bubble_type(a4)
	beq.b	.no_bubble
	subq.w	#1,bubble_timer(a4)
	beq.b	referee_bubble_timeout
.out
	rts
.no_bubble
	tst.b	controls_blocked_flag
	bne.b	.out		; no left/right move when fight is stopped
	; move referee
	move.w	max_xpos(a4),d0
	cmp.w	min_xpos(a4),d0
	beq.b	.out		; min=max: no move
	move.w	walk_timer(a4),d0
	addq.w	#1,d0
	cmp.w	#NB_TICKS_PER_SEC/3,d0
	bne.b	.no_wto
	move.w	xpos(a4),d1
	; toggle legs
	move.w	frame(a4),d0
	neg.w	d0
	addq.w	#4,d0
	move.w	d0,frame(a4)
	
	move.w	#8,d0
	cmp.w	#RIGHT,direction(a4)
	beq.b	.wr
	; walk left
	cmp.w	min_xpos(a4),d1
	bcc.b	.not_min
	; min: turn back
	move.w	#RIGHT,direction(a4)
	neg.w	d0
.not_min
	sub.w	d0,d1
	move.w	d1,xpos(a4)
	bra.b	.wdone
.wr
	cmp.w	max_xpos(a4),d1
	bcs.b	.not_max
	; max: turn back
	move.w	#LEFT,direction(a4)
	neg.w	d0
.not_max
	add.w	d0,d1
	move.w	d1,xpos(a4)
.wdone
	clr.w	d0
.no_wto
	move.w	d0,walk_timer(a4)
	rts

; what: do something when referee bubble times out
; generally, either display another bubble, or change game state
; this makes the referee control most game events :)
; < A4: referee structure
referee_bubble_timeout
	move.w	bubble_type(a4),d0	; decide what to do
	cmp.w	#BUBBLE_STOP,d0
	bne.b	.no_stop
	move.w	#BUBBLE_JUDGE,bubble_type(a4)
	move.w	#NB_TICKS_PER_SEC,bubble_timer(a4)
	lea		judge_sound,a0
	bsr		play_fx
	rts
.no_stop
	cmp.w	#BUBBLE_VERY_GOOD,d0
	beq.b	.phase_over
	st.b	erase_referee_bubble_message
	clr.w	bubble_type(a4)
	rts
.phase_over
	; timeout on "very good": set a new flag
	st.b	level_completed_flag
	rts
	
update_practice
	move.l	current_score_display_timer(pc),d0
	beq.b	.no_score_hide
	subq.l	#1,d0
	move.l	d0,current_score_display_timer
	bne.b	.no_score_hide
	move.w	current_score_x(pc),d0
	move.w	current_score_y(pc),d1
	move.w	#4,d2
	move.w	#16,d3
	;bsr		restore_background
	; so display routine knows it's possible again
	; to display score next time
	clr.w	current_score_x
.no_score_hide
	bsr		update_referee
	move.l	state_timer(pc),d0
	cmp.l	#PRACTICE_SKIP_MESSAGE_LEN,d0
	bcs.b	.nothing
    lea     player_1(pc),a4
    bsr update_player
    lea     player_2(pc),a4
    bsr update_player
	rts
.nothing
    lea     player_1(pc),a4
	move.l	joystick_state(a4),d0
	; check if FIRE is pressed
	btst	#JPB_BTN_RED,D0
	beq.b	.no_skip
	move.w	#GM_NORMAL,level_type
	move.w	#STATE_NEXT_LEVEL,current_state
.no_skip
	rts
	
.intro_music_played
    dc.b    0
    even
start_music_countdown
    dc.w    0

; know which player is still alive after a fight phase
; at this point only one player is still playing

update_active_player
	lea	player_1(pc),a4
	tst.b	is_cpu(a4)
	beq.b	.upd
	lea	player_2(pc),a4
.upd
	bra	update_player
	
update_level_type_table
	dc.l	update_normal
	dc.l	update_practice
	dc.l	update_bull
	dc.l	update_break
	dc.l	update_evade


init_level_type_table
	dc.l	init_normal
	dc.l	init_practice
	dc.l	init_bull
	dc.l	init_break
	dc.l	init_evade

init_normal:
	; todo reset hits, maybe call init players
	move.w	#START_ROUND_NB_TICKS,start_round_timer

	rts
	
init_practice
	rts

init_bull
init_break	
init_evade	
	rts
	
CHARACTER_X_START = 88

update_intro_screen
    move.l   state_timer(pc),d0
    bne.b   .no_first
    
.first

.no_first 

  
    rts

    
play_loop_fx
    tst.b   demo_mode
    bne.b   .nosfx
    lea _custom,a6
    bra _mt_loopfx
.nosfx
    rts
 
; < A4 player structure
   
update_player
    move.w  player_killed_timer(pc),d6
    bmi.b   .alive
    moveq.w #8,d0
    cmp.w   #2*PLAYER_KILL_TIMER/3,d6
    bcs.b   .no_first_frame
    moveq.w #4,d0
    bra.b   .frame_done
.no_first_frame
    cmp.w   #PLAYER_KILL_TIMER/3,d6
    bcs.b   .no_second_frame
    moveq.w #0,d0
.no_second_frame

.frame_done    
    ;;move.w  d0,death_frame_offset   ; 0,4,8
    rts
.alive
	tst.b	controls_blocked_flag
	beq.b	.no_blocked
	moveq.l	#0,d0
	bra.b	.no_demo
.no_blocked
    tst.b	is_cpu(a4)
	beq.b	.human_player
	bsr		handle_ai
	bra.b	.no_demo
	
.human_player
    move.l  joystick_state(a4),d0
    IFD    RECORD_INPUT_TABLE_SIZE
    bsr     record_input
    ENDC
    tst.b   demo_mode
    beq.b   .no_demo
    ; if fire is pressed, end demo, goto start screen
    btst    #JPB_BTN_RED,d0
    beq.b   .no_demo_end
    clr.b   demo_mode
    move.w  #STATE_GAME_START_SCREEN,current_state
    rts
.no_demo_end
    clr.l   d0
    ; demo running
    ; read next timestamp
    move.l  record_data_pointer(pc),a0
    cmp.l   record_data_end(pc),a0
    bcc.b   .no_demo        ; no more input
    move.b  (a0),d2
    lsl.w   #8,d2
    move.b  (1,a0),d2
    ;;add.b   #3,d2   ; correction???
    cmp.w  record_input_clock(pc),d2
    bne.b   .repeat        ; don't do anything now
    ; new event
    move.b  (2,a0),d2
    addq.w  #3,a0
    move.l  a0,record_data_pointer
	move.b	d2,previous_move
	bra.b	.cont
.repeat
	move.b	previous_move(pc),d2
.cont
    btst    #LEFT>>2,d2
    beq.b   .no_auto_left
    bset    #JPB_BTN_LEFT,d0
    bra.b   .no_auto_right
.no_auto_left
    btst    #RIGHT>>2,d2
    beq.b   .no_auto_right
    bset    #JPB_BTN_RIGHT,d0
.no_auto_right
;    btst    #2,d2
;    beq.b   .no_auto_up
;    bset    #JPB_BTN_UP,d0
;    bra.b   .no_auto_down
;.no_auto_up
;    btst    #3,d2
;    beq.b   .no_auto_down
;    bset    #JPB_BTN_DOWN,d0
;.no_auto_down
;    btst    #FIRE,d2
;    beq.b   .no_auto_fire
;    bset    #JPB_BTN_RED,d0
;.no_auto_fire
    
    ; read live or recorded controls
.no_demo

	; if move is rewound or is a jump move after enough frames, controls aren't active
	; TODO
	
	move.b	move_controls(a4),d2		; previous value
	clr.w	d1

    tst.l   d0
    beq.b   .out1        ; nothing is currently pressed: optimize
	; attacks
	CONTROL_TEST	DOWN,DOWN,.out1
	CONTROL_TEST	UP,UP,.out1
	CONTROL_TEST	RIGHT,RIGHT,.out1
	CONTROL_TEST	LEFT,LEFT,.out1
.out1
	move.w	d1,d4
	clr.w	d3
	; compute transition table for moves => d3
	bsr		.get_controls_truth_table
	lsl.w	#2,d3
	
	move.b	attack_controls(a4),d2		; previous value
	clr.w	d1
    tst.l   d0
    beq.b   .out2        ; nothing is currently pressed: optimize
	CONTROL_TEST	ADOWN,DOWN,.out2
	CONTROL_TEST	AUP,UP,.out2
	CONTROL_TEST	ARIGHT,RIGHT,.out2
	CONTROL_TEST	ALEFT,LEFT,.out2
.out2
	move.w	d1,d7
	move.w	d1,d5
	lsl.b	#4,d7
	or.b	d4,d7	; combine for table offset

	bsr		.get_controls_truth_table
	
	; now d3 is a 0-16 value encoding the moves/attack transitions
	add.w	d3,d3
	add.w	d3,d3

	st.b	d6		; default: rollback unless d6 is cleared in the function
	lea		transition_table(pc),a0
	move.l	(a0,d3.w),a0
	; call transition function, which may clear d4, d5 or d6
	jsr		(a0)
	
	; update d4 and d5 if changed
	move.b	d4,move_controls(a4)
	move.b	d5,attack_controls(a4)
	; setting it can be ignored by animation if move got passed rollback max frame
	; (can_rollback flag is false after a few frames for jumps 
	; or when ground technique has completed for ground moves)
	tst.b	rollback_lock(a4)
	bne.b	.not_reached_blocking_move	; keep on playing animation
	move.b	d6,rollback(a4)
	beq.b	.perform
	; can we really rollback? or is it too late/not possible?
	tst.w	current_frame_countdown(a4)
	bpl.b	.not_reached_blocking_move
	st.b	rollback_lock(a4)		; prevent further rollbacks on that move
	clr.b	rollback(a4)		; cancel rollback, continue move
	move.w	#1,current_frame_countdown(a4)
.not_reached_blocking_move
	; rollback: use previous move if exists
	move.l	current_move_callback(a4),d0
	bne.b	.move_routine
.perform
	tst.w	d7
	beq.b	.out
;	cmp.b	#144,d1
;	bcc.b	.out		; not possible

	; select proper direction
	lea		moves_table(pc),a0
	move.w	previous_direction(a4),d0
	move.l	(a0,d0.w),a0
	
	; times 16
	lsl.w	#4,d7
	move.l	(a0,d7.w),d0
	tst.l	(4,a0,d7.w)		; is jump argument
	bne.b	.do_move		; jumping move is responsible for handing interruptions by other jumps
	; not a jumping move. Are we jumping ?
	tst.b	is_jumping(a4)
	bne.b	.skip		; can't interrupt a jumping move	
.do_move
	; play sound
;	tst.b	is_cpu(a4)
;	bne.b	.no_sound2
	tst.b	sound_playing(a4)
	bne.b	.no_sound2
	move.l	d0,-(a7)
	bsr	random
	and.w	#3,d0
	beq.b	.no_sound
	move.l	(8,a0,d7.w),d0
	beq.b	.no_sound
	move.l	d0,a0
	st.b	sound_playing(a4)
	bsr		play_fx
.no_sound	
	move.l	(a7)+,d0
.no_sound2	
	; store in case we have to rollback or when the controls are changed but move
	; is not over
	move.l	d0,current_move_callback(a4)
.move_routine
	move.l	d0,a0
	clr.l	current_move_name(a4)	; default: no move name
	
	; call move routine
	jsr		(a0)	
.skip
	; correct x afterwards
	move.w	xpos(a4),d0
	cmp.w	#X_MAX+1,d0
	bcs.b	.ok_max
	move.w	#X_MAX,xpos(a4)
	bra.b	.ok_min
.ok_max
	cmp.w	#X_MIN+1,d0
	bcc.b	.ok_min
	move.w	#X_MIN,xpos(a4)
.ok_min
.out
    rts

; < d1: current controls
; < d2: previous controls
; > d3: bit 0 set if current is != 0, bit 1 set if previous is != 0
.get_controls_truth_table
	tst.b	d1
	beq.b	.z1
	bset	#0,d3
.z1
	tst.b	d2
	beq.b	.z2
	bset	#1,d3
.z2
	rts

transition_table
	dc.l	trans_all_zero				; 00:0000
	dc.l	trans_new_simple_attack		; 01:0001
	dc.l	trans_attack_dropped		; 02:0010
	dc.l	trans_simple_attack_held	; 03:0011
	dc.l	trans_new_move				; 04:0100
	dc.l	trans_new_complex_attack	; 05:0101
	dc.l	trans_attack_dropped		; 06:0110
	dc.l	trans_simple_attack_held	; 07:0111
	dc.l	trans_move_dropped			; 08:1000
	dc.l	trans_new_simple_attack		; 09:1001
	dc.l	trans_attack_dropped		; 0A:1010: both attack and move stopped
	dc.l	trans_attack_dropped		; 0B:1011: same attack but move cancelled
	dc.l	trans_move_held				; 0C:1100
	dc.l	trans_new_complex_attack	; 0D:1101: move already set, now attack is set
	dc.l	trans_attack_dropped		; 0E:1110: move already set, now attack is dropped
	dc.l	trans_complex_attack_held	; 0F:1111
	
; in: d6 cleared
; in/out: d4 and d5
; out: d4 zeroed if moves nullified (because should have no effect during an attack)
;      d5 zeroed if complex move cancelled, so next time it's seen as simple technique
;      d6 set move/technique dropped, rollback, 0 if continues or starts new move

trans_all_zero:
	; nothing changed, everything is zero and was zero
	rts
trans_new_simple_attack
	; attack with only buttons (right joy)
	clr.b	d6	; cancel possible rollback
	rts
trans_new_complex_attack
	; attack with both joys (exactly at the same time or move already set)
	clr.b	d6	; cancel possible rollback
	rts
trans_attack_dropped
	clr.b	d4		; cancel parasite move if exists
	clr.b	d5
	; don't cancel possible rollback
	rts
trans_complex_attack_held
	clr.b	d6
	rts
	
trans_simple_attack_held
	clr.b	d4		; cancel parasite move if exists
	clr.b	d6		; cancels possible rollback
	rts
trans_move_held
trans_new_move
	; new move, no previous or current attack
	clr.b	d6
	rts
trans_move_dropped
	; don't cancel possible rollback

	rts
	
; what: shows score value above the player
; < D0: score index 1:100, ... 10:1000
; < A4: player structure
; trashes: D0
show_awarded_score:
	;tst.w	current_score_x
	;bne.b	.out
	movem.l	a0/d1-d3,-(a7)
	move.l	score_table(a4),a0
	add.w	d0,d0
	add.w	d0,d0
	move.l	(a0,d0.w),a0
	move.w	xpos(a4),d0
	add.w	#10,d0
	move.w	ypos(a4),d1
	sub.w	#20,d1

	;move.w	d0,current_score_x
	;move.w	d1,current_score_y
	bsr		store_sprite_pos
	move.l	d0,(a0)
	move.l	a0,d0
	move.l	score_sprite(a4),a0
	bsr		store_sprite_copperlist
	move.l	#200,current_score_display_timer
	movem.l	(a7)+,a0/d1-d3
.out
	rts
	
score_table_white
	dc.l	0
	dc.l	score_100_white
	dc.l	score_200_white
	dc.l	score_300_white
	dc.l	score_400_white
	dc.l	score_500_white
	dc.l	score_600_white
	dc.l	score_700_white
	dc.l	score_800_white
	dc.l	score_900_white
	dc.l	score_1000_white
	
score_table_red
	dc.l	0
	dc.l	score_100_red
	dc.l	score_200_red
	dc.l	score_300_red
	dc.l	score_400_red
	dc.l	score_500_red
	dc.l	score_600_red
	dc.l	score_700_red
	dc.l	score_800_red
	dc.l	score_900_red
	dc.l	score_1000_red
	
; what: animate & move player according to animation table & player direction
; < a0: current frame set (right/left)
; < a4: player structure

move_player:
	move.l	a0,animation_struct(a4)
	; update animation loop flag if required
	move.w	(8,a0),d0
	move.b	d0,animation_loops(a4)

	move.w	direction(a4),d0
	move.l	(a0,d0.w),a0	; proper frame list according to direction

	move.l	frame_set(a4),a1
	; is frame set different from last time?
	cmp.l	a0,a1
	beq.b	.no_frame_set_change
	; change frame set
	move.l	a0,frame_set(a4)
	; re-set hit height so next hit is active again
	move.l	animation_struct(a4),a1
	move.w	hit_height(a1),current_hit_height(a4)
	
	move.l	a0,a1	; a0 transferred in a1 (not really useful apparently..)
	; reset all counters
	clr.w	current_frame_countdown(a4)
	; don't reset current frame if connecting move
	tst.b	skip_frame_reset(a4)
	bne.b	.no_frame_set_change
	clr.w	frame(a4)
.no_frame_set_change
	clr.b	skip_frame_reset(a4)
	move.w	current_frame_countdown(a4),d3
	bmi.b	.no_change		; negative: wait for player move change
	beq.b	.change
	subq.w	#1,d3
	bra.b	.no_change
.change
	; countdown at zero
	; advance/next frame / move
	move.w	frame(a4),d0
	tst.b	rollback(a4)
	beq.b	.forward
	; backwards (rollbacking)
	tst		d0
	beq.b	.animation_ended
	sub.w	#PlayerFrame_SIZEOF,d0		; frame long+2 words of x/y/nbframes
	bra.b	.fup
.forward
	add.w	#PlayerFrame_SIZEOF,d0		; frame long+2 words of x/y/nbframes
	; load frame type
	
	tst.l	(bob_data,a1,d0.w)
	bne.b	.fup
	tst.b	animation_loops(a4)
	beq.b	.animation_ended
	clr.w	d0		; starts over again (looping animations, basically walks)
.fup
	move.w	d0,frame(a4)
	; a1 holds frame structure

	add.w	d0,a1
	tst.b	rollback(a4)
	bne.b	.revert_deltas

	
	move.w	(delta_x,a1),d2	
	beq.b	.nox
	add.w	d2,xpos(a4)
.nox
	move.w	(delta_y,a1),d2
	beq.b	.noy
	add.w	d2,ypos(a4)
.noy
	move.l	(hit_data,a1),a0		; hit list
	; check if there are some hit points
	bsr		check_hit

	; convert "can_rollback" to lock
	tst.w	(can_rollback,a1)
	seq		rollback_lock(a4)

	; but cancel rollback lock if infinite time
	; (hit frame, but on ground)
	move.w	(staying_frames,a1),d3	; load frame countdown
	bpl.b	.no_change
	clr.b	rollback_lock(a4)
.no_change
	move.w	d3,current_frame_countdown(a4)
	rts

.revert_deltas
	move.w	(delta_x,a1),d2	
	beq.b	.nox2
	add.w	d2,xpos(a4)
.nox2
	move.w	(delta_y,a1),d2
	beq.b	.noy
	sub.w	d2,ypos(a4)
	bra.b	.noy
	
; todo be able to change that default frame when player is hit
; death anim + fall down
; animation complete, back to walk/default
.animation_ended
	tst.b	turn_back_flag(a4)
	beq.b	.no_turn_back
	; set turn back as soon as rollback lock
	clr.b	turn_back_flag(a4)
	bsr		turn_back

.no_turn_back
	lea		walk_forward_frames,a0
	bra		load_walk_frame


; < A0: X,Y hit list
; < A4: player struct   
check_hit
	tst.w	(a0)
	bmi.b	.no_hit	; optim if no hit points
	move.w	current_hit_height(a4),d0
	cmp.w	#HEIGHT_NONE,d0
	beq.b	.no_hit
	; first frame of the hit frame of the technique
	; there's some heavy processing to be done here
	; apart from the A.I. this is the most crucial part
	; of the code (in 2 player game, A.I. isn't active, this
	; code is active.
	movem.l	d1-d6/a0-a5,-(a7)
	
	; first, clear collision matrix
	
	move.l	#(COLLISION_NB_COLS*COLLISION_NB_ROWS)/8-1,d0
	lea		collision_matrix,a1
	move.l	a1,a0
.clr
	clr.l	(a1)+
	clr.l	(a1)+
	dbf		d0,.clr
	
	move.w	level_type(pc),d0
	lea		fill_opponent_routine_table(pc),a1
	move.l	(a1,d0.w),a1
	jsr		(a1)

	; now check this zone with hit points
	bsr		check_collisions
	
	IFD	DEBUG_COLLISIONS
	; debug it: save it here: S matrix ra0 !160*!55
	lea		collision_matrix,a0
	blitz	; so we can dump the matrix
	ENDC
	
	tst.l	d0
	beq.b	.no_collision
	lea		blow_sound,a0
	bsr		play_fx
.no_collision
	movem.l	(a7)+,d1-d6/a0-a5
	; only works when the hit arrives, not afterwards
	; (if player is stuck with kick, opponent can't
	; recieve a blow)
	move.w	#HEIGHT_NONE,current_hit_height(a4)

.no_hit
	rts

fill_opponent_routine_table:
	dc.l	fill_opponent_normal
	dc.l	fill_opponent_practice
	dc.l	fill_opponent_bull
	dc.l	fill_opponent_break
	dc.l	fill_opponent_evade

fill_opponent_evade
fill_opponent_break
fill_opponent_bull
	rts

; there aren't any opponent, just take advantage of that
; specific call just when the blow lands so we can compare
; the technique with the shown technique
fill_opponent_practice
	tst.b	is_cpu(a4)		; only human
	bne.b	.not_same
	; compare current technique to the dictated one, score points
	; if it's the same (doesn't work)
	move.l	joystick_state(a4),d0
	; special cases down+down is also foot sweep (front)
	cmp.l	#JPF_BTN_ADOWN|JPF_BTN_DOWN,d0
	bne.b	.no_down_down
	move.l	#JPF_BTN_ADOWN|JPF_BTN_RIGHT,d0
	cmp.w	#RIGHT,direction(a4)
	beq.b	.no_down_down
	move.l	#JPF_BTN_ADOWN|JPF_BTN_LEFT,d0
.no_down_down
	move.l	current_move_key_last_jump(pc),d1
	bne.b	.test_last
	move.l	current_move_key(pc),d1
.test_last
	cmp.l	d0,d1
	bne.b	.not_same
	; same move: award points
	move.l	#200,d0
	bsr		add_to_score
	moveq.l	#2,d0
	bsr		show_awarded_score
.not_same
	rts

check_collisions:
	move.l	frame_set(a4),a1
	add.w	frame(a4),a1
	move.l	(hit_data,a1),a2
	tst.w	(a2)
	bmi.b	.done	; optim: no hit data
	move.w	xpos(a4),d3
	move.w	ypos(a4),d4
	sub.w	level_players_y_min(pc),d4	; can't be negative

	; if facing left, we have to perform a symmetry
	cmp.w	#RIGHT,direction(a4)
	sne		d5
	beq.b	.do_check
	; facing left
	move.w	bob_nb_bytes_per_row(a1),d6
	sub.w	#6,d6	; minus 48 to center character
	lsl.w	#3,d6	; times 8
	add.w	d6,d3
	; can't seem to make it right
	; not going to spend hours on that symmetry issue
	; which depends on the original size: manual fix
	move.l	animation_struct(a4),a5
	add.w	(hit_left_shift,a5),d3
.do_check:
	lea		mulCOLLISION_NB_COLS_table(pc),a5
.do_check_loop:
	move.w	(a2)+,d0
	bmi.b	.done
	move.w	(a2)+,d1
	tst.b	d5
	beq.b	.pos
	neg.w	d0
.pos
	add.w	d3,d0
	add.w	d4,d1
	; divide
	lsr.w	#1,d0
	bclr	#0,d1	; avoids to shift right then left
	lea		collision_matrix,a0
	add.w	(a5,d1.w),a0
	add.w	d0,a0
	IFD	DEBUG_COLLISIONS
	move.b	#2,(a0)		; debug: mark map
	ELSE
	tst.b	(a0)
	bne.b	.blow_landed
	ENDC
	bra.b	.do_check_loop
.done
	moveq.l	#0,d0
	rts	
.blow_landed
	moveq.l	#1,d0
	rts
	
; < A0: collision matrix
; < A4: player structure

fill_opponent_normal
	move.l	opponent(a4),a5
	
	move.w	ypos(a5),d1
	sub.w	level_players_y_min(pc),d1	; can't be negative
	; sanity check
	bpl.b	.ok
	illegal
.ok
	cmp.w	#(COLLISION_NB_ROWS*2)-48,d1
	bcs.b	.ok2
	illegal
.ok2
	lsr.w	#1,d1
	move.w	xpos(a5),d0
	lsr.w	#1,d0
	; divided coordinates of opponent
	; now plot the opponent in the matrix
	
	move.l	frame_set(a5),a1
	add.w	frame(a5),a1
	; draw mask if defence in mask
	move.l	(target_data,a1),a2
	move.w	bob_height(a1),d6
	lsr.w	#1,d6
	subq.w	#1,d6
	; compute start of source
	lea		mulCOLLISION_NB_COLS_table(pc),a3
	move.w	d1,d4
	add.w	d4,d4
	add.w	(a3,d4.w),a0	; add y*COLLISION_NB_COLS
	move.l	a0,a3		; save a0 in a3: start of row
.yloop
	move.w	bob_width(a1),d7
	lsr.w	#1,d7
	move.w	d7,d5		; store half bob width
	subq.w	#1,d7
	cmp.w	#RIGHT,direction(a5)
	bne.b	.case_left
	add.w	d0,a0	; add X
.xloop
	move.b	(a2)+,(a0)+
	dbf		d7,.xloop
.xloop_end
	lea     (COLLISION_NB_COLS,a3),a3
	move.l	a3,a0	; next target row
	dbf		d6,.yloop
	rts
.case_left
	move.w	bob_nb_bytes_per_row(a1),d3
	sub.w	#6,d3	; minus 48 to center character
	beq.b	.zap	; optim
	lsl.w	#2,d3	; times 4 (not 8)
	sub.w	d3,d0	; subtract if facing left
.zap
	; the symmetry is easier to perform with a matrix
	; of dots instead of an offset list like the hit
	; xy list above
	add.w	d0,a0		; add X
.xloop_left
	move.b	(a2,d7.w),(a0)+
	dbf		d7,.xloop_left
	add.w	d5,a2			; next source row
	bra.b	.xloop_end
	
erase_referee:
	lea	referee(pc),a4
	move.w	previous_xpos(a4),d0
	beq.b	.out		; 0: not possible: first draw
	move.w	ypos(a4),d1
	move.w	#32,d2	; width (no shifting)
	move.w	#48,d3	; height
	bra.b		restore_background

.out
	rts
	
; < A4: player struct   
erase_player:
	
	; compute dest address
	
	move.w	previous_ypos(a4),d3
	beq.b	.out		; 0: not possible: first draw
	move.w	previous_xpos(a4),d2
	
	move.l	d2,d0
	move.l	d3,d1
	move.w	#80,d2	; width (no shifting)
	move.w	#48,d3	; height
	bra.b		restore_background
.out
	rts
	
; < D0: X (rounded to be a multiple of 16)
; < D1: Y
; < D2: width
; < D3: height
restore_background:
	lea		screen_data,a1
	and.w	#$F0,d0		; round & multiple of 16
	lsr.w	#3,d2	; pixels => bytes
	move.l	d1,-(a7)
	move.l	d0,-(a7)
	ADD_XY_TO_A1_40		a0
	; compute source address
	move.l	(a7)+,d0
	move.l	(a7)+,d1
	move.l	a1,-(a7)
	
	lea		backbuffer,a1
	ADD_XY_TO_A1_28		a0
	move.l	a1,a0
	move.l	(a7)+,a1
	
    lea _custom,A5
	
	; restore background
	
	REPT	3
    movem.l d2-d6,-(a7)
    bsr blit_back_plane
    movem.l (a7)+,d2-d6
	
	add.w	#BACKBUFFER_PLANE_SIZE,a0
	add.w	#SCREEN_PLANE_SIZE,a1
	ENDR
    movem.l d2-d6,-(a7)
    bsr blit_back_plane
    movem.l (a7)+,d2-d6
	
.out
    rts	
.not_first_draw
	rts
	
; < A5: custom
; < A0: source
; < A1: plane pointer
; < D2: width in bytes
; < D3: blit height
; trashes D0-D6

blit_back_plane:

    move.l  #$09f00000,d5    ;A->D copy, ascending mode, no shift

	move.w #NB_BYTES_PER_LINE,d0
    sub.w   d2,d0       ; blit width

	move.w #NB_BYTES_PER_BACKBUFFER_LINE,d1
    sub.w   d2,d1       ; blit width

    lsl.w   #6,d3
    lsr.w   #1,d2
    add.w   d2,d3       ; blit height

	moveq.l	#-1,d4
	
	
    ; now just wait for blitter ready to write all registers
	bsr	wait_blit
    
    ; blitter registers set
    move.l  d4,bltafwm(a5)
	move.l d5,bltcon0(a5)	
	move.w  d1,bltamod(a5)		;A modulo=bytes to skip between lines
    move.w  d0,bltdmod(a5)	;D modulo
	move.l a0,bltapt(a5)	;source graphic top left corner
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d3,bltsize(a5)	;rectangle size, starts blit
    rts

; < A4: referee structure
draw_referee
	lea	referee(pc),a4
	
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	move.w	d0,previous_xpos(a4)
	move.w	#4,d2
	move.w	#16,d3
	lea	referee_head,a0
	bsr	blit_4_planes_cookie_cut
	add.w	d3,d1
	move.w	#8,d3
	move.w	hand_red_or_japan_flag(a4),d5	; test both flags
	move.w	#$0101,d4
	and.w	d4,d5
	bne.b	.no_normal_body
	lea	referee_body_1,a0
	cmp.w	d4,d5
	beq.b	.both_arms_up
	lea	referee_body_0,a0
.both_arms_up
	bsr	blit_4_planes_cookie_cut
.no_normal_body
	add.w	d3,d1
	move.w	#16,d3
	lea	referee_leg_table(pc),a0
	move.w	frame(a4),d4
	move.l	(a0,d4.w),a0
	bsr	blit_4_planes_cookie_cut
	
	move.b	hand_red_or_japan_flag(a4),d6
	beq.b	.no_red_flag
	sub.w	#8,d1
	cmp.w	#$101,d5
	beq.b	.skip_arm_1
	lea		referee_right_arm_down,a0
	bsr	blit_4_planes_cookie_cut
.skip_arm_1
	lea		red_fan_arm,a0
	cmp.b	#1,d6
	beq.b	.rf
	lea		japan_fan_arm,a0
.rf
	move.w	#16,d3
	add.w	d3,d0
	sub.w	#12,d1
	bsr		blit_4_planes_cookie_cut
	
.no_red_flag

	move.b	hand_white_flag(a4),d6
	beq.b	.no_white_flag

	cmp.w	#$101,d5
	beq.b	.skip_arm_2
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	add.w	#16,d1
	lea		referee_left_arm_down,a0
	bsr	blit_4_planes_cookie_cut
.skip_arm_2
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	lea		white_fan_arm,a0
	move.w	#16,d3
	sub.w	d3,d0
	add.w	#4,d1
	bsr		blit_4_planes_cookie_cut
.no_white_flag	
	tst.b	erase_referee_bubble_message
	bne.b	.erase_bubble
	; handle bubbles
	move.w	bubble_type(a4),d0
	beq.b	.no_bubble
	lea		bubble_table(pc),a0
	move.l	(a0,d0.w),a0
	jsr	(a0)
.no_bubble

	rts

.erase_bubble
	clr.b	erase_referee_bubble_message
	bsr		erase_bubble
	rts
	
; < A4: player structure
draw_player:
    lea _custom,A5
	
	move.l	frame_set(a4),a0
	add.w	frame(a4),a0

	move.w	bob_plane_size(a0),d5
	move.w	bob_nb_bytes_per_row(a0),d2
	move.l	bob_data(a0),a0
	lea		screen_data,a1
	move.l	a1,a2
	move.l	a0,a3
	add.w	d5,a3
	add.w	d5,a3	; mask data
	
	; plane 1: clothes data as white
	move.w	xpos(a4),D0
	cmp.w	#RIGHT,direction(a4)
	beq.b	.no_offset
	move.w	d2,d3
	sub.w	#6,d3	; minus 48 to center character
	lsl.w	#3,d3	; times 8
	sub.w	d3,d0	; subtract if facing left
.no_offset

	move.w	ypos(a4),D1
	move.w	d0,previous_xpos(a4)
	move.w	d1,previous_ypos(a4)
	moveq.l #-1,d3	;masking of first/last word    
    move.w  #48,d4      ; 48 pixels height  

    bsr blit_plane_any_internal_cookie_cut

	add.w	d5,a0		; next source plane
	add.w	#SCREEN_PLANE_SIZE,a2
	move.l	a2,a1
    bsr blit_plane_any_internal_cookie_cut

	lea		empty_48x48_bob,a0
	add.w	#SCREEN_PLANE_SIZE,a2
	move.l	a2,a1
	
    bsr blit_plane_any_internal_cookie_cut

	add.w	#SCREEN_PLANE_SIZE,a2
	move.l	a2,a1

	tst.b	character_id(a4)
	beq.b	.white
	
	; red: another layer of clothes plane that activate color 9
	; (color 9 is fixed as red)
	move.l	a3,a0
	sub.w	d5,a0
	sub.w	d5,a0
	
.white:
	
    bsr blit_plane_any_internal_cookie_cut
	
	tst.b	draw_hit_zones_flag
	beq.b	.out
	bsr		wait_blit
	; debug only: draw hit/vulnerable/invisible zones

	move.l	frame_set(a4),a0
	add.w	frame(a4),a0
	move.l	(hit_data,a0),a1
	tst.w	(a1)
	bmi.b	.done	; optim: no hit data
	move.w	xpos(a4),d3
	move.w	ypos(a4),d4
	move.w	#$F00,d2
	; if facing left, we have to perform a symmetry
	cmp.w	#RIGHT,direction(a4)
	sne		d5
	beq.b	.hit_draw
	; facing left
	move.w	bob_nb_bytes_per_row(a0),d3
	sub.w	#6,d3	; minus 48 to center character
	lsl.w	#3,d3	; times 8
	add.w	xpos(a4),d3
	; can't seem to make it right
	; not going to spend hours on that symmetry issue
	; which depends on the original size: manual fix
	move.l	animation_struct(a4),a2
	add.w	(hit_left_shift,a2),d3
.hit_draw:
	move.w	(a1)+,d0
	bmi.b	.done
	move.w	(a1)+,d1
	tst.b	d5
	beq.b	.pos
	neg.w	d0
.pos
	add.w	d3,d0
	add.w	d4,d1
	bsr		write_2x2_box
	bra.b	.hit_draw
.done
	; draw mask if defence in mask
	move.l	(target_data,a0),a1
	move.w	bob_height(a0),d6
	lsr.w	#1,d6
	subq.w	#1,d6
	move.w	ypos(a4),d1
.yloop
	move.w	bob_width(a0),d7
	lsr.w	#1,d7
	move.w	d7,d5		; store (optimization for left side)
	subq.w	#1,d7
	move.w	xpos(a4),d0	; X
	cmp.w	#RIGHT,direction(a4)
	bne.b	.case_left	
.xloop
	tst.b	(a1)+
	beq.b	.no_block
	move.w	#$FFF,d2
	bsr		write_2x2_box
.no_block
	addq	#2,d0
	dbf		d7,.xloop
	addq	#2,d1
	dbf		d6,.yloop
	rts
.case_left
	move.w	bob_nb_bytes_per_row(a0),d3
	sub.w	#6,d3	; minus 48 to center character
	lsl.w	#3,d3	; times 8
	sub.w	d3,d0	; subtract if facing left
	; the symmetry is easier to perform with a matrix
	; of dots instead of an offset list like the hit
	; xy list above
.xloop_left
	tst.b	(a1,d7.w)
	beq.b	.no_block_left
	move.w	#$FFF,d2
	bsr		write_2x2_box
.no_block_left
	addq	#2,d0
	dbf		d7,.xloop_left
	add.w	d5,a1
	addq	#2,d1
	dbf		d6,.yloop
.out
	rts
	
handle_ai
	moveq.l	#0,d0
	cmp.w	#GM_PRACTICE,level_type
	bne.b	.normal
	move.l	a4,-(a7)
	; practice
	bsr		update_practice_moves
	move.l	(a7)+,a4
	rts
	
.normal
	rts

update_practice_moves
	tst.l	current_practice_move_timer
	beq.b	.not_performing_move
	subq.l	#1,current_practice_move_timer
	bne.b	.not_zero
	; erase message
	st		current_move_key_message
	clr.l	current_move_key
	rts
.not_zero
	; training is over
	tst.b	level_completed_flag
	beq.b	.out
	;move.w	#GM_BULL,level_type	; ends at demo
	
	move.w	#GM_NORMAL,level_type
	move.w	#STATE_NEXT_LEVEL,current_state
	clr.l	state_timer
	bra.b	.out
.not_performing_move
	subq.l	#1,next_practice_move_timer
	beq.b	.next_move
.out
	move.l	current_move_key(pc),d0
	rts
.next_move
	move.l	#PRACTICE_WAIT_BEFORE_NEXT_MOVE,next_practice_move_timer
	move.l	#PRACTICE_MOVE_DURATION,d0
	move.l	d0,current_practice_move_timer
	move.l	picked_practice_table(pc),a0
	move.w	practice_move_index(pc),d0
	tst.l	(4,a0,d0.w)
	bne.b	.no_last_move
	lea	referee(pc),a1
	move.b	#3,hand_red_or_japan_flag(a1)	; 0, 1 (red) or 3 (japan)
	move.w	#BUBBLE_VERY_GOOD,bubble_type(a1)
	move.w	#2*NB_TICKS_PER_SEC,bubble_timer(a1)	; 2 seconds?	
.no_last_move
	move.l	(a0,d0.w),d0
	beq.b	.no_more_moves
	move.l	d0,current_move_key		; to direct A.I.
	move.b	#1,current_move_key_message	; display move message

	cmp.l	#JPF_BTN_UP|JPF_BTN_ALEFT,d0	; jumping side kick, ends some sequences
	bne.b	.no_jsk
	; longer wait after last move
	move.l	d0,current_move_key_last_jump	; to compare to player moves
	move.l	#PRACTICE_WAIT_BEFORE_NEXT_MOVE*2,next_practice_move_timer
	; shorter move type else A.I. would do the jumping kick twice
	move.l	#PRACTICE_MOVE_DURATION/2,current_practice_move_timer
.no_jsk
	addq.w	#4,practice_move_index
.no_more_moves
	; signal message system to display move name
	rts
	
; < d0.w: x
; < d1.w: y
; > d0.L: control word
store_sprite_pos
    movem.l  d1/a0/a1,-(a7)

    lea	HW_SpriteXTable(pc),a0
    lea	HW_SpriteYTable(pc),a1

    add.w	d0,d0
    add.w	d0,d0
    move.l	(a0,d0.w),d0
    add.w	d1,d1
    add.w	d1,d1
    or.l	(a1,d1.w),d0
    movem.l  (a7)+,d1/a0/a1
    rts

    
; what: blits 16x16 data on one plane
; args:
; < A0: data (16x16)
; < A1: plane
; < D0: X
; < D1: Y
; < D2: blit mask
; trashes: D0-D1
; returns: A1 as start of destination (A1 = orig A1+40*D1+D0/8)

blit_plane
    movem.l d2-d6/a2-a5,-(a7)
    lea $DFF000,A5
	move.l d2,d3
    move.w  #4,d2       ; 16 pixels + 2 shift bytes
    move.w  #16,d4      ; 16 pixels height
    bsr blit_plane_any_internal
    movem.l (a7)+,d2-d6/a2-a5
    rts
    
; what: blits 16x16 data on one plane, cookie cut
; args:
; < A0: data (16x16)
; < A1: plane  (40 rows)
; < A2: background (40 rows) to mix with cookie cut
; < A3: source mask for cookie cut (16x16)
; < D0: X
; < D1: Y
; < D2: blit mask
; trashes: D0-D1
; returns: A1 as start of destination (A1 = orig A1+40*D1+D0/16)

blit_plane_cookie_cut
    movem.l d2-d7/a2-a5,-(a7)
    lea _custom,A5
	move.l d2,d3	;masking of first/last word    
    move.w  #4,d2       ; 16 pixels + 2 shift bytes
    move.w  #16,d4      ; 16 pixels height   
    bsr blit_plane_any_internal_cookie_cut
    movem.l (a7)+,d2-d7/a2-a5
    rts
    
    
; what: blits (any width)x(any height) data on one plane
; args:
; < A0: data (width x height)
; < A1: plane
; < D0: X
; < D1: Y
; < D2: blit width in bytes (+2)
; < D3: blit mask
; < D4: blit height
; trashes: D0-D1, A1
;
; if A1 is already computed with X/Y offset and no shifting, an optimization
; skips the XY offset computation

blit_plane_any:
    movem.l d2-d6/a2-a5,-(a7)
    lea $DFF000,A5
    bsr blit_plane_any_internal
    movem.l (a7)+,d2-d6/a2-a5
    rts

; < A5: custom
; < D0,D1: x,y
; < A0: source
; < A1: plane pointer
; < D2: width in bytes (inc. 2 extra for shifting)
; < D3: blit mask
; < D4: blit height
; trashes D0-D6
; > A1: even address where blit was done
blit_plane_any_internal:
    ; pre-compute the maximum of shit here
    lea mul40_table(pc),a2
    swap    d1
    clr.w   d1
    swap    d1
    add.w   d1,d1
    beq.b   .d1_zero    ; optim
    move.w  (a2,d1.w),d1
.d1_zero
    move.l  #$09f00000,d5    ;A->D copy, ascending mode
    move    d0,d6
    beq.b   .d0_zero
    and.w   #$F,d6
    and.w   #$1F0,d0
    lsr.w   #3,d0
    add.w   d0,d1

    swap    d6
    clr.w   d6
    lsl.l   #8,d6
    lsl.l   #4,d6
    or.l    d6,d5            ; add shift
.d0_zero    
    add.l   d1,a1       ; plane position (always even)

	move.w #NB_BYTES_PER_LINE,d0
    sub.w   d2,d0       ; blit width

    lsl.w   #6,d4
    lsr.w   #1,d2
    add.w   d2,d4       ; blit height


    ; now just wait for blitter ready to write all registers
	bsr	wait_blit
    
    ; blitter registers set
    move.l  d3,bltafwm(a5)
	move.l d5,bltcon0(a5)	
	clr.w bltamod(a5)		;A modulo=bytes to skip between lines
    move.w  d0,bltdmod(a5)	;D modulo
	move.l a0,bltapt(a5)	;source graphic top left corner
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
    rts


; quoting mcgeezer:
; "You have to feed the blitter with a mask of your sprite through channel A,
; you feed your actual bob bitmap through channel B,
; and you feed your pristine background through channel C."

; < A5: custom
; < D0.W,D1.W: x,y
; < A0: source
; < A1: destination
; < A2: background to mix with cookie cut
; < A3: source mask for cookie cut
; < D2: width in bytes (inc. 2 extra for shifting)
; < D3: blit mask
; < D4: height
; blit mask set
; returns: start of destination in A1 (computed from old A1+X,Y)
; trashes: a1

blit_plane_any_internal_cookie_cut:
    movem.l d0-d6/a2/a4,-(a7)
    ; pre-compute the maximum of shit here
    lea mul40_table(pc),a4
    swap    d1
    clr.w   d1
    swap    d1
    add.w   d1,d1
    beq.b   .d1_zero    ; optim
    move.w  (a4,d1.w),d1	; y times 40
	add.w	d1,a2			; Y plane position for background
.d1_zero
    move.l  #$0fca0000,d5    ;B+C-A->D cookie cut   

    move    d0,d6
    beq.b   .d0_zero
    and.w   #$1F0,d0
    lsr.w   #3,d0
    and.w   #$F,d6
	beq.b	.no_shifting

    lsl.l   #8,d6
    lsl.l   #4,d6
    or.w    d6,d5            ; add shift to mask (bplcon1)
    swap    d6
    clr.w   d6
    or.l    d6,d5            ; add shift
.no_shifting    
    move.w  d0,d6
    add.w   d0,d1
    
.d0_zero
    ; make offset even. Blitter will ignore odd address
    ; but a 68000 CPU doesn't and since we RETURN A1...
    bclr    #0,d1
    add.l   d1,a1       ; plane position (long: allow unsigned D1)

    add.w   d6,a2       ; X offset for background

	move.w #NB_BYTES_PER_LINE,d0

    sub.w   d2,d0       ; blit width

    lsl.w   #6,d4
    lsr.w   #1,d2
    add.w   d2,d4       ; blit height

    ; always the same settings (ATM)

    ; now just wait for blitter ready to write all registers
	bsr	wait_blit
    
    ; blitter registers set

    move.l  d3,bltafwm(a5)
	clr.w bltamod(a5)		;A modulo=bytes to skip between lines
	clr.w bltbmod(a5)		;A modulo=bytes to skip between lines
	move.l d5,bltcon0(a5)	; sets con0 and con1

    move.w  d0,bltcmod(a5)	;C modulo (maze width != screen width but we made it match)
    move.w  d0,bltdmod(a5)	;D modulo

	move.l a3,bltapt(a5)	;source graphic top left corner (mask)
	move.l a0,bltbpt(a5)	;source graphic top left corner
	move.l a2,bltcpt(a5)	;pristine background
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
    
    movem.l (a7)+,d0-d6/a2/a4
    rts


; what: blits data on 4 planes (no cookie cut)
; shifted, full mask, W/H generic
; args:
; < A0: data (16x16)
; < D0: X
; < D1: Y
; < D2: width in bytes (pls include 2 bytes for shifting)
; < D3: height
; trashes: none

blit_4_planes:
    movem.l d0-d6/a0-a1/a5,-(a7)
    lea $DFF000,A5
    lea     screen_data,a1
    moveq.l #3,d7
    move.w	d3,d4      ; height
    moveq.l #-1,d3  ; mask
	move.w	d4,d5
	mulu.w	d2,d5	; plane size
.loop
    movem.l d0-d5/a1,-(a7)
    bsr blit_plane_any_internal
    movem.l (a7)+,d0-d5/a1
    add.w   #SCREEN_PLANE_SIZE,a1
    add.w   D5,a0
    dbf d7,.loop
    movem.l (a7)+,d0-d6/a0-a1/a5
    rts
; what: blits data on 4 planes (cookie cut)
; shifted, full mask, W/H generic
; args:
; < A0: data
; < D0: X
; < D1: Y
; < D2: width in bytes (pls include 2 bytes for shifting)
; < D3: height
; trashes: nothing

blit_4_planes_cookie_cut
    movem.l d0-d6/a0-a3/a5,-(a7)
    lea $DFF000,A5
    lea     screen_data,a1
    moveq.l #3,d7
    move.w	d3,d4      ; height
    moveq.l #-1,d3  ; mask
	move.w	d4,d5
	mulu.w	d2,d5	; plane size
	move.l	a0,a3
	add.w	d5,a3
	add.w	d5,a3
	add.w	d5,a3
	add.w	d5,a3
.loop
    movem.l d0-d5/a1,-(a7)
	move.l	a1,a2
    bsr blit_plane_any_internal_cookie_cut
    movem.l (a7)+,d0-d5/a1
    add.w   #SCREEN_PLANE_SIZE,a1
    add.w   D5,a0
    dbf d7,.loop
    movem.l (a7)+,d0-d6/a0-a3/a5
    rts

wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts

; what: writes an hexadecimal number (or BCD) in a single plane
; args:
; < A1: plane
; < D0: X (multiple of 8)
; < D1: Y
; < D2: number value
; < D3: number of padding zeroes
; > D0: number of characters written

write_hexadecimal_number

    movem.l A0/D2-d5,-(a7)
    cmp.w   #7,d3
    bcs.b   .padok
    move.w  #7,d3
.padok
    bsr     .write_num
    movem.l (a7)+,A0/D2-d5
    rts
.write_num
    lea .buf+8(pc),a0

    
.loop
    subq    #1,d3    
    move.b  d2,d5
    and.b   #$F,d5
    cmp.b   #10,d5
    bcc.b   .letter
    add.b   #'0',d5
    bra.b   .ok
.letter
    add.b   #'A'-10,d5
.ok
    move.b  d5,-(a0)
    lsr.l   #4,d2
    beq.b   .write
    bra.b   .loop
.write
    tst.b   d3
    beq.b   .w
    bmi.b   .w
    subq    #1,d3
.pad
    move.b  #' ',-(a0)
    dbf d3,.pad
.w
    bra write_string
.buf
    ds.b    8
    dc.b    0
    even
    
; what: writes an decimal number in a single plane
; args:
; < A1: plane
; < D0: X (multiple of 8)
; < D1: Y
; < D2: number value
; < D3: number of padding zeroes
; > D0: number of characters written
    
write_decimal_number
    movem.l A0/D2-d5,-(a7)
    cmp.w   #18,d3
    bcs.b   .padok
    move.w  #18,d3
.padok
    cmp.l   #655361,d2
    bcs.b   .one
    sub.l   #4,d3
    move.w  d0,d5
    ; first write high part    
    divu    #10000,d2
    swap    d2
    moveq.l #0,d4
    move.w   d2,d4
    clr.w   d2
    swap    d2
    bsr     .write_num
    lsl.w   #3,d0
    add.w   d5,d0   ; new xpos
    
    move.l  d4,d2
    moveq   #4,d3   ; pad to 4
.one
    bsr     .write_num
    movem.l (a7)+,A0/D2-d5
    rts
.write_num
    bsr convert_number
    bra write_string
    
write_color_decimal_number
    movem.l A0-A1/D2-d6,-(a7)
    lea     write_color_string(pc),a1
    bsr.b     write_color_decimal_number_internal
    movem.l (a7)+,A0-A1/D2-d6
    rts
write_blanked_color_decimal_number
    movem.l A0-A1/D2-d6,-(a7)
    lea     write_blanked_color_string(pc),a1
    bsr.b     write_color_decimal_number_internal
    movem.l (a7)+,A0-A1/D2-d6
    rts
; what: writes an decimal number with a given color
; args:
; < D0: X (multiple of 8)
; < D1: Y
; < D2: number value
; < D3: number of padding zeroes
; < D4: RGB4 color
; > D0: number of characters written
    
write_color_decimal_number_internal
    cmp.w   #18,d3
    bcs.b   .padok
    move.w  #18,d3
.padok
    cmp.l   #655361,d2
    bcs.b   .one
    sub.l   #4,d3
    move.w  d0,d5
    ; first write high part    
    divu    #10000,d2
    swap    d2
    moveq.l #0,d6
    move.w   d2,d6
    clr.w   d2
    swap    d2
    bsr     .write_num
    lsl.w   #3,d0
    add.w   d5,d0   ; new xpos
    
    move.l  d6,d2
    moveq   #4,d3   ; pad to 4
.one
    bsr     .write_num
    rts
.write_num
    bsr convert_number
    move.w  d4,d2
    jmp     (a1) 
    
    
; < D2: value
; > A0: buffer on converted number
convert_number
    lea .buf+20(pc),a0
    tst.w   d2
    beq.b   .zero
.loop
    divu    #10,d2
    swap    d2
    add.b   #'0',d2
    subq    #1,d3
    move.b  d2,-(a0)
    clr.w   d2
    swap    d2
    tst.w   d2
    beq.b   .write
    bra.b   .loop
.zero
    subq    #1,d3
    move.b  #'0',-(a0)
.write
    tst.b   d3
    beq.b   .w
    bmi.b   .w
    subq    #1,d3
.pad
    move.b  #' ',-(a0)
    dbf d3,.pad
.w
    rts
    
.buf
    ds.b    20
    dc.b    0
    even
    

; what: writes a text in a given color, clears
; non-written planes (just in case another color was
; written earlier) so background is color 0 (black)
; args:
; < A0: c string
; < D0: X (multiple of 8)
; < D1: Y
; < D2: RGB4 color (must be in palette!)
; > D0: number of characters written
; trashes: none

write_blanked_color_string:
    movem.l D1-D6/A1,-(a7)
    ; compute string length first in D6
    clr.w   d6
.strlen
    tst.b   (a0,d6.w)
    beq.b   .outstrlen
    addq.w  #1,d6
    bra.b   .strlen
.outstrlen
	bsr		color_lookup
	bpl.b	.color_found
    moveq   #0,d0   ; nothing written
    bra.b   .out
.color_found
    ; d5: color index
    lea screen_data,a1
    moveq   #3,d3
    move.w  d0,d4
.plane_loop
; < A0: c string
; < A1: plane
; < D0: X (multiple of 8)
; < D1: Y
; > D0: number of characters written
    move.w  d4,d0
    btst    #0,d5
    beq.b   .clear_plane
    bsr overwrite_string
    bra.b   .next_plane
.clear_plane
    movem.l d0-d6/a1/a5,-(a7)
    move.w  d6,d2   ; width in bytes = string length
    ;lea _custom,a5
    ;moveq.l #-1,d3
    move.w  #8,d3

    bsr clear_plane_any_cpu_any_height
    movem.l (a7)+,d0-d6/a1/a5
.next_plane
    lsr.w   #1,d5
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf d3,.plane_loop
.out
    movem.l (a7)+,D1-D6/A1
    rts

; utility method for write_pixel/string
; trashes D3-D5
; > D5: palette index, negative if not found
; > N set if not found

color_lookup
	moveq.l	#0,d5
    lea game_palette(pc),a1
    moveq   #15,d3
.search
    move.w  (a1)+,d4
    cmp.w   d4,d2
    beq.b   .color_found
    addq.w  #1,d5
    dbf d3,.search
	moveq	#-1,d5
    rts
.color_found
	tst		d5	; probably useless, N is not set
	rts

; what: writes a pixel in a given color
; (note: this is very inefficient, debug purposes only)
; args:
; < D0: X
; < D1: Y
; < D2: RGB4 color (must be in palette!)
; trashes: none
	
write_2x2_box:
    movem.l D0-D5/A1-A2,-(a7)    
	bsr		color_lookup
	bmi.b	.out	
    lea	screen_data,a1
	move.w	d5,d4
	; save d0 3 first bits in d2
	move.b	d0,d2
    ADD_XY_TO_A1_40    a2
	move.l	a1,a2
	and.b	#7,d2
	neg.b	d2
	addq	#7,d2
    moveq   #3,d3
.plane_loop
    btst    #0,d5
    beq.b   .clr
	bset.b	d2,(a1)
	bset.b	d2,(NB_BYTES_PER_LINE,a1)
	bra.b	.next
.clr
	bclr.b	d2,(a1)
	bclr.b	d2,(NB_BYTES_PER_LINE,a1)
.next
    lsr.w   #1,d5
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf d3,.plane_loop
	move.l	a2,a1	; restore a1
	; second row
    moveq   #3,d3
	move.w	d4,d5
	tst.b	d2
	bne.b	.same_byte
	move.w	#7,d2
	addq.w	#1,a1
	bra.b	.plane_loop2
.same_byte
	subq.l	#1,d2
.plane_loop2
    btst    #0,d5
    beq.b   .clr2
	bset.b	d2,(a1)
	bset.b	d2,(NB_BYTES_PER_LINE,a1)
	bra.b	.next2
.clr2
	bclr.b	d2,(a1)
	bclr.b	d2,(NB_BYTES_PER_LINE,a1)
.next2
    lsr.w   #1,d5
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf d3,.plane_loop2
.out
    movem.l (a7)+,D0-D5/A1-A2
    rts
	
; what: writes a pixel in a given color
; (note: this is very inefficient, debug purposes only)
; args:
; < D0: X
; < D1: Y
; < D2: RGB4 color (must be in palette!)
; trashes: none

write_pixel:
    movem.l D0-D5/A1-A2,-(a7)    
	bsr		color_lookup
	bmi.b	.out	
    lea	screen_data,a1
	; save d0 3 first bits in d2
	move.b	d0,d2
    ADD_XY_TO_A1_40    a2
	and.b	#7,d2
	neg.b	d2
	addq	#7,d2
.noshift
    moveq   #3,d3
.plane_loop
    btst    #0,d5
    beq.b   .clr
	bset.b	d2,(a1)
	bra.b	.next
.clr
	bclr.b	d2,(a1)
.next
    lsr.w   #1,d5
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf d3,.plane_loop	
.out
    movem.l (a7)+,D0-D5/A1-A2
    rts

	
; what: writes a text in a given color
; args:
; < A0: c string
; < D0: X (multiple of 8)
; < D1: Y
; < D2: RGB4 color (must be in palette!)
; > D0: number of characters written
; trashes: none

write_color_string:
    movem.l D1-D5/A1,-(a7)
	bsr.b		color_lookup
	bmi.b	.out	
    ; d5: color index
    lea screen_data,a1
    moveq   #3,d3
    move.w  d0,d4
	tst.w	d5
	beq.b	.erase_loop
.plane_loop
    btst    #0,d5
    beq.b   .skip_plane
    move.w  d4,d0
    bsr write_string
.skip_plane
    lsr.w   #1,d5
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf d3,.plane_loop
.out
    movem.l (a7)+,D1-D5/A1
    rts
	
.erase_loop
; < A0: c string
; < A1: plane
; < D0: X (multiple of 8)
; < D1: Y
; > D0: number of characters written
    move.w  d4,d0
    bsr carve_string

    lsr.w   #1,d5
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf d3,.erase_loop
    bra.b	.out
; what: writes a text in a single plane
; args:
; < A0: c string
; < A1: plane
; < D0: X (multiple of 8 else it's rounded)
; < D1: Y
; > D0: number of characters written
; trashes: none

write_string
	move.l	d3,-(a7)
	moveq.l	#1,d3
	bsr		write_string_internal
	move.l	(a7)+,d3
	rts
overwrite_string
	move.l	d3,-(a7)
	moveq.l	#2,d3
	bsr		write_string_internal
	move.l	(a7)+,d3
	rts
carve_string
	move.l	d3,-(a7)
	moveq.l	#0,d3
	bsr		write_string_internal
	move.l	(a7)+,d3
	rts
	
write_string_internal:
    movem.l A0-A2/d1-D2/d4,-(a7)
    clr.w   d2
    ADD_XY_TO_A1_40    a2
    moveq.l #0,d0
.loop
    move.b  (a0)+,d2
    beq.b   .end
    addq.l  #1,d0

    cmp.b   #'0',d2
    bcs.b   .special
    cmp.b   #'9'+1,d2
    bcc.b   .try_letters
    ; digits
    lea digits(pc),a2
    sub.b   #'0',d2
    bra.b   .wl
    
.try_letters: 
    cmp.b   #'A',d2
    bcs.b   .special
    cmp.b   #'Z'+1,d2
    bcc.b   .special
    lea letters(pc),a2
    sub.b   #'A',d2
.wl
    lsl.w   #3,d2   ; *8
    add.w   d2,a2
	tst.w	d3
	beq.b	.carve
	cmp.w	#1,d3
	beq.b	.orit
	; overwrite
	REPT	8
	move.b	(a2)+,(NB_BYTES_PER_LINE*REPTN,a1)
	ENDR
    bra.b   .next
	
.orit
	REPT	8
	move.b	(a2)+,d4
    or.b  d4,(NB_BYTES_PER_LINE*REPTN,a1)
	ENDR
    bra.b   .next
.carve
	REPT	8
	move.b	(a2)+,d4
    eor.b  d4,(NB_BYTES_PER_LINE*REPTN,a1)
	ENDR
    bra.b   .next

.special
    cmp.b   #' ',d2
    bne.b   .nospace
    lea space(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.nospace    
    cmp.b   #'o',d2
    bne.b   .noellipse
    lea ellipse(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.noellipse
    cmp.b   #'-',d2
    bne.b   .nodash
    lea dash(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.nodash
    cmp.b   #'.',d2
    bne.b   .nodot
    lea dot(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.nodot
    cmp.b   #'/',d2
    bne.b   .nosq
    lea square(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.nosq
    cmp.b   #'h',d2
    bne.b   .noheart
    lea heart(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.noheart
    cmp.b   #'c',d2
    bne.b   .nocopy
    lea copyright(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.nocopy



.next   
    addq.l  #1,a1
    bra.b   .loop
.end
    movem.l (a7)+,A0-A2/d1-D2/d4
    rts

	IFD		HIGHSCORES_TEST
load_highscores
save_highscores
	rts
	ELSE
    
load_highscores
    lea scores_name(pc),a0
    move.l  _resload(pc),d0
    beq.b   .standard
    move.l  d0,a2
    jsr (resload_GetFileSize,a2)
    tst.l   d0
    beq.b   .no_file
    ; file is present, read it
    lea scores_name(pc),a0    
    lea hiscore_table(pc),a1
    move.l #40,d0   ; size
    moveq.l #0,d1   ; offset
    jsr  (resload_LoadFileOffset,a2)
    bra.b	.update_highest
.standard
    move.l  _dosbase(pc),a6
    move.l  a0,d1
    move.l  #MODE_OLDFILE,d2
    jsr     (_LVOOpen,a6)
    move.l  d0,d1
    beq.b   .no_file
    move.l  d1,d4
    move.l  #4,d3
    move.l  #hiscore_table,d2
    jsr (_LVORead,a6)
    move.l  d4,d1
    jsr (_LVOClose,a6)
.update_highest
	move.l	hiscore_table(pc),high_score
.no_file
    rts
    

; < D0: command to send to cdtv 
send_cdtv_command:
	tst.l	_resload
	beq.b	.go
	rts		; not needed within whdload (and will fail)
.go
	movem.l	d0-a6,-(a7)
    move.l  d0,d5
    
	; alloc some mem for IORequest

	MOVEQ	#40,D0			
	MOVE.L	#MEMF_CLEAR|MEMF_PUBLIC,D1
	move.l	$4.W,A6
	jsr	_LVOAllocMem(a6)
	move.l	D0,io_request
	beq	.Quit

	; open cdtv.device

	MOVEA.L	D0,A1
	LEA	cdtvname(PC),A0	; name
	MOVEQ	#0,D0			; unit 0
	MOVE.L	D0,D1			; flags
	jsr	_LVOOpenDevice(a6)
	move.l	D0,D6
	ext	D6
	ext.l	D6
	bne	.Quit		; unable to open

    ; wait a while if CMD_STOP
    cmp.l   #CMD_STOP,d5
    bne.b   .nowait
	move.l	_dosbase(pc),A6
	move.l	#20,D1
	JSR	_LVODelay(a6)		; wait 2/5 second before launching
.nowait
	; prepare the IORequest structure

	MOVEQ	#0,D0
	MOVEA.L	io_request(pc),A0
	MOVE.B	D0,8(A0)
	MOVE.B	D0,9(A0)
	SUBA.L	A1,A1
	MOVE.L	A1,10(A0)
	MOVE.L	A1,14(A0)
	CLR.L	36(A0)

	move.l	io_request(pc),A0

	move.l	A0,A1
	move.w	d5,(IO_COMMAND,a1)
	move.l	$4.W,A6
	JSR		_LVODoIO(a6)

.Quit:
	; close cdtv.device if open

	tst.l	D6
	bne	.Free
	MOVE.L	io_request(pc),D1
	beq	.End
	move.l	D1,A1
	move.l	$4.W,A6
	jsr	_LVOCloseDevice(a6)

.Free:		
	; free the memory

	MOVEQ	#40,D0
	move.l	io_request(pc),A1
	move.l	$4.W,A6
	JSR		_LVOFreeMem(a6)
.End:
	movem.l	(a7)+,d0-a6
	rts
	
save_highscores
    tst.w   cheat_keys
    bne.b   .out
    tst.b   highscore_needs_saving
    beq.b   .out
    lea scores_name(pc),a0
    move.l  _resload(pc),d0
    beq.b   .standard
    move.l  d0,a2
    lea scores_name(pc),a0    
    lea hiscore_table(pc),a1
    move.l #4*NB_HIGH_SCORES,d0   ; size
    jmp  (resload_SaveFile,a2)
.standard
    move.l  _dosbase(pc),a6
    move.l  a0,d1
    move.l  #MODE_NEWFILE,d2
    jsr     (_LVOOpen,a6)
    move.l  d0,d1
    beq.b   .out
    move.l  d1,d4
    move.l  #40,d3
    move.l  #hiscore_table,d2
    jsr (_LVOWrite,a6)
    move.l  d4,d1
    jsr (_LVOClose,a6)    
.out
    rts
    ENDC
    

	MUL_TABLE	COLLISION_NB_COLS
	
    MUL_TABLE   40
    MUL_TABLE   28


	STRUCTURE	Sound,0
    ; matches ptplayer
    APTR    ss_data
    UWORD   ss_len
    UWORD   ss_per
    UWORD   ss_vol
    UBYTE   ss_channel
    UBYTE   ss_pri
    LABEL   Sound_SIZEOF
    
; < D0: track start number
play_music
	tst.b	demo_mode
	bne.b	.out
    movem.l d0-a6,-(a7)
    lea _custom,a6
    lea music,a0
    sub.l   a1,a1
    bsr _mt_init
    ; set master volume a little less loud
    ; supposed to be max at 64 but actually 20 is already
    ; super loud...
    move.w  #12,d0
    bsr _mt_mastervol
    
    bsr _mt_start
    st.b    music_playing
    movem.l (a7)+,d0-a6
.out
    rts
    
; < A0: sound struct
play_fx
    tst.b   demo_mode
    bne.b   .no_sound
    lea _custom,a6
    bra _mt_playfx
.no_sound
    rts
   


get_player_distance
	cmp.w	#GM_NORMAL,level_type
	beq.b	.compute
	move.w	#-1,d0	; huge distance
	rts
.compute
	move.w	player+xpos(pc),d0
	sub.w	player+Player_SIZEOF+xpos(pc),d0
	bpl.b	.pos
	neg.w	d0
.pos
	rts
	
MOVE_CALLBACK:MACRO
do_\1:
	lea	\1_frames(pc),a0
	ENDM
	
BLOCK_CALLBACK:MACRO
	; no block cancel
	MOVE_CALLBACK	\1
	bra.b	move_player
	ENDM
SIMPLE_MOVE_CALLBACK:MACRO
	clr.w	block_lock(a4)		; no block
	MOVE_CALLBACK	\1
	bra.b	move_player
	ENDM
	
; each "do_xxx" function has the following input params
; < A4: player structure

	
	BLOCK_CALLBACK	low_block
	BLOCK_CALLBACK	medium_block
	BLOCK_CALLBACK	high_block
	SIMPLE_MOVE_CALLBACK	low_kick
	SIMPLE_MOVE_CALLBACK	crouch
		
	SIMPLE_MOVE_CALLBACK	jumping_side_kick
	SIMPLE_MOVE_CALLBACK	round_kick
	SIMPLE_MOVE_CALLBACK	back_kick
	SIMPLE_MOVE_CALLBACK	lunge_punch_400
	SIMPLE_MOVE_CALLBACK	lunge_punch_600
	SIMPLE_MOVE_CALLBACK	lunge_punch_1000
	SIMPLE_MOVE_CALLBACK	sommersault
	SIMPLE_MOVE_CALLBACK	sommersault_back

do_reverse_punch_800
	lea	reverse_punch_800_frames(pc),a0
	bra.b	do_foot_sweep_common

do_foot_sweep_back
	lea	foot_sweep_back_frames(pc),a0
	bra.b	do_foot_sweep_common
	
do_foot_sweep_front
	lea	foot_sweep_front_frames(pc),a0
do_foot_sweep_common
	clr.w	block_lock(a4)		; no block
	; are we crouching?
	lea		crouch_frames(pc),a1
	cmp.l	animation_struct(a4),a1
	bne.b	move_player
	; connect from crouch to move
	move.w	#PlayerFrame_SIZEOF*3,frame(a4)
	st.b	skip_frame_reset(a4)
	bra.b	move_player
	
do_jumping_back_kick:
	clr.w	block_lock(a4)		; no block
	lea	jumping_back_kick_frames(pc),a0
	move.l	animation_struct(a4),a1
	cmp.l	a0,a1
	bne.b	move_player
	; already jumping back kick, check if last frame
	; in which case reverse position when landing
	tst.b	rollback_lock(a4)
	beq.b	.no_turn_back
	st.b	turn_back_flag(a4)
.no_turn_back
	bra.b	move_player
	
do_front_kick:
	clr.w	block_lock(a4)		; no block
	; check the distance to the other player
	; if too close, then switch to weak reverse punch
	;
	; also, if reverse punch already running, don't switch
	; to front kick (the opposite is also true)
	bsr	get_player_distance
	move.l	animation_struct(a4),a1
	cmp.w	#MIN_FRONT_KICK_DISTANCE,d0
	bcc.b	.kick
	lea	front_kick_frames(pc),a2
	cmp.l	a2,a1
	beq.b	.force_kick	; already kick, keep kick
.force_punch
	lea	weak_reverse_punch_frames(pc),a0
	bra.b	move_player
.kick
	lea	weak_reverse_punch_frames(pc),a2
	cmp.l	a2,a1
	beq.b	.force_punch
.force_kick
	lea	front_kick_frames(pc),a0
	bra.b	move_player

	
do_back_round_kick_right:
	clr.w	block_lock(a4)		; no block
	move.w	direction(a4),d0
	cmp.w	#RIGHT,d0
	beq.b	.no_turn
	move.w	#RIGHT,direction(a4)	
.no_turn
	lea	back_round_kick_frames(pc),a0
	bra.b	move_player

do_jump:
	clr.w	block_lock(a4)		; no block
	lea	jump_frames(pc),a0
	
	bra.b	move_player
	
do_back_round_kick_left:
	clr.w	block_lock(a4)		; no block
	move.w	direction(a4),d0
	cmp.w	#LEFT,d0
	beq.b	.no_turn
	move.w	#LEFT,direction(a4)
.no_turn
	lea	back_round_kick_frames(pc),a0
	bra.b	move_player


do_move_forward:
	clr.w	block_lock(a4)		; no block
	lea		walk_forward_frames(pc),a0
	clr.b	rollback(a4)
	clr.b	rollback_lock(a4)
	clr.l	current_move_callback(a4)
	bsr		get_player_distance
	cmp.w	#GUARD_X_DISTANCE,d0		; approx...
	bcc.b	move_player
	lea		forward_frames(pc),a0
	bra.b	move_player

do_move_back:
	tst.b	is_cpu(a4)
	bne.b	normal_backing_away	; CPU chooses if must block
	move.w	block_lock(a4),d1
	bne.b	.locked
	bsr		check_if_facing_each_other
	tst.l	d0
	beq.b	normal_backing_away	; no block if not facing

	move.l	opponent(a4),a0
	; if opponent is attacking, convert to block instead
	move.w	current_hit_height(a0),block_lock(a4)
.locked	
	lea	block_table(pc),a0
	move.l	(a0,d1.w),a0
	jmp	(a0)
	

normal_backing_away
	lea		walk_backwards_frames(pc),a0
	clr.b	rollback(a4)
	clr.b	rollback_lock(a4)
	clr.l	current_move_callback(a4)
	bsr		get_player_distance
	cmp.w	#GUARD_X_DISTANCE,d0		; approx...
	bcc.b	move_player
	lea		backwards_frames(pc),a0

	bra.b	move_player

turn_back
	move.w	direction(a4),d0
	neg.w	d0
	add.w	#LEFT,d0
	move.w	d0,direction(a4)	
.no_turn
	rts

; < A4: player structure (any player)
; > D0: 0 if not facing, 1 if facing

check_if_facing_each_other:
	movem.l	d1/A0,-(a7)
	cmp.w	#GM_NORMAL,level_type
	bne.b	.not_facing		; not applicable in practice

	
	move.l	opponent(a4),a0
	move.w	direction(a4),d0
	cmp.w	direction(a0),d0
	beq.b	.not_facing
	; opposite direction, now we have to test xpos
	move.w	xpos(a4),d1
	cmp.w	xpos(a0),d1
	bcc.b	.other_is_on_the_left
	; other is on the right
	cmp.w	#RIGHT,d0
	bne.b	.facing
	bra.b	.not_facing
.other_is_on_the_left
	cmp.w	#RIGHT,d0
	beq.b	.not_facing
.facing
	moveq.l	#1,d0
	movem.l	(a7)+,D1/A0
	rts
.not_facing
	moveq.l	#0,d0
	movem.l	(a7)+,D1/A0
	rts
	
_dosbase
    dc.l    0
_gfxbase
    dc.l    0
_resload
    dc.l    0
io_request:
	dc.l	0
_keyexit
    dc.b    $59
scores_name
    dc.b    "kchampvs.high",0
highscore_needs_saving
    dc.b    0
cdtvname:
	dc.b	"cdtv.device",0
graphicsname:   dc.b "graphics.library",0
dosname
        dc.b    "dos.library",0
            even

    include ReadJoyPad.s
    include	RNC_1C.s
	
    ; variables
gfxbase_copperlist
    dc.l    0
    
previous_random
    dc.l    0
record_data_pointer
    dc.l    0
record_data_end
	dc.l	0
record_input_clock
    dc.w    0
previous_move
	dc.b	0
	even
    IFD    RECORD_INPUT_TABLE_SIZE
prev_record_joystick_state
    dc.l    0

    ENDC

  
current_state:
    dc.w    0



; general purpose timer for non-game states (intro, game over...)
state_timer:
    dc.l    0
intro_text_message:
    dc.w    0
previous_player_address
    dc.l    0
previous_valid_direction
    dc.l    0

start_round_timer
	dc.w	0
	
; 0: practice
level_number:
    dc.w    0
level_type:
	dc.w	0
loaded_level:
	dc.w	-1
demo_level_number:
    dc.w    0
enemy_kill_timer
    dc.w    0
player_killed_timer:
    dc.w    -1
bonus_score_timer:
    dc.w    0
cheat_sequence_pointer
    dc.l    cheat_sequence

cheat_keys
    dc.w    0


level_completed_flag:
	dc.b	0
controls_blocked_flag:
	dc.b	0
erase_referee_bubble_message:
    dc.b    0
score_update_message:
	dc.b	0
current_move_key_message:
	dc.b	0

music_playing:    
    dc.b    0
pause_flag
    dc.b    0
quit_flag
    dc.b    0

invincible_cheat_flag
    dc.b    0
debug_flag
    dc.b    0
demo_mode
    dc.b    0
draw_hit_zones_flag
	dc.b	0
music_played
    dc.b    0


cheat_sequence
    dc.b    $26,$18,$14,$22,0	; "JOTD" in raw keycodes
    even


digits:
    incbin  "digits_0.bin"
    incbin  "digits_1.bin"
    incbin  "digits_2.bin"
    incbin  "digits_3.bin"
    incbin  "digits_4.bin"
    incbin  "digits_5.bin"
    incbin  "digits_6.bin"
    incbin  "digits_7.bin"
    incbin  "digits_8.bin"
    incbin  "digits_9.bin"
letters
    incbin	"letters_1_0.bin"
    incbin	"letters_1_1.bin"
    incbin	"letters_1_2.bin"
    incbin	"letters_1_3.bin"
    incbin	"letters_1_4.bin"
    incbin	"letters_1_5.bin"
    incbin	"letters_1_6.bin"
    incbin	"letters_1_7.bin"
    incbin	"letters_1_8.bin"
    incbin	"letters_1_9.bin"
    incbin	"letters_1_10.bin"
    incbin	"letters_1_11.bin"
    incbin	"letters_1_12.bin"
    incbin	"letters_1_13.bin"
    incbin	"letters_1_14.bin"
    incbin	"letters_1_15.bin"
    incbin	"letters_1_16.bin"
    incbin	"letters_1_17.bin"
    incbin	"letters_1_18.bin"
    incbin	"letters_1_19.bin"
    incbin	"letters_1_20.bin"
    incbin	"letters_1_21.bin"
    incbin	"letters_2_0.bin"
    incbin	"letters_2_1.bin"
    incbin	"letters_2_2.bin"
    incbin	"letters_2_3.bin"
    

dash:
    incbin  "dash.bin"
dot:
    incbin  "dot.bin"
ellipse:
	incbin	"ellipse.bin"
square:
    REPT	8
	dc.b	$FF
	ENDR

heart:
    incbin  "heart.bin"
copyright:
    incbin  "copyright.bin"
space:
    ds.b    8,0
    
hiscore_string
	dc.b	"HISCORE",0
zero_string
	dc.b	"0",0
p1_string
    dc.b    "     1UP",0
level_string
    dc.b    "   LEVEL",0
score_string
    dc.b    "       00",0
game_over_string
    dc.b    "GAME##OVER",0
player_one_string
    dc.b    "PLAYER ONE",0
player_one_string_clear
    dc.b    "          ",0
    even
; game main tables


practice_tables:
	dc.l	practice_table_1
	dc.l	practice_table_2
	dc.l	practice_table_3
	dc.l	practice_table_2
	dc.l	practice_table_1
	dc.l	practice_table_2
	dc.l	practice_table_3
	dc.l	practice_table_1
	
	IFND	REPEAT_PRACTICE
REPEAT_PRACTICE = 1
	ENDC
	
practice_table_1:
	REPT	REPEAT_PRACTICE
	dc.l	JPF_BTN_AUP|JPF_BTN_RIGHT	; lunge punch
	IFD		SHORT_PRACTICE
	dc.l	0
	ENDC
	dc.l	JPF_BTN_ARIGHT	; front kick	
	dc.l	JPF_BTN_ALEFT	; back kick
	dc.l	JPF_BTN_ADOWN	; low kick
	dc.l	JPF_BTN_AUP|JPF_BTN_LEFT	; lunge punch
	dc.l	JPF_BTN_UP|JPF_BTN_ALEFT	; jumping back kick
	dc.l	JPF_BTN_DOWN|JPF_BTN_ALEFT	; foot sweep (back)
	dc.l	JPF_BTN_AUP					; round kick
	ENDR
	dc.l	0
practice_table_2	
	REPT	REPEAT_PRACTICE
	dc.l	JPF_BTN_AUP	; round kick
	IFD		SHORT_PRACTICE
	dc.l	0
	ENDC
	dc.l	JPF_BTN_ADOWN	; low kick
	dc.l	JPF_BTN_AUP|JPF_BTN_LEFT	; lunge punch (high, still)
	dc.l	JPF_BTN_LEFT|JPF_BTN_ARIGHT	; back round kick
	dc.l	JPF_BTN_ARIGHT	; front kick
	dc.l	JPF_BTN_DOWN|JPF_BTN_ALEFT	; foot sweep (back)
	dc.l	JPF_BTN_ALEFT	; back kick
	dc.l	JPF_BTN_AUP|JPF_BTN_RIGHT	; lunge punch (high, forward)
	ENDR
	dc.l	0
practice_table_3
	REPT	REPEAT_PRACTICE
	dc.l	JPF_BTN_ARIGHT	; front kick
	IFD		SHORT_PRACTICE
	dc.l	0
	ENDC
	dc.l	JPF_BTN_AUP	; round kick
	dc.l	JPF_BTN_DOWN|JPF_BTN_ALEFT	; foot sweep (back)
	dc.l	JPF_BTN_ADOWN	; low kick
	dc.l	JPF_BTN_ALEFT	; back kick
	dc.l	JPF_BTN_DOWN|JPF_BTN_AUP	; reverse punch
	dc.l	JPF_BTN_AUP|JPF_BTN_LEFT	; lunge punch (high, still)
	dc.l	JPF_BTN_UP|JPF_BTN_ALEFT	; jumping back kick
	ENDR
	dc.l	0
    
HW_SpriteXTable
  rept 320
x   set REPTN+$80
    dc.b  0, x>>1, 0, x&1
  endr


HW_SpriteYTable
  rept 260
ys  set REPTN+$2c
ye  set ys+16       ; size = 16
    dc.b  ys&255, 0, ye&255, ((ys>>6)&%100) | ((ye>>7)&%10)
  endr

	
bubble_table
	; those are used by the referee
	dc.l	draw_no_bubble
	dc.l	draw_very_good_bubble
	dc.l	draw_white_bubble
	dc.l	draw_red_bubble
	dc.l	draw_stop_bubble
	dc.l	draw_judge_bubble
	dc.l	draw_begin_bubble
	; those are used by the girls
	dc.l	draw_better_luck_bubble
	dc.l	draw_my_hero_bubble


referee_leg_table
	dc.l	referee_left_leg_down,referee_right_leg_down,referee_legs_down
	
block_table
	dc.l	normal_backing_away		; no blow
	dc.l	normal_backing_away		; super low: can't block
	dc.l	do_low_block
	dc.l	do_medium_block
	dc.l	do_high_block

	
moves_table
	dc.l	move_table_right,move_table_left
	include	"move_tables.s"
	
;base addr, len, per, vol, channel<<8 + pri, loop timer, number of repeats (or -1), current repeat, current vbl

FXFREQBASE = 3579564
SOUNDFREQ = 16000

SOUND_ENTRY:MACRO
\1_sound
    dc.l    \1_raw
    dc.w    (\1_raw_end-\1_raw)/2,FXFREQBASE/\3,\4
    dc.b    \2
    dc.b    $01
    ENDM
    
    ; radix, ,channel (0-3)
    SOUND_ENTRY begin,2,SOUNDFREQ,34
    SOUND_ENTRY blow,2,SOUNDFREQ,11
    SOUND_ENTRY fall,2,SOUNDFREQ,25
    SOUND_ENTRY full_point,2,SOUNDFREQ,34
    SOUND_ENTRY half_point,2,SOUNDFREQ,14
    SOUND_ENTRY judge,2,SOUNDFREQ,39
    SOUND_ENTRY kiai_1,2,SOUNDFREQ,29
    SOUND_ENTRY kiai_2,2,SOUNDFREQ,17
    SOUND_ENTRY stop,2,SOUNDFREQ,31
    SOUND_ENTRY swoosh1,2,SOUNDFREQ,24
    SOUND_ENTRY swoosh2,2,SOUNDFREQ,10	
game_palette
    include "palette.s"
level_players_y_min:
	dc.w	0
current_score_x:
	dc.w	0
current_score_y
	dc.w	0
current_score_display_timer
	dc.l	0
	
picked_practice_table:
	dc.l	0
current_practice_move_timer:
	dc.l	0
next_practice_move_timer:
	dc.l	0
current_move_key:
	dc.l	0
current_move_key_last_jump:
	dc.l	0
practice_move_index:
	dc.w	0
player:
player_1:
    ds.b    Player_SIZEOF
player_2:
    ds.b    Player_SIZEOF
referee:
	ds.b	Referee_SIZEOF
    even

    
keyboard_table:
    ds.b    $100,0
    
floppy_file
    dc.b    "floppy",0


if_you_do_not_message
	dc.b	"IF YOU DO NOT",0
want_practice_press_message 
	dc.b	"WANT PRACTICE PRESS",0
player_start_button_message 
	dc.b	"PLAYER START BUTTON",0
blank_13_message
	REPT	13
	dc.b	"/"
	ENDR
	dc.b	0
blank_19_message
	REPT	19
	dc.b	"/"
	ENDR
	dc.b	0
	
    even

	include	player_frames.s
	include	hit_lists.s
	include	player_bob_masks.s

level_params_table
	dc.l	practice_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	dc.l	pier_level
	
	

	
	; LevelParams
practice_level
	dc.l	pl3
	dc.w	40
	dc.w	152
	dc.w	112
	dc.w	96
	; referee
	dc.w	104
	dc.w	72
	dc.w	0
	dc.w	0

pier_level
	dc.l	pl1
	dc.w	24
	dc.w	176
	dc.w	152
	dc.w	0
	; referee
	dc.w	104
	dc.w	112
	dc.w	32
	dc.w	-32
	
fuji_level
	dc.l	pl1
	dc.w	22
	dc.w	190
	dc.w	152
	dc.w	0
	; referee
	dc.w	104
	dc.w	124
	dc.w	32
	dc.w	-32
	
	   
pl1:
	incbin	"back_01.bin.RNC"
pl2:
	incbin	"back_02.bin.RNC"
pl3:
	incbin	"back_03.bin.RNC"
pl4:
	incbin	"back_04.bin.RNC"
pl5:
	incbin	"back_05.bin.RNC"
pl6:
	incbin	"back_06.bin.RNC"
pl7:
	incbin	"back_07.bin.RNC"
pl8:
	incbin	"back_08.bin.RNC"
pl9:
	incbin	"back_09.bin.RNC"
pl10:
	incbin	"back_10.bin.RNC"
pl11:
	incbin	"back_11.bin.RNC"
pl12:
	incbin	"back_12.bin.RNC"
; BSS --------------------------------------
    SECTION  S3,BSS
HWSPR_TAB_XPOS:	
	ds.l	512			

HWSPR_TAB_YPOS:
	ds.l	512
    
    IFD   RECORD_INPUT_TABLE_SIZE
record_input_table:
    ds.b    RECORD_INPUT_TABLE_SIZE
    ENDC
    

player_move_buffer
    ds.l    NB_RECORDED_MOVES
    even
    
; resolution 1/2 compared to the original resolution
collision_matrix:
	ds.b	COLLISION_NB_COLS*COLLISION_NB_ROWS
    SECTION  S4,CODE
    include ptplayer.s

    SECTION  S5,DATA,CHIP
; main copper list
coplist
bitplanes:
   dc.l  $00e00000
   dc.l  $00e20000
   dc.l  $00e40000
   dc.l  $00e60000
   dc.l  $00e80000
   dc.l  $00ea0000
   dc.l  $00ec0000
   dc.l  $00ee0000
;   dc.l  $00f00000
;   dc.l  $00f20000

colors:
   dc.w color,0     ; fix black (so debug can flash color0)
sprites:
score_sprite_white:
    ; #0
    dc.w    sprpt+0,0
    dc.w    sprpt+2,0
    ; #1
    dc.w    sprpt+4,0
    dc.w    sprpt+6,0
score_sprite_red:
    ; #2
    dc.w    sprpt+8,0
    dc.w    sprpt+10,0
    ; #3
    dc.w    sprpt+12,0
    dc.w    sprpt+14,0   
    ; #4
    dc.w    sprpt+16,0
    dc.w    sprpt+18,0
    ; #5
    dc.w    sprpt+20,0
    dc.w    sprpt+22,0
    ; #6
    dc.w    sprpt+24,0
    dc.w    sprpt+26,0
    ; #7
    dc.w    sprpt+28,0
    dc.w    sprpt+30,0
end_color_copper:
   ; proper sprite priority: above bitplanes
   ;dc.w  $0102,$0000            ;  BPLCON1 := 0x0000
   ;dc.w  $0104,$0024            ;  BPLCON2 := 
   dc.w  $FFDF,$FFFE            ; PAL wait (256)
   dc.w  $2201,$FFFE            ; PAL extra wait (around 288)
   dc.w	 intreq,$8010            ; generate copper interrupt
    dc.l    -2					; end of copperlist

; score sprites
SCORE_SPRITES:MACRO
score_100_\1
	dc.l	0
	incbin	score_100.bin
	dc.l	0
score_200_\1
	dc.l	0
	incbin	score_200.bin
	dc.l	0
score_300_\1
	dc.l	0
	incbin	score_300.bin
	dc.l	0
score_400_\1
	dc.l	0
	incbin	score_400.bin
	dc.l	0
score_500_\1
	dc.l	0
	incbin	score_500.bin
	dc.l	0
score_600_\1
	dc.l	0
	incbin	score_600.bin
	dc.l	0
score_700_\1
	dc.l	0
	incbin	score_700.bin
	dc.l	0
score_800_\1
	dc.l	0
	incbin	score_800.bin
	dc.l	0
score_900_\1
	dc.l	0
	incbin	score_900.bin
	dc.l	0
score_1000_\1
	dc.l	0
	incbin	score_1000.bin
	dc.l	0
	ENDM
	
	SCORE_SPRITES	white
	SCORE_SPRITES	red
	
	

empty_16x16_bob
empty_48x48_bob
    ds.b    BOB_64X48_PLANE_SIZE,0

; sound samples
begin_raw
    incbin  "begin.raw"
    even
begin_raw_end

blow_raw
    incbin  "blow.raw"
    even
blow_raw_end

fall_raw
    incbin  "fall.raw"
    even
fall_raw_end

full_point_raw
    incbin  "full_point.raw"
    even
full_point_raw_end

half_point_raw
    incbin  "half_point.raw"
    even
half_point_raw_end

judge_raw
    incbin  "judge.raw"
    even
judge_raw_end

kiai_1_raw
    incbin  "kiai_1.raw"
    even
kiai_1_raw_end

kiai_2_raw
    incbin  "kiai_2.raw"
    even
kiai_2_raw_end

stop_raw
    incbin  "stop.raw"
    even
stop_raw_end

swoosh1_raw
    incbin  "swoosh1.raw"
    even
swoosh1_raw_end

swoosh2_raw
    incbin  "swoosh2.raw"
    even
swoosh2_raw_end

	include	"player_bobs.s"
	include	"other_bobs.s"
music:
    ;incbin  "amidar_music_conv.mod"
    
panel:
	incbin	"panel.bin"
; mask plane generated manually
panel_mask:
	REPT	64
	REPT	11
	dc.w	$FFFF
	ENDR
	dc.w	$0000
	ENDR
	
empty_sprite
    dc.l    0
	dc.l	-1	; TEMP
	dc.l	-1
	dc.l	-1
	dc.l	-1
	dc.l	-1
	dc.l	-1
	dc.l	-1
	dc.l	-1
	dc.l	-1
	dc.l	0
    
    SECTION S_4,BSS,CHIP

screen_data:
    ds.b    SCREEN_PLANE_SIZE*NB_PLANES,0
	
backbuffer
	ds.b	BACKBUFFER_PLANE_SIZE*NB_PLANES,0

    	