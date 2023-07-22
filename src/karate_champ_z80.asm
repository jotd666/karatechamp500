;
; Karate Champ VS 2. Reverse-engineering attempt by JOTD, focusing on 2 points:
; - CPU A.I.
; - animations
;
; CF02: time when entering highscore (BCD)
;
; current level info is propagated at 3 locations which mean different things:
;
; C0DC: number (1ST, 2ND...)
; C900: map index (picture, girl)
; C910: skill level (see below)
; background_and_state_bits_C911: background+state bits

; C028: attack flags (red player/red cpu), can be 08,09,0A TODO figure out when????

; nb_credits_minus_one_C024: 0 when no credit, then if coin is inserted, set to 1, then
; immediately decreased, while showing "press 1P button" screen

; C910: skill level / speed of computer
; 0: slow => 12: super fast. $10 seems a threshold
; aggressivity is also increased
; increasing skill level dynamically works: computer goes super ninja)
;
; C556-59: 4 bytes looks like counters. When move is completed all 4 values are 8

; C02D
; players_type_human_or_cpu_flags_C02D: 05 1 player vs CPU, 0F 2 players. Changing dynamically works too!

; note: there are 4 structures C200, C220, C240, C260... there are copies of data for instance C229/C22A are copied
; to C269/C26A. Not sure of everything that's written below in terms of addresses...
; C200/C240: player 1 structures
; C220/C260: player 1 structures


; C220: another structure, A.I. related, probably sharing both parties characteristics
; TODO: figure out more values from that structure, specially:
; +07/+08: frame id/pointer on frame structure of own player, used as input of check_hl_in_ix_list_B009 by A.I
;  so the CPU can recognize the moves
; +09 white player x ($20 min $DF max)
; +0A: current move index (at least during practice)
; +0B/+0C: frame id, like 07/08 for opponent player. Note: bit 8 of C22C set: opponent facing right, maybe
;     only important for frame display
; +0D opponent player x
; +0E oppnent move index
; +0F ($C20F): player logical distance, often addressed as  bit  7,(iy+$0f)
; distance seems to be computed from the backs of the players
; bit 7 set => means current player is turning his back to opponent)
; then
; 0: back 2 back distance > 0x70
; 1-4: opponent faces current player (which can turn its back to opponent, see bit 7)
; 1: back 2 back distance > 0x58
; 2: back 2 back distance > 0x40
; 3: back 2 back distance > 0x28
; 4: back 2 back distance > 0x10
; 5-7: opponent turns back to current player (which can turn its back to opponent, see bit 7)
; 5: back 2 back distance > 0x60
; 6: back 2 back distance > 0x30
; 7: back 2 back distance > 0x18
; 8: smaller distance (<= 0x10/0x18) (at least one player must turn his back)
;
; there's a $10 (8 ?) offset depending on facing

; C240: player 1 structure
; +2: 0 when not animated, else number of ticks to stay in the current animation frame
; +7,8: animation related. Bit 7 of C248: facing direction
; C249 (+$9): player 1 x coord. Ranges $20 (32 top left) to $DF (223 right), starts at 0x30
; C24A (+$A): player 1 y coord. $E0 when fighting. Practice:
; C24B (+$B): player 1 current move: codes below
; C24C (+$C): rough distance 0-4
; 0: far
; 1: intermediate, facing other player  (regardless of other player facing direction)
; 2: very close, facing other player   ("")
; 3: intermediate, turning back to other player  ("")
; 4: very close, turning back to other player    ("")
;
;
; C260: player 2 structure
; C269 (+$9): x coord. starts at 0xD0
; C26A (+$A): y coord. $E0 when fighting. Practice: $90
; C26B: player 2 current move (see codes below). Also set during "practice"
; C26C: player 2 rough distance to player 1 0 (same as C24C for second player)
;
; for instance if white is on the left (facing right) and red is on the right, close (facing right)
; the value of
; C24C is: 02
; C26C is: 04
;
; changing C249 immediately reflects on player 1 (white) moving x wise
; changing C269 immediately reflects on player 2 (red) moving x wise
; players can't be exactly at the same position. At least $10 distance is required
; (setting values too close to each other results in game correcting them, same for min/max)
;

; the codes don't match exact moves, but rather the attack type
; there is often only one attack type (back kick) but sometimes there are
; several: example with front kick and weak reverse punch, that only differ
; by attack distance
;
; values marked with "**" trigger the relevant moves only when injecting
; them by setting a at AB56. Injecting 07 doesn't make CPU turn around, but
; does something else.
;
; also attacks can be triggered in other places

; 0x00: not moving, guard
; 0x01: moving back
; 0x02: moving forward
; 0x03: pre-jump (jump to avoid low blow?)
; 0x04: crouch
; 0x05: back kick
; 0x06: ** back kick
; 0x07: turn around (only CPU can do that without using an aborted back jump/round kick)
; 0x08: jumping back kick
; 0x09: foot sweep (back)
; 0x0A: front kick (can also be small reverse punch at short range apparently)
; 0x0B: back round kick
; 0x0C: lunge punch (medium 200-400 forward+forward)
; 0x0D: jumping side kick
; 0x0E: ** foot sweep (front)
; 0x0F: round kick
; 0x10: lunge punch (high 300-600 rear+up)
; 0x11: lunge punch (high 500-1000 forward+up)
; 0x12: rear sommersault
; 0x13: reverse punch (crouch 400-800)
; 0x14: low kick
; 0x15: ** low kick
; 0x16: ** low kick
; 0x17: front sommersault
; 0x18: foot sweep (front)

; difficulty level only has an effect before "CMP" level number 16
; in CMP (champ) level and stage 16 (brige CMP if I'm not mistaken),
; difficulty dip switches are ignored, game is just super fast
; and super hard
;
;A.I: how computer maintains its moves ?
;
; - attack moves: once the attack went through (and failed), depending
;   on the skill level, computer waits a while with the move frozen
;   (including jumping moves, which looks a bit weird). In champion level
;   from level 16, there is no wait at all.
; - blocking moves: maintaned as long as the opponent is performing
;   an attack move with a matching attack height

; I should get more info about player_2_attack_flags_C028 what does the values mean (09,0A...)
; probably related to animation frames not to A.I. so less interesting

; VS Version Info:
; ---------------
; Memory Map:
; Main CPU
; 0000-bfff ROM (encrypted)
; c000-cfff RAM
; d000-d3ff char videoram
; d400-d7ff color videoram
; d800-d8ff sprites
; e000-ffff ROM (encrypted)

; IO Ports:
; Main CPU
; INPUT  00 = Player 1 Controls - ( ACTIVE LOW )
; INPUT  40 = Player 2 Controls - ( ACTIVE LOW )
; INPUT  80 = Coins and Start Buttons - ( ACTIVE LOW )
; INPUT  C0 = Dip Switches - ( ACTIVE LOW )
; OUTPUT 00 = Screen Flip
; OUTPUT 01 = CPU Control
;                 bit 0 = external nmi enable
; OUTPUT 02 = Sound Reset
; OUTPUT 40 = Sound latch write
;
; Sound CPU
; INPUT  01 = Sound latch read
; OUTPUT 00 = AY8910 #1 data write
; OUTPUT 01 = AY8910 #1 control write
; OUTPUT 02 = AY8910 #2 data write
; OUTPUT 03 = AY8910 #2 control write
; OUTPUT 04 = MSM5205 write
; OUTPUT 05 = CPU Control
;                 bit 0 = MSM5205 trigger
;                 bit 1 = external nmi enable


0000: C3 45 B0    jp   startup_B045
0003: C3 59 41    jp   $4153
	dc.b	0x69,0x53,0x41,0x00,0x00,0x00,0x00,0x00 ; $0003
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $000b
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $0013
	dc.b	0x00,0x00,0x00,0x00,0x00 ; $001b
; routines called by the main scheduler at B502
task_address_table_0020:
	dc.w	task_5250 ; task_address_table_0020
	dc.w	task_53d2 ; $0022
	dc.w	$544f ; $0024
	dc.w	$6491 ; $0026
	dc.w	$6529 ; $0028
	dc.w	$7c5d ; $002a
	dc.w	$6f89 ; $002c
	dc.w	$6622 ; $002e
	dc.w	$755b ; $0030
	dc.w	$7657 ; $0032
	dc.w	$3a9c ; $0034
	dc.w	$3a9c ; $0036
	dc.w	$0050 ; $0038		; not used probably!
	dc.w	$0050 ; $003a		; not used probably!
	dc.w	$0050 ; $003c		; not used probably!
	dc.w	$6d5e ; $003e
	dc.w	$47d6 ; $0040
	dc.w	$47d6 ; $0042
	dc.w	$47d6 ; $0044
	dc.w	$47d6 ; $0046
	dc.w	$50f2 ; $0048
	dc.w	$b099 ; $004a
	dc.w	$b09c ; $004c
	dc.w	$b09f ; $004e

	; rest seems invalid/illogical
	dc.w	$7567 ; $0050	invalid
	dc.w	$3ab0 ; $0052
	dc.w	$1eac ; $0054
	dc.w	$53ee ; $0056
	dc.w	$cc3d ; $0058	invalid
	dc.w	$7b09 ; $005a	invalid
	dc.w	$4cb8 ; $005c	invalid
	dc.w	$0060 ; $005e	invalid
	dc.w	$dd03 ; $0060	invalid
	dc.w	$4002 ; $0062	invalid?
	dc.w	$2661 ; $0064	invalid
; periodic interrupt
0066: C3 42 B0    jp   periodic_interrupt_B048



table_183F:
	dc.b	0x00,0x02,0xfc,0x00,0x00,0x04,0x92,0x33 ; $183f
	dc.b	0x00,0xff,0x04,0x05,0x00,0x00,0x08,0x99 ; $1847
	dc.b	0x33,0x10,0xff,0x04,0x04,0x00,0x00,0x08 ; $184f
	dc.b	0xa0,0x33,0x13,0x8f,0x02,0x03,0x00,0x22 ; $1857
	dc.b	0x08,0xa7,0x33,0x81,0x1e,0x03,0x00,0x00 ; $185f
	dc.b	0x00,0x04,0xc3,0x33,0x00,0xb6,0x02,0x00 ; $1867
	dc.b	0x00,0x21,0x08,0xca,0x33,0x82,0x8e,0x05 ; $186f
	dc.b	0xff,0x00,0x22,0x08,0xd8,0x33,0x03,0xb5 ; $1877
	dc.b	0x05,0x06,0x00,0x22,0x08,0xe6,0x33,0x84 ; $187f
	dc.b	0xc2,0x05,0x0a,0x00,0x21,0x08,0xfb,0x33 ; $1887
	dc.b	0x85,0xe9,0x05,0x05,0x00,0x21,0x08,0x09 ; $188f
	dc.b	0x34,0x86,0xc2,0x05,0x0a,0x00,0x21,0x08 ; $1897
	dc.b	0x17,0x34,0x87,0xff,0x04,0x04,0x00,0x21 ; $189f
	dc.b	0x08,0x25,0x34,0x88,0xe1,0x03,0x0a,0x00 ; $18a7
	dc.b	0x22,0x08,0x33,0x34,0x09,0x67,0x05,0x06 ; $18af
	dc.b	0x00,0x21,0x08,0x48,0x34,0x0a,0x1d,0x06 ; $18b7
	dc.b	0x07,0x00,0x22,0x08,0x5d,0x34,0x8b,0xc2 ; $18bf
	dc.b	0x05,0x0a,0x00,0x21,0x08,0x72,0x34,0x8c ; $18c7
	dc.b	0xff,0x04,0x00,0x00,0x00,0x08,0x80,0x34 ; $18cf
	dc.b	0x12,0xcf,0x05,0x0b,0x00,0x21,0x08,0x8e ; $18d7
	dc.b	0x34,0x8d,0xb5,0x05,0x06,0x00,0x22,0x08 ; $18df
	dc.b	0x9c,0x34,0x0e,0xff,0x04,0x04,0x00,0x00 ; $18e7
	dc.b	0x08,0xb8,0x34,0x11,0x00,0x02,0xf1,0x00 ; $18ef
	dc.b	0x00,0x04,0xc6,0x34,0x00,0x00,0x02,0xf1 ; $18f7
	dc.b	0x00,0x00,0x04,0xcd,0x34,0x00,0x27,0x02 ; $18ff
	dc.b	0x02,0x00,0x00,0x04,0xd4,0x34,0x00,0x1e ; $1907
	dc.b	0x03,0xfd,0x00,0x00,0x04,0xdb,0x34,0x00 ; $190f
	dc.b	0xff,0x04,0x01,0x00,0x00,0x08,0xe2,0x34 ; $1917
	dc.b	0x10,0xff,0x04,0x01,0x00,0x00,0x08,0xe9 ; $191f
	dc.b	0x34,0x13,0x8f,0x02,0x07,0x00,0x22,0x08 ; $1927
	dc.b	0xf0,0x34,0x81,0x34,0x02,0x00,0x00,0x00 ; $192f
	dc.b	0x04,0x0c,0x35,0x00,0xb6,0x02,0xf6,0x00 ; $1937
	dc.b	0x21,0x08,0x13,0x35,0x82,0x8e,0x05,0x05 ; $193f
	dc.b	0x00,0x22,0x08,0x21,0x35,0x03,0xcf,0x05 ; $1947
	dc.b	0x00,0x00,0x21,0x08,0x2f,0x35,0x85,0x00 ; $194f
	dc.b	0x02,0xf1,0x00,0x80,0x08,0x3d,0x35,0x86 ; $1957
	dc.b	0xb5,0x05,0x03,0x00,0x21,0x08,0x44,0x35 ; $195f
	dc.b	0x87,0xff,0x04,0x01,0x00,0x21,0x08,0x52 ; $1967
	dc.b	0x35,0x88,0xe1,0x03,0x06,0x00,0x22,0x01 ; $196f
	dc.b	0x60,0x35,0x09,0x67,0x05,0x06,0x00,0x21 ; $1977
	dc.b	0x08,0x75,0x35,0x0a,0x1d,0x06,0x04,0x00 ; $197f
	dc.b	0x22,0x08,0x8a,0x35,0x8b,0xb5,0x05,0x03 ; $1987
	dc.b	0x00,0x21,0x08,0x9f,0x35,0x8c,0xff,0x04 ; $198f
	dc.b	0xf6,0x00,0x00,0x08,0xad,0x35,0x12,0xcf ; $1997
	dc.b	0x05,0x02,0x00,0x21,0x08,0xbb,0x35,0x8d ; $199f
	dc.b	0xff,0x04,0x01,0x00,0x00,0x08,0xc9,0x35 ; $19a7
	dc.b	0x11,0x2a,0x06,0x03,0x00,0x00,0x02,0xd7 ; $19af
	dc.b	0x35,0x8b,0xfe,0x07,0x00,0x00,0x91,0x10 ; $19b7
	dc.b	0xec,0x35,0x00,0x0b,0x08,0x00,0x00,0x80 ; $19bf
	dc.b	0x10,0xf3,0x35,0x00,0x18,0x08,0x00,0x00 ; $19c7
	dc.b	0x90,0x01,0xfa,0x35,0x00,0xd7,0x07,0x00 ; $19cf
	dc.b	0x00,0x91,0x10,0x01,0x36,0x00,0xe4,0x07 ; $19d7
	dc.b	0x00,0x00,0x80,0x10,0x08,0x36,0x00,0xf1 ; $19df
	dc.b	0x07,0x00,0x00,0x90,0x01,0x0f,0x36,0x00 ; $19e7
	dc.b	0xb0,0x07,0x00,0x00,0x11,0x10,0x16,0x36 ; $19ef
	dc.b	0x00,0xbd,0x07,0x00,0x00,0x00,0x10,0x1d ; $19f7
	dc.b	0x36,0x00,0xca,0x07,0x00,0x00,0x10,0x01 ; $19ff
	dc.b	0x24,0x36,0x00,0x55,0x07,0x00,0x00,0x91 ; $1a07
	dc.b	0x10,0x2b,0x36,0x00,0x62,0x07,0x00,0x00 ; $1a0f
	dc.b	0x80,0x10,0x32,0x36,0x00,0x6f,0x07,0x00 ; $1a17
	dc.b	0x00,0x90,0x01,0x39,0x36,0x00,0xb0,0x07 ; $1a1f
	dc.b	0x00,0x00,0x11,0x10,0x40,0x36,0x00,0xbd ; $1a27
	dc.b	0x07,0x00,0x00,0x00,0x10,0x47,0x36,0x00 ; $1a2f
	dc.b	0xca,0x07,0x00,0x00,0x10,0x01,0x4e,0x36 ; $1a37
	dc.b	0x00,0x7c,0x07,0x00,0x00,0x11,0x10,0x55 ; $1a3f
	dc.b	0x36,0x00,0x89,0x07,0x00,0x00,0x00,0x10 ; $1a47
	dc.b	0x5c,0x36,0x00,0xa3,0x07,0x00,0x00,0x10 ; $1a4f
	dc.b	0x01,0x63,0x36,0x00,0x14,0x07,0x37,0x40 ; $1a57
	dc.b	0x00,0x02,0x6a,0x36,0x20,0x21,0x07,0x03 ; $1a5f
	dc.b	0x00,0x00,0x02,0x71,0x36,0x20,0x2e,0x07 ; $1a67
	dc.b	0x04,0x00,0x00,0x02,0x78,0x36,0x20,0x3b ; $1a6f
	dc.b	0x07,0x01,0x00,0x00,0x02,0x7f,0x36,0x20 ; $1a77
	dc.b	0x48,0x07,0x00,0x00,0x00,0x01,0x86,0x36 ; $1a7f
	dc.b	0x20,0x48,0x07,0x00,0x00,0x00,0x02,0x8d ; $1a87
	dc.b	0x36,0x20,0x00,0x02,0xf1,0x00,0x00,0x01 ; $1a8f
	dc.b	0x9b,0x36,0x00,0xc6,0x06,0x59,0x40,0x00 ; $1a97
	dc.b	0x02,0xa2,0x36,0x20,0xd3,0x06,0x05,0x00 ; $1a9f
	dc.b	0x00,0x02,0xa9,0x36,0x20,0xe0,0x06,0xfe ; $1aa7
	dc.b	0x00,0x00,0x02,0xb0,0x36,0x20,0xed,0x06 ; $1aaf
	dc.b	0x04,0x00,0x00,0x02,0xb7,0x36,0x20,0xfa ; $1ab7
	dc.b	0x06,0x01,0x00,0x00,0x02,0xbe,0x36,0x20 ; $1abf
	dc.b	0x07,0x07,0x02,0x00,0x00,0x01,0xc5,0x36 ; $1ac7
	dc.b	0x20,0x07,0x07,0x00,0x00,0x00,0x02,0xcc ; $1acf
	dc.b	0x36,0x20,0x00,0x02,0xf1,0x00,0x00,0x01 ; $1ad7
	dc.b	0xda,0x36,0x00,0x78,0x06,0x7b,0x40,0x00 ; $1adf
	dc.b	0x02,0xe1,0x36,0x20,0x85,0x06,0xfc,0x00 ; $1ae7
	dc.b	0x00,0x02,0xe8,0x36,0x20,0x92,0x06,0x00 ; $1aef
	dc.b	0x00,0x00,0x02,0xef,0x36,0x20,0x9f,0x06 ; $1af7
	dc.b	0x00,0x00,0x00,0x02,0xf6,0x36,0x20,0xac ; $1aff
	dc.b	0x06,0x01,0x00,0x00,0x02,0xfd,0x36,0x20 ; $1b07
	dc.b	0xb9,0x06,0x01,0x00,0x00,0x01,0x04,0x37 ; $1b0f
	dc.b	0x20,0xb9,0x06,0x00,0x00,0x00,0x02,0x0b ; $1b17
	dc.b	0x37,0x20,0x00,0x02,0xf2,0x00,0x00,0x08 ; $1b1f
	dc.b	0x19,0x37,0x00,0x7c,0x07,0x00,0x00,0x11 ; $1b27
	dc.b	0x10,0x20,0x37,0x00,0x96,0x07,0x00,0x00 ; $1b2f
	dc.b	0x10,0x10,0x27,0x37,0x00,0xa3,0x07,0x00 ; $1b37
	dc.b	0x00,0x00,0x01,0x2e,0x37,0x00,0x75,0x02 ; $1b3f
	dc.b	0xf7,0x00,0x00,0x08,0x35,0x37,0x13,0x75 ; $1b47
	dc.b	0x02,0xfa,0x00,0x00,0x08,0x3c,0x37,0x13 ; $1b4f
	dc.b	0x56,0x04,0x00,0x00,0x00,0x04,0x43,0x37 ; $1b57
	dc.b	0x00,0x00,0x02,0x00,0x00,0x00,0x01,0x4a ; $1b5f
	dc.b	0x37,0x00,0x00,0x02,0x00,0x00,0x00,0x01 ; $1b67
	dc.b	0x58,0x37,0x00,0x59,0x08,0x00,0x00,0x00 ; $1b6f
	dc.b	0x08,0x66,0x37,0x00,0x4c,0x08,0x17,0x00 ; $1b77
	dc.b	0x00,0x08,0x6d,0x37,0x00,0x59,0x08,0x12 ; $1b7f
	dc.b	0x00,0x00,0x08,0x74,0x37,0x00,0x3f,0x08 ; $1b87
	dc.b	0x12,0x00,0x00,0x08,0x7b,0x37,0x00,0x80 ; $1b8f
	dc.b	0x08,0x00,0x00,0x00,0x08,0x82,0x37,0x00 ; $1b97
	dc.b	0x66,0x08,0x00,0x00,0x20,0x08,0x89,0x37 ; $1b9f
	dc.b	0x00,0x73,0x08,0x00,0x00,0x00,0x08,0x90 ; $1ba7
	dc.b	0x37,0x00,0x80,0x08,0x00,0x00,0x00,0x08 ; $1baf
	dc.b	0x97,0x37,0x00 ; $1bb7
; move tables
; index 0 -> $18 followed by 3 frame pointers (often all 3 the same, not always)
1BBA:
	dc.b	0x00,0x89,0x0a,0x89,0x0a,0x89,0x0a,0x01 ; $1bba
	dc.b	0xd1,0x0a,0xda,0x0a,0xda,0x0a,0x02,0xe3 ; $1bc2
	dc.b	0x0a,0xec,0x0a,0xec,0x0a,0x03,0xf5,0x0a ; $1bca
	dc.b	0xf5,0x0a,0xf5,0x0a,0x04,0x03,0x0c,0x03 ; $1bd2
	dc.b	0x0c,0x03,0x0c,0x05,0x9c,0x0c,0x9c,0x0c ; $1bda
	dc.b	0x9c,0x0c,0x06,0x9c,0x0c,0x9c,0x0c,0x9c ; $1be2
	dc.b	0x0c,0x07,0x11,0x8d,0x9c,0x0c,0x9c,0x0c ; $1bea
	dc.b	0x08,0x1a,0x0d,0x1a,0x0d,0x1a,0x0d,0x09 ; $1bf2
	dc.b	0xaa,0x0d,0xaa,0x0d,0xaa,0x0d,0x0a,0x1f ; $1bfa
	dc.b	0x0e,0x1f,0x0e,0x94,0x0e,0x0b,0xe5,0x0e ; $1c02
	dc.b	0xe5,0x0e,0xe5,0x0e,0x0c,0x63,0x0f,0x63 ; $1c0a
	dc.b	0x0f,0x1f,0x0e,0x0d,0xd8,0x0f,0xd8,0x0f ; $1c12
	dc.b	0xd8,0x0f,0x0e,0x71,0x10,0x71,0x10,0x71 ; $1c1a
	dc.b	0x10,0x0f,0xe6,0x10,0xe6,0x10,0xe6,0x10 ; $1c22
	dc.b	0x10,0x49,0x11,0x49,0x11,0x49,0x11,0x11 ; $1c2a
	dc.b	0xb5,0x11,0xb5,0x11,0xe6,0x10,0x12,0x2a ; $1c32
	dc.b	0x12,0x2a,0x12,0x2a,0x12,0x13,0xa8,0x12 ; $1c3a
	dc.b	0xa8,0x12,0xa8,0x12,0x14,0x1d,0x13,0x1d ; $1c42
	dc.b	0x13,0x1d,0x13,0x15,0x1d,0x13,0x1d,0x13 ; $1c4a
	dc.b	0x1d,0x13,0x16,0x1d,0x13,0x1d,0x13,0x1d ; $1c52
	dc.b	0x13,0x17,0x92,0x13,0x92,0x13,0x92,0x13 ; $1c5a
	dc.b	0x18,0x71,0x10,0x71,0x10,0x71,0x10,0xff ; $1c62  end of frames
1C6A:
	dc.b	0x89,0x0a,0x89,0x0a,0x89,0x0a,0x00,0x92 ; $1c6a
	dc.b	0x0a,0x92,0x0a,0x92,0x0a,0x01,0x19,0x14 ; $1c72
	dc.b	0x22,0x14,0x22,0x14,0x02,0x2b,0x14,0x34 ; $1c7a
	dc.b	0x14,0x34,0x14,0x03,0x3d,0x14,0x3d,0x14 ; $1c82
	dc.b	0x3d,0x14,0x04,0x46,0x14,0x46,0x14,0x46 ; $1c8a
	dc.b	0x14,0x05,0x4f,0x14,0x4f,0x14,0x4f,0x14 ; $1c92
	dc.b	0x06,0x4f,0x14,0x4f,0x14,0x4f,0x14,0x07 ; $1c9a
	dc.b	0x58,0x94,0x4f,0x14,0x4f,0x14,0x08,0x61 ; $1ca2
	dc.b	0x14,0x61,0x14,0x61,0x14,0x09,0x6a,0x14 ; $1caa
	dc.b	0x6a,0x14,0x6a,0x14,0x0a,0x73,0x14,0x73 ; $1cb2
	dc.b	0x14,0x7c,0x14,0x0b,0x85,0x14,0x85,0x14 ; $1cba
	dc.b	0x85,0x14,0x0c,0x8e,0x14,0x8e,0x14,0x73 ; $1cc2
	dc.b	0x14,0x0d,0x97,0x14,0x97,0x14,0x97,0x14 ; $1cca
	dc.b	0x0e,0xa0,0x14,0xa0,0x14,0xa0,0x14,0x0f ; $1cd2
	dc.b	0xa9,0x14,0xa9,0x14,0xa9,0x14,0x10,0xb2 ; $1cda
	dc.b	0x14,0xb2,0x14,0xb2,0x14,0x11,0xbb,0x14 ; $1ce2
	dc.b	0xbb,0x14,0xa9,0x14,0x12,0xc4,0x14,0xc4 ; $1cea
	dc.b	0x14,0xc4,0x14,0x13,0xcd,0x14,0xcd,0x14 ; $1cf2
	dc.b	0xcd,0x14,0x14,0xd6,0x14,0xd6,0x14,0xd6 ; $1cfa
	dc.b	0x14,0x15,0xd6,0x14,0xd6,0x14,0xd6,0x14 ; $1d02
	dc.b	0x16,0xd6,0x14,0xd6,0x14,0xd6,0x14,0x17 ; $1d0a
	dc.b	0xdf,0x14,0xdf,0x14,0xdf,0x14,0x18,0xa0 ; $1d12
	dc.b	0x14,0xa0,0x14,0xa0,0x14,0xff,0x92,0x0a ; $1d1a
	dc.b	0x92,0x0a,0x92,0x0a,0x00,0x9b,0x0a,0x9b ; $1d22
	dc.b	0x0a,0x9b,0x0a,0x01,0xe8,0x14,0xf1,0x14 ; $1d2a
	dc.b	0xf1,0x14,0x02,0xfa,0x14,0x03,0x15,0x03 ; $1d32
	dc.b	0x15,0x03,0x0c,0x15,0x0c,0x15,0x0c,0x15 ; $1d3a
	dc.b	0x04,0x15,0x15,0xbb,0x0b,0x15,0x15,0x05 ; $1d42
	dc.b	0x1e,0x15,0x1e,0x15,0x1e,0x15,0x06,0x1e ; $1d4a
	dc.b	0x15,0x1e,0x15,0x1e,0x15,0x07,0x27,0x95 ; $1d52
	dc.b	0x1e,0x15,0x1e,0x15,0x08,0x30,0x15,0x30 ; $1d5a
	dc.b	0x15,0x30,0x15,0x09,0x39,0x15,0x39,0x15 ; $1d62
	dc.b	0x39,0x15,0x0a,0x42,0x15,0x42,0x15,0x4b ; $1d6a
	dc.b	0x15,0x0b,0x66,0x15,0x66,0x15,0x66,0x15 ; $1d72
	dc.b	0x0c,0x6f,0x15,0x6f,0x15,0x42,0x15,0x0d ; $1d7a
	dc.b	0x78,0x15,0x78,0x15,0x78,0x15,0x0e,0x54 ; $1d82
	dc.b	0x15,0x54,0x15,0x54,0x15,0x0f,0x5d,0x15 ; $1d8a
	dc.b	0x5d,0x15,0x5d,0x15,0x10,0x81,0x15,0x81 ; $1d92
	dc.b	0x15,0x81,0x15,0x11,0x8a,0x15,0x8a,0x15 ; $1d9a
	dc.b	0x5d,0x15,0x12,0x93,0x15,0x93,0x15,0x93 ; $1da2
	dc.b	0x15,0x13,0x9c,0x15,0x9c,0x15,0x9c,0x15 ; $1daa
	dc.b	0x14,0xa5,0x15,0xa5,0x15,0xa5,0x15,0x15 ; $1db2
	dc.b	0xa5,0x15,0xa5,0x15,0xa5,0x15,0x16,0xa5 ; $1dba
	dc.b	0x15,0xa5,0x15,0xa5,0x15,0x17,0xae,0x15 ; $1dc2
	dc.b	0xae,0x15,0xae,0x15,0x18,0x54,0x15,0x54 ; $1dca
	dc.b	0x15,0x54,0x15,0xff,0x9b,0x0a,0x9b,0x0a ; $1dd2
	dc.b	0x9b,0x0a,0x00,0xa4,0x0a,0xa4,0x0a,0xa4 ; $1dda
	dc.b	0x0a,0x01,0xb7,0x15,0xc0,0x15,0xc0,0x15 ; $1de2
	dc.b	0x02,0xc9,0x15,0xd2,0x15,0xd2,0x15,0x03 ; $1dea
	dc.b	0xdb,0x15,0xdb,0x15,0xdb,0x15,0x04,0xe4 ; $1df2
	dc.b	0x15,0xe4,0x15,0xe4,0x15,0x05,0xed,0x15 ; $1dfa
	dc.b	0xed,0x15,0xed,0x15,0x06,0xed,0x15,0xed ; $1e02
	dc.b	0x15,0xed,0x15,0x07,0xf6,0x95,0xed,0x15 ; $1e0a
	dc.b	0xed,0x15,0x08,0xff,0x15,0xff,0x15,0xff ; $1e12
	dc.b	0x15,0x09,0x08,0x16,0x08,0x16,0x08,0x16 ; $1e1a
	dc.b	0x0a,0x11,0x16,0x11,0x16,0x1a,0x16,0x0b ; $1e22
	dc.b	0x23,0x16,0x23,0x16,0x23,0x16,0x0c,0x2c ; $1e2a
	dc.b	0x16,0x2c,0x16,0x11,0x16,0x0d,0x35,0x16 ; $1e32
	dc.b	0x35,0x16,0x35,0x16,0x0e,0x3e,0x16,0x3e ; $1e3a
	dc.b	0x16,0x3e,0x16,0x0f,0x47,0x16,0x47,0x16 ; $1e42
	dc.b	0x47,0x16,0x10,0x50,0x16,0x50,0x16,0x50 ; $1e4a
	dc.b	0x16,0x11,0x59,0x16,0x59,0x16,0x47,0x16 ; $1e52
	dc.b	0x12,0x62,0x16,0x62,0x16,0x62,0x16,0x13 ; $1e5a
	dc.b	0x6b,0x16,0x6b,0x16,0x6b,0x16,0x14,0x74 ; $1e62
	dc.b	0x16,0x74,0x16,0x74,0x16,0x15,0x74,0x16 ; $1e6a
	dc.b	0x74,0x16,0x74,0x16,0x16,0x74,0x16,0x74 ; $1e72
	dc.b	0x16,0x74,0x16,0x17,0x7d,0x16,0x7d,0x16 ; $1e7a
	dc.b	0x7d,0x16,0x18,0x3e,0x16,0x3e,0x16,0x3e ; $1e82
	dc.b	0x16,0xff,0xa4,0x0a,0xa4,0x0a,0xa4,0x0a ; $1e8a
	dc.b	0x00,0xad,0x0a,0xad,0x0a,0xad,0x0a,0x01 ; $1e92
	dc.b	0x86,0x16,0x8f,0x16,0x8f,0x16,0x02,0x98 ; $1e9a
	dc.b	0x16,0xa1,0x16,0xa1,0x16,0x03,0xaa,0x16 ; $1ea2
	dc.b	0xaa,0x16,0xaa,0x16,0x04,0xb3,0x16,0xb3 ; $1eaa
	dc.b	0x16,0xb3,0x16,0x05,0xbc,0x16,0xbc,0x16 ; $1eb2
	dc.b	0xbc,0x16,0x06,0xbc,0x16,0xbc,0x16,0xbc ; $1eba
	dc.b	0x16,0x07,0xc5,0x96,0xbc,0x16,0xbc,0x16 ; $1ec2
	dc.b	0x08,0xce,0x16,0xce,0x16,0xce,0x16,0x09 ; $1eca
	dc.b	0xd7,0x16,0xd7,0x16,0xd7,0x16,0x0a,0xe0 ; $1ed2
	dc.b	0x16,0xe0,0x16,0xe9,0x16,0x0b,0xf2,0x16 ; $1eda
	dc.b	0xf2,0x16,0xf2,0x16,0x0c,0xfb,0x16,0xfb ; $1ee2
	dc.b	0x16,0xe0,0x16,0x0d,0x04,0x17,0x04,0x17 ; $1eea
	dc.b	0x04,0x17,0x0e,0x0d,0x17,0x0d,0x17,0x0d ; $1ef2
	dc.b	0x17,0x0f,0x16,0x17,0x16,0x17,0x16,0x17 ; $1efa
	dc.b	0x10,0x1f,0x17,0x1f,0x17,0x1f,0x17,0x11 ; $1f02
	dc.b	0x28,0x17,0x28,0x17,0x16,0x17,0x12,0x31 ; $1f0a
	dc.b	0x17,0x31,0x17,0x31,0x17,0x13,0x3a,0x17 ; $1f12
	dc.b	0x3a,0x17,0x3a,0x17,0x14,0x43,0x17,0x43 ; $1f1a
	dc.b	0x17,0x43,0x17,0x15,0x43,0x17,0x43,0x17 ; $1f22
	dc.b	0x43,0x17,0x16,0x43,0x17,0x43,0x17,0x43 ; $1f2a
	dc.b	0x17,0x17,0x4c,0x17,0x4c,0x17,0x4c,0x17 ; $1f32
	dc.b	0x18,0x0d,0x17,0x0d,0x17,0x0d,0x17,0xff ; $1f3a
	dc.b	0xad,0x0a,0xad,0x0a,0xad,0x0a,0x00,0xb6 ; $1f42
	dc.b	0x0a,0xb6,0x0a,0xb6,0x0a,0x01,0x55,0x17 ; $1f4a
	dc.b	0x5e,0x17,0x5e,0x17,0x02,0x67,0x17,0x70 ; $1f52
	dc.b	0x17,0x70,0x17,0x03,0x79,0x17,0x79,0x17 ; $1f5a
	dc.b	0x79,0x17,0x04,0x82,0x17,0x82,0x17,0x82 ; $1f62
	dc.b	0x17,0x05,0x8b,0x17,0x8b,0x17,0x8b,0x17 ; $1f6a
	dc.b	0x06,0x8b,0x17,0x8b,0x17,0x8b,0x17,0x07 ; $1f72
	dc.b	0x94,0x97,0x8b,0x17,0x8b,0x17,0x08,0x9d ; $1f7a
	dc.b	0x17,0x9d,0x17,0x9d,0x17,0x09,0xa6,0x17 ; $1f82
	dc.b	0xa6,0x17,0xa6,0x17,0x0a,0xaf,0x17,0xaf ; $1f8a
	dc.b	0x17,0xb8,0x17,0x0b,0xc1,0x17,0xc1,0x17 ; $1f92
	dc.b	0xc1,0x17,0x0c,0xca,0x17,0xca,0x17,0xaf ; $1f9a
	dc.b	0x17,0x0d,0xd3,0x17,0xd3,0x17,0xd3,0x17 ; $1fa2
	dc.b	0x0e,0xdc,0x17,0xdc,0x17,0xdc,0x17,0x0f ; $1faa
	dc.b	0xe5,0x17,0xe5,0x17,0xe5,0x17,0x10,0xee ; $1fb2
	dc.b	0x17,0xee,0x17,0xee,0x17,0x11,0xf7,0x17 ; $1fba
	dc.b	0xf7,0x17,0xe5,0x17,0x12,0x00,0x18,0x00 ; $1fc2
	dc.b	0x18,0x00,0x18,0x13,0x09,0x18,0x09,0x18 ; $1fca
	dc.b	0x09,0x18,0x14,0x12,0x18,0x12,0x18,0x12 ; $1fd2
	dc.b	0x18,0x15,0x12,0x18,0x12,0x18,0x12,0x18 ; $1fda
	dc.b	0x16,0x12,0x18,0x12,0x18,0x12,0x18,0x17 ; $1fe2
	dc.b	0x1b,0x18,0x1b,0x18,0x1b,0x18,0x18,0xdc ; $1fea
	dc.b	0x17,0xdc,0x17,0xdc,0x17,0xff,0xb6,0x0a ; $1ff2
	dc.b	0xb6,0x0a,0xb6,0x0a,0x00,0xbf,0x0a,0xbf ; $1ffa
	dc.b	0x0a,0xbf,0x0a,0x01,0x24,0x18,0x2d,0x18 ; $2002
	dc.b	0x2d,0x18,0x02,0x36,0x18,0x3f,0x18,0x3f ; $200a
	dc.b	0x18,0x03,0x48,0x18,0x48,0x18,0x48,0x18 ; $2012
	dc.b	0x04,0x51,0x18,0x51,0x18,0x51,0x18,0x05 ; $201a
	dc.b	0x5a,0x18,0x5a,0x18,0x5a,0x18,0x06,0x5a ; $2022
	dc.b	0x18,0x5a,0x18,0x5a,0x18,0x07,0x63,0x98 ; $202a
	dc.b	0x5a,0x18,0x5a,0x18,0x08,0x6c,0x18,0x6c ; $2032
	dc.b	0x18,0x6c,0x18,0x09,0x75,0x18,0x75,0x18 ; $203a
	dc.b	0x75,0x18,0x0a,0x7e,0x18,0x7e,0x18,0x87 ; $2042
	dc.b	0x18,0x0b,0x90,0x18,0x90,0x18,0x90,0x18 ; $204a
	dc.b	0x0c,0x99,0x18,0x99,0x18,0x7e,0x18,0x0d ; $2052
	dc.b	0xa2,0x18,0xa2,0x18,0xa2,0x18,0x0e,0xab ; $205a
	dc.b	0x18,0xab,0x18,0xab,0x18,0x0f,0xb4,0x18 ; $2062
	dc.b	0xb4,0x18,0xb4,0x18,0x10,0xbd,0x18,0xbd ; $206a
	dc.b	0x18,0xbd,0x18,0x11,0xc6,0x18,0xc6,0x18 ; $2072
	dc.b	0xb4,0x18,0x12,0xcf,0x18,0xcf,0x18,0xcf ; $207a
	dc.b	0x18,0x13,0xd8,0x18,0xd8,0x18,0xd8,0x18 ; $2082
	dc.b	0x14,0xe1,0x18,0xe1,0x18,0xe1,0x18,0x15 ; $208a
	dc.b	0xe1,0x18,0xe1,0x18,0xe1,0x18,0x16,0xe1 ; $2092
	dc.b	0x18,0xe1,0x18,0xe1,0x18,0x17,0xea,0x18 ; $209a
	dc.b	0xea,0x18,0xea,0x18,0x18,0xab,0x18,0xab ; $20a2
	dc.b	0x18,0xab,0x18,0xff,0xbf,0x0a,0xbf,0x0a ; $20aa
	dc.b	0xbf,0x0a,0x00,0xc8,0x0a,0xc8,0x0a,0xc8 ; $20b2
	dc.b	0x0a,0x01,0xf3,0x18,0xfc,0x18,0xfc,0x18 ; $20ba
	dc.b	0x02,0x05,0x19,0x0e,0x19,0x0e,0x19,0x03 ; $20c2
	dc.b	0x17,0x19,0x17,0x19,0x17,0x19,0x04,0x20 ; $20ca
	dc.b	0x19,0x20,0x19,0x20,0x19,0x05,0x29,0x19 ; $20d2
	dc.b	0x29,0x19,0x29,0x19,0x06,0x29,0x19,0x29 ; $20da
	dc.b	0x19,0x29,0x19,0x07,0x32,0x99,0x29,0x19 ; $20e2
	dc.b	0x29,0x19,0x08,0x3b,0x19,0x3b,0x19,0x3b ; $20ea
	dc.b	0x19,0x09,0x44,0x19,0x44,0x19,0x44,0x19 ; $20f2
	dc.b	0x0a,0x28,0x0e,0x28,0x0e,0x4d,0x19,0x0b ; $20fa
	dc.b	0x56,0x19,0x56,0x19,0x56,0x19,0x0c,0x5f ; $2102
	dc.b	0x19,0x5f,0x19,0x28,0x0e,0x0d,0x68,0x19 ; $210a
	dc.b	0x68,0x19,0x68,0x19,0x0e,0x71,0x19,0x71 ; $2112
	dc.b	0x19,0x71,0x19,0x0f,0x7a,0x19,0x7a,0x19 ; $211a
	dc.b	0x7a,0x19,0x10,0x83,0x19,0x83,0x19,0x83 ; $2122
	dc.b	0x19,0x11,0x8c,0x19,0x8c,0x19,0x7a,0x19 ; $212a
	dc.b	0x12,0x95,0x19,0x95,0x19,0x95,0x19,0x13 ; $2132
	dc.b	0x9e,0x19,0x9e,0x19,0x9e,0x19,0x14,0x26 ; $213a
	dc.b	0x13,0x26,0x13,0x26,0x13,0x15,0x26,0x13 ; $2142
	dc.b	0x26,0x13,0x26,0x13,0x16,0x26,0x13,0x26 ; $214a
	dc.b	0x13,0x26,0x13,0x17,0xa7,0x19,0xa7,0x19 ; $2152
	dc.b	0xa7,0x19,0x18,0x71,0x19,0x71,0x19,0x71 ; $215a
	dc.b	0x19,0xff,0xc8,0x0a,0xc8,0x0a,0xc8,0x0a ; $2162
	dc.b	0xff,0x92,0x0a,0x92,0x0a,0x92,0x0a,0xff ; $216a
	dc.b	0xbf,0x0a,0xbf,0x0a,0xbf,0x0a,0xff,0xb6 ; $2172
	dc.b	0x0a,0xb6,0x0a,0xb6,0x0a,0xff,0xc8,0x0a ; $217a
	dc.b	0xc8,0x0a,0xc8,0x0a,0xff,0xfe,0x0a,0xfe ; $2182
	dc.b	0x0a,0xfe,0x0a,0x08,0x58,0x0b,0x58,0x0b ; $218a
	dc.b	0x58,0x0b,0x0d,0xe1,0x0f,0xe1,0x0f,0xe1 ; $2192
	dc.b	0x0f,0x12,0x33,0x12,0x33,0x12,0x33,0x12 ; $219a
	dc.b	0x17,0x9b,0x13,0x9b,0x13,0x9b,0x13,0x03 ; $21a2
	dc.b	0x07,0x0b,0x07,0x0b,0x07,0x0b,0xff,0x4f ; $21aa
	dc.b	0x0b,0x4f,0x0b,0x4f,0x0b,0x03,0x10,0x0b ; $21b2
	dc.b	0x10,0x0b,0x10,0x0b,0x08,0x61,0x0b,0x61 ; $21ba
	dc.b	0x0b,0x61,0x0b,0x0d,0xea,0x0f,0xea,0x0f ; $21c2
	dc.b	0xea,0x0f,0x12,0x3c,0x12,0x3c,0x12,0x3c ; $21ca
	dc.b	0x12,0x17,0xa4,0x13,0xa4,0x13,0xa4,0x13 ; $21d2
	dc.b	0xff,0x46,0x0b,0x46,0x0b,0x46,0x0b,0x03 ; $21da
	dc.b	0x19,0x0b,0x19,0x0b,0x19,0x0b,0x08,0x6a ; $21e2
	dc.b	0x0b,0x6a,0x0b,0x6a,0x0b,0x0d,0xf3,0x0f ; $21ea
	dc.b	0xf3,0x0f,0xf3,0x0f,0x12,0x3c,0x12,0x3c ; $21f2
	dc.b	0x12,0x3c,0x12,0x17,0xad,0x13,0xad,0x13 ; $21fa
	dc.b	0xad,0x13,0xff,0x3d,0x0b,0x3d,0x0b,0x3d ; $2202
	dc.b	0x0b,0x0d,0xfc,0x0f,0xfc,0x0f,0xfc,0x0f ; $220a
	dc.b	0x17,0xb6,0x13,0xb6,0x13,0xb6,0x13,0x03 ; $2212
	dc.b	0x22,0x0b,0x22,0x0b,0x22,0x0b,0xff,0x34 ; $221a
	dc.b	0x0b,0x34,0x0b,0x34,0x0b,0x03,0x8e,0x0b ; $2222
	dc.b	0x8e,0x0b,0x8e,0x0b,0xff,0x2b,0x0b,0x2b ; $222a
	dc.b	0x0b,0x2b,0x0b,0xff,0x34,0x0b,0x34,0x0b ; $2232
	dc.b	0x34,0x0b,0xff,0x3d,0x0b,0x3d,0x0b,0x3d ; $223a
	dc.b	0x0b,0xff,0x46,0x0b,0x46,0x0b,0x46,0x0b ; $2242
	dc.b	0xff,0x4f,0x0b,0x4f,0x0b,0x4f,0x0b,0xff ; $224a
	dc.b	0x89,0x0a,0x89,0x0a,0x89,0x0a,0x08,0x23 ; $2252
	dc.b	0x0d,0x23,0x0d,0x23,0x0d,0xff,0xa1,0x0d ; $225a
	dc.b	0xa1,0x0d,0xa1,0x0d,0x08,0x2c,0x0d,0x2c ; $2262
	dc.b	0x0d,0x2c,0x0d,0xff,0x98,0x0d,0x98,0x0d ; $226a
	dc.b	0x98,0x0d,0x08,0x35,0x0d,0x35,0x0d,0x35 ; $2272
	dc.b	0x0d,0xff,0x8f,0x0d,0x8f,0x0d,0x8f,0x0d ; $227a
	dc.b	0xff,0x7c,0x0b,0x7c,0x0b,0x7c,0x0b,0xff ; $2282
	dc.b	0x85,0x0b,0x85,0x0b,0x85,0x0b,0xff,0x89 ; $228a
	dc.b	0x0a,0x89,0x0a,0x89,0x0a,0x03,0x97,0x0b ; $2292
	dc.b	0x97,0x0b,0x97,0x0b,0xff,0x73,0x0b,0x73 ; $229a
	dc.b	0x0b,0x73,0x0b,0x03,0xa0,0x0b,0xa0,0x0b ; $22a2
	dc.b	0xa0,0x0b,0xff,0xfa,0x0b,0xfa,0x0b,0xfa ; $22aa
	dc.b	0x0b,0x03,0xa9,0x0b,0xa9,0x0b,0xa9,0x0b ; $22b2
	dc.b	0xff,0xf1,0x0b,0xf1,0x0b,0xf1,0x0b,0x03 ; $22ba
	dc.b	0xb2,0x0b,0xb2,0x0b,0xb2,0x0b,0xff,0xe8 ; $22c2
	dc.b	0x0b,0xe8,0x0b,0xe8,0x0b,0x03,0xbb,0x0b ; $22ca
	dc.b	0xbb,0x0b,0xbb,0x0b,0xff,0xdf,0x0b,0xdf ; $22d2
	dc.b	0x0b,0xdf,0x0b,0x03,0xc4,0x0b,0xc4,0x0b ; $22da
	dc.b	0xc4,0x0b,0xff,0xd6,0x0b,0xd6,0x0b,0xd6 ; $22e2
	dc.b	0x0b,0xff,0xcd,0x0b,0xcd,0x0b,0xcd,0x0b ; $22ea
	dc.b	0xff,0xd6,0x0b,0xd6,0x0b,0xd6,0x0b,0xff ; $22f2
	dc.b	0xdf,0x0b,0xdf,0x0b,0xdf,0x0b,0xff,0xe8 ; $22fa
	dc.b	0x0b,0xe8,0x0b,0xe8,0x0b,0xff,0xf1,0x0b ; $2302
	dc.b	0xf1,0x0b,0xf1,0x0b,0xff,0xfa,0x0b,0xfa ; $230a
	dc.b	0x0b,0xfa,0x0b,0xff,0x73,0x0b,0x73,0x0b ; $2312
	dc.b	0x73,0x0b,0xff,0x0c,0x0c,0x0c,0x0c,0x0c ; $231a
	dc.b	0x0c,0x04,0x15,0x0c,0x15,0x0c,0x15,0x0c ; $2322
	dc.b	0x09,0x81,0x0c,0x81,0x0c,0x81,0x0c,0x0e ; $232a
	dc.b	0x4b,0x0c,0x4b,0x0c,0x4b,0x0c,0x13,0x8a ; $2332
	dc.b	0x0c,0x8a,0x0c,0x8a,0x0c,0x18,0x4b,0x0c ; $233a
	dc.b	0x4b,0x0c,0x4b,0x0c,0xff,0x42,0x0c,0x42 ; $2342
	dc.b	0x0c,0x42,0x0c,0x04,0x1e,0x0c,0x1e,0x0c ; $234a
	dc.b	0x1e,0x0c,0x09,0x6f,0x0c,0x6f,0x0c,0x6f ; $2352
	dc.b	0x0c,0x0e,0x66,0x0c,0x66,0x0c,0x66,0x0c ; $235a
	dc.b	0x13,0x54,0x0c,0x54,0x0c,0x54,0x0c,0x18 ; $2362
	dc.b	0x66,0x0c,0x66,0x0c,0x66,0x0c,0xff,0x39 ; $236a
	dc.b	0x0c,0x39,0x0c,0x39,0x0c,0xff,0x27,0x0c ; $2372
	dc.b	0x27,0x0c,0x27,0x0c,0x04,0x27,0x0c,0x27 ; $237a
	dc.b	0x0c,0x27,0x0c,0x09,0x5d,0x0c,0x5d,0x0c ; $2382
	dc.b	0x5d,0x0c,0x0e,0x5d,0x0c,0x5d,0x0c,0x5d ; $238a
	dc.b	0x0c,0x13,0x5d,0x0c,0x5d,0x0c,0x5d,0x0c ; $2392
	dc.b	0x18,0x5d,0x0c,0x5d,0x0c,0x5d,0x0c,0xff ; $239a
	dc.b	0x30,0x0c,0x30,0x0c,0x30,0x0c,0x04,0x1e ; $23a2
	dc.b	0x0c,0x1e,0x0c,0x1e,0x0c,0xff,0x39,0x0c ; $23aa
	dc.b	0x39,0x0c,0x39,0x0c,0x04,0x15,0x0c,0x15 ; $23b2
	dc.b	0x0c,0x15,0x0c,0xff,0x42,0x0c,0x42,0x0c ; $23ba
	dc.b	0x42,0x0c,0xff,0x89,0x0a,0x89,0x0a,0x89 ; $23c2
	dc.b	0x0a,0x0e,0x8c,0x10,0x8c,0x10,0x8c,0x10 ; $23ca
	dc.b	0x18,0x8c,0x10,0x8c,0x10,0x8c,0x10,0xff ; $23d2
	dc.b	0xcb,0x10,0xcb,0x10,0xcb,0x10,0x13,0xd5 ; $23da
	dc.b	0x12,0xd5,0x12,0xd5,0x12,0xff,0xf0,0x12 ; $23e2
	dc.b	0xf0,0x12,0xf0,0x12,0x09,0x6f,0x0c,0x6f ; $23ea
	dc.b	0x0c,0x6f,0x0c,0x0e,0x66,0x0c,0x66,0x0c ; $23f2
	dc.b	0x66,0x0c,0x13,0x78,0x0c,0x78,0x0c,0x78 ; $23fa
	dc.b	0x0c,0x18,0x66,0x0c,0x66,0x0c,0x66,0x0c ; $2402
	dc.b	0xff,0x39,0x0c,0x39,0x0c,0x39,0x0c,0x0e ; $240a
	dc.b	0x8c,0x10,0x8c,0x10,0x8c,0x10,0x18,0x8c ; $2412
	dc.b	0x10,0x8c,0x10,0x8c,0x10,0xff,0xcb,0x10 ; $241a
	dc.b	0xcb,0x10,0xcb,0x10,0x09,0xce,0x0d,0xce ; $2422
	dc.b	0x0d,0xce,0x0d,0xff,0xfb,0x0d,0xfb,0x0d ; $242a
	dc.b	0xfb,0x0d,0x13,0xd5,0x12,0xd5,0x12,0xd5 ; $2432
	dc.b	0x12,0xff,0xf0,0x12,0xf0,0x12,0xf0,0x12 ; $243a
	dc.b	0x09,0xbc,0x0d,0xbc,0x0d,0xbc,0x0d,0xff ; $2442
	dc.b	0x0d,0x0e,0x0d,0x0e,0x0d,0x0e,0x13,0xcc ; $244a
	dc.b	0x12,0xcc,0x12,0xcc,0x12,0xff,0x93,0x0c ; $2452
	dc.b	0x93,0x0c,0x93,0x0c,0xff,0x89,0x0a,0x89 ; $245a
	dc.b	0x0a,0x89,0x0a,0x06,0xa5,0x0c,0xa5,0x0c ; $2462
	dc.b	0xa5,0x0c,0x05,0xa5,0x0c,0xa5,0x0c,0xa5 ; $246a
	dc.b	0x0c,0x07,0xa5,0x0c,0xa5,0x0c,0xa5,0x0c ; $2472
	dc.b	0xff,0x08,0x0d,0x08,0x0d,0x08,0x0d,0x05 ; $247a
	dc.b	0xae,0x0c,0xae,0x0c,0xae,0x0c,0x06,0xae ; $2482
	dc.b	0x0c,0xae,0x0c,0xae,0x0c,0x07,0xae,0x0c ; $248a
	dc.b	0xae,0x0c,0xae,0x0c,0xff,0xff,0x0c,0xff ; $2492
	dc.b	0x0c,0xff,0x0c,0x05,0xb7,0x0c,0xb7,0x0c ; $249a
	dc.b	0xb7,0x0c,0x06,0xb7,0x0c,0xb7,0x0c,0xb7 ; $24a2
	dc.b	0x0c,0x07,0xb7,0x0c,0xb7,0x0c,0xb7,0x0c ; $24aa
	dc.b	0xff,0xf6,0x0c,0xf6,0x0c,0xf6,0x0c,0x05 ; $24b2
	dc.b	0xc0,0x0c,0xc0,0x0c,0xc0,0x0c,0x06,0xd2 ; $24ba
	dc.b	0x0c,0xd2,0x0c,0xd2,0x0c,0x07,0xc0,0x0c ; $24c2
	dc.b	0xc0,0x0c,0xc0,0x0c,0xff,0xed,0x0c,0xed ; $24ca
	dc.b	0x0c,0xed,0x0c,0xff,0xc9,0x0c,0xc9,0x0c ; $24d2
	dc.b	0xc9,0x0c,0x05,0xc9,0x0c,0xc9,0x0c,0xc9 ; $24da
	dc.b	0x0c,0x07,0xc9,0x0c,0xc9,0x0c,0xc9,0x0c ; $24e2
	dc.b	0xff,0xe4,0x0c,0xe4,0x0c,0xe4,0x0c,0xff ; $24ea
	dc.b	0xdb,0x0c,0xdb,0x0c,0xdb,0x0c,0x06,0xdb ; $24f2
	dc.b	0x0c,0xdb,0x0c,0xdb,0x0c,0xff,0xe4,0x0c ; $24fa
	dc.b	0xe4,0x0c,0xe4,0x0c,0xff,0xf6,0x0c,0xf6 ; $2502
	dc.b	0x0c,0xf6,0x0c,0xff,0xf6,0x0c,0xf6,0x0c ; $250a
	dc.b	0xf6,0x0c,0xff,0xff,0x0c,0xff,0x0c,0xff ; $2512
	dc.b	0x0c,0xff,0x08,0x0d,0x08,0x0d,0x08,0x0d ; $251a
	dc.b	0xff,0x89,0x0a,0x89,0x0a,0x89,0x0a,0xff ; $2522
	dc.b	0x89,0x0a,0x89,0x0a,0x89,0x0a,0x08,0x23 ; $252a
	dc.b	0x0d,0x23,0x0d,0x23,0x0d,0xff,0xa1,0x0d ; $2532
	dc.b	0xa1,0x0d,0xa1,0x0d,0x08,0x2c,0x0d,0x2c ; $253a
	dc.b	0x0d,0x2c,0x0d,0xff,0x98,0x0d,0x98,0x0d ; $2542
	dc.b	0x98,0x0d,0x08,0x35,0x0d,0x35,0x0d,0x35 ; $254a
	dc.b	0x0d,0xff,0x8f,0x0d,0x8f,0x0d,0x8f,0x0d ; $2552
	dc.b	0x08,0x3e,0x0d,0x3e,0x0d,0x3e,0x0d,0xff ; $255a
	dc.b	0x86,0x0d,0x86,0x0d,0x86,0x0d,0x08,0x47 ; $2562
	dc.b	0x0d,0x47,0x0d,0x47,0x0d,0xff,0x7d,0x0d ; $256a
	dc.b	0x7d,0x0d,0x7d,0x0d,0xff,0x50,0x0d,0x50 ; $2572
	dc.b	0x0d,0x50,0x0d,0xff,0x59,0x0d,0x59,0x0d ; $257a
	dc.b	0x59,0x0d,0xff,0x62,0x0d,0x62,0x0d,0x62 ; $2582
	dc.b	0x0d,0xff,0x6b,0x0d,0x6b,0x0d,0x6b,0x0d ; $258a
	dc.b	0xff,0x74,0x8d,0x74,0x8d,0x74,0x8d,0xff ; $2592
	dc.b	0x69,0x1b,0x69,0x1b,0x69,0x1b,0xff,0x86 ; $259a
	dc.b	0x0d,0x86,0x0d,0x86,0x0d,0xff,0x8f,0x0d ; $25a2
	dc.b	0x8f,0x0d,0x8f,0x0d,0xff,0x98,0x0d,0x98 ; $25aa
	dc.b	0x0d,0x98,0x0d,0xff,0xa1,0x0d,0xa1,0x0d ; $25b2
	dc.b	0xa1,0x0d,0xff,0x89,0x0a,0x89,0x0a,0x89 ; $25ba
	dc.b	0x0a,0x09,0xb3,0x0d,0xb3,0x0d,0xb3,0x0d ; $25c2
	dc.b	0xff,0x16,0x0e,0x16,0x0e,0x16,0x0e,0x09 ; $25ca
	dc.b	0xbc,0x0d,0xbc,0x0d,0xbc,0x0d,0xff,0x0d ; $25d2
	dc.b	0x0e,0x0d,0x0e,0x0d,0x0e,0x09,0xc5,0x0d ; $25da
	dc.b	0xc5,0x0d,0xc5,0x0d,0xff,0x04,0x0e,0x04 ; $25e2
	dc.b	0x0e,0x04,0x0e,0x09,0xce,0x0d,0xce,0x0d ; $25ea
	dc.b	0xce,0x0d,0xff,0xfb,0x0d,0xfb,0x0d,0xfb ; $25f2
	dc.b	0x0d,0x09,0xd7,0x0d,0xd7,0x0d,0xd7,0x0d ; $25fa
	dc.b	0xff,0xf2,0x0d,0xf2,0x0d,0xf2,0x0d,0xff ; $2602
	dc.b	0xe0,0x0d,0xe0,0x0d,0xe0,0x0d,0x09,0xe0 ; $260a
	dc.b	0x0d,0xe0,0x0d,0xe0,0x0d,0xff,0xe9,0x0d ; $2612
	dc.b	0xe9,0x0d,0xe9,0x0d,0xff,0xf2,0x0d,0xf2 ; $261a
	dc.b	0x0d,0xf2,0x0d,0x04,0x45,0x1b,0x45,0x1b ; $2622
	dc.b	0x45,0x1b,0x0e,0x45,0x1b,0x45,0x1b,0x45 ; $262a
	dc.b	0x1b,0x13,0x45,0x1b,0x45,0x1b,0x45,0x1b ; $2632
	dc.b	0x18,0x45,0x1b,0x45,0x1b,0x45,0x1b,0xff ; $263a
	dc.b	0xfb,0x0d,0xfb,0x0d,0xfb,0x0d,0xff,0x04 ; $2642
	dc.b	0x0e,0x04,0x0e,0x04,0x0e,0xff,0x0d,0x0e ; $264a
	dc.b	0x0d,0x0e,0x0d,0x0e,0xff,0x16,0x0e,0x16 ; $2652
	dc.b	0x0e,0x16,0x0e,0xff,0x89,0x0a,0x89,0x0a ; $265a
	dc.b	0x89,0x0a,0x0a,0x28,0x0e,0x28,0x0e,0x28 ; $2662
	dc.b	0x0e,0x0c,0x28,0x0e,0x28,0x0e,0x28,0x0e ; $266a
	dc.b	0xff,0x8b,0x0e,0x8b,0x0e,0x8b,0x0e,0x0a ; $2672
	dc.b	0x31,0x0e,0x31,0x0e,0x31,0x0e,0x0c,0x31 ; $267a
	dc.b	0x0e,0x31,0x0e,0x31,0x0e,0xff,0x82,0x0e ; $2682
	dc.b	0x82,0x0e,0x82,0x0e,0x0a,0x3a,0x0e,0x3a ; $268a
	dc.b	0x0e,0x3a,0x0e,0x0c,0x3a,0x0e,0x3a,0x0e ; $2692
	dc.b	0x3a,0x0e,0xff,0x79,0x0e,0x79,0x0e,0x79 ; $269a
	dc.b	0x0e,0x0a,0x43,0x0e,0x43,0x0e,0x43,0x0e ; $26a2
	dc.b	0x0c,0x43,0x0e,0x43,0x0e,0x43,0x0e,0xff ; $26aa
	dc.b	0x70,0x0e,0x70,0x0e,0x70,0x0e,0x0a,0x4c ; $26b2
	dc.b	0x0e,0x4c,0x0e,0x4c,0x0e,0x0c,0x4c,0x0e ; $26ba
	dc.b	0x4c,0x0e,0x4c,0x0e,0xff,0x67,0x0e,0x67 ; $26c2
	dc.b	0x0e,0x67,0x0e,0xff,0x55,0x0e,0x55,0x0e ; $26ca
	dc.b	0x55,0x0e,0x0a,0x55,0x0e,0x55,0x0e,0x55 ; $26d2
	dc.b	0x0e,0x0c,0x55,0x0e,0x55,0x0e,0x55,0x0e ; $26da
	dc.b	0xff,0x5e,0x0e,0x5e,0x0e,0x5e,0x0e,0xff ; $26e2
	dc.b	0x79,0x0e,0x79,0x0e,0x79,0x0e,0xff,0x70 ; $26ea
	dc.b	0x0e,0x70,0x0e,0x70,0x0e,0xff,0x79,0x0e ; $26f2
	dc.b	0x79,0x0e,0x79,0x0e,0xff,0x82,0x0e,0x82 ; $26fa
	dc.b	0x0e,0x82,0x0e,0xff,0x8b,0x0e,0x8b,0x0e ; $2702
	dc.b	0x8b,0x0e,0xff,0x89,0x0a,0x89,0x0a,0x89 ; $270a
	dc.b	0x0a,0x0a,0x9d,0x0e,0x9d,0x0e,0x9d,0x0e ; $2712
	dc.b	0xff,0xdc,0x0e,0xdc,0x0e,0xdc,0x0e,0x0a ; $271a
	dc.b	0xa6,0x0e,0xa6,0x0e,0xa6,0x0e,0xff,0xd3 ; $2722
	dc.b	0x0e,0xd3,0x0e,0xd3,0x0e,0x0a,0xaf,0x0e ; $272a
	dc.b	0xaf,0x0e,0xaf,0x0e,0xff,0xca,0x0e,0xca ; $2732
	dc.b	0x0e,0xca,0x0e,0xff,0xb8,0x0e,0xb8,0x0e ; $273a
	dc.b	0xb8,0x0e,0x0a,0xb8,0x0e,0xb8,0x0e,0xb8 ; $2742
	dc.b	0x0e,0xff,0xc1,0x0e,0xc1,0x0e,0xc1,0x0e ; $274a
	dc.b	0xff,0xd3,0x0e,0xd3,0x0e,0xd3,0x0e,0xff ; $2752
	dc.b	0xd3,0x0e,0xd3,0x0e,0xd3,0x0e,0xff,0xdc ; $275a
	dc.b	0x0e,0xdc,0x0e,0xdc,0x0e,0xff,0x89,0x0a ; $2762
	dc.b	0x89,0x0a,0x89,0x0a,0x0b,0xee,0x0e,0xee ; $276a
	dc.b	0x0e,0xee,0x0e,0xff,0x5a,0x0f,0x5a,0x0f ; $2772
	dc.b	0x5a,0x0f,0x0b,0xf7,0x0e,0xf7,0x0e,0xf7 ; $277a
	dc.b	0x0e,0xff,0x51,0x0f,0x51,0x0f,0x51,0x0f ; $2782
	dc.b	0x0b,0x00,0x0f,0x00,0x0f,0x00,0x0f,0xff ; $278a
	dc.b	0x48,0x0f,0x48,0x0f,0x48,0x0f,0x0b,0x09 ; $2792
	dc.b	0x0f,0x09,0x0f,0x09,0x0f,0xff,0x3f,0x0f ; $279a
	dc.b	0x3f,0x0f,0x3f,0x0f,0x0b,0x12,0x0f,0x12 ; $27a2
	dc.b	0x0f,0x12,0x0f,0xff,0x36,0x0f,0x36,0x0f ; $27aa
	dc.b	0x36,0x0f,0x0b,0x1b,0x0f,0x1b,0x0f,0x1b ; $27b2
	dc.b	0x0f,0xff,0x2d,0x0f,0x2d,0x0f,0x2d,0x0f ; $27ba
	dc.b	0xff,0x24,0x0f,0x24,0x0f,0x24,0x0f,0x0b ; $27c2
	dc.b	0x24,0x0f,0x24,0x0f,0x24,0x0f,0xff,0x57 ; $27ca
	dc.b	0x1b,0x57,0x1b,0x57,0x1b,0xff,0x36,0x0f ; $27d2
	dc.b	0x36,0x0f,0x36,0x0f,0xff,0x3f,0x0f,0x3f ; $27da
	dc.b	0x0f,0x3f,0x0f,0xff,0x48,0x0f,0x48,0x0f ; $27e2
	dc.b	0x48,0x0f,0xff,0x51,0x0f,0x51,0x0f,0x51 ; $27ea
	dc.b	0x0f,0xff,0x5a,0x0f,0x5a,0x0f,0x5a,0x0f ; $27f2
	dc.b	0xff,0x89,0x0a,0x89,0x0a,0x89,0x0a,0x0c ; $27fa
	dc.b	0x6c,0x0f,0x6c,0x0f,0x6c,0x0f,0xff,0xcf ; $2802
	dc.b	0x0f,0xcf,0x0f,0xcf,0x0f,0x0c,0x75,0x0f ; $280a
	dc.b	0x75,0x0f,0x75,0x0f,0xff,0xc6,0x0f,0xc6 ; $2812
	dc.b	0x0f,0xc6,0x0f,0x0c,0x7e,0x0f,0x7e,0x0f ; $281a
	dc.b	0x7e,0x0f,0xff,0xbd,0x0f,0xbd,0x0f,0xbd ; $2822
	dc.b	0x0f,0x0c,0x87,0x0f,0x87,0x0f,0x87,0x0f ; $282a
	dc.b	0xff,0xb4,0x0f,0xb4,0x0f,0xb4,0x0f,0x0c ; $2832
	dc.b	0x90,0x0f,0x90,0x0f,0x90,0x0f,0xff,0xab ; $283a
	dc.b	0x0f,0xab,0x0f,0xab,0x0f,0xff,0x99,0x0f ; $2842
	dc.b	0x99,0x0f,0x99,0x0f,0x0c,0x99,0x0f,0x99 ; $284a
	dc.b	0x0f,0x99,0x0f,0xff,0xa2,0x0f,0xa2,0x0f ; $2852
	dc.b	0xa2,0x0f,0xff,0xbd,0x0f,0xbd,0x0f,0xbd ; $285a
	dc.b	0x0f,0xff,0xb4,0x0f,0xb4,0x0f,0xb4,0x0f ; $2862
	dc.b	0xff,0xbd,0x0f,0xbd,0x0f,0xbd,0x0f,0xff ; $286a
	dc.b	0xc6,0x0f,0xc6,0x0f,0xc6,0x0f,0xff,0xcf ; $2872
	dc.b	0x0f,0xcf,0x0f,0xcf,0x0f,0xff,0x89,0x0a ; $287a
	dc.b	0x89,0x0a,0x89,0x0a,0x0d,0xe1,0x0f,0xe1 ; $2882
	dc.b	0x0f,0xe1,0x0f,0xff,0x68,0x10,0x68,0x10 ; $288a
	dc.b	0x68,0x10,0x0d,0xea,0x0f,0xea,0x0f,0xea ; $2892
	dc.b	0x0f,0xff,0x5f,0x10,0x5f,0x10,0x5f,0x10 ; $289a
	dc.b	0x0d,0xf3,0x0f,0xf3,0x0f,0xf3,0x0f,0xff ; $28a2
	dc.b	0x56,0x10,0x56,0x10,0x56,0x10,0x0d,0xfc ; $28aa
	dc.b	0x0f,0xfc,0x0f,0xfc,0x0f,0xff,0x4d,0x10 ; $28b2
	dc.b	0x4d,0x10,0x4d,0x10,0x0d,0x05,0x10,0x05 ; $28ba
	dc.b	0x10,0x05,0x10,0xff,0x44,0x10,0x44,0x10 ; $28c2
	dc.b	0x44,0x10,0x0d,0x0e,0x10,0x0e,0x10,0x0e ; $28ca
	dc.b	0x10,0xff,0x3b,0x10,0x3b,0x10,0x3b,0x10 ; $28d2
	dc.b	0xff,0x17,0x10,0x17,0x10,0x17,0x10,0xff ; $28da
	dc.b	0x20,0x10,0x20,0x10,0x20,0x10,0xff,0x29 ; $28e2
	dc.b	0x10,0x29,0x10,0x29,0x10,0xff,0x32,0x10 ; $28ea
	dc.b	0x32,0x10,0x32,0x10,0xff,0x60,0x1b,0x60 ; $28f2
	dc.b	0x1b,0x60,0x1b,0xff,0x44,0x10,0x44,0x10 ; $28fa
	dc.b	0x44,0x10,0xff,0x4d,0x10,0x4d,0x10,0x4d ; $2902
	dc.b	0x10,0xff,0x56,0x10,0x56,0x10,0x56,0x10 ; $290a
	dc.b	0xff,0x5f,0x10,0x5f,0x10,0x5f,0x10,0xff ; $2912
	dc.b	0x68,0x10,0x68,0x10,0x68,0x10,0xff,0x89 ; $291a
	dc.b	0x0a,0x89,0x0a,0x89,0x0a,0x0e,0x7a,0x10 ; $2922
	dc.b	0x7a,0x10,0x7a,0x10,0x18,0x7a,0x10,0x7a ; $292a
	dc.b	0x10,0x7a,0x10,0xff,0xdd,0x10,0xdd,0x10 ; $2932
	dc.b	0xdd,0x10,0x0e,0x83,0x10,0x83,0x10,0x83 ; $293a
	dc.b	0x10,0x18,0x83,0x10,0x83,0x10,0x83,0x10 ; $2942
	dc.b	0xff,0xd4,0x10,0xd4,0x10,0xd4,0x10,0x0e ; $294a
	dc.b	0x8c,0x10,0x8c,0x10,0x8c,0x10,0x18,0x8c ; $2952
	dc.b	0x10,0x8c,0x10,0x8c,0x10,0xff,0xcb,0x10 ; $295a
	dc.b	0xcb,0x10,0xcb,0x10,0x0e,0x95,0x10,0x95 ; $2962
	dc.b	0x10,0x95,0x10,0x18,0x95,0x10,0x95,0x10 ; $296a
	dc.b	0x95,0x10,0xff,0xc2,0x10,0xc2,0x10,0xc2 ; $2972
	dc.b	0x10,0x0e,0x9e,0x10,0x9e,0x10,0x9e,0x10 ; $297a
	dc.b	0x18,0x9e,0x10,0x9e,0x10,0x9e,0x10,0xff ; $2982
	dc.b	0xb9,0x10,0xb9,0x10,0xb9,0x10,0xff,0xa7 ; $298a
	dc.b	0x10,0xa7,0x10,0xa7,0x10,0x0e,0xa7,0x10 ; $2992
	dc.b	0xa7,0x10,0xa7,0x10,0x18,0xa7,0x10,0xa7 ; $299a
	dc.b	0x10,0xa7,0x10,0xff,0xb0,0x10,0xb0,0x10 ; $29a2
	dc.b	0xb0,0x10,0xff,0xb9,0x10,0xb9,0x10,0xb9 ; $29aa
	dc.b	0x10,0xff,0xc2,0x10,0xc2,0x10,0xc2,0x10 ; $29b2
	dc.b	0x04,0x4e,0x1b,0x4e,0x1b,0x4e,0x1b,0x09 ; $29ba
	dc.b	0x4e,0x1b,0x4e,0x1b,0x4e,0x1b,0x18,0x4e ; $29c2
	dc.b	0x1b,0x4e,0x1b,0x4e,0x1b,0xff,0xcb,0x10 ; $29ca
	dc.b	0xcb,0x10,0xcb,0x10,0xff,0xd4,0x10,0xd4 ; $29d2
	dc.b	0x10,0xd4,0x10,0xff,0xdd,0x10,0xdd,0x10 ; $29da
	dc.b	0xdd,0x10,0xff,0x89,0x0a,0x89,0x0a,0x89 ; $29e2
	dc.b	0x0a,0x0f,0xef,0x10,0xef,0x10,0xef,0x10 ; $29ea
	dc.b	0x11,0xef,0x10,0xef,0x10,0xef,0x10,0xff ; $29f2
	dc.b	0x40,0x11,0x40,0x11,0x40,0x11,0x0f,0xf8 ; $29fa
	dc.b	0x10,0xf8,0x10,0xf8,0x10,0x11,0xf8,0x10 ; $2a02
	dc.b	0xf8,0x10,0xf8,0x10,0xff,0x37,0x11,0x37 ; $2a0a
	dc.b	0x11,0x37,0x11,0x0f,0x01,0x11,0x01,0x11 ; $2a12
	dc.b	0x01,0x11,0x11,0x01,0x11,0x01,0x11,0x01 ; $2a1a
	dc.b	0x11,0xff,0x2e,0x11,0x2e,0x11,0x2e,0x11 ; $2a22
	dc.b	0x0f,0x0a,0x11,0x0a,0x11,0x0a,0x11,0x11 ; $2a2a
	dc.b	0x0a,0x11,0x0a,0x11,0x0a,0x11,0xff,0x25 ; $2a32
	dc.b	0x11,0x25,0x11,0x25,0x11,0xff,0x13,0x11 ; $2a3a
	dc.b	0x13,0x11,0x13,0x11,0x0f,0x13,0x11,0x13 ; $2a42
	dc.b	0x11,0x13,0x11,0x11,0x13,0x11,0x13,0x11 ; $2a4a
	dc.b	0x13,0x11,0xff,0x1c,0x11,0x1c,0x11,0x1c ; $2a52
	dc.b	0x11,0xff,0x25,0x11,0x25,0x11,0x25,0x11 ; $2a5a
	dc.b	0xff,0x2e,0x11,0x2e,0x11,0x2e,0x11,0xff ; $2a62
	dc.b	0x37,0x11,0x37,0x11,0x37,0x11,0xff,0x40 ; $2a6a
	dc.b	0x11,0x40,0x11,0x40,0x11,0xff,0x89,0x0a ; $2a72
	dc.b	0x89,0x0a,0x89,0x0a,0x0f,0x52,0x11,0x52 ; $2a7a
	dc.b	0x11,0x52,0x11,0x10,0x52,0x11,0x52,0x11 ; $2a82
	dc.b	0x52,0x11,0xff,0xac,0x11,0xac,0x11,0xac ; $2a8a
	dc.b	0x11,0x0f,0xb0,0x19,0xb0,0x19,0xb0,0x19 ; $2a92
	dc.b	0x10,0xb0,0x19,0xb0,0x19,0xb0,0x19,0xff ; $2a9a
	dc.b	0xa3,0x11,0xa3,0x11,0xa3,0x11,0x0f,0x64 ; $2aa2
	dc.b	0x11,0x64,0x11,0x64,0x11,0x10,0x64,0x11 ; $2aaa
	dc.b	0x64,0x11,0x64,0x11,0xff,0x91,0x11,0x91 ; $2ab2
	dc.b	0x11,0x91,0x11,0x0f,0x6d,0x11,0x6d,0x11 ; $2aba
	dc.b	0x6d,0x11,0x10,0x6d,0x11,0x6d,0x11,0x6d ; $2ac2
	dc.b	0x11,0xff,0x88,0x11,0x88,0x11,0x88,0x11 ; $2aca
	dc.b	0xff,0x76,0x11,0x76,0x11,0x76,0x11,0x0f ; $2ad2
	dc.b	0x76,0x11,0x76,0x11,0x76,0x11,0x10,0x76 ; $2ada
	dc.b	0x11,0x76,0x11,0x76,0x11,0xff,0x7f,0x11 ; $2ae2
	dc.b	0x7f,0x11,0x7f,0x11,0xff,0x9a,0x11,0x9a ; $2aea
	dc.b	0x11,0x9a,0x11,0xff,0x91,0x11,0x91,0x11 ; $2af2
	dc.b	0x91,0x11,0xff,0x9a,0x11,0x9a,0x11,0x9a ; $2afa
	dc.b	0x11,0xff,0xa3,0x11,0xa3,0x11,0xa3,0x11 ; $2b02
	dc.b	0xff,0xac,0x11,0xac,0x11,0xac,0x11,0xff ; $2b0a
	dc.b	0x89,0x0a,0x89,0x0a,0x89,0x0a,0x11,0xbe ; $2b12
	dc.b	0x11,0xbe,0x11,0xbe,0x11,0xff,0x21,0x12 ; $2b1a
	dc.b	0x21,0x12,0x21,0x12,0x11,0xc7,0x11,0xc7 ; $2b22
	dc.b	0x11,0xc7,0x11,0xff,0x18,0x12,0x18,0x12 ; $2b2a
	dc.b	0x18,0x12,0x11,0xd0,0x11,0xd0,0x11,0xd0 ; $2b32
	dc.b	0x11,0xff,0x0f,0x12,0x0f,0x12,0x0f,0x12 ; $2b3a
	dc.b	0x11,0xd9,0x11,0xd9,0x11,0xd9,0x11,0xff ; $2b42
	dc.b	0x06,0x12,0x06,0x12,0x06,0x12,0x11,0xe2 ; $2b4a
	dc.b	0x11,0xe2,0x11,0xe2,0x11,0xff,0xfd,0x11 ; $2b52
	dc.b	0xfd,0x11,0xfd,0x11,0xff,0xeb,0x11,0xeb ; $2b5a
	dc.b	0x11,0xeb,0x11,0x11,0xeb,0x11,0xeb,0x11 ; $2b62
	dc.b	0xeb,0x11,0xff,0xf4,0x11,0xf4,0x11,0xf4 ; $2b6a
	dc.b	0x11,0xff,0x0f,0x12,0x0f,0x12,0x0f,0x12 ; $2b72
	dc.b	0xff,0x06,0x12,0x06,0x12,0x06,0x12,0xff ; $2b7a
	dc.b	0x0f,0x12,0x0f,0x12,0x0f,0x12,0xff,0x18 ; $2b82
	dc.b	0x12,0x18,0x12,0x18,0x12,0xff,0x21,0x12 ; $2b8a
	dc.b	0x21,0x12,0x21,0x12,0xff,0x89,0x0a,0x89 ; $2b92
	dc.b	0x0a,0x89,0x0a,0x12,0x33,0x12,0x33,0x12 ; $2b9a
	dc.b	0x33,0x12,0xff,0x9f,0x12,0x9f,0x12,0x9f ; $2ba2
	dc.b	0x12,0x12,0x3c,0x12,0x3c,0x12,0x3c,0x12 ; $2baa
	dc.b	0xff,0x96,0x12,0x96,0x12,0x96,0x12,0x12 ; $2bb2
	dc.b	0x45,0x12,0x45,0x12,0x45,0x12,0xff,0x8d ; $2bba
	dc.b	0x12,0x8d,0x12,0x8d,0x12,0xff,0x4e,0x12 ; $2bc2
	dc.b	0x4e,0x12,0x4e,0x12,0xff,0x57,0x12,0x57 ; $2bca
	dc.b	0x12,0x57,0x12,0xff,0x60,0x12,0x60,0x12 ; $2bd2
	dc.b	0x60,0x12,0xff,0x69,0x12,0x69,0x12,0x69 ; $2bda
	dc.b	0x12,0xff,0x72,0x12,0x72,0x12,0x72,0x12 ; $2be2
	dc.b	0xff,0x7b,0x12,0x7b,0x12,0x7b,0x12,0xff ; $2bea
	dc.b	0x84,0x12,0x84,0x12,0x84,0x12,0xff,0x89 ; $2bf2
	dc.b	0x0a,0x89,0x0a,0x89,0x0a,0xff,0x96,0x12 ; $2bfa
	dc.b	0x96,0x12,0x96,0x12,0xff,0x9f,0x12,0x9f ; $2c02
	dc.b	0x12,0x9f,0x12,0xff,0x89,0x0a,0x89,0x0a ; $2c0a
	dc.b	0x89,0x0a,0x13,0xb1,0x12,0xb1,0x12,0xb1 ; $2c12
	dc.b	0x12,0xff,0x14,0x13,0x14,0x13,0x14,0x13 ; $2c1a
	dc.b	0x13,0xba,0x12,0xba,0x12,0xba,0x12,0xff ; $2c22
	dc.b	0x0b,0x13,0x0b,0x13,0x0b,0x13,0x13,0xc3 ; $2c2a
	dc.b	0x12,0xc3,0x12,0xc3,0x12,0xff,0x02,0x13 ; $2c32
	dc.b	0x02,0x13,0x02,0x13,0x13,0xcc,0x12,0xcc ; $2c3a
	dc.b	0x12,0xcc,0x12,0xff,0xf9,0x12,0xf9,0x12 ; $2c42
	dc.b	0xf9,0x12,0x13,0xd5,0x12,0xd5,0x12,0xd5 ; $2c4a
	dc.b	0x12,0xff,0xf0,0x12,0xf0,0x12,0xf0,0x12 ; $2c52
	dc.b	0xff,0xde,0x12,0xde,0x12,0xde,0x12,0x13 ; $2c5a
	dc.b	0xde,0x12,0xde,0x12,0xde,0x12,0xff,0xe7 ; $2c62
	dc.b	0x12,0xe7,0x12,0xe7,0x12,0xff,0xf0,0x12 ; $2c6a
	dc.b	0xf0,0x12,0xf0,0x12,0xff,0xf9,0x12,0xf9 ; $2c72
	dc.b	0x12,0xf9,0x12,0xff,0x02,0x13,0x02,0x13 ; $2c7a
	dc.b	0x02,0x13,0xff,0x0b,0x13,0x0b,0x13,0x0b ; $2c82
	dc.b	0x13,0xff,0x14,0x13,0x14,0x13,0x14,0x13 ; $2c8a
	dc.b	0xff,0x89,0x0a,0x89,0x0a,0x89,0x0a,0x14 ; $2c92
	dc.b	0x26,0x13,0x26,0x13,0x26,0x13,0x15,0x26 ; $2c9a
	dc.b	0x13,0x26,0x13,0x26,0x13,0x16,0x26,0x13 ; $2ca2
	dc.b	0x26,0x13,0x26,0x13,0xff,0x89,0x13,0x89 ; $2caa
	dc.b	0x13,0x89,0x13,0x14,0x2f,0x13,0x2f,0x13 ; $2cb2
	dc.b	0x2f,0x13,0x15,0x2f,0x13,0x2f,0x13,0x2f ; $2cba
	dc.b	0x13,0x16,0x2f,0x13,0x2f,0x13,0x2f,0x13 ; $2cc2
	dc.b	0xff,0x80,0x13,0x80,0x13,0x80,0x13,0x14 ; $2cca
	dc.b	0x38,0x13,0x38,0x13,0x38,0x13,0x15,0x38 ; $2cd2
	dc.b	0x13,0x38,0x13,0x38,0x13,0x16,0x38,0x13 ; $2cda
	dc.b	0x38,0x13,0x38,0x13,0xff,0x77,0x13,0x77 ; $2ce2
	dc.b	0x13,0x77,0x13,0x14,0x41,0x13,0x41,0x13 ; $2cea
	dc.b	0x41,0x13,0x15,0x41,0x13,0x41,0x13,0x41 ; $2cf2
	dc.b	0x13,0x16,0x41,0x13,0x41,0x13,0x41,0x13 ; $2cfa
	dc.b	0xff,0x6e,0x13,0x6e,0x13,0x6e,0x13,0x14 ; $2d02
	dc.b	0x4a,0x13,0x4a,0x13,0x4a,0x13,0x15,0x4a ; $2d0a
	dc.b	0x13,0x4a,0x13,0x4a,0x13,0x16,0x4a,0x13 ; $2d12
	dc.b	0x4a,0x13,0x4a,0x13,0xff,0x65,0x13,0x65 ; $2d1a
	dc.b	0x13,0x65,0x13,0xff,0x53,0x13,0x53,0x13 ; $2d22
	dc.b	0x53,0x13,0x14,0x53,0x13,0x53,0x13,0x53 ; $2d2a
	dc.b	0x13,0x15,0x53,0x13,0x53,0x13,0x53,0x13 ; $2d32
	dc.b	0x16,0x53,0x13,0x53,0x13,0x53,0x13,0xff ; $2d3a
	dc.b	0x5c,0x13,0x5c,0x13,0x5c,0x13,0xff,0x6e ; $2d42
	dc.b	0x13,0x6e,0x13,0x6e,0x13,0xff,0x6e,0x13 ; $2d4a
	dc.b	0x6e,0x13,0x6e,0x13,0xff,0x77,0x13,0x77 ; $2d52
	dc.b	0x13,0x77,0x13,0xff,0x80,0x13,0x80,0x13 ; $2d5a
	dc.b	0x80,0x13,0xff,0x89,0x13,0x89,0x13,0x89 ; $2d62
	dc.b	0x13,0xff,0x89,0x0a,0x89,0x0a,0x89,0x0a ; $2d6a
	dc.b	0x17,0x9b,0x13,0x9b,0x13,0x9b,0x13,0xff ; $2d72
	dc.b	0x10,0x14,0x10,0x14,0x10,0x14,0x17,0xa4 ; $2d7a
	dc.b	0x13,0xa4,0x13,0xa4,0x13,0xff,0x07,0x14 ; $2d82
	dc.b	0x07,0x14,0x07,0x14,0x17,0xad,0x13,0xad ; $2d8a
	dc.b	0x13,0xad,0x13,0xff,0xfe,0x13,0xfe,0x13 ; $2d92
	dc.b	0xfe,0x13,0x17,0xb6,0x13,0xb6,0x13,0xb6 ; $2d9a
	dc.b	0x13,0xff,0xf5,0x13,0xf5,0x13,0xf5,0x13 ; $2da2
	dc.b	0xff,0xbf,0x13,0xbf,0x13,0xbf,0x13,0xff ; $2daa
	dc.b	0xc8,0x13,0xc8,0x13,0xc8,0x13,0xff,0xd1 ; $2db2
	dc.b	0x13,0xd1,0x13,0xd1,0x13,0xff,0xda,0x13 ; $2dba
	dc.b	0xda,0x13,0xda,0x13,0xff,0xe3,0x13,0xe3 ; $2dc2
	dc.b	0x13,0xe3,0x13,0xff,0xec,0x13,0xec,0x13 ; $2dca
	dc.b	0xec,0x13,0xff,0x89,0x0a,0x89,0x0a,0x89 ; $2dd2
	dc.b	0x0a,0xff,0xfe,0x13,0xfe,0x13,0xfe,0x13 ; $2dda
	dc.b	0xff,0x07,0x14,0x07,0x14,0x07,0x14,0xff ; $2de2
	dc.b	0x10,0x14,0x10,0x14,0x10,0x14,0xff,0x89 ; $2dea
	dc.b	0x0a,0x89,0x0a,0x89,0x0a,0xff,0x9b,0x0a ; $2df2
	dc.b	0x9b,0x0a,0x9b,0x0a,0xff,0xad,0x0a,0xad ; $2dfa
	dc.b	0x0a,0xad,0x0a,0xff,0x89,0x0a,0x89,0x0a ; $2e02
	dc.b	0x89,0x0a,0xff,0x89,0x0a,0x89,0x0a,0x89 ; $2e0a
	dc.b	0x0a,0xff,0xf5,0x0a,0xf5,0x0a,0xf5,0x0a ; $2e12
	dc.b	0xff,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x05 ; $2e1a
	dc.b	0xb7,0x0c,0xb7,0x0c,0xb7,0x0c,0x06,0xb7 ; $2e22
	dc.b	0x0c,0xb7,0x0c,0xb7,0x0c,0x07,0xb7,0x0c ; $2e2a
	dc.b	0xb7,0x0c,0xb7,0x0c,0xff,0xf6,0x0c,0xf6 ; $2e32
	dc.b	0x0c,0xf6,0x0c,0xff,0x92,0x0a,0x92,0x0a ; $2e3a
	dc.b	0x92,0x0a,0x08,0x23,0x0d,0x23,0x0d,0x23 ; $2e42
	dc.b	0x0d,0xff,0xa1,0x0d,0xa1,0x0d,0xa1,0x0d ; $2e4a
	dc.b	0x09,0xbc,0x0d,0xbc,0x0d,0xbc,0x0d,0xff ; $2e52
	dc.b	0x3a,0x0e,0x3a,0x0e,0x3a,0x0e,0x0a,0x28 ; $2e5a
	dc.b	0x0e,0x28,0x0e,0x28,0x0e,0x0c,0x28,0x0e ; $2e62
	dc.b	0x28,0x0e,0x28,0x0e,0xff,0x8b,0x0e,0x8b ; $2e6a
	dc.b	0x0e,0x8b,0x0e,0xff,0x89,0x0a,0x89,0x0a ; $2e72
	dc.b	0x89,0x0a,0x0b,0xf7,0x0e,0xf7,0x0e,0xf7 ; $2e7a
	dc.b	0x0e,0xff,0x51,0x0f,0x51,0x0f,0x51,0x0f ; $2e82
	dc.b	0xff,0x89,0x0a,0x89,0x0a,0x89,0x0a,0x0d ; $2e8a
	dc.b	0xe1,0x0f,0xe1,0x0f,0xe1,0x0f,0xff,0x68 ; $2e92
	dc.b	0x10,0x68,0x10,0x68,0x10,0x0e,0x7a,0x10 ; $2e9a
	dc.b	0x7a,0x10,0x7a,0x10,0x18,0x7a,0x10,0x7a ; $2ea2
	dc.b	0x10,0x7a,0x10,0xff,0xdd,0x10,0xdd,0x10 ; $2eaa
	dc.b	0xdd,0x10,0xff,0x89,0x0a,0x89,0x0a,0x89 ; $2eb2
	dc.b	0x0a,0x0f,0x49,0x11,0x49,0x11,0x49,0x11 ; $2eba
	dc.b	0x10,0x49,0x11,0x49,0x11,0x49,0x11,0xff ; $2ec2
	dc.b	0xac,0x11,0xac,0x11,0xac,0x11,0xff,0x89 ; $2eca
	dc.b	0x0a,0x89,0x0a,0x89,0x0a,0x12,0x3c,0x12 ; $2ed2
	dc.b	0x3c,0x12,0x3c,0x12,0xff,0x9f,0x12,0x9f ; $2eda
	dc.b	0x12,0x9f,0x12,0x13,0xb1,0x12,0xb1,0x12 ; $2ee2
	dc.b	0xb1,0x12,0xff,0x14,0x13,0x14,0x13,0x14 ; $2eea
	dc.b	0x13,0x14,0x26,0x13,0x26,0x13,0x26,0x13 ; $2ef2
	dc.b	0x15,0x26,0x13,0x26,0x13,0x26,0x13,0x16 ; $2efa
	dc.b	0x26,0x13,0x26,0x13,0x26,0x13,0xff,0x89 ; $2f02
	dc.b	0x13,0x89,0x13,0x89,0x13,0x17,0x9b,0x13 ; $2f0a
	dc.b	0x9b,0x13,0x9b,0x13,0xff,0x10,0x14,0x10 ; $2f12
	dc.b	0x14,0x10,0x14,0xff,0xa4,0x0a,0xa4,0x0a ; $2f1a
	dc.b	0xa4,0x0a,0xff,0xad,0x0a,0xad,0x0a,0xad ; $2f22
	dc.b	0x0a,0xff,0x92,0x0a,0x92,0x0a,0x92,0x0a ; $2f2a
	dc.b	0xff,0x92,0x0a,0x92,0x0a,0x92,0x0a,0xff ; $2f32
	dc.b	0x92,0x0a,0x92,0x0a,0x92,0x0a,0xff,0x92 ; $2f3a
	dc.b	0x0a,0x92,0x0a,0x92,0x0a,0x05,0xa5,0x0c ; $2f42
	dc.b	0xa5,0x0c,0xa5,0x0c,0x06,0xa5,0x0c,0xa5 ; $2f4a
	dc.b	0x0c,0xa5,0x0c,0x07,0xa5,0x0c,0xa5,0x0c ; $2f52
	dc.b	0xa5,0x0c,0xff,0x08,0x0d,0x08,0x0d,0x08 ; $2f5a
	dc.b	0x0d,0xff,0x9b,0x0a,0x9b,0x0a,0x9b,0x0a ; $2f62
	dc.b	0x08,0x23,0x0d,0x23,0x0d,0x23,0x0d,0xff ; $2f6a
	dc.b	0xa1,0x0d,0xa1,0x0d,0xa1,0x0d,0x09,0xbc ; $2f72
	dc.b	0x0d,0xbc,0x0d,0xbc,0x0d,0xff,0x0d,0x0e ; $2f7a
	dc.b	0x0d,0x0e,0x0d,0x0e,0x0a,0x31,0x0e,0x31 ; $2f82
	dc.b	0x0e,0x31,0x0e,0xff,0x82,0x0e,0x82,0x0e ; $2f8a
	dc.b	0x82,0x0e,0xff,0x92,0x0a,0x92,0x0a,0x92 ; $2f92
	dc.b	0x0a,0xff,0x92,0x0a,0x92,0x0a,0x92,0x0a ; $2f9a
	dc.b	0x0f,0xef,0x10,0xef,0x10,0xef,0x10,0x11 ; $2fa2
	dc.b	0xef,0x10,0xef,0x10,0xef,0x10,0xff,0x40 ; $2faa
	dc.b	0x11,0x40,0x11,0x40,0x11,0x0b,0xee,0x0e ; $2fb2
	dc.b	0xee,0x0e,0xee,0x0e,0xff,0x5a,0x0f,0x5a ; $2fba
	dc.b	0x0f,0x5a,0x0f,0x0c,0x87,0x0f,0x87,0x0f ; $2fc2
	dc.b	0x87,0x0f,0xff,0xb4,0x0f,0xb4,0x0f,0xb4 ; $2fca
	dc.b	0x0f,0xff,0x92,0x0a,0x92,0x0a,0x92,0x0a ; $2fd2
	dc.b	0x0f,0xb0,0x19,0xb0,0x19,0xb0,0x19,0x10 ; $2fda
	dc.b	0xb0,0x19,0xb0,0x19,0xb0,0x19,0xff,0xa3 ; $2fe2
	dc.b	0x11,0xa3,0x11,0xa3,0x11,0x11,0xd0,0x11 ; $2fea
	dc.b	0xd0,0x11,0xd0,0x11,0xff,0x0f,0x12,0x0f ; $2ff2
	dc.b	0x12,0x0f,0x12,0xff,0x92,0x0a,0x92,0x0a ; $2ffa
	dc.b	0x92,0x0a,0x13,0xba,0x12,0xba,0x12,0xba ; $3002
	dc.b	0x12,0xff,0x0b,0x13,0x0b,0x13,0x0b,0x13 ; $300a
	dc.b	0xff,0x92,0x0a,0x92,0x0a,0x92,0x0a,0xff ; $3012
	dc.b	0x92,0x0a,0x92,0x0a,0x92,0x0a,0xff,0xad ; $301a
	dc.b	0x0a,0xad,0x0a,0xad,0x0a,0xff,0x89,0x0a ; $3022
	dc.b	0x89,0x0a,0x89,0x0a,0xff,0x9b,0x0a,0x9b ; $302a
	dc.b	0x0a,0x9b,0x0a,0xff,0x92,0x0a,0x92,0x0a ; $3032
	dc.b	0x92,0x0a,0xff,0xad,0x0a,0xad,0x0a,0xad ; $303a
	dc.b	0x0a,0xff,0xad,0x0a,0xad,0x0a,0xad,0x0a ; $3042
	dc.b	0xff,0x92,0x0a,0x92,0x0a,0x92,0x0a,0xff ; $304a
	dc.b	0xa4,0x0a,0xa4,0x0a,0xa4,0x0a,0xff,0x92 ; $3052
	dc.b	0x0a,0x92,0x0a,0x92,0x0a,0x09,0xbc,0x0d ; $305a
	dc.b	0xbc,0x0d,0xbc,0x0d,0xff,0x0d,0x0e,0x0d ; $3062
	dc.b	0x0e,0x0d,0x0e,0x0a,0x31,0x0e,0x31,0x0e ; $306a
	dc.b	0x31,0x0e,0x0c,0x31,0x0e,0x31,0x0e,0x31 ; $3072
	dc.b	0x0e,0xff,0x82,0x0e,0x82,0x0e,0x82,0x0e ; $307a
	dc.b	0xff,0x92,0x0a,0x92,0x0a,0x92,0x0a,0xff ; $3082
	dc.b	0x92,0x0a,0x92,0x0a,0x92,0x0a,0x0c,0x87 ; $308a
	dc.b	0x0f,0x87,0x0f,0x87,0x0f,0xff,0xb4,0x0f ; $3092
	dc.b	0xb4,0x0f,0xb4,0x0f,0xff,0x92,0x0a,0x92 ; $309a
	dc.b	0x0a,0x92,0x0a,0xff,0x92,0x0a,0x92,0x0a ; $30a2
	dc.b	0x92,0x0a,0x0f,0xef,0x10,0xef,0x10,0xef ; $30aa
	dc.b	0x10,0x11,0xef,0x10,0xef,0x10,0xef,0x10 ; $30b2
	dc.b	0xff,0x40,0x11,0x40,0x11,0x40,0x11,0x0f ; $30ba
	dc.b	0xb0,0x19,0xb0,0x19,0xb0,0x19,0x10,0xb0 ; $30c2
	dc.b	0x19,0xb0,0x19,0xb0,0x19,0xff,0xa3,0x11 ; $30ca
	dc.b	0xa3,0x11,0xa3,0x11,0x11,0xd0,0x11,0xd0 ; $30d2
	dc.b	0x11,0xd0,0x11,0xff,0x0f,0x12,0x0f,0x12 ; $30da
	dc.b	0x0f,0x12,0x12,0x33,0x12,0x33,0x12,0x33 ; $30e2
	dc.b	0x12,0xff,0x9f,0x12,0x9f,0x12,0x9f,0x12 ; $30ea
	dc.b	0xff,0x92,0x0a,0x92,0x0a,0x92,0x0a,0xff ; $30f2
	dc.b	0x9b,0x0a,0x9b,0x0a,0x9b,0x0a,0xff,0xad ; $30fa
	dc.b	0x0a,0xad,0x0a,0xad,0x0a,0xff,0xb6,0x0a ; $3102
	dc.b	0xb6,0x0a,0xb6,0x0a,0xff,0x89,0x0a,0x89 ; $310a
	dc.b	0x0a,0x89,0x0a,0xff,0xa4,0x0a,0xa4,0x0a ; $3112
	dc.b	0xa4,0x0a,0xff,0x92,0x0a,0x92,0x0a,0x92 ; $311a
	dc.b	0x0a,0xff,0xfe,0x0a,0xfe,0x0a,0xfe,0x0a ; $3122
	dc.b	0xff,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x05 ; $312a
	dc.b	0xb7,0x0c,0xb7,0x0c,0xb7,0x0c,0x06,0xb7 ; $3132
	dc.b	0x0c,0xb7,0x0c,0xb7,0x0c,0x07,0xb7,0x0c ; $313a
	dc.b	0xb7,0x0c,0xb7,0x0c,0xff,0xf6,0x0c,0xf6 ; $3142
	dc.b	0x0c,0xf6,0x0c,0xff,0xad,0x0a,0xad,0x0a ; $314a
	dc.b	0xad,0x0a,0x08,0x23,0x0d,0x23,0x0d,0x23 ; $3152
	dc.b	0x0d,0xff,0xa1,0x0d,0xa1,0x0d,0xa1,0x0d ; $315a
	dc.b	0x09,0xbc,0x0d,0xbc,0x0d,0xbc,0x0d,0xff ; $3162
	dc.b	0x0d,0x0e,0x0d,0x0e,0x0d,0x0e,0x0a,0x43 ; $316a
	dc.b	0x0e,0x43,0x0e,0x43,0x0e,0x0c,0x43,0x0e ; $3172
	dc.b	0x43,0x0e,0x43,0x0e,0xff,0x70,0x0e,0x70 ; $317a
	dc.b	0x0e,0x70,0x0e,0xff,0x92,0x0a,0x92,0x0a ; $3182
	dc.b	0x92,0x0a,0x0b,0xf7,0x0e,0xf7,0x0e,0xf7 ; $318a
	dc.b	0x0e,0xff,0x51,0x0f,0x51,0x0f,0x51,0x0f ; $3192
	dc.b	0x0c,0x87,0x0f,0x87,0x0f,0x87,0x0f,0xff ; $319a
	dc.b	0xab,0x0f,0xab,0x0f,0xab,0x0f,0x0d,0xe1 ; $31a2
	dc.b	0x0f,0xe1,0x0f,0xe1,0x0f,0xff,0x68,0x10 ; $31aa
	dc.b	0x68,0x10,0x68,0x10,0x0e,0x7a,0x10,0x7a ; $31b2
	dc.b	0x10,0x7a,0x10,0x18,0x7a,0x10,0x7a,0x10 ; $31ba
	dc.b	0x7a,0x10,0xff,0xdd,0x10,0xdd,0x10,0xdd ; $31c2
	dc.b	0x10,0x0f,0xf8,0x10,0xf8,0x10,0xf8,0x10 ; $31ca
	dc.b	0x11,0xf8,0x10,0xf8,0x10,0xf8,0x10,0xff ; $31d2
	dc.b	0x2e,0x11,0x2e,0x11,0x2e,0x11,0x0f,0x52 ; $31da
	dc.b	0x11,0x52,0x11,0x52,0x11,0x10,0x52,0x11 ; $31e2
	dc.b	0x52,0x11,0x52,0x11,0xff,0xac,0x11,0xac ; $31ea
	dc.b	0x11,0xac,0x11,0x11,0xd9,0x11,0xd9,0x11 ; $31f2
	dc.b	0xd9,0x11,0xff,0x06,0x12,0x06,0x12,0x06 ; $31fa
	dc.b	0x12,0x12,0x33,0x12,0x33,0x12,0x33,0x12 ; $3202
	dc.b	0xff,0x9f,0x12,0x9f,0x12,0x9f,0x12,0x13 ; $320a
	dc.b	0xba,0x12,0xba,0x12,0xba,0x12,0xff,0x0b ; $3212
	dc.b	0x13,0x0b,0x13,0x0b,0x13,0x14,0x41,0x13 ; $321a
	dc.b	0x41,0x13,0x41,0x13,0x15,0x41,0x13,0x41 ; $3222
	dc.b	0x13,0x41,0x13,0x16,0x41,0x13,0x41,0x13 ; $322a
	dc.b	0x41,0x13,0xff,0x6e,0x13,0x6e,0x13,0x6e ; $3232
	dc.b	0x13,0x17,0x9b,0x13,0x9b,0x13,0x9b,0x13 ; $323a
	dc.b	0xff,0x10,0x14,0x10,0x14,0x10,0x14,0xff ; $3242
	dc.b	0x89,0x0a,0x89,0x0a,0x89,0x0a,0xff,0xc8 ; $324a
	dc.b	0x0a,0xc8,0x0a,0xc8,0x0a,0xff,0xad,0x0a ; $3252
	dc.b	0xad,0x0a,0xad,0x0a,0xff,0xc8,0x0a,0xc8 ; $325a
	dc.b	0x0a,0xc8,0x0a,0xff,0xfe,0x0a,0xfe,0x0a ; $3262
	dc.b	0xfe,0x0a,0xff,0x0c,0x0c,0x0c,0x0c,0x0c ; $326a
	dc.b	0x0c,0x05,0xae,0x0c,0xae,0x0c,0xae,0x0c ; $3272
	dc.b	0x06,0xae,0x0c,0xae,0x0c,0xae,0x0c,0x07 ; $327a
	dc.b	0xae,0x0c,0xae,0x0c,0xae,0x0c,0xff,0xff ; $3282
	dc.b	0x0c,0xff,0x0c,0xff,0x0c,0xff,0xb6,0x0a ; $328a
	dc.b	0xb6,0x0a,0xb6,0x0a,0x08,0x23,0x0d,0x23 ; $3292
	dc.b	0x0d,0x23,0x0d,0xff,0xa1,0x0d,0xa1,0x0d ; $329a
	dc.b	0xa1,0x0d,0x09,0xb3,0x0d,0xb3,0x0d,0xb3 ; $32a2
	dc.b	0x0d,0xff,0x16,0x0e,0x16,0x0e,0x16,0x0e ; $32aa
	dc.b	0x0a,0x3a,0x0e,0x3a,0x0e,0x3a,0x0e,0x0c ; $32b2
	dc.b	0x3a,0x0e,0x3a,0x0e,0x3a,0x0e,0xff,0x79 ; $32ba
	dc.b	0x0e,0x79,0x0e,0x79,0x0e,0xff,0x89,0x0a ; $32c2
	dc.b	0x89,0x0a,0x89,0x0a,0x0b,0xf7,0x0e,0xf7 ; $32ca
	dc.b	0x0e,0xf7,0x0e,0xff,0x51,0x0f,0x51,0x0f ; $32d2
	dc.b	0x51,0x0f,0xff,0x89,0x0a,0x89,0x0a,0x89 ; $32da
	dc.b	0x0a,0x0d,0xe1,0x0f,0xe1,0x0f,0xe1,0x0f ; $32e2
	dc.b	0xff,0x68,0x10,0x68,0x10,0x68,0x10,0x0e ; $32ea
	dc.b	0x83,0x10,0x83,0x10,0x83,0x10,0x18,0x83 ; $32f2
	dc.b	0x10,0x83,0x10,0x83,0x10,0xff,0xd4,0x10 ; $32fa
	dc.b	0xd4,0x10,0xd4,0x10,0x0f,0xf8,0x10,0xf8 ; $3302
	dc.b	0x10,0xf8,0x10,0x11,0xf8,0x10,0xf8,0x10 ; $330a
	dc.b	0xf8,0x10,0xff,0x2e,0x11,0x2e,0x11,0x2e ; $3312
	dc.b	0x11,0x0f,0x49,0x11,0x49,0x11,0x49,0x11 ; $331a
	dc.b	0x10,0x49,0x11,0x49,0x11,0x49,0x11,0xff ; $3322
	dc.b	0xac,0x11,0xac,0x11,0xac,0x11,0xff,0x89 ; $332a
	dc.b	0x0a,0x89,0x0a,0x89,0x0a,0x12,0x33,0x12 ; $3332
	dc.b	0x33,0x12,0x33,0x12,0xff,0x9f,0x12,0x9f ; $333a
	dc.b	0x12,0x9f,0x12,0x13,0xba,0x12,0xba,0x12 ; $3342
	dc.b	0xba,0x12,0xff,0x0b,0x13,0x0b,0x13,0x0b ; $334a
	dc.b	0x13,0x14,0x38,0x13,0x38,0x13,0x38,0x13 ; $3352
	dc.b	0x15,0x38,0x13,0x38,0x13,0x38,0x13,0x16 ; $335a
	dc.b	0x38,0x13,0x38,0x13,0x38,0x13,0xff,0x77 ; $3362
	dc.b	0x13,0x77,0x13,0x77,0x13,0x17,0x9b,0x13 ; $336a
	dc.b	0x9b,0x13,0x9b,0x13,0xff,0x10,0x14,0x10 ; $3372
	dc.b	0x14,0x10,0x14,0xff,0x89,0x0a,0x89,0x0a ; $337a
	dc.b	0x89,0x0a,0xff,0xc8,0x0a,0xc8,0x0a,0xc8 ; $3382
	dc.b	0x0a,0xff,0x92,0x0a,0x92,0x0a,0x92,0x0a ; $338a
	dc.b	0xff,0x89,0x0a,0x89,0x0a,0x89,0x0a,0xff ; $3392
	dc.b	0xfe,0x0a,0xfe,0x0a,0xfe,0x0a,0xff,0x0c ; $339a
	dc.b	0x0c,0x0c,0x0c,0x0c,0x0c,0x05,0xae,0x0c ; $33a2
	dc.b	0xae,0x0c,0xae,0x0c,0x06,0xae,0x0c,0xae ; $33aa
	dc.b	0x0c,0xae,0x0c,0x07,0xae,0x0c,0xae,0x0c ; $33b2
	dc.b	0xae,0x0c,0xff,0xff,0x0c,0xff,0x0c,0xff ; $33ba
	dc.b	0x0c,0xff,0xbf,0x0a,0xbf,0x0a,0xbf,0x0a ; $33c2
	dc.b	0x08,0x23,0x0d,0x23,0x0d,0x23,0x0d,0xff ; $33ca
	dc.b	0xa1,0x0d,0xa1,0x0d,0xa1,0x0d,0x09,0xb3 ; $33d2
	dc.b	0x0d,0xb3,0x0d,0xb3,0x0d,0xff,0x16,0x0e ; $33da
	dc.b	0x16,0x0e,0x16,0x0e,0x0a,0x3a,0x0e,0x3a ; $33e2
	dc.b	0x0e,0x3a,0x0e,0x0c,0x3a,0x0e,0x3a,0x0e ; $33ea
	dc.b	0x3a,0x0e,0xff,0x79,0x0e,0x79,0x0e,0x79 ; $33f2
	dc.b	0x0e,0x0a,0x9d,0x0e,0x9d,0x0e,0x9d,0x0e ; $33fa
	dc.b	0xff,0xdc,0x0e,0xdc,0x0e,0xdc,0x0e,0x0b ; $3402
	dc.b	0xf7,0x0e,0xf7,0x0e,0xf7,0x0e,0xff,0x51 ; $340a
	dc.b	0x0f,0x51,0x0f,0x51,0x0f,0x0c,0x6c,0x0f ; $3412
	dc.b	0x6c,0x0f,0x6c,0x0f,0xff,0xcf,0x0f,0xcf ; $341a
	dc.b	0x0f,0xcf,0x0f,0x0d,0xe1,0x0f,0xe1,0x0f ; $3422
	dc.b	0xe1,0x0f,0xff,0x68,0x10,0x68,0x10,0x68 ; $342a
	dc.b	0x10,0x0e,0x83,0x10,0x83,0x10,0x83,0x10 ; $3432
	dc.b	0x18,0x83,0x10,0x83,0x10,0x83,0x10,0xff ; $343a
	dc.b	0xd4,0x10,0xd4,0x10,0xd4,0x10,0x0f,0xef ; $3442
	dc.b	0x10,0xef,0x10,0xef,0x10,0x11,0xef,0x10 ; $344a
	dc.b	0xef,0x10,0xef,0x10,0xff,0x37,0x11,0x37 ; $3452
	dc.b	0x11,0x37,0x11,0x0f,0x49,0x11,0x49,0x11 ; $345a
	dc.b	0x49,0x11,0x10,0x49,0x11,0x49,0x11,0x49 ; $3462
	dc.b	0x11,0xff,0xac,0x11,0xac,0x11,0xac,0x11 ; $346a
	dc.b	0x11,0xbe,0x11,0xbe,0x11,0xbe,0x11,0xff ; $3472
	dc.b	0x21,0x12,0x21,0x12,0x21,0x12,0x12,0x33 ; $347a
	dc.b	0x12,0x33,0x12,0x33,0x12,0xff,0x9f,0x12 ; $3482
	dc.b	0x9f,0x12,0x9f,0x12,0x13,0xba,0x12,0xba ; $348a
	dc.b	0x12,0xba,0x12,0xff,0x0b,0x13,0x0b,0x13 ; $3492
	dc.b	0x0b,0x13,0x14,0x38,0x13,0x38,0x13,0x38 ; $349a
	dc.b	0x13,0x15,0x38,0x13,0x38,0x13,0x38,0x13 ; $34a2
	dc.b	0x16,0x38,0x13,0x38,0x13,0x38,0x13,0xff ; $34aa
	dc.b	0x77,0x13,0x77,0x13,0x77,0x13,0x17,0x9b ; $34b2
	dc.b	0x13,0x9b,0x13,0x9b,0x13,0xff,0x10,0x14 ; $34ba
	dc.b	0x10,0x14,0x10,0x14,0xff,0x89,0x0a,0x89 ; $34c2
	dc.b	0x0a,0x89,0x0a,0xff,0x89,0x0a,0x89,0x0a ; $34ca
	dc.b	0x89,0x0a,0xff,0xad,0x0a,0xad,0x0a,0xad ; $34d2
	dc.b	0x0a,0xff,0xbf,0x0a,0xbf,0x0a,0xbf,0x0a ; $34da
	dc.b	0xff,0xfe,0x0a,0xfe,0x0a,0xfe,0x0a,0xff ; $34e2
	dc.b	0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x05,0xae ; $34ea
	dc.b	0x0c,0xae,0x0c,0xae,0x0c,0x06,0xae,0x0c ; $34f2
	dc.b	0xae,0x0c,0xae,0x0c,0x07,0xae,0x0c,0xae ; $34fa
	dc.b	0x0c,0xae,0x0c,0xff,0xff,0x0c,0xff,0x0c ; $3502
	dc.b	0xff,0x0c,0xff,0xc8,0x0a,0xc8,0x0a,0xc8 ; $350a
	dc.b	0x0a,0x08,0x23,0x0d,0x23,0x0d,0x23,0x0d ; $3512
	dc.b	0xff,0xa1,0x0d,0xa1,0x0d,0xa1,0x0d,0x09 ; $351a
	dc.b	0xb3,0x0d,0xb3,0x0d,0xb3,0x0d,0xff,0x16 ; $3522
	dc.b	0x0e,0x16,0x0e,0x16,0x0e,0x0a,0xa6,0x0e ; $352a
	dc.b	0xa6,0x0e,0xa6,0x0e,0xff,0xd3,0x0e,0xd3 ; $3532
	dc.b	0x0e,0xd3,0x0e,0xff,0x89,0x0a,0x89,0x0a ; $353a
	dc.b	0x89,0x0a,0x0c,0x7e,0x0f,0x7e,0x0f,0x7e ; $3542
	dc.b	0x0f,0xff,0xb4,0x0f,0xb4,0x0f,0xb4,0x0f ; $354a
	dc.b	0x0d,0xe1,0x0f,0xe1,0x0f,0xe1,0x0f,0xff ; $3552
	dc.b	0x68,0x10,0x68,0x10,0x68,0x10,0x0e,0x83 ; $355a
	dc.b	0x10,0x83,0x10,0x83,0x10,0x18,0x83,0x10 ; $3562
	dc.b	0x83,0x10,0x83,0x10,0xff,0xd4,0x10,0xd4 ; $356a
	dc.b	0x10,0xd4,0x10,0x0f,0xef,0x10,0xef,0x10 ; $3572
	dc.b	0xef,0x10,0x11,0xef,0x10,0xef,0x10,0xef ; $357a
	dc.b	0x10,0xff,0x37,0x11,0x37,0x11,0x37,0x11 ; $3582
	dc.b	0x0f,0x49,0x11,0x49,0x11,0x49,0x11,0x10 ; $358a
	dc.b	0x49,0x11,0x49,0x11,0x49,0x11,0xff,0xac ; $3592
	dc.b	0x11,0xac,0x11,0xac,0x11,0x11,0xd0,0x11 ; $359a
	dc.b	0xd0,0x11,0xd0,0x11,0xff,0x0f,0x12,0x0f ; $35a2
	dc.b	0x12,0x0f,0x12,0x12,0x33,0x12,0x33,0x12 ; $35aa
	dc.b	0x33,0x12,0xff,0x9f,0x12,0x9f,0x12,0x9f ; $35b2
	dc.b	0x12,0x13,0xba,0x12,0xba,0x12,0xba,0x12 ; $35ba
	dc.b	0xff,0x0b,0x13,0x0b,0x13,0x0b,0x13,0x17 ; $35c2
	dc.b	0x9b,0x13,0x9b,0x13,0x9b,0x13,0xff,0x10 ; $35ca
	dc.b	0x14,0x10,0x14,0x10,0x14,0x0f,0x5b,0x11 ; $35d2
	dc.b	0x5b,0x11,0x5b,0x11,0x10,0x5b,0x11,0x5b ; $35da
	dc.b	0x11,0x5b,0x11,0xff,0x9a,0x11,0x9a,0x11 ; $35e2
	dc.b	0x9a,0x11,0xff,0xc2,0x19,0xc2,0x19,0xc2 ; $35ea
	dc.b	0x19,0xff,0xcb,0x19,0xcb,0x19,0xcb,0x19 ; $35f2
	dc.b	0xff,0xcb,0x19,0xcb,0x19,0xcb,0x19,0xff ; $35fa
	dc.b	0xdd,0x19,0xdd,0x19,0xdd,0x19,0xff,0xe6 ; $3602
	dc.b	0x19,0xe6,0x19,0xe6,0x19,0xff,0xe6,0x19 ; $360a
	dc.b	0xe6,0x19,0xe6,0x19,0xff,0xf8,0x19,0xf8 ; $3612
	dc.b	0x19,0xf8,0x19,0xff,0x01,0x1a,0x01,0x1a ; $361a
	dc.b	0x01,0x1a,0xff,0x01,0x1a,0x01,0x1a,0x01 ; $3622
	dc.b	0x1a,0xff,0x13,0x1a,0x13,0x1a,0x13,0x1a ; $362a
	dc.b	0xff,0x1c,0x1a,0x1c,0x1a,0x1c,0x1a,0xff ; $3632
	dc.b	0x1c,0x1a,0x1c,0x1a,0x1c,0x1a,0xff,0x25 ; $363a
	dc.b	0x1a,0x25,0x1a,0x25,0x1a,0xff,0x37,0x1a ; $3642
	dc.b	0x37,0x1a,0x37,0x1a,0xff,0x37,0x1a,0x37 ; $364a
	dc.b	0x1a,0x37,0x1a,0xff,0x49,0x1a,0x49,0x1a ; $3652
	dc.b	0x49,0x1a,0xff,0x52,0x1a,0x52,0x1a,0x52 ; $365a
	dc.b	0x1a,0xff,0x52,0x1a,0x52,0x1a,0x52,0x1a ; $3662
	dc.b	0xff,0x64,0x1a,0x64,0x1a,0x64,0x1a,0xff ; $366a
	dc.b	0x6d,0x1a,0x6d,0x1a,0x6d,0x1a,0xff,0x76 ; $3672
	dc.b	0x1a,0x76,0x1a,0x76,0x1a,0xff,0x7f,0x1a ; $367a
	dc.b	0x7f,0x1a,0x7f,0x1a,0xff,0x88,0x1a,0x88 ; $3682
	dc.b	0x1a,0x88,0x1a,0x01,0x88,0x1a,0x88,0x1a ; $368a
	dc.b	0x88,0x1a,0xff,0x91,0x1a,0x91,0x1a,0x91 ; $3692
	dc.b	0x1a,0xff,0x89,0x0a,0x89,0x0a,0x89,0x0a ; $369a
	dc.b	0xff,0xa3,0x1a,0xa3,0x1a,0xa3,0x1a,0xff ; $36a2
	dc.b	0xac,0x1a,0xac,0x1a,0xac,0x1a,0xff,0xb5 ; $36aa
	dc.b	0x1a,0xb5,0x1a,0xb5,0x1a,0xff,0xbe,0x1a ; $36b2
	dc.b	0xbe,0x1a,0xbe,0x1a,0xff,0xc7,0x1a,0xc7 ; $36ba
	dc.b	0x1a,0xc7,0x1a,0xff,0xd0,0x1a,0xd0,0x1a ; $36c2
	dc.b	0xd0,0x1a,0x01,0xd0,0x1a,0xd0,0x1a,0xd0 ; $36ca
	dc.b	0x1a,0xff,0xd9,0x1a,0xd9,0x1a,0xd9,0x1a ; $36d2
	dc.b	0xff,0x89,0x0a,0x89,0x0a,0x89,0x0a,0xff ; $36da
	dc.b	0xeb,0x1a,0xeb,0x1a,0xeb,0x1a,0xff,0xf4 ; $36e2
	dc.b	0x1a,0xf4,0x1a,0xf4,0x1a,0xff,0xfd,0x1a ; $36ea
	dc.b	0xfd,0x1a,0xfd,0x1a,0xff,0x06,0x1b,0x06 ; $36f2
	dc.b	0x1b,0x06,0x1b,0xff,0x0f,0x1b,0x0f,0x1b ; $36fa
	dc.b	0x0f,0x1b,0xff,0x18,0x1b,0x18,0x1b,0x18 ; $3702
	dc.b	0x1b,0x01,0x18,0x1b,0x18,0x1b,0x18,0x1b ; $370a
	dc.b	0xff,0x21,0x1b,0x21,0x1b,0x21,0x1b,0xff ; $3712
	dc.b	0x89,0x0a,0x89,0x0a,0x89,0x0a,0xff,0x33 ; $371a
	dc.b	0x1b,0x33,0x1b,0x33,0x1b,0xff,0x3c,0x1b ; $3722
	dc.b	0x3c,0x1b,0x3c,0x1b,0xff,0x3c,0x1b,0x3c ; $372a
	dc.b	0x1b,0x3c,0x1b,0xff,0x1e,0x0c,0x1e,0x0c ; $3732
	dc.b	0x1e,0x0c,0xff,0x1e,0x0c,0x1e,0x0c,0x1e ; $373a
	dc.b	0x0c,0xff,0x25,0x11,0x25,0x11,0x25,0x11 ; $3742
	dc.b	0x0d,0x60,0x1b,0x60,0x1b,0x60,0x1b,0xff ; $374a
	dc.b	0x89,0x0a,0x89,0x0a,0x89,0x0a,0x08,0x69 ; $3752
	dc.b	0x1b,0x69,0x1b,0x69,0x1b,0xff,0x89,0x0a ; $375a
	dc.b	0x89,0x0a,0x89,0x0a,0xff,0x7b,0x1b,0x7b ; $3762
	dc.b	0x1b,0x7b,0x1b,0xff,0x84,0x1b,0x84,0x1b ; $376a
	dc.b	0x84,0x1b,0xff,0x8d,0x1b,0x8d,0x1b,0x8d ; $3772
	dc.b	0x1b,0xff,0x96,0x1b,0x96,0x1b,0x96,0x1b ; $377a
	dc.b	0xff,0x9f,0x1b,0x9f,0x1b,0x9f,0x1b,0xff ; $3782
	dc.b	0xa8,0x1b,0xa8,0x1b,0xa8,0x1b,0xff,0xb1 ; $378a
	dc.b	0x1b,0xb1,0x1b,0xb1,0x1b,0xff,0xb1,0x1b ; $3792
	dc.b	0xb1,0x1b,0xb1,0x1b,0x00,0x01,0x14,0x00 ; $379a
	dc.b	0x01,0x15,0x00,0x01,0x16,0x00,0x01,0x17 ; $37a2
	dc.b	0x00,0x01,0x18,0x00,0x01,0x19,0x00,0x02 ; $37aa
	dc.b	0x1a,0x00,0x56,0x00,0x57,0x00,0x5e,0x00 ; $37b2
	dc.b	0x82,0x83,0x00,0x5f,0x00,0xf4,0x01,0x84 ; $37ba
	dc.b	0x00,0x02,0xf5,0x01,0xf6,0x01,0xf7,0x01 ; $37c2
	dc.b	0xf8,0x01,0x82,0xfb,0x01,0xfc,0x01,0xf9 ; $37ca
	dc.b	0x01,0xfa,0x01,0x42,0xf6,0x01,0xf5,0x01 ; $37d2
	dc.b	0xf8,0x01,0xf7,0x01,0x02,0xfd,0x01,0xfe ; $37da
	dc.b	0x01,0xff,0x01,0x01,0x02,0x01,0x85,0x03 ; $37e2
	dc.b	0x01,0x86,0x03,0x01,0x87,0x03,0x01,0x88 ; $37ea
	dc.b	0x03,0x02,0x89,0x03,0x8a,0x03,0x8b,0x03 ; $37f2
	dc.b	0x8c,0x03,0x02,0x8d,0x03,0x8e,0x03,0x8f ; $37fa
	dc.b	0x03,0x90,0x03,0x02,0x91,0x03,0x92,0x03 ; $3802
	dc.b	0x93,0x03,0x94,0x03,0x01,0xe0,0x03,0x01 ; $380a
	dc.b	0xe6,0x03,0x02,0xe1,0x03,0xe7,0x03,0xe8 ; $3812
	dc.b	0x03,0xe9,0x03,0x02,0xe2,0x03,0xe3,0x03 ; $381a
	dc.b	0xe4,0x03,0xe5,0x03,0x01,0xed,0x03,0x01 ; $3822
	dc.b	0xf0,0x03,0x81,0xed,0x03,0x81,0xf0,0x03 ; $382a
	dc.b	0x01,0xee,0x03,0x01,0xef,0x03,0x01,0xbe ; $3832
	dc.b	0x04,0x01,0xbf,0x04,0x01,0xc0,0x04,0x01 ; $383a
	dc.b	0xc1,0x04,0x01,0xc2,0x04,0x01,0xc3,0x04 ; $3842
	dc.b	0x9f,0x37,0xfe,0x00,0x4a,0x38,0x4a,0x38 ; $384a
	dc.b	0x01,0xb1,0x37,0xff,0x00,0xff,0xff,0xff ; $3852
	dc.b	0xff,0x08,0xba,0x37,0xfe,0x00,0x5c,0x38 ; $385a
	dc.b	0x5c,0x38,0x01,0xde,0x37,0xff,0x00,0xff ; $3862
	dc.b	0xff,0xff,0xff,0x08,0xe7,0x37,0xfe,0x00 ; $386a
	dc.b	0x6e,0x38,0x6e,0x38,0x01,0xf3,0x37,0xff ; $3872
	dc.b	0x00,0x80,0x38,0x80,0x38,0x08,0xfc,0x37 ; $387a
	dc.b	0xff,0x00,0x89,0x38,0x89,0x38,0x08,0x05 ; $3882
	dc.b	0x38,0xff,0x00,0xff,0xff,0xff,0xff,0x08 ; $388a
	dc.b	0x0e,0x38,0xfe,0x00,0x92,0x38,0x92,0x38 ; $3892
	dc.b	0x01,0x14,0x38,0xff,0x00,0xa4,0x38,0xa4 ; $389a
	dc.b	0x38,0x08,0x1d,0x38,0xff,0x00,0xff,0xff ; $38a2
	dc.b	0xff,0xff,0x08,0x26,0x38,0xfe,0x00,0xad ; $38aa
	dc.b	0x38,0xad,0x38,0x01,0x32,0x38,0xff,0x00 ; $38b2
	dc.b	0xbf,0x38,0xbf,0x38,0x08,0x35,0x38,0xff ; $38ba
	dc.b	0x00,0xff,0xff,0xff,0xff,0x08,0x38,0x38 ; $38c2
	dc.b	0xfe,0x00,0xc8,0x38,0xc8,0x38,0x01,0x3b ; $38ca
	dc.b	0x38,0xff,0x00,0xda,0x38,0xda,0x38,0x08 ; $38d2
	dc.b	0x3e,0x38,0xff,0x00,0xff,0xff,0xff,0xff ; $38da
	dc.b	0x08,0x41,0x38,0xfe,0x00,0xe3,0x38,0xe3 ; $38e2
	dc.b	0x38,0x01,0x44,0x38,0xff,0x00,0xf5,0x38 ; $38ea
	dc.b	0xf5,0x38,0x08,0x47,0x38,0xff,0x00,0xff ; $38f2
	dc.b	0xff,0xff,0xff,0x08,0x03,0x00,0x00,0x00 ; $38fa
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $3902
	dc.b	0x00,0x69,0x04,0x6a,0x04,0x6b,0x04,0x6c ; $390a
	dc.b	0x04,0x00,0x00,0x6d,0x04,0x6e,0x04,0xff ; $3912
	dc.b	0x03,0x6f,0x04,0x00,0x00,0x70,0x04,0x71 ; $391a
	dc.b	0x04,0x72,0x04,0x73,0x04,0x03,0x00,0x00 ; $3922
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $392a
	dc.b	0x00,0x00,0x69,0x04,0x6a,0x04,0x6b,0x04 ; $3932
	dc.b	0xc4,0x04,0x00,0x00,0x6d,0x04,0x6e,0x04 ; $393a
	dc.b	0xff,0x03,0x79,0x04,0x00,0x00,0x75,0x04 ; $3942
	dc.b	0x76,0x04,0x77,0x04,0x78,0x04,0x03,0x00 ; $394a
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $3952
	dc.b	0x00,0x00,0x00,0x69,0x04,0x6a,0x04,0x6b ; $395a
	dc.b	0x04,0x6c,0x04,0x00,0x00,0x6d,0x04,0x6e ; $3962
	dc.b	0x04,0xff,0x03,0x6f,0x04,0x00,0x00,0x74 ; $396a
	dc.b	0x04,0x71,0x04,0x72,0x04,0x73,0x04,0x03 ; $3972
	dc.b	0x18,0x05,0x19,0x05,0x00,0x00,0x00,0x00 ; $397a
	dc.b	0x00,0x00,0x99,0x04,0x69,0x04,0x6a,0x04 ; $3982
	dc.b	0x6b,0x04,0x6c,0x04,0x00,0x00,0x6d,0x04 ; $398a
	dc.b	0x6e,0x04,0xff,0x03,0x6f,0x04,0x00,0x00 ; $3992
	dc.b	0x70,0x04,0x71,0x04,0x72,0x04,0x73,0x04 ; $399a
	dc.b	0x03,0x18,0x05,0x19,0x05,0x00,0x00,0x00 ; $39a2
	dc.b	0x00,0x00,0x00,0x99,0x04,0x69,0x04,0x6a ; $39aa
	dc.b	0x04,0x6b,0x04,0xc4,0x04,0x00,0x00,0x6d ; $39b2
	dc.b	0x04,0x6e,0x04,0xff,0x03,0x79,0x04,0x00 ; $39ba
	dc.b	0x00,0x75,0x04,0x76,0x04,0x77,0x04,0x78 ; $39c2
	dc.b	0x04,0x03,0x00,0x00,0x00,0x00,0x00,0x00 ; $39ca
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x69,0x04 ; $39d2
	dc.b	0x6a,0x04,0x6b,0x04,0x6c,0x04,0x00,0x00 ; $39da
	dc.b	0x7a,0x04,0x7b,0x04,0xff,0x03,0x6f,0x04 ; $39e2
	dc.b	0x00,0x00,0x70,0x04,0x71,0x04,0x72,0x04 ; $39ea
	dc.b	0x73,0x04,0x03,0x00,0x00,0x00,0x00,0x00 ; $39f2
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x69 ; $39fa
	dc.b	0x04,0x6a,0x04,0x6b,0x04,0xc4,0x04,0x00 ; $3a02
	dc.b	0x00,0x7a,0x04,0x7b,0x04,0xff,0x03,0x79 ; $3a0a
	dc.b	0x04,0x00,0x00,0x75,0x04,0x76,0x04,0x77 ; $3a12
	dc.b	0x04,0x78,0x04,0xfe,0x38,0x00,0x00,0x26 ; $3a1a
	dc.b	0x3a,0x26,0x3a,0x04,0xa2,0x39,0x00,0x00 ; $3a22
	dc.b	0x2f,0x3a,0x2f,0x3a,0x04,0x79,0x39,0x00 ; $3a2a
	dc.b	0x00,0x38,0x3a,0x38,0x3a,0x04,0x27,0x39 ; $3a32
	dc.b	0xfc,0x00,0x41,0x3a,0x41,0x3a,0x04,0x50 ; $3a3a
	dc.b	0x39,0xfc,0x00,0x4a,0x3a,0x4a,0x3a,0x04 ; $3a42
	dc.b	0x27,0x39,0xfc,0x00,0x53,0x3a,0x53,0x3a ; $3a4a
	dc.b	0x04,0xfe,0x38,0xfc,0x00,0x5c,0x3a,0x5c ; $3a52
	dc.b	0x3a,0x04,0x27,0x39,0xfc,0x00,0x65,0x3a ; $3a5a
	dc.b	0x65,0x3a,0x04,0x50,0x39,0xfc,0x00,0x6e ; $3a62
	dc.b	0x3a,0x6e,0x3a,0x04,0xa2,0x39,0xfc,0x00 ; $3a6a
	dc.b	0x77,0x3a,0x77,0x3a,0x04,0x79,0x39,0xfc ; $3a72
	dc.b	0x00,0x38,0x3a,0x38,0x3a,0x04,0xcb,0x39 ; $3a7a
	dc.b	0x04,0x04,0x89,0x3a,0x89,0x3a,0x08,0xf4 ; $3a82
	dc.b	0x39,0x04,0x04,0x92,0x3a,0x92,0x3a,0x10 ; $3a8a
	dc.b	0xf4,0x39,0x00,0x04,0xff,0xff,0xff,0xff ; $3a92
	dc.b	0x10,0x00 ; $3a9a
; a shitload of frame tables here!!!
; then code resumes

3A9C: CD 4B B0    call load_iy_with_player_structure_B04B
3A9F: CD 18 B0    call clear_player_structure_partial_b012
3AA2: CD 41 96    call $3C41
3AA5: CD B0 96    call $3CB0
3AA8: CD B9 40    call $40B3
3AAB: CD 59 41    call $4153
3AAE: 3A 11 63    ld   a,(background_and_state_bits_C911)
3AB1: E6 D0       and  $70
3AB3: FE 80       cp   $20
3AB5: CA 9E 96    jp   z,$3C3E
3AB8: 3A 11 63    ld   a,(background_and_state_bits_C911)
3ABB: CB BF       res  7,a
3ABD: FE 10       cp   $10
3ABF: D2 74 9A    jp   nc,$3AD4
3AC2: AF          xor  a
3AC3: FD E5       push iy
3AC5: CD 5A B0    call suspend_this_task_B05A
3AC8: FD E1       pop  iy
3ACA: FE 02       cp   $08
3ACC: CA F2 9B    jp   z,$3BF8
3ACF: FE 0A       cp   $0A
3AD1: C4 D5 B0    call nz,display_error_text_B075
3AD4: FD E5       push iy
3AD6: 06 06       ld   b,$0C
3AD8: 3A 82 60    ld   a,(player_2_attack_flags_C028)
3ADB: FE 0A       cp   $0A
3ADD: 3E 02       ld   a,$08
3ADF: CA E4 9A    jp   z,$3AE4
3AE2: 3E 03       ld   a,$09
3AE4: CD 57 B0    call task_manipulation_B05D
3AE7: A7          and  a
3AE8: C4 D5 B0    call nz,display_error_text_B075
3AEB: AF          xor  a
3AEC: CD 5A B0    call suspend_this_task_B05A
3AEF: FD E1       pop  iy
3AF1: FE 09       cp   $03
3AF3: CA E6 9B    jp   z,$3BEC
3AF6: FE 04       cp   $04
3AF8: CA E6 9B    jp   z,$3BEC
3AFB: FE 05       cp   $05
3AFD: CA E6 9B    jp   z,$3BEC
3B00: FE 02       cp   $08
3B02: CA F2 9B    jp   z,$3BF8
3B05: FE 10       cp   $10
3B07: CA E6 9B    jp   z,$3BEC
3B0A: FE 11       cp   $11
3B0C: CA F8 9B    jp   z,$3BF2
3B0F: FE 07       cp   $0D
3B11: C4 D5 B0    call nz,display_error_text_B075
3B14: CD AD 9E    call $3EA7
3B17: CD 3A 4D    call $479A
3B1A: CD C9 4C    call $4663
3B1D: CD 37 40    call $409D
3B20: CD B9 40    call $40B3
3B23: CD 59 41    call $4153
3B26: CD 5C 48    call $4256
3B29: A7          and  a
3B2A: CA 6D 9B    jp   z,$3BC7
3B2D: FD E5       push iy
3B2F: E5          push hl
3B30: F5          push af
3B31: 3E 09       ld   a,$03
3B33: 06 03       ld   b,$09
3B35: CD 57 B0    call task_manipulation_B05D
3B38: A7          and  a
3B39: C4 D5 B0    call nz,display_error_text_B075
3B3C: F1          pop  af
3B3D: E1          pop  hl
3B3E: FD E1       pop  iy
3B40: 47          ld   b,a
3B41: 3A 82 60    ld   a,(player_2_attack_flags_C028)
3B44: FE 0A       cp   $0A
3B46: 3E 0B       ld   a,$0B
3B48: CA 47 9B    jp   z,$3B4D
3B4B: 3E 0A       ld   a,$0A
3B4D: E5          push hl
3B4E: C5          push bc
3B4F: FD E5       push iy
3B51: CD 57 B0    call task_manipulation_B05D
3B54: A7          and  a
3B55: C4 D5 B0    call nz,display_error_text_B075
3B58: 3E 02       ld   a,$08
3B5A: 06 03       ld   b,$09
3B5C: CD 57 B0    call task_manipulation_B05D
3B5F: A7          and  a
3B60: C4 D5 B0    call nz,display_error_text_B075
3B63: 3E 03       ld   a,$09
3B65: 06 03       ld   b,$09
3B67: CD 57 B0    call task_manipulation_B05D
3B6A: A7          and  a
3B6B: C4 D5 B0    call nz,display_error_text_B075
3B6E: FD E1       pop  iy
3B70: FD 7E 0D    ld   a,(iy+$07)
3B73: 32 ED 61    ld   (unknown_C1E7),a
3B76: FD 7E 02    ld   a,(iy+$08)
3B79: 32 E2 61    ld   (unknown_C1E8),a
3B7C: CD 2D 44    call $4487
3B7F: C1          pop  bc
3B80: 3E 0D       ld   a,$07
3B82: FD E5       push iy
3B84: CD 57 B0    call task_manipulation_B05D
3B87: A7          and  a
3B88: C4 D5 B0    call nz,display_error_text_B075
3B8B: FD E1       pop  iy
3B8D: E1          pop  hl
3B8E: DD 21 87 60 ld   ix,players_type_human_or_cpu_flags_C02D
3B92: 3A 82 60    ld   a,(player_2_attack_flags_C028)
3B95: FE 0A       cp   $0A
3B97: C2 A4 9B    jp   nz,$3BA4
3B9A: DD CB 00 5C bit  2,(ix+$00)
3B9E: CA 15 96    jp   z,$3C15
3BA1: C3 B0 9B    jp   $3BB0
3BA4: FE 0B       cp   $0B
3BA6: C4 D5 B0    call nz,display_error_text_B075
3BA9: DD CB 00 5E bit  3,(ix+$00)
3BAD: CA 15 96    jp   z,$3C15
3BB0: 44          ld   b,h
3BB1: 3E 04       ld   a,$04
3BB3: C5          push bc
3BB4: FD E5       push iy
3BB6: CD 57 B0    call task_manipulation_B05D
3BB9: A7          and  a
3BBA: C4 D5 B0    call nz,display_error_text_B075
3BBD: FD E1       pop  iy
3BBF: C1          pop  bc
3BC0: 78          ld   a,b
3BC1: CD 12 B0    call $B018
3BC4: C3 15 96    jp   $3C15
3BC7: CD F7 4C    call player_management_routine_46FD
3BCA: A7          and  a
3BCB: CA 74 9A    jp   z,$3AD4
3BCE: FE 09       cp   $03
3BD0: CA E6 9B    jp   z,$3BEC
3BD3: FE 04       cp   $04
3BD5: CA E6 9B    jp   z,$3BEC
3BD8: FE 05       cp   $05
3BDA: CA E6 9B    jp   z,$3BEC
3BDD: FE 02       cp   $08
3BDF: CA F2 9B    jp   z,$3BF8
3BE2: FE 11       cp   $11
3BE4: CA F8 9B    jp   z,$3BF2
3BE7: FE 10       cp   $10
3BE9: C4 D5 B0    call nz,display_error_text_B075
3BEC: CD 05 44    call $4405
3BEF: C3 15 96    jp   $3C15
3BF2: CD 2D 44    call $4487
3BF5: C3 90 96    jp   $3C30
3BF8: CD 2D 44    call $4487
3BFB: FD E5       push iy
3BFD: 3E 03       ld   a,$09
3BFF: 06 03       ld   b,$09
3C01: CD 57 B0    call task_manipulation_B05D
3C04: A7          and  a
3C05: C4 D5 B0    call nz,display_error_text_B075
3C08: 3E 02       ld   a,$08
3C0A: 06 03       ld   b,$09
3C0C: CD 57 B0    call task_manipulation_B05D
3C0F: A7          and  a
3C10: C4 D5 B0    call nz,display_error_text_B075
3C13: FD E1       pop  iy
3C15: AF          xor  a
3C16: FD E5       push iy
3C18: CD 5A B0    call suspend_this_task_B05A
3C1B: FD E1       pop  iy
3C1D: FE 07       cp   $0D
3C1F: CA 15 96    jp   z,$3C15
3C22: A7          and  a
3C23: CA A5 9A    jp   z,$3AA5
3C26: FE 19       cp   $13
3C28: CA 9B 96    jp   z,$3C3B
3C2B: FE 18       cp   $12
3C2D: C4 D5 B0    call nz,display_error_text_B075
3C30: 3E 01       ld   a,$01
3C32: CD D8 B0    call play_sound_B072
3C35: CD B3 44    call $44B9
3C38: C3 9E 96    jp   $3C3E
3C3B: CD 17 45    call $451D
3C3E: CD 51 B0    call task_yield_B051
3C41: C9          ret
3C42: 3A 11 63    ld   a,(background_and_state_bits_C911)
3C45: CB BF       res  7,a
3C47: FE 01       cp   $01
3C49: C2 AD 96    jp   nz,$3CA7
3C4C: DD 21 A2 96 ld   ix,table_3CA8
3C50: 3A 82 60    ld   a,(player_2_attack_flags_C028)
3C53: FE 0A       cp   $0A
3C55: CA 57 96    jp   z,$3C5D
3C58: 11 04 00    ld   de,$0004
3C5B: DD 19       add  ix,de
3C5D: FD E5       push iy
3C5F: D1          pop  de
3C60: 21 0D 00    ld   hl,$0007
3C63: 19          add  hl,de
3C64: EB          ex   de,hl
3C65: DD E5       push ix
3C67: E1          pop  hl
3C68: 01 04 00    ld   bc,$0004
3C6B: ED B0       ldir
3C6D: CD B9 40    call $40B3
3C70: CD 59 41    call $4153
3C73: CD F7 4C    call player_management_routine_46FD
3C76: CD AD 9E    call $3EA7
3C79: CD 37 40    call $409D
3C7C: CD B9 40    call $40B3
3C7F: CD 59 41    call $4153
3C82: CD F7 4C    call player_management_routine_46FD
3C85: A7          and  a
3C86: C4 D5 B0    call nz,display_error_text_B075
3C89: FD 6E 0D    ld   l,(iy+$07)
3C8C: FD 66 02    ld   h,(iy+$08)
3C8F: CB BC       res  7,h
3C91: 11 B1 1B    ld   de,$1BB1		; immediate value
3C94: A7          and  a
3C95: ED 52       sbc  hl,de
3C97: C2 DC 96    jp   nz,$3C76
3C9A: FD E5       push iy
3C9C: 3E 02       ld   a,$08
3C9E: CD 5A B0    call suspend_this_task_B05A
3CA1: A7          and  a
3CA2: C4 D5 B0    call nz,display_error_text_B075
3CA5: FD E1       pop  iy
3CA7: C9          ret
table_3CA8:
	dc.b	0x72,0x1b,0x1f,0xd8,0x72,0x9b,0xdf,0xd8 ; table_3CA8
3CB0: 3A 11 63    ld   a,(background_and_state_bits_C911)
3CB3: E6 DF       and  $7F
3CB5: FE 50       cp   $50
3CB7: DA 7D 96    jp   c,$3CD7
3CBA: D6 50       sub  $50
; demo fight (blue title screen) There's a table but there is probably only
; one title screen remaining. Others are leftovers from first version where
; there were more demos in attract mode.
3CBC: 21 1D 97    ld   hl,table_3D17
3CBF: 3A 82 60    ld   a,(player_2_attack_flags_C028)
3CC2: FE 0A       cp   $0A
3CC4: CA 6A 96    jp   z,$3CCA
3CC7: 21 8D 97    ld   hl,table_3D27
3CCA: 3A 11 63    ld   a,(background_and_state_bits_C911)
3CCD: E6 DF       and  $7F
3CCF: D6 50       sub  $50
3CD1: CD 00 97    call init_player_data_3D00
3CD4: C3 F7 96    jp   $3CFD
; normal init
3CD7: 21 9D 97    ld   hl,table_3D37
3CDA: FE 90       cp   $30
3CDC: D4 D5 B0    call nc,display_error_text_B075
3CDF: FE 80       cp   $20
3CE1: DA EC 96    jp   c,$3CE6
3CE4: D6 80       sub  $20
; init player X with $30 coord (+$10)
3CE6: CD 00 97    call init_player_data_3D00
3CE9: 3A 82 60    ld   a,(player_2_attack_flags_C028)
3CEC: FE 0A       cp   $0A
3CEE: CA F7 96    jp   z,$3CFD
; player 2: symmetrize
3CF1: FD CB 02 FE set  7,(iy+$08)	; set direction facing left
3CF5: FD 7E 03    ld   a,(iy+$09)
3CF8: ED 44       neg				; negate 255-x or something
3CFA: FD 77 03    ld   (iy+$09),a
3CFD: C9          ret
3CFE: 00          nop
3CFF: 00          nop

; init player x,y whatever
; < a: background image / level index
; < iy: player struct to initialize (C240, C220)
init_player_data_3D00:
3D00: 87          add  a,a
3D01: 87          add  a,a
3D02: 4F          ld   c,a
3D03: 06 00       ld   b,$00
3D05: 09          add  hl,bc
3D06: FD E5       push iy
3D08: DD E1       pop  ix
3D0A: 0E 0D       ld   c,$07
3D0C: DD 09       add  ix,bc
3D0E: DD E5       push ix
3D10: D1          pop  de
3D11: 01 04 00    ld   bc,$0004
; copy 4 values from for ex 3D53 to C247
3D14: ED B0       ldir
3D16: C9          ret
; start stance, x,y for player 1
table_3D17:
	dc.b	0x89,0x0a,0x40 ; table_3D17
table_3D1A:
	dc.b	0xd0,0x89,0x0a,0x88,0x88,0x89,0x0a,0x88 ; table_3D1A
	dc.b	0x88,0x89,0x0a,0x40,0xc8 ; $3d22
table_3D27:
	dc.b	0x89,0x8a,0xc0,0xd0,0x89,0x8a,0x88,0x88 ; table_3D27
	dc.b	0x89,0x8a,0x88,0x88,0x89,0x0a,0x88,0x90 ; $3d2f
; normal table
table_3D37:
	dc.b	0x89,0x0a,0x30 ; table_3D37
table_3D3A:
	dc.b	0xc0,0x89,0x0a,0x30,0xe0,0x89,0x0a,0x30 ; table_3D3A
	dc.b	0xc0,0x89,0x0a,0x30,0xe0,0x89,0x0a,0x30 ; $3d42
	dc.b	0xe0,0x89,0x0a,0x30,0xe0,0x89,0x0a,0x30 ; $3d4a
	dc.b	0xe0,0x89,0x0a,0x30,0xe0,0x89,0x0a,0x30 ; $3d52
	dc.b	0xe0,0x89,0x0a,0x30,0xe0,0x89,0x0a,0x30 ; $3d5a
	dc.b	0xe0,0x89,0x0a,0x30,0xc0,0x89,0x0a,0x88 ; $3d62
	dc.b	0x88,0x89,0x0a,0x88,0x88,0x89,0x0a,0x88 ; $3d6a
	dc.b	0x88,0x89,0x0a,0x88,0x88 ; $3d72
table_3D77:
	dc.b	0x89,0x0a,0x60,0xc0,0x89,0x0a,0x88,0x88 ; table_3D77
	dc.b	0x89,0x0a,0x50,0xc0,0x89,0x0a,0x60,0xe0 ; $3d7f
	dc.b	0x89,0x0a,0x88,0x88,0x89,0x0a,0x60,0xe0 ; $3d87
	dc.b	0x89,0x0a,0x50,0xe0,0x89,0x0a,0x60,0xe0 ; $3d8f
	dc.b	0x89,0x0a,0x50,0xe0,0x89,0x0a,0x88,0x88 ; $3d97
	dc.b	0x89,0x0a,0x88,0x88,0x89,0x0a,0x50,0xc0 ; $3d9f
	dc.b	0x89,0x0a,0x88,0x88,0x89,0x0a,0x88,0x88 ; $3da7
	dc.b	0x89,0x0a,0x88,0x88,0x89,0x0a,0x88,0x88 ; $3daf

; probably move related, but not A.I. related (player movement)
3DB7: CD 4B B0 	  call load_iy_with_player_structure_B04B
3DBA: 3A 82 60    ld   a,(player_2_attack_flags_C028)
3DBD: FE 02       cp   $08
3DBF: C2 62 97    jp   nz,$3DC8
3DC2: CD BD B0    call read_p1_controls_B0B7
3DC5: C3 70 97    jp   $3DD0
3DC8: FE 03       cp   $09
3DCA: C4 D5 B0    call nz,display_error_text_B075
3DCD: CD BA B0    call read_p2_controls_B0BA
3DD0: 06 13       ld   b,$19
3DD2: 21 F2 97    ld   hl,table_3DF8
3DD5: 11 09 00    ld   de,$0003
3DD8: BE          cp   (hl)
3DD9: CA E9 97    jp   z,$3DE3
3DDC: 19          add  hl,de
3DDD: 10 F3       djnz $3DD8
3DDF: AF          xor  a
3DE0: C3 FD 97    jp   $3DF7
3DE3: 47          ld   b,a
3DE4: 23          inc  hl
3DE5: FD E5       push iy
3DE7: 11 40 00    ld   de,$0040
3DEA: FD 19       add  iy,de
3DEC: FD CB 02 DE bit  7,(iy+$08)
3DF0: FD E1       pop  iy
3DF2: CA FC 97    jp   z,$3DF6
3DF5: 23          inc  hl
3DF6: 7E          ld   a,(hl)
3DF7: C9          ret

table_3DF8:
	dc.b	0x00,0x00,0x00,0x20,0x01,0x02,0x10,0x02 ; table_3DF8
	dc.b	0x01,0x40,0x03,0x03,0x80,0x04,0x04,0x02 ; $3e00
	dc.b	0x05,0x0a,0x22,0x06,0x0c,0x12,0x07,0x0b ; $3e08
	dc.b	0x42,0x08,0x0d,0x82,0x09,0x0e,0x01,0x0a ; $3e10
	dc.b	0x05,0x21,0x0b,0x07,0x11,0x0c,0x06,0x41 ; $3e18
	dc.b	0x0d,0x08,0x81,0x0e,0x09,0x04,0x0f,0x0f ; $3e20
	dc.b	0x24,0x10,0x11,0x14,0x11,0x10,0x44,0x12 ; $3e28
	dc.b	0x12,0x84,0x13,0x13,0x08,0x14,0x14,0x28 ; $3e30
	dc.b	0x15,0x16,0x18,0x16,0x15,0x48,0x17,0x17 ; $3e38
	dc.b	0x88,0x18,0x18 ; $3e40

3E43: DD 21 3D 9E ld   ix,table_3E97
3E47: FD 6E 0D    ld   l,(iy+$07)
3E4A: FD 66 02    ld   h,(iy+$08)
3E4D: CB BC       res  7,h
3E4F: CD 03 B0    call check_hl_in_ix_list_B009
3E52: A7          and  a
3E53: CA D7 9E    jp   z,$3E7D
3E56: DD 21 9D 97 ld   ix,table_3D37
3E5A: 3A 11 63    ld   a,(background_and_state_bits_C911)
3E5D: E6 DF       and  $7F
3E5F: FE 80       cp   $20
3E61: D4 D5 B0    call nc,display_error_text_B075
3E64: 87          add  a,a
3E65: 87          add  a,a
3E66: 4F          ld   c,a
3E67: 06 00       ld   b,$00
3E69: DD 09       add  ix,bc
3E6B: FD 7E 0A    ld   a,(iy+$0a)
3E6E: DD BE 09    cp   (ix+$03)
3E71: CA D7 9E    jp   z,$3E7D
3E74: DA 2C 9E    jp   c,$3E86
3E77: DD 7E 09    ld   a,(ix+$03)
3E7A: FD 77 0A    ld   (iy+$0a),a
3E7D: FD 36 14 00 ld   (iy+$14),$00
3E81: 3E 00       ld   a,$00
3E83: C3 34 9E    jp   $3E94
3E86: FD 7E 0A    ld   a,(iy+$0a)
3E89: C6 08       add  a,$02
3E8B: FD 77 0A    ld   (iy+$0a),a
3E8E: FD 36 14 FF ld   (iy+$14),$FF
3E92: 3E FF       ld   a,$FF
3E94: C9          ret
3E95: 00          nop
3E96: 00          nop
table_3E97:
	dc.b	0xc2,0x19,0xdd,0x19,0xf8,0x19,0x13,0x1a ; table_3E97
	dc.b	0x2e,0x1a,0x49,0x1a,0x33,0x1b,0xff,0xff ; $3e9f
3EA7: CD 49 9E    call $3E43
3EAA: A7          and  a
3EAB: C2 38 9F    jp   nz,$3F92
3EAE: FD 6E 0D    ld   l,(iy+$07)
3EB1: FD 66 02    ld   h,(iy+$08)
3EB4: CB BC       res  7,h
3EB6: E5          push hl
3EB7: DD E1       pop  ix
3EB9: DD 6E 0C    ld   l,(ix+$06)
3EBC: DD 66 0D    ld   h,(ix+$07)
3EBF: 11 0D 00    ld   de,$0007
3EC2: FD 7E 0B    ld   a,(iy+$0b)
3EC5: 47          ld   b,a
3EC6: 7E          ld   a,(hl)
3EC7: FE FF       cp   $FF
3EC9: CA 74 9E    jp   z,$3ED4
3ECC: B8          cp   b
3ECD: CA 74 9E    jp   z,$3ED4
3ED0: 19          add  hl,de
3ED1: C3 6C 9E    jp   $3EC6
3ED4: E5          push hl
3ED5: DD 21 9B AA ld   ix,walk_frames_list_AA3B
3ED9: FD 6E 0D    ld   l,(iy+$07)
3EDC: FD 66 02    ld   h,(iy+$08)
3EDF: CB BC       res  7,h
3EE1: CD 03 B0    call check_hl_in_ix_list_B009
3EE4: E1          pop  hl
3EE5: A7          and  a
3EE6: CA 94 9F    jp   z,$3F34
3EE9: FD 5E 0D    ld   e,(iy+$07)
3EEC: FD 56 02    ld   d,(iy+$08)
3EEF: CB BA       res  7,d
3EF1: D5          push de
3EF2: DD E1       pop  ix
3EF4: DD 7E 02    ld   a,(ix+$08)
3EF7: FE 80       cp   $20
3EF9: CA 94 9F    jp   z,$3F34
; check attack distance (0,1,2 at C26C for player 2)
3EFC: FD 7E 06    ld   a,(iy+$0c)
3EFF: FE 08       cp   $02
3F01: C2 94 9F    jp   nz,$3F34
; player are close enough for long range attacks
; (probably unrelated to A.I. more for front kick / reverse punch variation)
3F04: FD 46 0B    ld   b,(iy+$0b)
3F07: 05          dec  b
3F08: C2 94 9F    jp   nz,$3F34
3F0B: DD 21 40 68 ld   ix,player_1_struct_C240
3F0F: 3A 82 60    ld   a,(player_2_attack_flags_C028)
3F12: FE 0A       cp   $0A
3F14: C2 1B 9F    jp   nz,$3F1B
3F17: DD 21 C0 68 ld   ix,player_2_struct_C260
3F1B: DD 5E 0D    ld   e,(ix+$07)
3F1E: DD 56 02    ld   d,(ix+$08)
3F21: CB BA       res  7,d
3F23: D5          push de
3F24: DD E1       pop  ix
3F26: DD 4E 02    ld   c,(ix+$08)
3F29: CB 79       bit  7,c
3F2B: CA 94 9F    jp   z,$3F34
3F2E: CD 39 9F    call $3F93
3F31: C3 38 9F    jp   $3F92

3F34: FD 7E 06    ld   a,(iy+$0c)
3F37: 23          inc  hl
3F38: A7          and  a
3F39: CA 4A 9F    jp   z,$3F4A
3F3C: FE 09       cp   $03
3F3E: D2 4A 9F    jp   nc,$3F4A
3F41: 23          inc  hl
3F42: 23          inc  hl
3F43: FE 01       cp   $01
3F45: CA 4A 9F    jp   z,$3F4A
3F48: 23          inc  hl
3F49: 23          inc  hl
3F4A: 5E          ld   e,(hl)
3F4B: 23          inc  hl
3F4C: 56          ld   d,(hl)
3F4D: D5          push de
3F4E: E1          pop  hl
3F4F: CB BC       res  7,h
3F51: E5          push hl
3F52: DD E1       pop  ix
3F54: FD 7E 02    ld   a,(iy+$08)
3F57: AA          xor  d
3F58: FA DC 9F    jp   m,$3F76
3F5B: FD 75 0D    ld   (iy+$07),l
3F5E: FD 74 02    ld   (iy+$08),h
3F61: FD 7E 03    ld   a,(iy+$09)
3F64: DD 86 08    add  a,(ix+$02)
; write current x position
3F67: FD 77 03    ld   (iy+$09),a
3F6A: FD 7E 0A    ld   a,(iy+$0a)
3F6D: DD 86 09    add  a,(ix+$03)
3F70: FD 77 0A    ld   (iy+$0a),a
3F73: C3 38 9F    jp   $3F92
3F76: FD 73 0D    ld   (iy+$07),e
3F79: CB FA       set  7,d
3F7B: FD 72 02    ld   (iy+$08),d
3F7E: DD 7E 08    ld   a,(ix+$02)
3F81: ED 44       neg
3F83: FD 86 03    add  a,(iy+$09)
3F86: FD 77 03    ld   (iy+$09),a
3F89: FD 7E 0A    ld   a,(iy+$0a)
3F8C: DD 86 09    add  a,(ix+$03)
3F8F: FD 77 0A    ld   (iy+$0a),a
3F92: C9          ret
3F93: DD 21 00 6F ld   ix,temp_numeric_buffer_CF00
3F97: CB B9       res  7,c
3F99: FD 7E 0D    ld   a,(iy+$07)
3F9C: DD 77 00    ld   (ix+$00),a
3F9F: FD 7E 02    ld   a,(iy+$08)
3FA2: DD 77 01    ld   (ix+$01),a
3FA5: FD 7E 03    ld   a,(iy+$09)
3FA8: DD 77 08    ld   (ix+$02),a
3FAB: FD 7E 0A    ld   a,(iy+$0a)
3FAE: DD 77 09    ld   (ix+$03),a
3FB1: FD 6E 0D    ld   l,(iy+$07)
3FB4: FD 66 02    ld   h,(iy+$08)
3FB7: CB BC       res  7,h
3FB9: 7E          ld   a,(hl)
3FBA: DD 77 04    ld   (ix+$04),a
3FBD: 23          inc  hl
3FBE: 7E          ld   a,(hl)
3FBF: DD 77 05    ld   (ix+$05),a
3FC2: DD E5       push ix
3FC4: DD 21 13 40 ld   ix,table_4019
3FC8: 06 00       ld   b,$00
3FCA: 79          ld   a,c
3FCB: 87          add  a,a
3FCC: 4F          ld   c,a
3FCD: DD 09       add  ix,bc
3FCF: DD 6E 00    ld   l,(ix+$00)
3FD2: DD 66 01    ld   h,(ix+$01)
3FD5: 7D          ld   a,l
3FD6: B4          or   h
3FD7: CC D5 B0    call z,display_error_text_B075
3FDA: FD 75 0D    ld   (iy+$07),l
3FDD: FD 74 02    ld   (iy+$08),h
3FE0: DD E1       pop  ix
3FE2: DD 5E 04    ld   e,(ix+$04)
3FE5: DD 56 05    ld   d,(ix+$05)
3FE8: DD E5       push ix
3FEA: 23          inc  hl
3FEB: 23          inc  hl
3FEC: 4E          ld   c,(hl)
3FED: 23          inc  hl
3FEE: 46          ld   b,(hl)
3FEF: C5          push bc
3FF0: DD E1       pop  ix
3FF2: CD 06 B0    call key_value_linear_search_B00C
3FF5: A7          and  a
3FF6: C4 D5 B0    call nz,display_error_text_B075
3FF9: DD E1       pop  ix
3FFB: DD CB 01 DE bit  7,(ix+$01)
3FFF: CA 0A 40    jp   z,$400A
4002: FD CB 02 FE set  7,(iy+$08)
4006: 7D          ld   a,l
4007: ED 44       neg
4009: 6F          ld   l,a
400A: 7D          ld   a,l
400B: DD 86 08    add  a,(ix+$02)
400E: FD 77 03    ld   (iy+$09),a
4011: 7C          ld   a,h
4012: DD 86 09    add  a,(ix+$03)
4015: FD 77 0A    ld   (iy+$0a),a
4018: C9          ret

* used for random seed or whatever
table_4000:
	dc.b	0x0a,0x40,0xf7,0x6b,0x08,0xfe,0xd7,0xe7 ; $4000
	dc.b	0x44,0xcf,0xd7,0x77,0x2c,0x02,0xf7,0xdd ; $4008
	dc.b	0x09,0xd6,0x77,0x2c,0x03,0xf7,0xdd,0x0a ; $4010
	dc.b	0x63,0x00,0x00,0xe2,0x1a,0x5b,0x1a,0x00 ; $4018
	dc.b	0x00,0xe2,0x1a,0x9a,0x1a,0x5b,0x1a,0x9a ; $4020
	dc.b	0x1a,0x5b,0x1a,0x00,0x00,0x00,0x00,0x5b ; $4028
	dc.b	0x1a,0x5b,0x1a,0xe2,0x1a,0x00,0x00,0x00 ; $4030
	dc.b	0x02,0x07,0x00,0x0d,0x02,0x08,0x00,0x1a ; $4038
	dc.b	0x02,0xfc,0x00,0x5b,0x02,0x00,0x00,0x27 ; $4040
	dc.b	0x02,0x04,0x00,0xf2,0x04,0xfd,0x00,0x1e ; $4048
	dc.b	0x03,0x02,0x00,0x34,0x02,0xf8,0x00,0xff ; $4050
	dc.b	0xff,0x00,0x02,0x06,0x00,0x0d,0x02,0x07 ; $4058
	dc.b	0x00,0x1a,0x02,0xfa,0x00,0x5b,0x02,0xff ; $4060
	dc.b	0x00,0x27,0x02,0x03,0x00,0xf2,0x04,0xfc ; $4068
	dc.b	0x00,0x1e,0x03,0x01,0x00,0x34,0x02,0xf7 ; $4070
	dc.b	0x00,0xff,0xff,0x00,0x02,0x07,0x00,0x0d ; $4078
	dc.b	0x02,0x08,0x00,0x1a,0x02,0xfc,0x00,0x5b ; $4080
	dc.b	0x02,0x00,0x00,0x27,0x02,0x04,0x00,0xf2 ; $4088
	dc.b	0x04,0xfe,0x00,0x1e,0x03,0x02,0x00,0x34 ; $4090
	dc.b	0x02,0xf9,0x00,0xff,0xff,0xf7,0xce,0x07 ; $4098
	dc.b	0xf7,0xcc,0x08,0x6b,0xb6,0x11,0x04,0x00 ; $40a0
	dc.b	0x13,0xde,0xec,0x7f,0x6a,0xb2,0x40,0x67 ; $40a8
	dc.b	0x72,0xb0,0x63,0x9a,0x11,0xc9,0x6b,0xbf ; $40b0
	dc.b	0xfe,0x50,0x6a,0xdc,0x40,0xfe,0x10,0x7a ; $40b8
	dc.b	0xdc,0x40,0x77,0x81,0x1c,0xc7,0xec,0xf0 ; $40c0
	dc.b	0xfe,0x10,0x6a,0x46,0x41,0x9a,0x28,0xc0 ; $40c8
	dc.b	0xfe,0x0b,0x6a,0x46,0x41,0x77,0x81,0x4c ; $40d0
	dc.b	0xc7,0x69,0x46,0x41,0x77,0x81,0x4c,0xc7 ; $40d8
	dc.b	0x9a,0x28,0xc0,0xfe,0x0b,0x6a,0x46,0x41 ; $40e0
	dc.b	0x77,0x81,0x1c,0xc7,0xf7,0xe5,0xf7,0x81 ; $40e8
	dc.b	0x60,0xc2,0xf7,0xce,0x07,0xf7,0xcc,0x08 ; $40f0
	dc.b	0x6b,0xb6,0x11,0x08,0x00,0x13,0xde,0x6b ; $40f8


table_4019:
	dc.b	0x00,0x00,0xe2,0x1a,0x5b,0x1a,0x00,0x00 ; table_4019
	dc.b	0xe2,0x1a,0x9a,0x1a,0x5b,0x1a,0x9a,0x1a ; $4021
	dc.b	0x5b,0x1a,0x00,0x00,0x00,0x00,0x5b,0x1a ; $4029
	dc.b	0x5b,0x1a,0xe2,0x1a,0x00,0x00,0x00,0x02 ; $4031
	dc.b	0x07,0x00,0x0d,0x02,0x08,0x00,0x1a,0x02 ; $4039
	dc.b	0xfc,0x00,0x5b,0x02,0x00,0x00,0x27,0x02 ; $4041
	dc.b	0x04,0x00,0xf2,0x04,0xfd,0x00,0x1e,0x03 ; $4049
	dc.b	0x02,0x00,0x34,0x02,0xf8,0x00,0xff,0xff ; $4051
	dc.b	0x00,0x02,0x06,0x00,0x0d,0x02,0x07,0x00 ; $4059
	dc.b	0x1a,0x02,0xfa,0x00,0x5b,0x02,0xff,0x00 ; $4061
	dc.b	0x27,0x02,0x03,0x00,0xf2,0x04,0xfc,0x00 ; $4069
	dc.b	0x1e,0x03,0x01,0x00,0x34,0x02,0xf7,0x00 ; $4071
	dc.b	0xff,0xff,0x00,0x02,0x07,0x00,0x0d,0x02 ; $4079
	dc.b	0x08,0x00,0x1a,0x02,0xfc,0x00,0x5b,0x02 ; $4081
	dc.b	0x00,0x00,0x27,0x02,0x04,0x00,0xf2,0x04 ; $4089
	dc.b	0xfe,0x00,0x1e,0x03,0x02,0x00,0x34,0x02 ; $4091
	dc.b	0xf9,0x00,0xff,0xff ; $4099
409D: FD 6E 0D    ld   l,(iy+$07)
40A0: FD 66 02    ld   h,(iy+$08)
40A3: CB BC       res  7,h
40A5: 11 04 00    ld   de,$0004
40A8: 19          add  hl,de
40A9: 7E          ld   a,(hl)
40AA: E6 DF       and  $7F
40AC: CA B8 40    jp   z,$40B2
40AF: CD D8 B0    call play_sound_B072
40B2: C9          ret

40B3: 3A 11 63    ld   a,(background_and_state_bits_C911)
40B6: CB BF       res  7,a
40B8: FE 50       cp   $50
40BA: CA 76 40    jp   z,$40DC
40BD: FE 10       cp   $10
40BF: DA 76 40    jp   c,$40DC
40C2: DD 21 16 6D ld   ix,unknown_C71C
40C6: E6 F0       and  $F0
40C8: FE 10       cp   $10
40CA: CA 4C 41    jp   z,$4146
40CD: 3A 82 60    ld   a,(player_2_attack_flags_C028)
40D0: FE 0B       cp   $0B
40D2: CA 4C 41    jp   z,$4146
40D5: DD 21 46 6D ld   ix,unknown_C74C
40D9: C3 4C 41    jp   $4146
40DC: DD 21 46 6D ld   ix,unknown_C74C
40E0: 3A 82 60    ld   a,(player_2_attack_flags_C028)
40E3: FE 0B       cp   $0B
40E5: CA 4C 41    jp   z,$4146
40E8: DD 21 16 6D ld   ix,unknown_C71C
40EC: FD E5       push iy
40EE: FD 21 C0 68 ld   iy,player_2_struct_C260
40F2: FD 6E 0D    ld   l,(iy+$07)
40F5: FD 66 02    ld   h,(iy+$08)
40F8: CB BC       res  7,h
40FA: 11 02 00    ld   de,$0008
40FD: 19          add  hl,de
40FE: 7E          ld   a,(hl)
40FF: CB BF       res  7,a
4101: FD E1       pop  iy
4103: FE 80       cp   $20
4105: CA 98 41    jp   z,$4132
4108: FE 08       cp   $02
410A: CA 98 41    jp   z,$4132
410D: FE 03       cp   $09
410F: CA 98 41    jp   z,$4132
4112: FE 0A       cp   $0A
4114: CA 98 41    jp   z,$4132
4117: FE 0E       cp   $0E
4119: CA 98 41    jp   z,$4132
411C: FD 6E 0D    ld   l,(iy+$07)
411F: FD 66 02    ld   h,(iy+$08)
4122: CB BC       res  7,h
4124: 11 04 00    ld   de,$0004
4127: 19          add  hl,de
4128: 7E          ld   a,(hl)
4129: CB 7F       bit  7,a
412B: C2 98 41    jp   nz,$4132
412E: DD 21 D6 6D ld   ix,unknown_C77C
4132: DD E5       push ix
4134: DD 21 16 6D ld   ix,unknown_C71C
4138: AF          xor  a
4139: CD 43 48    call $4249
413C: DD 21 D6 6D ld   ix,unknown_C77C
4140: AF          xor  a
4141: CD 43 48    call $4249
4144: DD E1       pop  ix
4146: 0E 01       ld   c,$01
4148: 3A 82 60    ld   a,(player_2_attack_flags_C028)
414B: FE 0A       cp   $0A
414D: CA 58 41    jp   z,$4152
4150: 0E 08       ld   c,$02
4152: C9          ret

4153: CD 27 4D    call get_current_frame_contents_478D
4156: E5          push hl
4157: 11 00 08    ld   de,$0200
415A: A7          and  a
415B: ED 52       sbc  hl,de
415D: 16 07       ld   d,$0D
415F: CD 09 B0    call $B003
4162: A7          and  a
4163: C4 D5 B0    call nz,display_error_text_B075
4166: 29          add  hl,hl
4167: 29          add  hl,hl
4168: 11 27 02    ld   de,$088D		; offset
416B: 19          add  hl,de
416C: 7E          ld   a,(hl)
416D: FD CB 02 DE bit  7,(iy+$08)
4171: CA DC 41    jp   z,$4176
4174: ED 44       neg
4176: FD 86 03    add  a,(iy+$09)
4179: D6 80       sub  $20
417B: DD 77 00    ld   (ix+$00),a
417E: DD 77 10    ld   (ix+$10),a
4181: DD 77 80    ld   (ix+$20),a
4184: C6 10       add  a,$10
4186: DD 77 04    ld   (ix+$04),a
4189: DD 77 14    ld   (ix+$14),a
418C: DD 77 84    ld   (ix+$24),a
418F: C6 10       add  a,$10
4191: DD 77 02    ld   (ix+$08),a
4194: DD 77 12    ld   (ix+$18),a
4197: DD 77 82    ld   (ix+$28),a
419A: C6 10       add  a,$10
419C: DD 77 06    ld   (ix+$0c),a
419F: DD 77 16    ld   (ix+$1c),a
41A2: DD 77 86    ld   (ix+$2c),a
41A5: FD 7E 0A    ld   a,(iy+$0a)
41A8: D6 90       sub  $30
41AA: DD 77 09    ld   (ix+$03),a
41AD: DD 77 0D    ld   (ix+$07),a
41B0: DD 77 0B    ld   (ix+$0b),a
41B3: DD 77 0F    ld   (ix+$0f),a
41B6: C6 10       add  a,$10
41B8: DD 77 19    ld   (ix+$13),a
41BB: DD 77 1D    ld   (ix+$17),a
41BE: DD 77 1B    ld   (ix+$1b),a
41C1: DD 77 1F    ld   (ix+$1f),a
41C4: C6 10       add  a,$10
41C6: DD 77 89    ld   (ix+$23),a
41C9: DD 77 8D    ld   (ix+$27),a
41CC: DD 77 8B    ld   (ix+$2b),a
41CF: DD 77 8F    ld   (ix+$2f),a
41D2: E1          pop  hl
41D3: 06 00       ld   b,$00
41D5: 7E          ld   a,(hl)
41D6: 07          rlca
41D7: 07          rlca
41D8: CB 18       rr   b
41DA: 07          rlca
41DB: 07          rlca
41DC: E6 D0       and  $70
41DE: B0          or   b
41DF: B1          or   c
41E0: FD CB 02 DE bit  7,(iy+$08)
41E4: CA E3 41    jp   z,$41E9
41E7: EE 20       xor  $80
41E9: DD E5       push ix
41EB: DD 23       inc  ix
41ED: DD 23       inc  ix
41EF: CD 43 48    call $4249
41F2: DD E1       pop  ix
41F4: 23          inc  hl
41F5: FD CB 02 DE bit  7,(iy+$08)
41F9: C2 07 48    jp   nz,$420D
41FC: 06 06       ld   b,$0C
41FE: 11 04 00    ld   de,$0004
4201: 7E          ld   a,(hl)
4202: DD 77 01    ld   (ix+$01),a
4205: 23          inc  hl
4206: DD 19       add  ix,de
4208: 10 FD       djnz $4201
420A: C3 42 48    jp   $4248
420D: 56          ld   d,(hl)
420E: DD 72 07    ld   (ix+$0d),d
4211: 23          inc  hl
4212: 56          ld   d,(hl)
4213: DD 72 03    ld   (ix+$09),d
4216: 23          inc  hl
4217: 56          ld   d,(hl)
4218: DD 72 05    ld   (ix+$05),d
421B: 23          inc  hl
421C: 56          ld   d,(hl)
421D: DD 72 01    ld   (ix+$01),d
4220: 23          inc  hl
4221: 56          ld   d,(hl)
4222: DD 72 17    ld   (ix+$1d),d
4225: 23          inc  hl
4226: 56          ld   d,(hl)
4227: DD 72 13    ld   (ix+$19),d
422A: 23          inc  hl
422B: 56          ld   d,(hl)
422C: DD 72 15    ld   (ix+$15),d
422F: 23          inc  hl
4230: 56          ld   d,(hl)
4231: DD 72 11    ld   (ix+$11),d
4234: 23          inc  hl
4235: 56          ld   d,(hl)
4236: DD 72 87    ld   (ix+$2d),d
4239: 23          inc  hl
423A: 56          ld   d,(hl)
423B: DD 72 83    ld   (ix+$29),d
423E: 23          inc  hl
423F: 56          ld   d,(hl)
4240: DD 72 85    ld   (ix+$25),d
4243: 23          inc  hl
4244: 56          ld   d,(hl)
4245: DD 72 81    ld   (ix+$21),d
4248: C9          ret
4249: 06 06       ld   b,$0C
424B: 11 04 00    ld   de,$0004
424E: DD 77 00    ld   (ix+$00),a
4251: DD 19       add  ix,de
4253: 10 F3       djnz $424E
4255: C9          ret

4256: 3A 11 63    ld   a,(background_and_state_bits_C911)
4259: CB BF       res  7,a
425B: FE 10       cp   $10
425D: DA C4 48    jp   c,$4264
4260: AF          xor  a
4261: C3 BC 49    jp   $43B6
4264: DD 21 6D 49 ld   ix,table_43C7
4268: FD 5E 0D    ld   e,(iy+$07)
426B: FD 56 02    ld   d,(iy+$08)
426E: CB BA       res  7,d
4270: CD 06 B0    call key_value_linear_search_B00C
4273: A7          and  a
4274: CA DB 48    jp   z,$427B
4277: AF          xor  a
4278: C3 BC 49    jp   $43B6
427B: E5          push hl
427C: DD 21 9F 46 ld   ix,table_4C3F
4280: FD 5E 0D    ld   e,(iy+$07)
4283: FD 56 02    ld   d,(iy+$08)
4286: CB BA       res  7,d
4288: CD 06 B0    call key_value_linear_search_B00C
428B: A7          and  a
428C: C4 D5 B0    call nz,display_error_text_B075
428F: FD 7E 0A    ld   a,(iy+$0a)
4292: 84          add  a,h
4293: 5F          ld   e,a
4294: FD 7E 03    ld   a,(iy+$09)
4297: FD CB 02 DE bit  7,(iy+$08)
429B: C2 A8 48    jp   nz,$42A2
429E: 85          add  a,l
429F: C3 A9 48    jp   $42A3
42A2: 95          sub  l
42A3: 57          ld   d,a
42A4: E1          pop  hl
42A5: FD E5       push iy
42A7: D5          push de
42A8: E5          push hl
42A9: FD 22 02 6F ld   (unknown_CF08),iy
42AD: FD 21 C0 68 ld   iy,player_2_struct_C260
42B1: 3A 82 60    ld   a,(player_2_attack_flags_C028)
42B4: FE 0A       cp   $0A
42B6: CA B7 48    jp   z,$42BD
42B9: FD 21 40 68 ld   iy,player_1_struct_C240
42BD: CD 27 4D    call get_current_frame_contents_478D
42C0: DD 21 00 6F ld   ix,temp_numeric_buffer_CF00
42C4: 11 00 08    ld   de,$0200
42C7: A7          and  a
42C8: ED 52       sbc  hl,de
42CA: 16 07       ld   d,$0D
42CC: CD 09 B0    call $B003
42CF: A7          and  a
42D0: C4 D5 B0    call nz,display_error_text_B075
42D3: 29          add  hl,hl
42D4: 29          add  hl,hl
42D5: 11 27 02    ld   de,$088D		; offset
42D8: 19          add  hl,de
42D9: 23          inc  hl
42DA: 23          inc  hl
42DB: 23          inc  hl
42DC: FD 7E 0A    ld   a,(iy+$0a)
42DF: 86          add  a,(hl)
42E0: DD 77 08    ld   (ix+$02),a
42E3: DD 77 0C    ld   (ix+$06),a
42E6: 7E          ld   a,(hl)
42E7: ED 44       neg
42E9: DD 77 09    ld   (ix+$03),a
42EC: DD 77 0D    ld   (ix+$07),a
42EF: 21 65 49    ld   hl,table_43C5
42F2: FD 7E 03    ld   a,(iy+$09)
42F5: 96          sub  (hl)
42F6: DD 77 00    ld   (ix+$00),a
42F9: 7E          ld   a,(hl)
42FA: 87          add  a,a
42FB: DD 77 01    ld   (ix+$01),a
42FE: 23          inc  hl
42FF: FD 7E 03    ld   a,(iy+$09)
4302: 96          sub  (hl)
4303: DD 77 04    ld   (ix+$04),a
4306: 7E          ld   a,(hl)
4307: 87          add  a,a
4308: DD 77 05    ld   (ix+$05),a
430B: FD E5       push iy
430D: C3 49 49    jp   $4343
4310: FD 2A 02 6F ld   iy,(unknown_CF08)
4314: FD 7E 0B    ld   a,(iy+$0b)
4317: FD BE 18    cp   (iy+$12)
431A: CA 8F 49    jp   z,$432F
431D: FD 7E 0D    ld   a,(iy+$07)
4320: FD BE 10    cp   (iy+$10)
4323: C2 49 49    jp   nz,$4343
4326: FD 7E 02    ld   a,(iy+$08)
4329: FD BE 11    cp   (iy+$11)
432C: C2 49 49    jp   nz,$4343
432F: DD 7E 00    ld   a,(ix+$00)
4332: C6 09       add  a,$03
4334: DD 77 00    ld   (ix+$00),a
4337: DD 36 01 09 ld   (ix+$01),$03
433B: 3D          dec  a
433C: DD 77 04    ld   (ix+$04),a
433F: DD 36 05 05 ld   (ix+$05),$05
4343: FD E1       pop  iy
4345: E1          pop  hl
4346: D1          pop  de
4347: CD 48 B0    call is_point_in_rectangle_B042
434A: A7          and  a
434B: CA 56 49    jp   z,$435C
434E: 06 04       ld   b,$04
4350: 7C          ld   a,h
4351: FE 05       cp   $05
4353: D2 52 49    jp   nc,$4358
4356: 06 05       ld   b,$05
4358: 78          ld   a,b
4359: C3 C6 49    jp   $436C
435C: 01 04 00    ld   bc,$0004
435F: DD 09       add  ix,bc
4361: CD 48 B0    call is_point_in_rectangle_B042
4364: A7          and  a
4365: CA C6 49    jp   z,$436C
4368: 3E 05       ld   a,$05
436A: CB 0C       rrc  h
436C: A7          and  a
436D: CA B4 49    jp   z,$43B4
4370: F5          push af
4371: E5          push hl
4372: DD 21 BD 49 ld   ix,table_43B7
4376: FD 5E 0D    ld   e,(iy+$07)
4379: FD 56 02    ld   d,(iy+$08)
437C: CB BA       res  7,d
437E: CD 06 B0    call key_value_linear_search_B00C
4381: D1          pop  de
4382: C1          pop  bc
4383: A7          and  a
4384: C2 39 49    jp   nz,$4393
4387: 7D          ld   a,l
4388: BB          cp   e
4389: C2 39 49    jp   nz,$4393
438C: AF          xor  a
438D: 21 00 00    ld   hl,$0000
4390: C3 B4 49    jp   $43B4
4393: EB          ex   de,hl
4394: 78          ld   a,b
4395: FD 2A 02 6F ld   iy,(unknown_CF08)
4399: FD 4E 0D    ld   c,(iy+$07)
439C: FD 46 02    ld   b,(iy+$08)
439F: FD 71 10    ld   (iy+$10),c
43A2: FD 70 11    ld   (iy+$11),b
43A5: C5          push bc
43A6: DD E1       pop  ix
43A8: DD 46 02    ld   b,(ix+$08)
43AB: FD 70 19    ld   (iy+$13),b
43AE: FD 46 0B    ld   b,(iy+$0b)
43B1: FD 70 18    ld   (iy+$12),b
43B4: FD E1       pop  iy
43B6: C9          ret
table_43B7:
	dc.b	0x88,0x1a,0x01,0x01,0xd0,0x1a
table_43C5:
	dc.b	0x02,0x02 ; table_43B7
table_43C7:
	dc.b	0x18,0x1b,0x03,0x03,0xff,0xff,0x04,0x08 ; $43bf
	dc.b	0x4a,0x13,0x00,0x02,0xd5,0x12,0x03,0x08 ; table_43C7
	dc.b	0xe2,0x11,0x01,0x0a,0x6d,0x11,0x01,0x06 ; $43cf
	dc.b	0x0a,0x11,0x00,0x06,0x9e,0x10,0x00,0x04 ; $43d7
	dc.b	0x0e,0x10,0x01,0x0a,0x90,0x0f,0x02,0x04 ; $43df
	dc.b	0x1b,0x0f,0x01,0x0a,0xaf,0x0e,0x02,0x02 ; $43e7
	dc.b	0x4c,0x0e,0x03,0x02,0xd7,0x0d,0x00,0x02 ; $43ef
	dc.b	0x47,0x0d,0x01,0x0a,0xc0,0x0c,0x03,0x04 ; $43f7
	dc.b	0xd2,0x0c,0x03,0x04,0xff,0xff ; $43ff
4405: FD E5       push iy
4407: FD 21 40 68 ld   iy,player_1_struct_C240
440B: 3A 82 60    ld   a,(player_2_attack_flags_C028)
440E: FE 0B       cp   $0B
4410: CA 1D 44    jp   z,$4417
4413: FD 21 C0 68 ld   iy,player_2_struct_C260
4417: CD 27 4D    call get_current_frame_contents_478D
441A: FD E1       pop  iy
441C: FD 75 07    ld   (iy+$0d),l
441F: FD 74 0E    ld   (iy+$0e),h
4422: 3E 04       ld   a,$04
4424: FD E5       push iy
4426: CD 5A B0    call suspend_this_task_B05A
4429: FD E1       pop  iy
442B: FE 07       cp   $0D
442D: CA 88 44    jp   z,$4422
4430: A7          and  a
4431: C4 D5 B0    call nz,display_error_text_B075
4434: 78          ld   a,b
4435: FE 06       cp   $0C
4437: DA 40 44    jp   c,$4440
443A: CD 70 45    call $45D0
443D: C3 49 44    jp   $4443
4440: CD 9C 45    call $4536
4443: CD 37 40    call $409D
4446: CD B9 40    call $40B3
4449: CD 59 41    call $4153
444C: CD F7 4C    call player_management_routine_46FD
444F: FE 07       cp   $0D
4451: CA 46 44    jp   z,$444C
4454: FE 02       cp   $08
4456: CA 57 44    jp   z,$445D
4459: A7          and  a
445A: C4 D5 B0    call nz,display_error_text_B075
445D: CD AD 9E    call $3EA7
4460: CD C9 4C    call $4663
4463: CD 37 40    call $409D
4466: CD B9 40    call $40B3
4469: CD 59 41    call $4153
446C: CD F7 4C    call player_management_routine_46FD
446F: FE 07       cp   $0D
4471: CA C6 44    jp   z,$446C
4474: A7          and  a
4475: C4 D5 B0    call nz,display_error_text_B075
4478: CD 27 4D    call get_current_frame_contents_478D
447B: DD 21 1A 4C ld   ix,table_461A
447F: CD 03 B0    call check_hl_in_ix_list_B009
4482: A7          and  a
4483: CA 57 44    jp   z,$445D
4486: C9          ret
4487: CD F7 4C    call player_management_routine_46FD
448A: A7          and  a
448B: C4 D5 B0    call nz,display_error_text_B075
; reached when player is hit, same c42B (technique index)
; value written with 2 now...
448E: FD 36 0B 08 ld   (iy+$0b),$02
4492: 01 23 0A    ld   bc,$0A89
4495: C5          push bc
4496: CD AD 9E    call $3EA7
4499: CD C9 4C    call $4663
449C: CD B9 40    call $40B3
449F: CD 59 41    call $4153
44A2: CD F7 4C    call player_management_routine_46FD
44A5: A7          and  a
44A6: C4 D5 B0    call nz,display_error_text_B075
44A9: C1          pop  bc
44AA: FD 6E 0D    ld   l,(iy+$07)
44AD: FD 66 02    ld   h,(iy+$08)
44B0: CB BC       res  7,h
44B2: A7          and  a
44B3: ED 42       sbc  hl,bc
44B5: C2 35 44    jp   nz,$4495
44B8: C9          ret
44B9: FD E5       push iy
44BB: 3E 96       ld   a,$3C
44BD: CD 5A B0    call suspend_this_task_B05A
44C0: FD E1       pop  iy
44C2: CD B9 40    call $40B3
44C5: DD E5       push ix
44C7: AF          xor  a
44C8: CD 43 48    call $4249
44CB: DD E1       pop  ix
44CD: 06 05       ld   b,$05
44CF: FD 7E 03    ld   a,(iy+$09)
44D2: D6 02       sub  $08
44D4: 67          ld   h,a
44D5: FD 7E 0A    ld   a,(iy+$0a)
44D8: D6 40       sub  $40
44DA: 6F          ld   l,a
44DB: FD E5       push iy
44DD: C5          push bc
44DE: E5          push hl
44DF: DD E5       push ix
44E1: 7D          ld   a,l
44E2: 90          sub  b
44E3: 6F          ld   l,a
44E4: 06 1C       ld   b,$16
44E6: 3A 82 60    ld   a,(player_2_attack_flags_C028)
44E9: FE 0A       cp   $0A
44EB: CA F0 44    jp   z,$44F0
44EE: 06 12       ld   b,$18
44F0: 78          ld   a,b
44F1: CD A8 B0    call $B0A2
44F4: 3E 10       ld   a,$10
44F6: CD 5A B0    call suspend_this_task_B05A
44F9: DD E1       pop  ix
44FB: E1          pop  hl
44FC: E5          push hl
44FD: DD E5       push ix
44FF: 06 1D       ld   b,$17
4501: 3A 82 60    ld   a,(player_2_attack_flags_C028)
4504: FE 0A       cp   $0A
4506: CA 0B 45    jp   z,$450B
4509: 06 13       ld   b,$19
450B: 78          ld   a,b
450C: CD A8 B0    call $B0A2
450F: 3E 10       ld   a,$10
4511: CD 5A B0    call suspend_this_task_B05A
4514: DD E1       pop  ix
4516: E1          pop  hl
4517: C1          pop  bc
4518: 10 69       djnz $44DD
451A: FD E1       pop  iy
451C: C9          ret
451D: FD E5       push iy
451F: 3E 96       ld   a,$3C
4521: CD 5A B0    call suspend_this_task_B05A
4524: FD E1       pop  iy
4526: 21 A2 1B    ld   hl,$1BA8		; immediate value
4529: FD 75 0D    ld   (iy+$07),l
452C: FD 74 02    ld   (iy+$08),h
452F: CD B9 40    call $40B3
4532: CD 59 41    call $4153
4535: C9          ret

4536: DD 21 40 68 ld   ix,player_1_struct_C240
453A: 3A 82 60    ld   a,(player_2_attack_flags_C028)
453D: FE 0A       cp   $0A
453F: C2 4C 45    jp   nz,$4546
4542: DD 21 C0 68 ld   ix,player_2_struct_C260
4546: 21 59 4C    ld   hl,table_4653
4549: 11 02 00    ld   de,$0008
454C: FD CB 02 DE bit  7,(iy+$08)
4550: C2 C0 45    jp   nz,$4560
4553: FD 7E 03    ld   a,(iy+$09)
4556: DD 96 03    sub  (ix+$09)
4559: DA CA 45    jp   c,$456A
455C: 19          add  hl,de
455D: C3 CA 45    jp   $456A
4560: FD 7E 03    ld   a,(iy+$09)
4563: DD 96 03    sub  (ix+$09)
4566: D2 CA 45    jp   nc,$456A
4569: 19          add  hl,de
456A: E5          push hl
456B: FD 5E 07    ld   e,(iy+$0d)
456E: FD 56 0E    ld   d,(iy+$0e)
4571: DD 21 8C 4C ld   ix,table_4626
4575: DD 6E 00    ld   l,(ix+$00)
4578: DD 66 01    ld   h,(ix+$01)
457B: 7D          ld   a,l
457C: A4          and  h
457D: FE FF       cp   $FF
457F: CC D5 B0    call z,display_error_text_B075
4582: A7          and  a
4583: ED 52       sbc  hl,de
4585: CA 31 45    jp   z,$4591
4588: DD 23       inc  ix
458A: DD 23       inc  ix
458C: DD 23       inc  ix
458E: C3 D5 45    jp   $4575
4591: DD 7E 08    ld   a,(ix+$02)
4594: E1          pop  hl
4595: 87          add  a,a
4596: 4F          ld   c,a
4597: 06 00       ld   b,$00
4599: 09          add  hl,bc
459A: 5E          ld   e,(hl)
459B: 23          inc  hl
459C: 56          ld   d,(hl)
459D: D5          push de
459E: CD FF 45    call $45FF
45A1: FD CB 02 DE bit  7,(iy+$08)
45A5: CA AA 45    jp   z,$45AA
45A8: ED 44       neg
45AA: FD 86 03    add  a,(iy+$09)
45AD: FD 77 03    ld   (iy+$09),a
45B0: E1          pop  hl
45B1: FD 7E 02    ld   a,(iy+$08)
45B4: E6 20       and  $80
45B6: B4          or   h
45B7: FD 75 0D    ld   (iy+$07),l
45BA: FD 77 02    ld   (iy+$08),a
45BD: CD FF 45    call $45FF
45C0: FD CB 02 DE bit  7,(iy+$08)
45C4: C2 63 45    jp   nz,$45C9
45C7: ED 44       neg
45C9: FD 86 03    add  a,(iy+$09)
45CC: FD 77 03    ld   (iy+$09),a
45CF: C9          ret
45D0: 50          ld   d,b
45D1: 1E 80       ld   e,$20
45D3: CD 00 B0    call $B000
45D6: DD 21 00 61 ld   ix,task_struct_C100
45DA: DD 19       add  ix,de
45DC: 21 F9 45    ld   hl,table_45F3
45DF: FD 7E 02    ld   a,(iy+$08)
45E2: DD AE 02    xor  (ix+$08)
45E5: E6 20       and  $80
45E7: C2 E7 45    jp   nz,$45ED
45EA: 21 F3 45    ld   hl,table_45F9
45ED: DD 7E 0B    ld   a,(ix+$0b)
45F0: C3 35 45    jp   $4595
table_45F3:
	dc.b	0x40,0x1a,0x2a,0x1b,0xef,0x19 ; table_45F3
table_45F9:
	dc.b	0xb9,0x19,0x0a,0x1a,0xef,0x19 ; table_45F9
45FF: CD 27 4D    call get_current_frame_contents_478D
4602: 01 00 08    ld   bc,$0200
4605: A7          and  a
4606: ED 42       sbc  hl,bc
4608: 16 07       ld   d,$0D
460A: CD 09 B0    call $B003
460D: A7          and  a
460E: C4 D5 B0    call nz,display_error_text_B075
4611: 29          add  hl,hl
4612: 29          add  hl,hl
4613: 11 27 02    ld   de,$088D		; offset
4616: 19          add  hl,de
4617: 23          inc  hl
4618: 7E          ld   a,(hl)
4619: C9          ret
table_461A:
	dc.b	0x6f,0x07,0xa3,0x07,0xca,0x07,0xf1,0x07 ; table_461A
	dc.b	0x18,0x08,0xff,0xff ; $4622
table_4626:
	dc.b	0xa9,0x02,0x02,0xd0,0x02,0x00,0xf7,0x02 ; table_4626
	dc.b	0x01,0x2b,0x03,0x02,0x49,0x04,0x02,0x52 ; $462e
	dc.b	0x03,0x01,0x6c,0x03,0x02,0x86,0x03,0x00 ; $4636
	dc.b	0xfb,0x03,0x01,0x63,0x04,0x03,0xad,0x03 ; $463e
	dc.b	0x00,0xd4,0x03,0x00,0x22,0x04,0x02,0xd8 ; $4646
	dc.b	0x04,0x01,0xff,0xff,0xff ; $464e
table_4653:
	dc.b	0xb9,0x19,0xef,0x19,0x0a,0x1a,0xd4,0x19 ; table_4653
	dc.b	0x40,0x1a,0xef,0x19,0x2a,0x1b,0xd4,0x19 ; $465b
4663: DD 21 40 68 ld   ix,player_1_struct_C240
4667: 21 1A 97    ld   hl,table_3D1A
466A: 3A 11 63    ld   a,(background_and_state_bits_C911)
466D: E6 DF       and  $7F
466F: FE 50       cp   $50
4671: CA 28 4C    jp   z,$4682
4674: 21 9A 97    ld   hl,table_3D3A
4677: 3A 11 63    ld   a,(background_and_state_bits_C911)
467A: CB BF       res  7,a
467C: 87          add  a,a
467D: 87          add  a,a
467E: 4F          ld   c,a
467F: 06 00       ld   b,$00
4681: 09          add  hl,bc
4682: 3A 11 63    ld   a,(background_and_state_bits_C911)
4685: E6 D0       and  $70
4687: FE 10       cp   $10
4689: CA 7C 4C    jp   z,$46D6
468C: 7E          ld   a,(hl)
468D: DD BE 0A    cp   (ix+$0a)
4690: C2 7C 4C    jp   nz,$46D6
4693: DD 21 C0 68 ld   ix,player_2_struct_C260
4697: 7E          ld   a,(hl)
4698: DD BE 0A    cp   (ix+$0a)
469B: C2 7C 4C    jp   nz,$46D6
469E: DD 21 C0 68 ld   ix,player_2_struct_C260
46A2: 3A 82 60    ld   a,(player_2_attack_flags_C028)
46A5: FE 0A       cp   $0A
46A7: CA AE 4C    jp   z,$46AE
46AA: DD 21 40 68 ld   ix,player_1_struct_C240
46AE: FD 7E 03    ld   a,(iy+$09)
46B1: DD 96 03    sub  (ix+$09)
46B4: DA 6D 4C    jp   c,$46C7
46B7: FE 10       cp   $10
46B9: D2 7C 4C    jp   nc,$46D6
46BC: DD 7E 03    ld   a,(ix+$09)
46BF: C6 10       add  a,$10
46C1: FD 77 03    ld   (iy+$09),a
46C4: C3 7C 4C    jp   $46D6
46C7: ED 44       neg
46C9: FE 10       cp   $10
46CB: D2 7C 4C    jp   nc,$46D6
46CE: FD 7E 03    ld   a,(iy+$09)
46D1: D6 10       sub  $10
46D3: FD 77 03    ld   (iy+$09),a
46D6: DD 21 F3 4C ld   ix,table_46F9
46DA: FD 7E 03    ld   a,(iy+$09)
46DD: DD BE 00    cp   (ix+$00)
46E0: D2 E6 4C    jp   nc,$46EC
46E3: DD 7E 01    ld   a,(ix+$01)
46E6: FD 77 03    ld   (iy+$09),a
46E9: C3 F2 4C    jp   $46F8
46EC: DD BE 08    cp   (ix+$02)
46EF: DA F2 4C    jp   c,$46F8
46F2: DD 7E 09    ld   a,(ix+$03)
46F5: FD 77 03    ld   (iy+$09),a
46F8: C9          ret
table_46F9:
	dc.b	0x63,0x20,0x20,0xe0,0xdf ; $46f8
player_management_routine_46FD:
46FD: FD 7E 14    ld   a,(iy+$14)
4700: A7          and  a
4701: C2 29 4D    jp   nz,$4783
4704: FD 6E 0D    ld   l,(iy+$07)
4707: FD 66 02    ld   h,(iy+$08)
470A: CB BC       res  7,h
470C: E5          push hl
470D: DD E1       pop  ix	; current frame data
470F: DD 4E 05    ld   c,(ix+$05)	; load c (number of ticks of current frame?)
4712: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
4715: E6 06       and  $0C
4717: FE 06       cp   $0C	; 2 players human?
4719: CA DB 4D    jp   z,$477B	; 2-player: skip the part below

; this isn't called in 2p mode
; in 2p mode (or dynamically), players_type_human_or_cpu_flags_C02D is $F
; at start in 1p mode players_type_human_or_cpu_flags_C02D is $5
; at start C02D is 4
; bit 0 is added when a credit is inserted 4 => 5
;
; during the demo, setting 0F to C02D seem to have no effect
; but during 2P play setting C02D from F to 5,6,7 makes red player
; attack white. So maybe there are more flags that need to be
; set or are overridden by demo mode
; setting to 8 (1000) => white attacks, red is player 2
; 0xB (1011) also behaves that way
; setting to 0 or 3 => error
; maybe in non-demo mode at least 1 player should be controlled
; by a human player
;
; this is not part of the A.I. routine, rather part of the CPU moves
; animation speed
;

471C: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
471F: 3A 82 60    ld   a,(player_2_attack_flags_C028)	; loads player Y, 0A: ground, 0B: preparing to jump
4722: CB 56       bit  2,(hl)	; is player 2 human?
4724: CA 94 4D    jp   z,$4734
; player 2 is CPU
4727: FE 0A       cp   $0A		; attack sequence?
4729: CA DB 4D    jp   z,$477B	; attacking: skip
472C: FE 0B       cp   $0B		; not attacking / standing guard?
472E: C4 D5 B0    call nz,display_error_text_B075	; sanity check, has to be 0B
4731: C3 49 4D    jp   $4743	; the other player is human, skip below

4734: CB 5E       bit  3,(hl)	; is player 1 human?
4736: CA D5 B0    jp   z,display_error_text_B075	; sanity: if reach here p1 is human
4739: FE 0B       cp   $0B
473B: CA DB 4D    jp   z,$477B	; not attacking: skip
473E: FE 0A       cp   $0A
4740: C4 D5 B0    call nz,display_error_text_B075
; check skill level (just for moves speed, not for A.I)
4743: 3A 10 63    ld   a,(computer_skill_C910)
4746: FE 10       cp   $10
; CMP level 16+: set maximum speed: -2 ticks per frame for all moves
4748: 3E FE       ld   a,$FE
474A: D2 D6 4D    jp   nc,$477C	; if > $10 skip (CMP level 16)
; if not CMP, check difficulty level
474D: 21 CD A7    ld   hl,counter_attack_timer_table_AD67
4750: 3A 90 60    ld   a,(dip_switches_copy_C030)
4753: CB 3F       srl  a
4755: CB 3F       srl  a
4757: CB 3F       srl  a
4759: E6 0C       and  $06
; difficulty level 00 easy ... 06 hardest to pick one of the 4 tables
475B: 5F          ld   e,a
475C: 16 00       ld   d,$00
475E: 19          add  hl,de
475F: 5E          ld   e,(hl)
4760: 23          inc  hl
4761: 56          ld   d,(hl)		; de points on the timer table
4762: 3A 10 63    ld   a,(computer_skill_C910)
4765: 87          add  a,a
4766: 6F          ld   l,a
4767: 26 00       ld   h,$00
4769: 19          add  hl,de
476A: 3A 42 61    ld   a,(unknown_C148)
476D: 47          ld   b,a
476E: 3A 4D 61    ld   a,(unknown_C147)
4771: B0          or   b
4772: CA DC 4D    jp   z,$4776
4775: 23          inc  hl
; It's loading a from one of the
; counter attack timer tables, but if it's > 0 then
; it sets it to 0... So all the values > 0 (which
; seem to be very well tuned) are zeroed... Only remains
; the negative ones (to speed up cpu moves)
;
; the positive values are used for computer reaction
;
4776: 7E          ld   a,(hl)
4777: A7          and  a
4778: FA D6 4D    jp   m,$477C
477B: AF          xor  a
; skips there on high difficulty level (high speed actually)
477C: 81          add  a,c		; sub delay to c => in a
477D: CA 29 4D    jp   z,$4783	; can't be zero!
4780: F2 25 4D    jp   p,$4785	; can't be negative
4783: 3E 01       ld   a,$01
4785: FD E5       push iy
4787: CD 5A B0    call suspend_this_task_B05A
478A: FD E1       pop  iy
478C: C9          ret

; < HL: pointer of frame
; > HL: contents of frame (first 2 bytes)
get_current_frame_contents_478D:
478D: FD 6E 0D    ld   l,(iy+$07)
4790: FD 66 02    ld   h,(iy+$08)
4793: CB BC       res  7,h
4795: 5E          ld   e,(hl)
4796: 23          inc  hl
4797: 56          ld   d,(hl)
4798: EB          ex   de,hl
4799: C9          ret


479A: 00          nop
479B: 3A 82 60    ld   a,(player_2_attack_flags_C028)
479E: FE 0A       cp   $0A
47A0: CA A2 4D    jp   z,$47A8
47A3: FE 0B       cp   $0B
47A5: C4 D5 B0    call nz,display_error_text_B075
47A8: CD 27 4D    call get_current_frame_contents_478D
47AB: 11 00 08    ld   de,$0200
47AE: A7          and  a
47AF: ED 52       sbc  hl,de
47B1: C2 74 4D    jp   nz,$47D4
47B4: 3A 11 63    ld   a,(background_and_state_bits_C911)
47B7: CB BF       res  7,a
47B9: FE 10       cp   $10
47BB: D2 74 4D    jp   nc,$47D4
47BE: 87          add  a,a
47BF: 87          add  a,a
47C0: 4F          ld   c,a
47C1: 06 00       ld   b,$00
47C3: 21 9D 97    ld   hl,table_3D37
47C6: 09          add  hl,bc
47C7: 23          inc  hl
47C8: 23          inc  hl
47C9: 23          inc  hl
47CA: 7E          ld   a,(hl)
47CB: FD BE 0A    cp   (iy+$0a)
47CE: CA 74 4D    jp   z,$47D4
47D1: FD 77 0A    ld   (iy+$0a),a
47D4: C9          ret
47D5: 00          nop

47D6: CD 4B B0    call load_iy_with_player_structure_B04B
47D9: 3E 19       ld   a,$13
47DB: CD D8 B0    call play_sound_B072
47DE: CD 18 B0    call clear_player_structure_partial_b012
47E1: CD BD 42    call $48B7
47E4: CD C2 43    call $4968
47E7: CD D2 43    call $4978
47EA: FD E5       push iy
47EC: 3E 01       ld   a,$01
47EE: CD 5A B0    call suspend_this_task_B05A
47F1: FD E1       pop  iy
47F3: A7          and  a
47F4: C4 D5 B0    call nz,display_error_text_B075
47F7: CD 15 4B    call $4B15
47FA: CD 56 4B    call $4B5C
47FD: FE FF       cp   $FF
47FF: CA A2 42    jp   z,$48A8
4802: CD C2 43    call $4968
4805: CD D2 43    call $4978
4808: CD F6 4B    call $4BFC
480B: F5          push af
480C: CD 5E 47    call $4D5E
480F: A7          and  a
4810: C4 D5 B0    call nz,display_error_text_B075
4813: F1          pop  af
4814: A7          and  a
4815: CA FD 4D    jp   z,$47F7
4818: FE 08       cp   $02
481A: CA 51 42    jp   z,$4851
481D: FD E5       push iy
481F: 3E 0A       ld   a,$0A
4821: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
4824: CB 56       bit  2,(hl)
4826: C2 8B 42    jp   nz,$482B
4829: 3E 0B       ld   a,$0B
482B: 06 09       ld   b,$03
482D: CD 57 B0    call task_manipulation_B05D
4830: A7          and  a
4831: C4 D5 B0    call nz,display_error_text_B075
4834: 3E 08       ld   a,$02
4836: 06 09       ld   b,$03
4838: CD 57 B0    call task_manipulation_B05D
483B: A7          and  a
483C: C4 D5 B0    call nz,display_error_text_B075
483F: FD E1       pop  iy
4841: FD E5       push iy
4843: 3E 96       ld   a,$3C
4845: CD 5A B0    call suspend_this_task_B05A
4848: A7          and  a
4849: C4 D5 B0    call nz,display_error_text_B075
484C: FD E1       pop  iy
484E: C3 A2 42    jp   $48A8
4851: CD 16 47    call $4D1C
4854: 3E 18       ld   a,$12
4856: CD D8 B0    call play_sound_B072
4859: CD C2 43    call $4968
485C: CD D2 43    call $4978
485F: CD 5E 47    call $4D5E
4862: A7          and  a
4863: C4 D5 B0    call nz,display_error_text_B075
4866: FD 6E 0D    ld   l,(iy+$07)
4869: FD 66 02    ld   h,(iy+$08)
486C: CB BC       res  7,h
486E: E5          push hl
486F: DD E1       pop  ix
4871: DD 7E 04    ld   a,(ix+$04)
4874: DD A6 05    and  (ix+$05)
4877: DD A6 0C    and  (ix+$06)
487A: DD A6 0D    and  (ix+$07)
487D: FE FF       cp   $FF
487F: CA 22 42    jp   z,$4888
4882: CD 15 4B    call $4B15
4885: C3 53 42    jp   $4859
4888: 3A 82 60    ld   a,(player_2_attack_flags_C028)
488B: FE 10       cp   $10
488D: DA A2 42    jp   c,$48A8
4890: 3E 04       ld   a,$04
4892: 06 08       ld   b,$02
4894: FD E5       push iy
4896: CD 57 B0    call task_manipulation_B05D
4899: FD E1       pop  iy
489B: A7          and  a
489C: C2 D5 B0    jp   nz,display_error_text_B075
489F: 3E 08       ld   a,$02
48A1: FD E5       push iy
48A3: CD 12 B0    call $B018
48A6: FD E1       pop  iy
48A8: FD 6E 0E    ld   l,(iy+$0e)
48AB: FD 66 0F    ld   h,(iy+$0f)
48AE: 01 10 00    ld   bc,$0010
48B1: CD 81 B0    call clear_zone_B021
48B4: CD 51 B0    call task_yield_B051
; evade sequence index
48B7: 3A 12 63    ld   a,(unknown_C918)
48BA: FE 0C       cp   $06
; not possible that it's >= 06
48BC: D4 D5 B0    call nc,display_error_text_B075
48BF: FE 09       cp   $03
48C1: DA 6C 42    jp   c,$48C6
; > 3, just make it symmetrical?
48C4: D6 09       sub  $03
48C6: FD 77 0B    ld   (iy+$0b),a
48C9: 3A 12 63    ld   a,(unknown_C918)
48CC: FE 09       cp   $03
48CE: DA 7C 42    jp   c,$48D6
48D1: 0E 20       ld   c,$80
48D3: FD 71 02    ld   (iy+$08),c
48D6: FD 36 03 00 ld   (iy+$09),$00
48DA: 21 42 43    ld   hl,table_4948
48DD: 3A 12 63    ld   a,(unknown_C918)
48E0: FE 09       cp   $03
48E2: DA ED 42    jp   c,$48E7
48E5: D6 09       sub  $03
48E7: 06 00       ld   b,$00
48E9: 4F          ld   c,a
48EA: 09          add  hl,bc
48EB: DD 21 9D 97 ld   ix,table_3D37
48EF: 3A 11 63    ld   a,(background_and_state_bits_C911)
48F2: 87          add  a,a
48F3: 87          add  a,a
48F4: 4F          ld   c,a
48F5: 06 00       ld   b,$00
48F7: DD 09       add  ix,bc
48F9: DD 7E 09    ld   a,(ix+$03)
48FC: 86          add  a,(hl)
48FD: FD 77 0A    ld   (iy+$0a),a
4900: 3A 13 63    ld   a,(unknown_C919)
4903: FE 0D       cp   $07
4905: D4 D5 B0    call nc,display_error_text_B075
4908: FD 77 06    ld   (iy+$0c),a
490B: 4F          ld   c,a
490C: 87          add  a,a
490D: 81          add  a,c
490E: DD 21 4B 43 ld   ix,table_494B
4912: 4F          ld   c,a
4913: 06 00       ld   b,$00
4915: DD 09       add  ix,bc
4917: DD 7E 00    ld   a,(ix+$00)
491A: FD 77 0D    ld   (iy+$07),a
491D: DD 7E 01    ld   a,(ix+$01)
4920: FD B6 02    or   (iy+$08)
4923: FD 77 02    ld   (iy+$08),a
4926: DD 7E 08    ld   a,(ix+$02)
4929: FD 77 07    ld   (iy+$0d),a
492C: 3A 82 60    ld   a,(player_2_attack_flags_C028)
492F: D6 10       sub  $10
4931: 87          add  a,a
4932: 4F          ld   c,a
4933: 06 00       ld   b,$00
4935: DD 21 C0 43 ld   ix,table_4960
4939: DD 09       add  ix,bc
493B: DD 7E 00    ld   a,(ix+$00)
493E: FD 77 0E    ld   (iy+$0e),a
4941: DD 7E 01    ld   a,(ix+$01)
4944: FD 77 0F    ld   (iy+$0f),a
4947: C9          ret
table_4948:
	dc.b	0xd8,0xe8,0xf8 ; table_4948
table_494B:
	dc.b	0x4a,0x38,0x0f,0x5c,0x38,0x07,0x6e,0x38 ; table_494B
	dc.b	0x0c,0x92,0x38,0x06,0xad,0x38,0x07,0xc8 ; $4953
	dc.b	0x38,0x07,0xe3,0x38,0x0d ; $495b
table_4960:
	dc.b	0x7c,0xc7,0x8c,0xc7,0x9c,0xc7,0xac,0xc7 ; table_4960

4968: CD 4B B0    call load_iy_with_player_structure_B04B
496B: FD 6E 0E    ld   l,(iy+$0e)
496E: FD 66 0F    ld   h,(iy+$0f)
4971: E5          push hl
4972: DD E1       pop  ix
4974: FD 4E 07    ld   c,(iy+$0d)
4977: C9          ret

4978: CD 27 4D    call get_current_frame_contents_478D
497B: 7E          ld   a,(hl)
497C: E6 20       and  $80
497E: FD 77 17    ld   (iy+$1d),a
4981: 79          ld   a,c
4982: E6 0F       and  $0F
4984: FD B6 17    or   (iy+$1d)
4987: FD 77 17    ld   (iy+$1d),a
498A: 7E          ld   a,(hl)
498B: CB BF       res  7,a
498D: CB B7       res  6,a
498F: 87          add  a,a
4990: 5F          ld   e,a
4991: 16 00       ld   d,$00
4993: E5          push hl
4994: 21 72 4A    ld   hl,table_4AD8
4997: 19          add  hl,de
4998: 5E          ld   e,(hl)
4999: 23          inc  hl
499A: 56          ld   d,(hl)
499B: E1          pop  hl
499C: 23          inc  hl
499D: 1A          ld   a,(de)
499E: 13          inc  de
499F: FE FF       cp   $FF
49A1: CA 02 4A    jp   z,$4A08
49A4: FD 4E 03    ld   c,(iy+$09)
49A7: CB 7F       bit  7,a
49A9: C2 B0 43    jp   nz,$49B0
49AC: 81          add  a,c
49AD: C3 B5 43    jp   $49B5
49B0: ED 44       neg
49B2: 47          ld   b,a
49B3: 79          ld   a,c
49B4: 90          sub  b
49B5: DD 77 00    ld   (ix+$00),a
49B8: 1A          ld   a,(de)
49B9: FD 4E 0A    ld   c,(iy+$0a)
49BC: CB 7F       bit  7,a
49BE: C2 65 43    jp   nz,$49C5
49C1: 81          add  a,c
49C2: C3 6A 43    jp   $49CA
49C5: ED 44       neg
49C7: 47          ld   b,a
49C8: 79          ld   a,c
49C9: 90          sub  b
49CA: DA F3 43    jp   c,$49F9
49CD: FE 02       cp   $08
49CF: DA F3 43    jp   c,$49F9
49D2: FE F2       cp   $F8
49D4: D2 F3 43    jp   nc,$49F9
49D7: DD 77 09    ld   (ix+$03),a
49DA: 4E          ld   c,(hl)
49DB: 23          inc  hl
49DC: 46          ld   b,(hl)
49DD: 23          inc  hl
49DE: DD 71 01    ld   (ix+$01),c
49E1: CB 00       rlc  b
49E3: CB 00       rlc  b
49E5: CB 00       rlc  b
49E7: CB 00       rlc  b
49E9: DD 70 08    ld   (ix+$02),b
49EC: FD 7E 17    ld   a,(iy+$1d)
49EF: DD B6 08    or   (ix+$02)
49F2: DD 77 08    ld   (ix+$02),a
49F5: 13          inc  de
49F6: C3 00 4A    jp   $4A00
49F9: 23          inc  hl
49FA: 23          inc  hl
49FB: 13          inc  de
49FC: DD 36 00 00 ld   (ix+$00),$00
4A00: 01 04 00    ld   bc,$0004
4A03: DD 09       add  ix,bc
4A05: C3 37 43    jp   $499D
4A08: 3A 82 60    ld   a,(player_2_attack_flags_C028)
4A0B: FE 14       cp   $14
4A0D: C2 71 4A    jp   nz,$4AD1
4A10: FD CB 02 DE bit  7,(iy+$08)
4A14: CA A5 4A    jp   z,$4AA5
4A17: CD C2 43    call $4968
4A1A: 06 04       ld   b,$04
4A1C: DD 4E 01    ld   c,(ix+$01)
4A1F: DD 7E 08    ld   a,(ix+$02)
4A22: DD 6E 11    ld   l,(ix+$11)
4A25: DD 66 18    ld   h,(ix+$12)
4A28: EE 20       xor  $80
4A2A: DD 71 11    ld   (ix+$11),c
4A2D: DD 77 18    ld   (ix+$12),a
4A30: 7C          ld   a,h
4A31: EE 20       xor  $80
4A33: DD 75 01    ld   (ix+$01),l
4A36: DD 77 08    ld   (ix+$02),a
4A39: DD 4E 05    ld   c,(ix+$05)
4A3C: DD 7E 0C    ld   a,(ix+$06)
4A3F: DD 6E 07    ld   l,(ix+$0d)
4A42: DD 66 0E    ld   h,(ix+$0e)
4A45: EE 20       xor  $80
4A47: DD 71 07    ld   (ix+$0d),c
4A4A: DD 77 0E    ld   (ix+$0e),a
4A4D: 7C          ld   a,h
4A4E: EE 20       xor  $80
4A50: DD 75 05    ld   (ix+$05),l
4A53: DD 77 0C    ld   (ix+$06),a
4A56: DD 7E 0A    ld   a,(ix+$0a)
4A59: EE 20       xor  $80
4A5B: DD 77 0A    ld   (ix+$0a),a
4A5E: 11 14 00    ld   de,$0014
4A61: DD 19       add  ix,de
4A63: 10 BD       djnz $4A1C
4A65: CD C2 43    call $4968
4A68: DD 4E 01    ld   c,(ix+$01)
4A6B: DD 46 08    ld   b,(ix+$02)
4A6E: DD 5E 05    ld   e,(ix+$05)
4A71: DD 56 0C    ld   d,(ix+$06)
4A74: DD 73 01    ld   (ix+$01),e
4A77: DD 72 08    ld   (ix+$02),d
4A7A: DD 71 05    ld   (ix+$05),c
4A7D: DD 70 0C    ld   (ix+$06),b
4A80: DD 4E 07    ld   c,(ix+$0d)
4A83: DD 46 0E    ld   b,(ix+$0e)
4A86: DD 5E 11    ld   e,(ix+$11)
4A89: DD 56 18    ld   d,(ix+$12)
4A8C: DD 73 07    ld   (ix+$0d),e
4A8F: DD 72 0E    ld   (ix+$0e),d
4A92: DD 71 11    ld   (ix+$11),c
4A95: DD 70 18    ld   (ix+$12),b
4A98: 06 05       ld   b,$05
4A9A: DD CB 08 BE res  7,(ix+$02)
4A9E: 11 04 00    ld   de,$0004
4AA1: DD 19       add  ix,de
4AA3: 10 F5       djnz $4A9A
4AA5: DD 21 74 4A ld   ix,table_4AD4
4AA9: FD 56 03    ld   d,(iy+$09)
4AAC: FD 5E 0A    ld   e,(iy+$0a)
4AAF: CD 48 B0    call is_point_in_rectangle_B042
4AB2: A7          and  a
4AB3: C2 71 4A    jp   nz,$4AD1
4AB6: CD C2 43    call $4968
4AB9: 06 14       ld   b,$14
4ABB: FD 7E 03    ld   a,(iy+$09)
4ABE: DD AE 00    xor  (ix+$00)
4AC1: E6 20       and  $80
4AC3: CA 6A 4A    jp   z,$4ACA
4AC6: DD 36 00 00 ld   (ix+$00),$00
4ACA: 11 04 00    ld   de,$0004
4ACD: DD 19       add  ix,de
4ACF: 10 EA       djnz $4ABB
4AD1: C9          ret
table_4AD4:
	dc.b	0x30,0x9f,0x00,0xff,0x00,0x00,0xe0,0x4a ; table_4AD4
	dc.b	0xe3,0x4a,0xec,0x4a,0xf8,0xf8,0xff,0xf0 ; $4adc
	dc.b	0xf0,0x00,0xf0,0xf0,0x00,0x00,0x00,0xff ; $4ae4
	dc.b	0xd8,0xe0,0xe8,0xe0,0xf8,0xe0,0x08,0xe0 ; $4aec
	dc.b	0x18,0xe0,0xd8,0xf0,0xe8,0xf0,0xf8,0xf0 ; $4af4
	dc.b	0x08,0xf0,0x18,0xf0,0xd8,0x00,0xe8,0x00 ; $4afc
	dc.b	0xf8,0x00,0x08,0x00,0x18,0x00,0xd8,0x10 ; $4b04
	dc.b	0xe8,0x10,0xf8,0x10,0x08,0x10,0x18,0x10 ; $4b0c
	dc.b	0xff ; $4b14
4B15: FD 4E 0D    ld   c,(iy+$07)
4B18: FD 46 02    ld   b,(iy+$08)
4B1B: CB B8       res  7,b
4B1D: C5          push bc
4B1E: DD E1       pop  ix
4B20: DD 7E 08    ld   a,(ix+$02)
4B23: DD 4E 09    ld   c,(ix+$03)
4B26: FD CB 02 DE bit  7,(iy+$08)
4B2A: C2 96 4B    jp   nz,$4B3C
4B2D: DD 56 04    ld   d,(ix+$04)
4B30: FD 72 0D    ld   (iy+$07),d
4B33: DD 56 05    ld   d,(ix+$05)
4B36: FD 72 02    ld   (iy+$08),d
4B39: C3 4E 4B    jp   $4B4E
4B3C: DD 56 0C    ld   d,(ix+$06)
4B3F: FD 72 0D    ld   (iy+$07),d
4B42: DD 56 0D    ld   d,(ix+$07)
4B45: FD 72 02    ld   (iy+$08),d
4B48: FD CB 02 FE set  7,(iy+$08)
4B4C: ED 44       neg
4B4E: FD 86 03    add  a,(iy+$09)
4B51: FD 77 03    ld   (iy+$09),a
4B54: 79          ld   a,c
4B55: FD 86 0A    add  a,(iy+$0a)
4B58: FD 77 0A    ld   (iy+$0a),a
4B5B: C9          ret
4B5C: DD 21 D5 4B ld   ix,table_4B75
4B60: FD CB 02 DE bit  7,(iy+$08)
4B64: C2 CB 4B    jp   nz,$4B6B
4B67: DD 21 D3 4B ld   ix,table_4B79
4B6B: FD 56 03    ld   d,(iy+$09)
4B6E: FD 5E 0A    ld   e,(iy+$0a)
4B71: CD 48 B0    call is_point_in_rectangle_B042
4B74: C9          ret

table_4B75:
	dc.b	0xf0,0x0f,0x00,0xff ; table_4B75
table_4B79:
	dc.b	0x00,0x0f,0x00,0xff ; table_4B79

4B7D: FD E5       push iy
4B7F: FD 6E 10    ld   l,(iy+$10)
4B82: FD 66 11    ld   h,(iy+$11)
4B85: E5          push hl
4B86: FD E1       pop  iy
4B88: CD 14 46    call $4C14
4B8B: FD E1       pop  iy
4B8D: A7          and  a
4B8E: C2 A0 4B    jp   nz,$4BA0
4B91: CD D7 46    call $4C7D
4B94: CD 48 B0    call is_point_in_rectangle_B042
4B97: A7          and  a
4B98: CA A0 4B    jp   z,$4BA0
4B9B: 3E 08       ld   a,$02
4B9D: C3 FB 4B    jp   $4BFB
4BA0: CD 65 46    call $4CC5
4BA3: 3A 82 60    ld   a,(player_2_attack_flags_C028)
4BA6: FE 14       cp   $14
4BA8: C2 E6 4B    jp   nz,$4BEC
4BAB: FD 7E 03    ld   a,(iy+$09)
4BAE: D6 10       sub  $10
4BB0: FD CB 02 DE bit  7,(iy+$08)
4BB4: CA B3 4B    jp   z,$4BB9
4BB7: C6 80       add  a,$20
4BB9: 57          ld   d,a
4BBA: FD 7E 0A    ld   a,(iy+$0a)
4BBD: D6 10       sub  $10
4BBF: 5F          ld   e,a
4BC0: CD 48 B0    call is_point_in_rectangle_B042
4BC3: A7          and  a
4BC4: C2 F3 4B    jp   nz,$4BF9
4BC7: FD 7E 03    ld   a,(iy+$09)
4BCA: C6 10       add  a,$10
4BCC: FD CB 02 DE bit  7,(iy+$08)
4BD0: CA 75 4B    jp   z,$4BD5
4BD3: D6 80       sub  $20
4BD5: 57          ld   d,a
4BD6: FD 5E 0A    ld   e,(iy+$0a)
4BD9: CD 48 B0    call is_point_in_rectangle_B042
4BDC: A7          and  a
4BDD: C2 F3 4B    jp   nz,$4BF9
4BE0: FD 56 03    ld   d,(iy+$09)
4BE3: FD 7E 0A    ld   a,(iy+$0a)
4BE6: C6 10       add  a,$10
4BE8: 5F          ld   e,a
4BE9: C3 F8 4B    jp   $4BF2
4BEC: FD 56 03    ld   d,(iy+$09)
4BEF: FD 5E 0A    ld   e,(iy+$0a)
4BF2: CD 48 B0    call is_point_in_rectangle_B042
4BF5: A7          and  a
4BF6: CA FB 4B    jp   z,$4BFB
4BF9: 3E 01       ld   a,$01
4BFB: C9          ret
4BFC: 21 40 68    ld   hl,player_1_struct_C240
4BFF: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
4C02: CB 57       bit  2,a
4C04: C2 0A 46    jp   nz,$4C0A
4C07: 21 C0 68    ld   hl,player_2_struct_C260
4C0A: FD 75 10    ld   (iy+$10),l
4C0D: FD 74 11    ld   (iy+$11),h
4C10: CD D7 4B    call $4B7D
4C13: C9          ret

4C14: FD 5E 0D    ld   e,(iy+$07)
4C17: FD 56 02    ld   d,(iy+$08)
4C1A: CB BA       res  7,d
4C1C: DD 21 9F 46 ld   ix,table_4C3F
4C20: CD 06 B0    call key_value_linear_search_B00C
4C23: A7          and  a
4C24: C2 9E 46    jp   nz,$4C3E
4C27: FD 7E 03    ld   a,(iy+$09)
4C2A: FD CB 02 DE bit  7,(iy+$08)
4C2E: C2 9C 46    jp   nz,$4C36
4C31: 85          add  a,l
4C32: 57          ld   d,a
4C33: C3 92 46    jp   $4C38
4C36: 95          sub  l
4C37: 57          ld   d,a
4C38: FD 7E 0A    ld   a,(iy+$0a)
4C3B: 84          add  a,h
4C3C: 5F          ld   e,a
4C3D: AF          xor  a
4C3E: C9          ret

table_4C3F:
     4C3F  C0 0C DC E7 D2 0C D9 E7 47 0D DC DB D7 0D DC FD
     4C4F  4C 0E 18 E6 AF 0E 18 E4 1B 0F 23 D5 90 0F 1B E4
     4C5F  0E 10 24 FD 9E 10 19 FD 0A 11 17 D5 6D 11 1C DA
     4C6F  E2 11 1B D9 D5 12 1A E4 4A 13 1B F5 FF FF 81 BD
     4C7F  4C F7 4E 0C 0C 00 03 77 81 00 CF F7 DE 09 3C 77
     4C8F  DD 00 F7 DE 0A 3C 77 DD 02 DE 2D 77 DD 01 77 DD
     4C9F  03 9A 28 C0 FE 14 68 BC 4C 77 DE 00 7C 08 77 DD
     4CAF  00 F7 6B 08 7E 6A BC 4C 6C 10 77 DD 00 63 0C 0C
     4CBF  0C 0C 0C 0C 0C 08 F7 E5 77 81 00 CF 81 14 4D F7
     4CCF  4E 0C 0C 00 03 F7 5E 10 F7 5C 11 75 F7 E1 F7 DE
     4CDF  09 3C 77 DD 00 DE 2D 77 DD 01 67 8D 47 11 00 02
     4CEF  AD E7 58 1C 0D 67 03 B0 AD 64 75 B0 83 83 11 8D
     4CFF  08 13 89 89 89 F7 DE 0A 2C 77 DD 02 DE E7 44 77
     4D0F  DD 03 F7 E1 63 10 10 10 10 10 10 10 10 77 81 74
     4D1F  4D F7 4E 0C 0C 00 77 03 77 03 77 CE 00 77 CC 01
     4D2F  E5 77 E1 F7 D5 07 F7 6B 08 7E 6A 3E 4D 6B F6 F7
     4D3F  D4 08 77 DE 02 77 4E 03 F7 6B 08 7E 6A 50 4D E7
     4D4F  44 F7 2C 09 F7 DD 09 D3 F7 2C 0A F7 DD 0A 63 F7
     4D5F  CE 07 F7 CC 08 6B B6 11 08 00 13 DE 00 F7 E5 67
     4D6F  5A B0 F7 E1 63 53 38 65 38 77 38 9B 38 B6

4C7D: 21 B7 46    ld   hl,table_4CBD
4C80: FD 4E 06    ld   c,(iy+$0c)
4C83: 06 00       ld   b,$00
4C85: 09          add  hl,bc
4C86: DD 21 00 6F ld   ix,temp_numeric_buffer_CF00
4C8A: FD 7E 03    ld   a,(iy+$09)
4C8D: 96          sub  (hl)
4C8E: DD 77 00    ld   (ix+$00),a
4C91: FD 7E 0A    ld   a,(iy+$0a)
4C94: 96          sub  (hl)
4C95: DD 77 08    ld   (ix+$02),a
4C98: 7E          ld   a,(hl)
4C99: 87          add  a,a
4C9A: DD 77 01    ld   (ix+$01),a
4C9D: DD 77 09    ld   (ix+$03),a
4CA0: 3A 82 60    ld   a,(player_2_attack_flags_C028)
4CA3: FE 14       cp   $14
4CA5: C2 B6 46    jp   nz,$4CBC
4CA8: DD 7E 00    ld   a,(ix+$00)
4CAB: D6 02       sub  $08
4CAD: DD 77 00    ld   (ix+$00),a
4CB0: FD CB 02 DE bit  7,(iy+$08)
4CB4: CA B6 46    jp   z,$4CBC
4CB7: C6 10       add  a,$10
4CB9: DD 77 00    ld   (ix+$00),a
4CBC: C9          ret
table_4CBD:
  0C 0C 0C 0C 0C 0C 0C 08

4CC5: FD E5       push iy
4CC7: DD 21 00 6F ld   ix,temp_numeric_buffer_CF00
4CCB: 21 14 47    ld   hl,table_4D14
4CCE: FD 4E 06    ld   c,(iy+$0c)
4CD1: 06 00       ld   b,$00
4CD3: 09          add  hl,bc
4CD4: FD 5E 10    ld   e,(iy+$10)
4CD7: FD 56 11    ld   d,(iy+$11)
4CDA: D5          push de
4CDB: FD E1       pop  iy
4CDD: FD 7E 03    ld   a,(iy+$09)
4CE0: 96          sub  (hl)
4CE1: DD 77 00    ld   (ix+$00),a
4CE4: 7E          ld   a,(hl)
4CE5: 87          add  a,a
4CE6: DD 77 01    ld   (ix+$01),a
4CE9: CD 27 4D    call get_current_frame_contents_478D
4CEC: 11 00 08    ld   de,$0200
4CEF: A7          and  a
4CF0: ED 52       sbc  hl,de
4CF2: 16 07       ld   d,$0D
4CF4: CD 09 B0    call $B003
4CF7: A7          and  a
4CF8: C4 D5 B0    call nz,display_error_text_B075
4CFB: 29          add  hl,hl
4CFC: 29          add  hl,hl
4CFD: 11 27 02    ld   de,$088D	; offset
4D00: 19          add  hl,de
4D01: 23          inc  hl
4D02: 23          inc  hl
4D03: 23          inc  hl
4D04: FD 7E 0A    ld   a,(iy+$0a)
4D07: 86          add  a,(hl)
4D08: DD 77 08    ld   (ix+$02),a
4D0B: 7E          ld   a,(hl)
4D0C: ED 44       neg
4D0E: DD 77 09    ld   (ix+$03),a
4D11: FD E1       pop  iy
4D13: C9          ret

table_4D14:
 10 10
 10 10
 10 10
 10 10

4D1C: DD 21 D4 47 ld   ix,table_4D74
4D20: FD 4E 06    ld   c,(iy+$0c)
4D23: 06 00       ld   b,$00
4D25: DD 09       add  ix,bc
4D27: DD 09       add  ix,bc
4D29: DD 6E 00    ld   l,(ix+$00)
4D2C: DD 66 01    ld   h,(ix+$01)
4D2F: E5          push hl
4D30: DD E1       pop  ix
4D32: FD 75 0D    ld   (iy+$07),l
4D35: FD CB 02 DE bit  7,(iy+$08)
4D39: CA 9E 47    jp   z,$4D3E
4D3C: CB FC       set  7,h
4D3E: FD 74 02    ld   (iy+$08),h
4D41: DD 7E 08    ld   a,(ix+$02)
4D44: DD 4E 09    ld   c,(ix+$03)
4D47: FD CB 02 DE bit  7,(iy+$08)
4D4B: CA 50 47    jp   z,$4D50
4D4E: ED 44       neg
4D50: FD 86 03    add  a,(iy+$09)
4D53: FD 77 03    ld   (iy+$09),a
4D56: 79          ld   a,c
4D57: FD 86 0A    add  a,(iy+$0a)
4D5A: FD 77 0A    ld   (iy+$0a),a
4D5D: C9          ret
4D5E: FD 6E 0D    ld   l,(iy+$07)
4D61: FD 66 02    ld   h,(iy+$08)
4D64: CB BC       res  7,h
4D66: 11 02 00    ld   de,$0008
4D69: 19          add  hl,de
4D6A: 7E          ld   a,(hl)
4D6B: 00          nop
4D6C: FD E5       push iy
4D6E: CD 5A B0    call suspend_this_task_B05A
4D71: FD E1       pop  iy
4D73: C9          ret
table_4D74:
	dc.b	0x53,0x38,0x65,0x38,0x77,0x38,0x9b,0x38 ; table_4D74
	dc.b	0xb6,0x38 ; $4d7c
4D7E: 71          ld   (hl),c
4D7F: 92          sub  d
4D80: E6 92       and  $38
4D82: 20 9A       jr   nz,$4DBE

4D84: CD 4B B0    call load_iy_with_player_structure_B04B
4D87: CD 18 B0    call clear_player_structure_partial_b012
4D8A: FD E5       push iy
4D8C: 3E 02       ld   a,$08
4D8E: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
4D91: CB 56       bit  2,(hl)
4D93: C2 3D 47    jp   nz,$4D97
4D96: 3C          inc  a
4D97: CD 5D B0    call schedule_task_to_start_B057
4D9A: A7          and  a
4D9B: C4 D5 B0    call nz,display_error_text_B075
4D9E: 3E 0A       ld   a,$0A
4DA0: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
4DA3: CB 56       bit  2,(hl)
4DA5: C2 A3 47    jp   nz,$4DA9
4DA8: 3C          inc  a
4DA9: CD 5D B0    call schedule_task_to_start_B057
4DAC: A7          and  a
4DAD: C4 D5 B0    call nz,display_error_text_B075
4DB0: 3E 04       ld   a,$04
4DB2: CD 5D B0    call schedule_task_to_start_B057
4DB5: A7          and  a
4DB6: C4 D5 B0    call nz,display_error_text_B075
4DB9: 3E 14       ld   a,$14
4DBB: CD 5D B0    call schedule_task_to_start_B057
4DBE: A7          and  a
4DBF: C4 D5 B0    call nz,display_error_text_B075
4DC2: FD E1       pop  iy
4DC4: FD E5       push iy
4DC6: 3E 00       ld   a,$00
4DC8: CD 5A B0    call suspend_this_task_B05A
4DCB: FE 10       cp   $10
4DCD: CA E0 47    jp   z,$4DE0
4DD0: FE 01       cp   $01
4DD2: C4 D5 B0    call nz,display_error_text_B075
4DD5: 3E 0F       ld   a,$0F
4DD7: 06 80       ld   b,$20
4DD9: CD 57 B0    call task_manipulation_B05D
4DDC: A7          and  a
4DDD: C4 D5 B0    call nz,display_error_text_B075
4DE0: FD E1       pop  iy
4DE2: FD E5       push iy
4DE4: 3E F0       ld   a,$F0
4DE6: CD 5A B0    call suspend_this_task_B05A
4DE9: A7          and  a
4DEA: C4 D5 B0    call nz,display_error_text_B075
4DED: FD E1       pop  iy
4DEF: 3E 01       ld   a,$01
4DF1: 06 01       ld   b,$01
4DF3: CD 57 B0    call task_manipulation_B05D
4DF6: A7          and  a
4DF7: C4 D5 B0    call nz,display_error_text_B075
4DFA: CD 51 B0    call task_yield_B051
4DFD: 01 16 0A    ld   bc,$0A1C
4E00: 11 96 22    ld   de,$883c
4E03: 21 00 17    ld   hl,$1D00
4E06: CD 1B B0    call fill_rectangle_B01B
4E09: DD 21 00 6F ld   ix,temp_numeric_buffer_CF00
4E0D: DD 36 00 08 ld   (ix+$00),$02
4E11: DD 36 01 10 ld   (ix+$01),$10
4E15: DD 36 1E FF ld   (ix+$1e),$FF
4E19: 21 00 40    ld   hl,$4000		; suspicious
4E1C: DD E5       push ix
4E1E: 06 16       ld   b,$1C
4E20: 0E E6       ld   c,$EC
4E22: 56          ld   d,(hl)
4E23: 1E 09       ld   e,$03
4E25: C5          push bc
4E26: CD 0C B0    call random_B006
4E29: C1          pop  bc
4E2A: 81          add  a,c
4E2B: DD 77 08    ld   (ix+$02),a
4E2E: DD 23       inc  ix
4E30: 23          inc  hl
4E31: 10 EF       djnz $4E22
4E33: D1          pop  de
4E34: E5          push hl
4E35: D5          push de
4E36: EB          ex   de,hl
4E37: 16 E8       ld   d,$E2
4E39: CD 93 B0    call display_text_B039
4E3C: DD E1       pop  ix
4E3E: E1          pop  hl
4E3F: 3E 1F       ld   a,$1F
4E41: DD BE 01    cp   (ix+$01)
4E44: CA 47 4E    jp   z,$4E4D
4E47: DD 34 01    inc  (ix+$01)
4E4A: C3 16 4E    jp   $4E1C
4E4D: 21 D9 4E    ld   hl,table_4E73
4E50: 16 2A       ld   d,$8A
4E52: CD 93 B0    call display_text_B039
4E55: 21 4B 4F    ld   hl,table_4F4B
4E58: 16 39       ld   d,$93
4E5A: 3A 10 63    ld   a,(computer_skill_C910)
4E5D: FE 05       cp   $05
4E5F: DA CF 4E    jp   c,$4E6F
4E62: 21 C5 4F    ld   hl,table_4F65
4E65: FE 02       cp   $08
4E67: DA CF 4E    jp   c,$4E6F
4E6A: 21 DF 4F    ld   hl,table_4F7F
4E6D: 16 89       ld   d,$23
4E6F: CD 93 B0    call display_text_B039
4E72: C9          ret
table_4E73:
	dc.b	0x1a,0x00,0xf1,0xf4,0xf4,0xf4,0xfe,0x1b ; table_4E73
	dc.b	0x01,0xf1,0xf4,0xf4,0xfe,0x1c,0x02,0xf1 ; $4e7b
	dc.b	0xf4,0xfe,0x09,0x01,0xef,0xf4,0xf0,0xef ; $4e83
	dc.b	0xf0,0xfe,0x07,0x02,0xef,0xf4,0xf4,0xf4 ; $4e8b
	dc.b	0xf4,0xf4,0xf4,0xf0,0xfe,0x05,0x03,0xef ; $4e93
	dc.b	0xf4,0xf4,0xf4,0xf4,0xfe,0x05,0x04,0xf4 ; $4e9b
	dc.b	0xf4,0xf4,0xf4,0xf4,0xfe,0x04,0x05,0xef ; $4ea3
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4 ; $4eab
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf0,0xfe,0x16,0x02 ; $4eb3
	dc.b	0xef,0xf4,0xf0,0xfe,0x15,0x03,0xef,0xf4 ; $4ebb
	dc.b	0xf4,0xf4,0xf0,0xfe,0x14,0x04,0xef,0xf4 ; $4ec3
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf0,0xfe,0x14,0x05 ; $4ecb
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf2,0xfe ; $4ed3
	dc.b	0x03,0x06,0xef,0xf4,0xf4,0xf4,0xf4,0xf4 ; $4edb
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4 ; $4ee3
	dc.b	0xf4,0xf0,0xef,0xf4,0xf4,0xf4,0xf4,0xf4 ; $4eeb
	dc.b	0xf4,0xf0,0xfe,0x03,0x07,0xf4,0xf4,0xf4 ; $4ef3
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4 ; $4efb
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4 ; $4f03
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf4,0xf0,0xfe,0x03 ; $4f0b
	dc.b	0x08,0xf1,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4 ; $4f13
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4 ; $4f1b
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4 ; $4f23
	dc.b	0xf4,0xf4,0xf0,0xfe,0x04,0x09,0xf1,0xf4 ; $4f2b
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4 ; $4f33
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4 ; $4f3b
	dc.b	0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf2,0xff ; $4f43
table_4F4B:
	dc.b	0x0a,0x03,0xa9,0xaa,0xab,0xac,0xad,0xae ; table_4F4B
	dc.b	0xaf,0xb0,0xb1,0xb2,0xfe,0x0a,0x04,0xb3 ; $4f53
	dc.b	0xb4,0xb5,0xb6,0xb7,0xb8,0xb9,0xba,0xbb ; $4f5b
	dc.b	0xbc,0xff ; $4f63
table_4F65:
	dc.b	0x0a,0x03,0xbd,0xbe,0xbf,0xc0,0xc1,0xc2 ; table_4F65
	dc.b	0xc3,0xc4,0xc5,0xc6,0xfe,0x0a,0x04,0xc7 ; $4f6d
	dc.b	0xc8,0xc9,0xca,0xcb,0xcc,0xcd,0xce,0xcf ; $4f75
	dc.b	0x83,0xff ; $4f7d
table_4F7F:
	dc.b	0x0a,0x03,0x00,0x01,0x02,0x03,0x04,0x05 ; table_4F7F
	dc.b	0x06,0x07,0x08,0x09,0xfe,0x0a,0x04,0x0a ; $4f87
	dc.b	0x0b,0x0c,0x0d,0x0e,0x0f,0x10,0x11,0x12 ; $4f8f
	dc.b	0x13,0xff ; $4f97

4F99: FD 34 03    inc  (iy+$09)
4F9C: 01 16 0C    ld   bc,$061C
4F9F: 11 9F 12    ld   de,$183F
4FA2: 21 0A 17    ld   hl,$1D0A
4FA5: CD 1B B0    call fill_rectangle_B01B
4FA8: 21 96 50    ld   hl,table_503C
4FAB: FD 7E 0D    ld   a,(iy+$07)
4FAE: 87          add  a,a
4FAF: 4F          ld   c,a
4FB0: 06 00       ld   b,$00
4FB2: 09          add  hl,bc
4FB3: 4E          ld   c,(hl)
4FB4: 23          inc  hl
4FB5: 46          ld   b,(hl)
4FB6: C5          push bc
4FB7: DD E1       pop  ix
4FB9: 01 00 04    ld   bc,$0400
4FBC: 3E FF       ld   a,$FF
4FBE: DD BE 00    cp   (ix+$00)
4FC1: CA 7B 4F    jp   z,$4FDB
4FC4: DD 66 00    ld   h,(ix+$00)
4FC7: DD 6E 01    ld   l,(ix+$01)
4FCA: C5          push bc
4FCB: CD 87 B0    call $B02D
4FCE: C1          pop  bc
4FCF: 36 F9       ld   (hl),$F3
4FD1: 09          add  hl,bc
4FD2: 36 1A       ld   (hl),$1A
4FD4: DD 23       inc  ix
4FD6: DD 23       inc  ix
4FD8: C3 B6 4F    jp   $4FBC
4FDB: FD 7E 0D    ld   a,(iy+$07)
4FDE: FD 36 0D 01 ld   (iy+$07),$01
4FE2: A7          and  a
4FE3: CA EA 4F    jp   z,$4FEA
4FE6: FD 36 0D 00 ld   (iy+$07),$00
4FEA: FD CB 03 4C bit  0,(iy+$09)
4FEE: CA 84 50    jp   z,$5024
4FF1: 21 40 50    ld   hl,table_5040
4FF4: FD 7E 02    ld   a,(iy+$08)
4FF7: 4F          ld   c,a
4FF8: 87          add  a,a
4FF9: 81          add  a,c
4FFA: 4F          ld   c,a
4FFB: 06 00       ld   b,$00
4FFD: 09          add  hl,bc
4FFE: E5          push hl
4FFF: DD E1       pop  ix
5001: DD 66 00    ld   h,(ix+$00)
5004: DD 6E 01    ld   l,(ix+$01)
5007: DD 7E 08    ld   a,(ix+$02)
500A: DD 21 02 6D ld   ix,unknown_C708
500E: FD E5       push iy
5010: CD A8 B0    call $B0A2
5013: FD E1       pop  iy
5015: FD 34 02    inc  (iy+$08)
5018: 3E 09       ld   a,$03
501A: FD BE 02    cp   (iy+$08)
501D: D2 84 50    jp   nc,$5024
5020: FD 36 02 00 ld   (iy+$08),$00
5024: FD CB 03 4C bit  0,(iy+$09)
5028: C2 9B 50    jp   nz,$503B
502B: 3A 00 6D    ld   a,(referee_x_pos_C700)
502E: D6 01       sub  $01
5030: 32 00 6D    ld   (referee_x_pos_C700),a
5033: 3A 04 6D    ld   a,(unknown_C704)
5036: C6 01       add  a,$01
5038: 32 04 6D    ld   (unknown_C704),a
503B: C9          ret

table_503C:
	dc.b	0x4c,0x50,0x73,0x50 ; table_503C
table_5040:
	dc.b	0x18,0x88,0x12,0x18,0x85,0x13,0x18,0x82 ; table_5040
	dc.b	0x14,0x18,0x85,0x15,0x04,0x0a,0x0d,0x0a ; $5048
	dc.b	0x13,0x0a,0x1d,0x0a,0x06,0x0b,0x09,0x0b ; $5050
	dc.b	0x15,0x0b,0x18,0x0b,0x0c,0x0c,0x10,0x0c ; $5058
	dc.b	0x1b,0x0c,0x07,0x0d,0x14,0x0d,0x02,0x0e ; $5060
	dc.b	0x11,0x0e,0x17,0x0e,0x1d,0x0e,0x0a,0x0f ; $5068
	dc.b	0x1a,0x0f,0xff,0x08,0x0a,0x11,0x0a,0x1c ; $5070
	dc.b	0x0a,0x03,0x0b,0x0b,0x0b,0x0e,0x0b,0x14 ; $5078
	dc.b	0x0b,0x1a,0x0b,0x17,0x0c,0x05,0x0d,0x0c ; $5080
	dc.b	0x0d,0x11,0x0d,0x1c,0x0d,0x09,0x0e,0x13 ; $5088
	dc.b	0x0e,0x19,0x0e,0x04,0x0f,0x0d,0x0f,0x16 ; $5090
	dc.b	0x0f,0xff,0x0e,0x01,0x7c,0x04,0x8a,0x7d ; $5098
	dc.b	0x04,0x8a,0x7e,0x04,0x8a,0x7f,0x04,0x8a ; $50a0
	dc.b	0x7c,0x04,0x8a,0x7d,0x04,0x8a,0x7e,0x04 ; $50a8
	dc.b	0x8a,0x7f,0x04,0x8a,0x7c,0x04,0x8a,0x7d ; $50b0
	dc.b	0x04,0x8a,0x7e,0x04,0x8a,0x7f,0x04,0x8a ; $50b8
	dc.b	0x7c,0x04,0x8a,0x7d,0x04,0x8a,0x0e,0x01 ; $50c0
	dc.b	0x7e,0x04,0x8a,0x7f,0x04,0x8a,0x7c,0x04 ; $50c8
	dc.b	0x8a,0x7d,0x04,0x8a,0x7e,0x04,0x8a,0x7f ; $50d0
	dc.b	0x04,0x8a,0x7c,0x04,0x8a,0x7d,0x04,0x8a ; $50d8
	dc.b	0x7e,0x04,0x8a,0x7f,0x04,0x8a,0x7c,0x04 ; $50e0
	dc.b	0x8a,0x7d,0x04,0x8a,0x7e,0x04,0x8a,0x7f ; $50e8
	dc.b	0x04,0x8a,0x67,0x4b,0xb0 ; $50f0

50F5: CD 18 B0    call clear_player_structure_partial_b012
50F8: FD 36 19 09 ld   (iy+$13),$03
50FC: 11 2D 69    ld   de,task_struct_C380+7
50FF: 21 45 58    ld   hl,table_5245
5102: 01 03 00    ld   bc,$0009
5105: ED B0       ldir
5107: DD 21 DD 97 ld   ix,table_3D77
510B: 3A 11 63    ld   a,(background_and_state_bits_C911)
510E: D6 10       sub  $10
5110: 87          add  a,a
5111: 87          add  a,a
5112: 06 00       ld   b,$00
5114: 4F          ld   c,a
5115: DD 09       add  ix,bc
5117: DD 7E 09    ld   a,(ix+$03)
511A: D6 80       sub  $20
511C: FD 77 0A    ld   (iy+$0a),a
511F: FD 46 19    ld   b,(iy+$13)
5122: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
5125: CB 56       bit  2,(hl)
5127: C2 8B 51    jp   nz,$512B
512A: 04          inc  b
512B: CB 40       bit  0,b
512D: C2 96 51    jp   nz,$513C
5130: FD CB 02 FE set  7,(iy+$08)
5134: FD 7E 03    ld   a,(iy+$09)
5137: ED 44       neg
5139: FD 77 03    ld   (iy+$09),a
513C: 3E 14       ld   a,$14
513E: CD D8 B0    call play_sound_B072
5141: CD C2 43    call $4968
5144: CD D2 43    call $4978
5147: CD 5E 47    call $4D5E
514A: CD 15 4B    call $4B15
514D: CD 56 4B    call $4B5C
5150: FE FF       cp   $FF
5152: CA 9C 58    jp   z,$5236
5155: FD 7E 18    ld   a,(iy+$12)
5158: A7          and  a
5159: C2 C1 51    jp   nz,$5161
515C: 3E 14       ld   a,$14
515E: CD D8 B0    call play_sound_B072
5161: CD C2 43    call $4968
5164: CD D2 43    call $4978
5167: CD F6 4B    call $4BFC
516A: F5          push af
516B: CD 5E 47    call $4D5E
516E: F1          pop  af
516F: A7          and  a
5170: CA 4A 51    jp   z,$514A
5173: FE 08       cp   $02
5175: CA AE 51    jp   z,$51AE
5178: FE 01       cp   $01
517A: C4 D5 B0    call nz,display_error_text_B075
517D: FD 7E 18    ld   a,(iy+$12)
5180: A7          and  a
5181: C2 4A 51    jp   nz,$514A
5184: FD E5       push iy
5186: 3E 0A       ld   a,$0A
5188: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
518B: CB 56       bit  2,(hl)
518D: C2 31 51    jp   nz,$5191
5190: 3C          inc  a
5191: 06 10       ld   b,$10
5193: CD 57 B0    call task_manipulation_B05D
5196: A7          and  a
5197: C4 D5 B0    call nz,display_error_text_B075
519A: 3E 08       ld   a,$02
519C: 06 10       ld   b,$10
519E: CD 57 B0    call task_manipulation_B05D
51A1: A7          and  a
51A2: C4 D5 B0    call nz,display_error_text_B075
51A5: FD E1       pop  iy
51A7: FD 36 18 FF ld   (iy+$12),$FF
51AB: C3 4A 51    jp   $514A
51AE: CD 16 47    call $4D1C
51B1: 3E 18       ld   a,$12
51B3: CD D8 B0    call play_sound_B072
51B6: CD C2 43    call $4968
51B9: CD D2 43    call $4978
51BC: CD 5E 47    call $4D5E
51BF: FD 6E 0D    ld   l,(iy+$07)
51C2: FD 66 02    ld   h,(iy+$08)
51C5: CB BC       res  7,h
51C7: E5          push hl
51C8: DD E1       pop  ix
51CA: 3E 10       ld   a,$10
51CC: CD D8 B0    call play_sound_B072
51CF: DD 7E 04    ld   a,(ix+$04)
51D2: DD A6 05    and  (ix+$05)
51D5: DD A6 0C    and  (ix+$06)
51D8: DD A6 0D    and  (ix+$07)
51DB: FE FF       cp   $FF
51DD: CA EC 51    jp   z,$51E6
51E0: CD 15 4B    call $4B15
51E3: C3 BC 51    jp   $51B6
51E6: FD E5       push iy
51E8: 3E 07       ld   a,$0D
51EA: FD 96 19    sub  (iy+$13)
51ED: 47          ld   b,a
51EE: 3E 04       ld   a,$04
51F0: CD 57 B0    call task_manipulation_B05D
51F3: FD E1       pop  iy
51F5: 3E 04       ld   a,$04
51F7: FD 96 19    sub  (iy+$13)
51FA: CB 27       sla  a
51FC: CB 27       sla  a
51FE: CB 27       sla  a
5200: CB 27       sla  a
5202: CD 12 B0    call $B018
5205: FD E5       push iy
5207: 3E 40       ld   a,$40
5209: CD 5A B0    call suspend_this_task_B05A
520C: A7          and  a
520D: C4 D5 B0    call nz,display_error_text_B075
5210: FD E1       pop  iy
5212: FD 35 19    dec  (iy+$13)
5215: C2 F6 50    jp   nz,$50FC
5218: 3E 08       ld   a,$02
521A: 06 01       ld   b,$01
521C: CD 57 B0    call task_manipulation_B05D
521F: 3E 0A       ld   a,$0A
5221: 06 11       ld   b,$11
5223: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
5226: CB 56       bit  2,(hl)
5228: C2 86 58    jp   nz,$522C
522B: 3C          inc  a
522C: CD 57 B0    call task_manipulation_B05D
522F: A7          and  a
5230: C4 D5 B0    call nz,display_error_text_B075
5233: C3 48 58    jp   $5242
5236: CD C2 43    call $4968
5239: DD E5       push ix
523B: E1          pop  hl
523C: 01 50 00    ld   bc,$0050
523F: CD 81 B0    call clear_zone_B021
5242: CD 51 B0    call task_yield_B051
table_5245:
	dc.b	0x1d,0x3a,0xe8,0xb0,0x00,0x07,0x03,0x4c ; table_5245
	dc.b	0xc7,0x00,0x00 ; $524d

task_5250:
5250: 3E 00       ld   a,$00
5252: DD 21 00 63 ld   ix,map_index_C900
5256: DD 77 00    ld   (ix+$00),a
5259: 21 66 59    ld   hl,table_53CC
525C: DD 75 08    ld   (ix+$02),l
525F: DD 74 09    ld   (ix+$03),h
5262: 7E          ld   a,(hl)
5263: DD 77 01    ld   (ix+$01),a
5266: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5269: 32 98 60    ld   (unknown_C032),a
526C: 3E 01       ld   a,$01
526E: CD 5D B0    call schedule_task_to_start_B057
5271: A7          and  a
5272: C4 D5 B0    call nz,display_error_text_B075
5275: 3E 20       ld   a,$80
5277: CD AE B0    call stop_sound_b0ae
527A: 3A 90 60    ld   a,(dip_switches_copy_C030)
527D: CB 7F       bit  7,a		; free play bit
527F: CA 2D 58    jp   z,$5287
5282: 3E 09       ld   a,$03
5284: 32 84 60    ld   (nb_credits_minus_one_C024),a
5287: 3E 00       ld   a,$00
5289: CD 5A B0    call suspend_this_task_B05A
528C: CD C0 B0    call set_normal_screen_b060
528F: 3E 01       ld   a,$01
5291: CD 15 B0    call resume_tasks_b015
5294: 3A 84 60    ld   a,(nb_credits_minus_one_C024)
5297: A7          and  a
; after game over check if there are still credits
5298: CA 50 58    jp   z,$5250
529B: DD 21 00 63 ld   ix,map_index_C900
529F: FD 21 02 63 ld   iy,unknown_C908
52A3: 3E 00       ld   a,$00
52A5: DD 77 00    ld   (ix+$00),a
52A8: FD 77 00    ld   (iy+$00),a
52AB: 21 47 59    ld   hl,table_534d
52AE: 7E          ld   a,(hl)
52AF: DD 77 01    ld   (ix+$01),a
52B2: FD 77 01    ld   (iy+$01),a
52B5: DD 75 08    ld   (ix+$02),l
52B8: FD 75 08    ld   (iy+$02),l
52BB: DD 74 09    ld   (ix+$03),h
52BE: FD 74 09    ld   (iy+$03),h
52C1: 3E 00       ld   a,$00
52C3: DD 77 04    ld   (ix+$04),a
52C6: FD 77 04    ld   (iy+$04),a
52C9: DD 77 05    ld   (ix+$05),a
52CC: FD 77 05    ld   (iy+$05),a
52CF: DD 77 0C    ld   (ix+$06),a
52D2: FD 77 0C    ld   (iy+$06),a
52D5: DD 77 0D    ld   (ix+$07),a
52D8: FD 77 0D    ld   (iy+$07),a
52DB: 32 76 60    ld   (level_number_C0DC),a
52DE: 32 77 60    ld   (unknown_C0DD),a
52E1: 32 7E 60    ld   (unknown_C0DE),a
52E4: 32 7F 60    ld   (unknown_C0DF),a
52E7: 32 E0 60    ld   (unknown_C0E0),a
52EA: 32 E1 60    ld   (unknown_C0E1),a
52ED: 32 E8 60    ld   (unknown_C0E2),a
52F0: 32 E9 60    ld   (unknown_C0E3),a
52F3: 32 E4 60    ld   (unknown_C0E4),a
52F6: 32 E5 60    ld   (unknown_C0E5),a
52F9: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
52FC: CB C6       set  0,(hl)
52FE: CB D6       set  2,(hl)
5300: 21 84 60    ld   hl,nb_credits_minus_one_C024
5303: 7E          ld   a,(hl)
5304: D6 01       sub  $01
5306: 27          daa
5307: 77          ld   (hl),a
5308: CD 1E B0    call clear_C7xx_B01E
530B: 3E 01       ld   a,$01
530D: CD 5A B0    call suspend_this_task_B05A
5310: 01 96 00    ld   bc,$003C
5313: CD 90 B0    call fill_video_and_attribute_memory_B030
5316: 3E 20       ld   a,$80
5318: CD D8 B0    call play_sound_B072
531B: CD 60 B0    call enable_interrupts_b0c0
531E: CD 38 DB    call display_start_message_7b92
5321: CD 16 D6    call display_credits_7C1C
5324: CD C3 B0    call check_coin_ports_B069
5327: CB 57       bit  2,a
5329: C2 CC 58    jp   nz,$5266
532C: 3A 84 60    ld   a,(nb_credits_minus_one_C024)
532F: A7          and  a
5330: CA 1B 59    jp   z,$531B
5333: CD C3 B0    call check_coin_ports_B069
5336: CB 5F       bit  3,a
5338: CA 1B 59    jp   z,$531B
; set 2 player mode
533B: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
533E: CB CE       set  1,(hl)
5340: CB DE       set  3,(hl)
5342: 21 84 60    ld   hl,nb_credits_minus_one_C024
5345: 7E          ld   a,(hl)
5346: D6 01       sub  $01
5348: 27          daa
5349: 77          ld   (hl),a
534A: C3 CC 58    jp   $5266
table_534d:
	dc.b	0x53,0x27,0x07,0x37,0x17,0x55,0x24,0x04 ; table_534d
	dc.b	0x34,0x14,0x55,0x22,0x02,0x32,0x12,0x55 ; $5355
	dc.b	0x20,0x00,0x30,0x10,0x55,0x2a,0x0a,0x3a ; $535d
	dc.b	0x1a,0x55,0x28,0x08,0x38,0x18,0x55,0x25 ; $5365
	dc.b	0x05,0x35,0x15,0x55,0x29,0x09,0x39,0x19 ; $536d
	dc.b	0x55,0x26,0x06,0x36,0x16,0x55,0x23,0x03 ; $5375
	dc.b	0x33,0x13,0x55,0x21,0x01,0x31,0x11,0x55 ; $537d
	dc.b	0x2b,0x0b,0x3b,0x1b,0x55,0x27,0x07,0x37 ; $5385
	dc.b	0x17,0x55,0x24,0x04,0x34,0x14,0x55,0x22 ; $538d
	dc.b	0x02,0x32,0x12,0x55,0x20,0x00,0x30,0x10 ; $5395
	dc.b	0x55,0x2a,0x0a,0x3a,0x1a,0x55,0x28,0x08 ; $539d
	dc.b	0x38,0x18,0x55,0x25,0x05,0x35,0x15,0x55 ; $53a5
	dc.b	0x29,0x09,0x39,0x19,0x55,0x26,0x06,0x36 ; $53ad
	dc.b	0x16,0x55,0x23,0x03,0x33,0x13,0x55,0x21 ; $53b5
	dc.b	0x01,0x31,0x11,0x55,0x2b,0x0b,0xff,0x4d ; $53bd
	dc.b	0x53 ; $53c5
table_53C6:
	dc.b	0x54,0x40,0x51
table_53C9:
	dc.b	0x3b,0x54,0x51 ; table_53C9
table_53CC:
	dc.b	0xd2,0xd0,0x80,0xff,0xcc,0x53 ; table_53CC
task_53d2:
53D2: 21 62 60    ld   hl,unknown_C0C8
53D5: 06 10       ld   b,$10
53D7: 36 00       ld   (hl),$00
53D9: 23          inc  hl
53DA: 10 FB       djnz $53D7
53DC: CD C0 B0    call set_normal_screen_b060
; 1 player mode (and also at game bootup)
53DF: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
53E2: CB D6       set  2,(hl)
53E4: 3E 20       ld   a,$80
53E6: CD D8 B0    call play_sound_B072
53E9: 3E 08       ld   a,$02
53EB: CD 15 B0    call resume_tasks_b015
53EE: CD 1E B0    call clear_C7xx_B01E
53F1: 3E 01       ld   a,$01
53F3: CD 5A B0    call suspend_this_task_B05A
53F6: A7          and  a
53F7: C4 D5 B0    call nz,display_error_text_B075
53FA: 01 96 00    ld   bc,$003C
53FD: CD 90 B0    call fill_video_and_attribute_memory_B030
5400: 21 02 63    ld   hl,unknown_C908
5403: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5406: CB 57       bit  2,a
5408: CA 0E 54    jp   z,$540E
; copy the contents of C900 to C907 (8 bytes)
540B: 21 00 63    ld   hl,map_index_C900
540E: 11 10 63    ld   de,computer_skill_C910
5411: 01 02 00    ld   bc,$0008
5414: ED B0       ldir
5416: 3E 09       ld   a,$03
5418: CD 5D B0    call schedule_task_to_start_B057
541B: A7          and  a
541C: C4 D5 B0    call nz,display_error_text_B075
541F: 3E 08       ld   a,$02
5421: CD 5D B0    call schedule_task_to_start_B057
5424: A7          and  a
5425: C4 D5 B0    call nz,display_error_text_B075
5428: 3E 05       ld   a,$05
542A: CD 5D B0    call schedule_task_to_start_B057
542D: A7          and  a
542E: C4 D5 B0    call nz,display_error_text_B075
5431: 3E 0F       ld   a,$0F
5433: CD 5D B0    call schedule_task_to_start_B057
5436: A7          and  a
5437: C4 D5 B0    call nz,display_error_text_B075
543A: 3E 00       ld   a,$00
543C: CD 5A B0    call suspend_this_task_B05A
543F: CD D4 53    call $5974
5442: A7          and  a
5443: CA E4 59    jp   z,$53E4
5446: 3E 00       ld   a,$00
5448: 47          ld   b,a
5449: CD 57 B0    call task_manipulation_B05D
544C: CD 51 B0    call task_yield_B051
544F: CD 23 DA    call $7A89
5452: CD 7C DA    call $7AD6
5455: CD B1 B0    call is_title_screen_demo_mode_B0B1
5458: A7          and  a
5459: CA C4 54    jp   z,$5464
545C: CD B4 B0    call display_players_rank_B0B4
545F: 3E 00       ld   a,$00
5461: CD 12 B0    call $B018
5464: 3A 11 63    ld   a,(background_and_state_bits_C911)
5467: CB BF       res  7,a
5469: CB 27       sla  a
546B: 4F          ld   c,a
546C: 06 00       ld   b,$00
546E: DD 21 DB 54 ld   ix,jump_table_547B
5472: DD 09       add  ix,bc
5474: DD 6E 00    ld   l,(ix+$00)
5477: DD 66 01    ld   h,(ix+$01)
547A: E9          jp   (hl)
jump_table_547B:
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$5529
	.word	$56F8
	.word	$B084
	.word	$4D84
	.word	$56F8
	.word	$B087
	.word	$56F8
	.word	$4D84
	.word	$56F8
	.word	$4D84
	.word	$B08A
	.word	$B08D
	.word	$4D84
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58C7
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$58FF
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$5925
	.word	$78EA
	.word	$B078
	.word	$B07B
	.word	$5F2A
	.word	$5BF4
	.word	$5836
	.word	display_error_text_B075


5529: 3E 00       ld   a,$00
552B: 32 4D 61    ld   (unknown_C147),a
552E: 32 42 61    ld   (unknown_C148),a
5531: 3E 0A       ld   a,$0A
5533: CD 5D B0    call schedule_task_to_start_B057
5536: A7          and  a
5537: C4 D5 B0    call nz,display_error_text_B075
553A: 3E 0B       ld   a,$0B
553C: CD 5D B0    call schedule_task_to_start_B057
553F: A7          and  a
5540: C4 D5 B0    call nz,display_error_text_B075
5543: 3E 04       ld   a,$04
5545: CD 5D B0    call schedule_task_to_start_B057
5548: 3E 09       ld   a,$03
554A: CD 5D B0    call schedule_task_to_start_B057
554D: 3E 0D       ld   a,$07
554F: CD 5D B0    call schedule_task_to_start_B057
5552: A7          and  a
5553: C4 D5 B0    call nz,display_error_text_B075
5556: 3E 02       ld   a,$08
5558: CD 5D B0    call schedule_task_to_start_B057
555B: A7          and  a
555C: C4 D5 B0    call nz,display_error_text_B075
555F: 3E 03       ld   a,$09
5561: CD 5D B0    call schedule_task_to_start_B057
5564: A7          and  a
5565: C4 D5 B0    call nz,display_error_text_B075
5568: 3E 00       ld   a,$00
556A: CD 5A B0    call suspend_this_task_B05A
556D: FE 02       cp   $08
556F: C2 36 55    jp   nz,$559C
5572: 3E 0A       ld   a,$0A
5574: 06 02       ld   b,$08
5576: CD 57 B0    call task_manipulation_B05D
5579: 3E 0B       ld   a,$0B
557B: 06 02       ld   b,$08
557D: CD 57 B0    call task_manipulation_B05D
5580: 3E 02       ld   a,$08
5582: 06 03       ld   b,$09
5584: CD 57 B0    call task_manipulation_B05D
5587: 3E 03       ld   a,$09
5589: 06 03       ld   b,$09
558B: CD 57 B0    call task_manipulation_B05D
558E: 3E 0D       ld   a,$07
5590: 06 02       ld   b,$08
5592: CD 57 B0    call task_manipulation_B05D
5595: A7          and  a
5596: C4 D5 B0    call nz,display_error_text_B075
5599: C3 C2 55    jp   $5568
559C: FE 01       cp   $01
559E: CA A3 55    jp   z,$55A9
55A1: FE 08       cp   $02
55A3: CA 50 5C    jp   z,$5650
55A6: CD D5 B0    call display_error_text_B075
55A9: 3E 20       ld   a,$80
55AB: CD D8 B0    call play_sound_B072
55AE: 3E 0D       ld   a,$07
55B0: CD 54 B0    call resume_task_B054
55B3: 3E 02       ld   a,$08
55B5: CD 54 B0    call resume_task_B054
55B8: 3E 03       ld   a,$09
55BA: CD 54 B0    call resume_task_B054
55BD: 3E 0B       ld   a,$0B
55BF: CD 54 B0    call resume_task_B054
55C2: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
55C5: CB 57       bit  2,a
55C7: CA 14 5C    jp   z,$5614
55CA: 3A CD 61    ld   a,(match_timer_C167)
55CD: A7          and  a
55CE: CA 14 5C    jp   z,$5614
55D1: 3A CD 61    ld   a,(match_timer_C167)
55D4: D6 01       sub  $01
55D6: 27          daa
55D7: 32 CD 61    ld   (match_timer_C167),a
55DA: CD FB C4    call $64FB
55DD: 3E 02       ld   a,$08
55DF: CD D8 B0    call play_sound_B072
55E2: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
55E5: E6 06       and  $0C
55E7: FE 06       cp   $0C
55E9: C2 FE 55    jp   nz,$55FE
55EC: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
55EF: CB 9E       res  3,(hl)
55F1: 3E 01       ld   a,$01
55F3: CD 12 B0    call $B018
55F6: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
55F9: CB DE       set  3,(hl)
55FB: C3 09 5C    jp   $5603
55FE: 3E 01       ld   a,$01
5600: CD 12 B0    call $B018
5603: 3E 0C       ld   a,$06
5605: CD 5A B0    call suspend_this_task_B05A
5608: 3A CD 61    ld   a,(match_timer_C167)
560B: A7          and  a
560C: C2 71 55    jp   nz,$55D1
560F: 3E 96       ld   a,$3C
5611: CD 5A B0    call suspend_this_task_B05A
5614: 3E 0D       ld   a,$07
5616: CD 54 B0    call resume_task_B054
5619: 3E 0A       ld   a,$0A
561B: CD 54 B0    call resume_task_B054
561E: 3A 11 63    ld   a,(background_and_state_bits_C911)
5621: CB 7F       bit  7,a
5623: C2 49 5C    jp   nz,$5643
5626: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5629: FE 0A       cp   $0A
562B: CA 92 5C    jp   z,$5638
562E: 21 42 61    ld   hl,unknown_C148
5631: 34          inc  (hl)
5632: 7E          ld   a,(hl)
5633: FE 08       cp   $02
5635: DA 91 55    jp   c,$5531
5638: 21 E0 60    ld   hl,unknown_C0E0
563B: CD 03 5F    call $5F09
563E: 3E C4       ld   a,$64
5640: CD 5A B0    call suspend_this_task_B05A
5643: 3E 01       ld   a,$01
5645: 47          ld   b,a
5646: CD 57 B0    call task_manipulation_B05D
5649: A7          and  a
564A: C4 D5 B0    call nz,display_error_text_B075
564D: CD 51 B0    call task_yield_B051
5650: 3E 20       ld   a,$80
5652: CD D8 B0    call play_sound_B072
5655: 3E 0D       ld   a,$07
5657: CD 54 B0    call resume_task_B054
565A: 3E 02       ld   a,$08
565C: CD 54 B0    call resume_task_B054
565F: 3E 03       ld   a,$09
5661: CD 54 B0    call resume_task_B054
5664: 3E 0A       ld   a,$0A
5666: CD 54 B0    call resume_task_B054
5669: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
566C: CB 5F       bit  3,a
566E: CA BB 5C    jp   z,$56BB
5671: 3A CD 61    ld   a,(match_timer_C167)
5674: A7          and  a
5675: CA BB 5C    jp   z,$56BB
5678: 3A CD 61    ld   a,(match_timer_C167)
567B: D6 01       sub  $01
567D: 27          daa
567E: 32 CD 61    ld   (match_timer_C167),a
5681: CD FB C4    call $64FB
5684: 3E 02       ld   a,$08
5686: CD D8 B0    call play_sound_B072
5689: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
568C: E6 06       and  $0C
568E: FE 06       cp   $0C
5690: C2 A5 5C    jp   nz,$56A5
5693: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
5696: CB 96       res  2,(hl)
5698: 3E 01       ld   a,$01
569A: CD 12 B0    call $B018
569D: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
56A0: CB D6       set  2,(hl)
56A2: C3 AA 5C    jp   $56AA
56A5: 3E 01       ld   a,$01
56A7: CD 12 B0    call $B018
56AA: 3E 0C       ld   a,$06
56AC: CD 5A B0    call suspend_this_task_B05A
56AF: 3A CD 61    ld   a,(match_timer_C167)
56B2: A7          and  a
56B3: C2 D2 5C    jp   nz,$5678
56B6: 3E 96       ld   a,$3C
56B8: CD 5A B0    call suspend_this_task_B05A
56BB: 3E 0D       ld   a,$07
56BD: CD 54 B0    call resume_task_B054
56C0: 3E 0B       ld   a,$0B
56C2: CD 54 B0    call resume_task_B054
56C5: 3A 11 63    ld   a,(background_and_state_bits_C911)
56C8: CB 7F       bit  7,a
56CA: C2 EA 5C    jp   nz,$56EA
56CD: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
56D0: FE 05       cp   $05
56D2: CA 7F 5C    jp   z,$56DF
56D5: 21 4D 61    ld   hl,unknown_C147
56D8: 34          inc  (hl)
56D9: 7E          ld   a,(hl)
56DA: FE 08       cp   $02
56DC: DA 91 55    jp   c,$5531
56DF: 21 E9 60    ld   hl,unknown_C0E3
56E2: CD 03 5F    call $5F09
56E5: 3E C4       ld   a,$64
56E7: CD 5A B0    call suspend_this_task_B05A
56EA: 3E 01       ld   a,$01
56EC: 06 08       ld   b,$02
56EE: CD 57 B0    call task_manipulation_B05D
56F1: A7          and  a
56F2: C4 D5 B0    call nz,display_error_text_B075
56F5: CD 51 B0    call task_yield_B051

56F8: 21 E9 DD    ld   hl,table_77e3
56FB: CD 96 B0    call display_multicolor_text_B03C
56FE: 3E 0A       ld   a,$0A
5700: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
5703: CB 56       bit  2,(hl)
5705: C2 03 5D    jp   nz,$5709
5708: 3C          inc  a
5709: CD 5D B0    call schedule_task_to_start_B057
570C: A7          and  a
570D: C4 D5 B0    call nz,display_error_text_B075
5710: 3E 02       ld   a,$08
5712: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
5715: CB 56       bit  2,(hl)
5717: C2 1B 5D    jp   nz,$571B
571A: 3C          inc  a
571B: CD 5D B0    call schedule_task_to_start_B057
571E: A7          and  a
571F: C4 D5 B0    call nz,display_error_text_B075
5722: 3E 04       ld   a,$04
5724: CD 5D B0    call schedule_task_to_start_B057
5727: A7          and  a
5728: C4 D5 B0    call nz,display_error_text_B075
572B: 3E D2       ld   a,$78
572D: CD 5A B0    call suspend_this_task_B05A
5730: A7          and  a
5731: C4 D5 B0    call nz,display_error_text_B075
5734: 3E 0C       ld   a,$06
5736: 32 42 61    ld   (unknown_C148),a
5739: 32 4D 61    ld   (unknown_C147),a
573C: 21 8E 60    ld   hl,periodic_counter_16bit_C02E
573F: 56          ld   d,(hl)
; choose among 6 evade sequences
; 3 sequences + mirrored
5740: 1E 0C       ld   e,$06
5742: CD 0C B0    call random_B006
5745: 32 12 63    ld   (unknown_C918),a
5748: 3A 42 61    ld   a,(unknown_C148)
574B: FE 09       cp   $03
574D: C2 5D 5D    jp   nz,$5757
5750: 21 4D 61    ld   hl,unknown_C147
5753: 35          dec  (hl)
5754: 23          inc  hl
5755: 35          dec  (hl)
5756: 7E          ld   a,(hl)
5757: 32 13 63    ld   (unknown_C919),a
575A: 3A 01 60    ld   a,(unknown_C001)
575D: E6 F0       and  $F0
575F: 07          rlca
5760: 07          rlca
5761: 07          rlca
5762: 07          rlca
5763: 47          ld   b,a
5764: 3A 08 60    ld   a,(unknown_C002)
5767: E6 0F       and  $0F
5769: B0          or   b
576A: 1F          rra
576B: DA DA 5D    jp   c,$577A
576E: 3E 10       ld   a,$10
5770: CD 5D B0    call schedule_task_to_start_B057
5773: A7          and  a
5774: C4 D5 B0    call nz,display_error_text_B075
5777: C3 AD 5D    jp   $57A7
577A: 1F          rra
577B: DA 2A 5D    jp   c,$578A
577E: 3E 11       ld   a,$11
5780: CD 5D B0    call schedule_task_to_start_B057
5783: A7          and  a
5784: C4 D5 B0    call nz,display_error_text_B075
5787: C3 AD 5D    jp   $57A7
578A: 1F          rra
578B: DA 3A 5D    jp   c,$579A
578E: 3E 18       ld   a,$12
5790: CD 5D B0    call schedule_task_to_start_B057
5793: A7          and  a
5794: C4 D5 B0    call nz,display_error_text_B075
5797: C3 AD 5D    jp   $57A7
579A: 1F          rra
579B: DA A7 5D    jp   c,$57AD
579E: 3E 19       ld   a,$13
57A0: CD 5D B0    call schedule_task_to_start_B057
57A3: A7          and  a
57A4: C4 D5 B0    call nz,display_error_text_B075
57A7: 21 4D 61    ld   hl,unknown_C147
57AA: 35          dec  (hl)
57AB: 23          inc  hl
57AC: 35          dec  (hl)
; very strange code getting skill then rotating the value
; (divide by 4 but get low bits in high bits)
; then clipping the value to 15 if >= 16
; looks like someone didn't know about sra...
;
; so basically what it does is that it divides the skill
; level by 4, to adjust appear period. It creates harder and
; harder evade stages (if it wasn't already super-hard like that)
; because objects appear faster and faster. At higher level (not
; reachable without hacking the game), 2 objects can be present on
; screen: for instance one object is in the middle of the screen when
; the next object appears!
;
; this is called each time an object is introduced in the evade
; sequence
;
57AD: 3A 10 63    ld   a,(computer_skill_C910)
57B0: CB 3F       srl  a
57B2: CB 3F       srl  a
57B4: FE 10       cp   $10
57B6: DA BB 5D    jp   c,$57BB
; clip to 15
57B9: 3E 0F       ld   a,$0F
57BB: E6 0F       and  $0F
57BD: 4F          ld   c,a
57BE: 06 00       ld   b,$00
57C0: 21 73 D3    ld   hl,evade_object_period_table_79D9
57C3: 09          add  hl,bc
57C4: 7E          ld   a,(hl)
57C5: CD 5A B0    call suspend_this_task_B05A
57C8: A7          and  a
57C9: CA E6 5D    jp   z,$57EC
57CC: FE 09       cp   $03
57CE: C4 D5 B0    call nz,display_error_text_B075
57D1: 3E 06       ld   a,$0C
57D3: CD 15 B0    call resume_tasks_b015
57D6: 3E 96       ld   a,$3C
57D8: CD 5A B0    call suspend_this_task_B05A
57DB: A7          and  a
57DC: C4 D5 B0    call nz,display_error_text_B075
57DF: 3E 01       ld   a,$01
57E1: 47          ld   b,a
57E2: CD 57 B0    call task_manipulation_B05D
57E5: A7          and  a
57E6: C4 D5 B0    call nz,display_error_text_B075
57E9: CD 51 B0    call task_yield_B051
57EC: 3A 4D 61    ld   a,(unknown_C147)
57EF: A7          and  a
57F0: C2 96 5D    jp   nz,$573C
57F3: DD 21 00 60 ld   ix,active_task_bit_table_C000
57F7: DD 7E 01    ld   a,(ix+$01)
57FA: E6 D0       and  $70
57FC: 47          ld   b,a
57FD: DD 7E 08    ld   a,(ix+$02)
5800: E6 0F       and  $0F
5802: B0          or   b
5803: CA 18 52    jp   z,$5812
5806: 3E 1E       ld   a,$1E
5808: CD 5A B0    call suspend_this_task_B05A
580B: A7          and  a
580C: C2 66 5D    jp   nz,$57CC
580F: C3 F9 5D    jp   $57F3
5812: C4 D5 B0    call nz,display_error_text_B075
5815: 3E 0F       ld   a,$0F
5817: 06 80       ld   b,$20
5819: CD 57 B0    call task_manipulation_B05D
581C: A7          and  a
581D: C4 D5 B0    call nz,display_error_text_B075
5820: 3E 28       ld   a,$82
5822: CD 5A B0    call suspend_this_task_B05A
5825: A7          and  a
5826: C4 D5 B0    call nz,display_error_text_B075
5829: 3E 01       ld   a,$01
582B: 47          ld   b,a
582C: CD 57 B0    call task_manipulation_B05D
582F: A7          and  a
5830: C4 D5 B0    call nz,display_error_text_B075
5833: CD 51 B0    call task_yield_B051
5836: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5839: E6 09       and  $03
583B: FE 09       cp   $03
583D: C2 B3 52    jp   nz,$58B9
5840: 3A 90 60    ld   a,(dip_switches_copy_C030)
5843: CB 7F       bit  7,a	; free play
5845: CA 47 52    jp   z,$584D
5848: 3E 09       ld   a,$03
584A: 32 84 60    ld   (nb_credits_minus_one_C024),a
584D: 3A 84 60    ld   a,(nb_credits_minus_one_C024)
5850: A7          and  a
5851: C2 AE 52    jp   nz,$58AE
5854: 21 1C D2    ld   hl,table_7816
5857: 16 32       ld   d,$98
5859: CD 93 B0    call display_text_B039
585C: 3E 15       ld   a,$15
585E: 32 43 61    ld   (unknown_C149),a
5861: 06 96       ld   b,$3C
5863: C5          push bc
5864: 3E 01       ld   a,$01
5866: CD 5A B0    call suspend_this_task_B05A
5869: CD C3 B0    call check_coin_ports_B069
586C: C1          pop  bc
586D: CB 57       bit  2,a
586F: C2 B3 52    jp   nz,$58B9
5872: 3A 84 60    ld   a,(nb_credits_minus_one_C024)
5875: A7          and  a
5876: C2 AE 52    jp   nz,$58AE
5879: 10 E2       djnz $5863
587B: 21 15 06    ld   hl,$0C15		; immediate
587E: 22 00 6F    ld   (temp_numeric_buffer_CF00),hl
5881: 3E FF       ld   a,$FF
5883: 32 04 6F    ld   (address_of_current_player_move_byte_CF04),a
5886: 21 43 61    ld   hl,unknown_C149
5889: 7E          ld   a,(hl)
588A: D6 01       sub  $01
588C: 27          daa
588D: FE 33       cp   $99
588F: CA B3 52    jp   z,$58B9
5892: 77          ld   (hl),a
5893: 47          ld   b,a
5894: E6 0F       and  $0F
5896: 32 09 6F    ld   (unknown_CF03),a
5899: 78          ld   a,b
589A: E6 F0       and  $F0
589C: 0F          rrca
589D: 0F          rrca
589E: 0F          rrca
589F: 0F          rrca
58A0: 32 08 6F    ld   (unknown_CF02),a
58A3: 21 00 6F    ld   hl,temp_numeric_buffer_CF00
58A6: 16 32       ld   d,$98
58A8: CD 93 B0    call display_text_B039
58AB: C3 C1 52    jp   $5861
58AE: 21 84 60    ld   hl,nb_credits_minus_one_C024
58B1: 35          dec  (hl)
58B2: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
58B5: CB D6       set  2,(hl)
58B7: CB DE       set  3,(hl)
58B9: 3E 01       ld   a,$01
58BB: 06 01       ld   b,$01
58BD: CD 57 B0    call task_manipulation_B05D
58C0: A7          and  a
58C1: C4 D5 B0    call nz,display_error_text_B075
58C4: CD 51 B0    call task_yield_B051
58C7: 3E 09       ld   a,$03
58C9: CD D8 B0    call play_sound_B072
58CC: 3E 0A       ld   a,$0A
58CE: CD 5D B0    call schedule_task_to_start_B057
58D1: A7          and  a
58D2: C4 D5 B0    call nz,display_error_text_B075
58D5: 3E 0B       ld   a,$0B
58D7: CD 5D B0    call schedule_task_to_start_B057
58DA: A7          and  a
58DB: C4 D5 B0    call nz,display_error_text_B075
58DE: 3E 0C       ld   a,$06
58E0: CD 5D B0    call schedule_task_to_start_B057
58E3: 06 0D       ld   b,$07
58E5: C5          push bc
58E6: 3E 9F       ld   a,$3F
58E8: CD 5A B0    call suspend_this_task_B05A
58EB: A7          and  a
58EC: C4 D5 B0    call nz,display_error_text_B075
58EF: C1          pop  bc
58F0: 10 F9       djnz $58E5
58F2: 3E 01       ld   a,$01
58F4: 47          ld   b,a
58F5: CD 57 B0    call task_manipulation_B05D
58F8: A7          and  a
58F9: C4 D5 B0    call nz,display_error_text_B075
58FC: CD 51 B0    call task_yield_B051
58FF: 3E 04       ld   a,$04
5901: CD D8 B0    call play_sound_B072
5904: 3E 0C       ld   a,$06
5906: CD 5D B0    call schedule_task_to_start_B057
5909: 06 05       ld   b,$05
590B: C5          push bc
590C: 3E 9F       ld   a,$3F
590E: CD 5A B0    call suspend_this_task_B05A
5911: A7          and  a
5912: C4 D5 B0    call nz,display_error_text_B075
5915: C1          pop  bc
5916: 10 F9       djnz $590B
5918: 3E 01       ld   a,$01
591A: 47          ld   b,a
591B: CD 57 B0    call task_manipulation_B05D
591E: A7          and  a
591F: C4 D5 B0    call nz,display_error_text_B075
5922: CD 51 B0    call task_yield_B051
5925: 3E 08       ld   a,$02
5927: CD D8 B0    call play_sound_B072
592A: 3E 0C       ld   a,$06
592C: CD 5D B0    call schedule_task_to_start_B057
592F: 06 08       ld   b,$02
5931: C5          push bc
5932: 3E 9F       ld   a,$3F
5934: CD 5A B0    call suspend_this_task_B05A
5937: A7          and  a
5938: C4 D5 B0    call nz,display_error_text_B075
593B: C1          pop  bc
593C: 10 F9       djnz $5931
593E: 21 B3 DD    ld   hl,table_77b9
5941: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5944: E6 09       and  $03
5946: FE 09       cp   $03
5948: C2 53 53    jp   nz,$5959
594B: 21 BD D2    ld   hl,table_78b7
594E: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5951: CB 57       bit  2,a
5953: C2 53 53    jp   nz,$5959
5956: 21 24 D2    ld   hl,table_7884
5959: 16 32       ld   d,$98
595B: CD 93 B0    call display_text_B039
595E: 3E 50       ld   a,$50
5960: CD 5A B0    call suspend_this_task_B05A
5963: A7          and  a
5964: C4 D5 B0    call nz,display_error_text_B075
5967: 3E 01       ld   a,$01
5969: 47          ld   b,a
596A: CD 57 B0    call task_manipulation_B05D
596D: A7          and  a
596E: C4 D5 B0    call nz,display_error_text_B075
5971: CD 51 B0    call task_yield_B051
5974: 47          ld   b,a
5975: 3A 11 63    ld   a,(background_and_state_bits_C911)
5978: CB 7F       bit  7,a
597A: C2 58 5B    jp   nz,$5B52
597D: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5980: E6 09       and  $03
5982: FE 09       cp   $03
5984: CA FF 53    jp   z,$59FF
5987: 3A 11 63    ld   a,(background_and_state_bits_C911)
598A: CB BF       res  7,a
598C: FE 51       cp   $51
598E: C2 36 53    jp   nz,$599C
5991: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5994: E6 F0       and  $F0
5996: 32 87 60    ld   (players_type_human_or_cpu_flags_C02D),a
5999: 3E FF       ld   a,$FF
599B: C9          ret
599C: FE 10       cp   $10
599E: D2 56 5B    jp   nc,$5B5C
59A1: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
59A4: CB 57       bit  2,a
59A6: CA 65 53    jp   z,$59C5
59A9: DD 21 00 63 ld   ix,map_index_C900
59AD: 78          ld   a,b
59AE: FE 01       cp   $01
59B0: C2 F3 53    jp   nz,$59F9
; increase level
59B3: 21 76 60    ld   hl,level_number_C0DC
59B6: 34          inc  (hl)
59B7: 3A 14 63    ld   a,(unknown_C914)
59BA: FE FF       cp   $FF
59BC: CA EC 53    jp   z,$59E6
; increase level number too (separate counters than C0DC: C900)
59BF: DD 34 00    inc  (ix+$00)
59C2: C3 56 5B    jp   $5B5C
59C5: CB 5F       bit  3,a
59C7: CC D5 B0    call z,display_error_text_B075
59CA: DD 21 02 63 ld   ix,unknown_C908
59CE: 78          ld   a,b
59CF: FE 08       cp   $02
59D1: C2 F3 53    jp   nz,$59F9
59D4: 21 76 60    ld   hl,level_number_C0DC
59D7: 34          inc  (hl)
59D8: 3A 14 63    ld   a,(unknown_C914)
59DB: FE FF       cp   $FF
59DD: CA EC 53    jp   z,$59E6
59E0: DD 34 00    inc  (ix+$00)
59E3: C3 56 5B    jp   $5B5C
59E6: DD 34 00    inc  (ix+$00)
59E9: 21 63 59    ld   hl,table_53C9
59EC: 7E          ld   a,(hl)
59ED: DD 77 01    ld   (ix+$01),a
59F0: DD 75 08    ld   (ix+$02),l
59F3: DD 74 09    ld   (ix+$03),h
59F6: C3 DA 5B    jp   return_zero_in_A_5B7A
59F9: CD D7 5B    call $5B7D
59FC: C3 DA 5B    jp   return_zero_in_A_5B7A
59FF: 3A 11 63    ld   a,(background_and_state_bits_C911)
5A02: CB BF       res  7,a
5A04: FE 10       cp   $10
5A06: D2 B2 5A    jp   nc,$5AB8
5A09: 78          ld   a,b
5A0A: FE 01       cp   $01
5A0C: C2 C1 5A    jp   nz,$5A61
5A0F: 21 76 60    ld   hl,level_number_C0DC
5A12: 34          inc  (hl)
5A13: DD 21 00 63 ld   ix,map_index_C900
5A17: DD 34 00    inc  (ix+$00)
5A1A: DD 46 01    ld   b,(ix+$01)
5A1D: C5          push bc
5A1E: DD 70 05    ld   (ix+$05),b
5A21: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
5A24: CB 96       res  2,(hl)
5A26: 3A 14 63    ld   a,(unknown_C914)
5A29: FE FF       cp   $FF
5A2B: C2 48 5A    jp   nz,$5A42
5A2E: 21 63 59    ld   hl,table_53C9
5A31: DD 21 00 63 ld   ix,map_index_C900
5A35: 7E          ld   a,(hl)
5A36: DD 77 01    ld   (ix+$01),a
5A39: DD 75 08    ld   (ix+$02),l
5A3C: DD 74 09    ld   (ix+$03),h
5A3F: C3 43 5A    jp   $5A49
5A42: DD 21 00 63 ld   ix,map_index_C900
5A46: CD A1 5B    call $5BA1
5A49: 21 6C 59    ld   hl,table_53C6
5A4C: C1          pop  bc
5A4D: DD 21 02 63 ld   ix,unknown_C908
5A51: DD 70 05    ld   (ix+$05),b
5A54: 7E          ld   a,(hl)
5A55: DD 77 01    ld   (ix+$01),a
5A58: DD 75 08    ld   (ix+$02),l
5A5B: DD 74 09    ld   (ix+$03),h
5A5E: C3 DA 5B    jp   return_zero_in_A_5B7A
5A61: FE 08       cp   $02
5A63: C4 D5 B0    call nz,display_error_text_B075
5A66: 21 76 60    ld   hl,level_number_C0DC
5A69: 34          inc  (hl)
5A6A: DD 21 02 63 ld   ix,unknown_C908
5A6E: DD 34 00    inc  (ix+$00)
5A71: DD 46 01    ld   b,(ix+$01)
5A74: C5          push bc
5A75: DD 70 05    ld   (ix+$05),b
5A78: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
5A7B: CB 9E       res  3,(hl)
5A7D: 3A 14 63    ld   a,(unknown_C914)
5A80: FE FF       cp   $FF
5A82: C2 33 5A    jp   nz,$5A99
5A85: 21 63 59    ld   hl,table_53C9
5A88: DD 21 02 63 ld   ix,unknown_C908
5A8C: 7E          ld   a,(hl)
5A8D: DD 77 01    ld   (ix+$01),a
5A90: DD 75 08    ld   (ix+$02),l
5A93: DD 74 09    ld   (ix+$03),h
5A96: C3 A0 5A    jp   $5AA0
5A99: DD 21 02 63 ld   ix,unknown_C908
5A9D: CD A1 5B    call $5BA1
5AA0: 21 6C 59    ld   hl,table_53C6
5AA3: C1          pop  bc
5AA4: DD 21 00 63 ld   ix,map_index_C900
5AA8: DD 70 05    ld   (ix+$05),b
5AAB: 7E          ld   a,(hl)
5AAC: DD 77 01    ld   (ix+$01),a
5AAF: DD 75 08    ld   (ix+$02),l
5AB2: DD 74 09    ld   (ix+$03),h
5AB5: C3 DA 5B    jp   return_zero_in_A_5B7A
5AB8: 3A 11 63    ld   a,(background_and_state_bits_C911)
5ABB: CB BF       res  7,a
5ABD: FE 51       cp   $51
5ABF: C2 FA 5A    jp   nz,$5AFA
5AC2: 3A 14 63    ld   a,(unknown_C914)
5AC5: FE FF       cp   $FF
5AC7: CA 75 5A    jp   z,$5AD5
5ACA: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5ACD: EE 06       xor  $0C
5ACF: 32 87 60    ld   (players_type_human_or_cpu_flags_C02D),a
5AD2: C3 DA 5B    jp   return_zero_in_A_5B7A
5AD5: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5AD8: CB 57       bit  2,a
5ADA: CA E3 5A    jp   z,$5AE9
5ADD: CB 87       res  0,a
5ADF: CB 97       res  2,a
5AE1: CB DF       set  3,a
5AE3: 32 87 60    ld   (players_type_human_or_cpu_flags_C02D),a
5AE6: C3 DA 5B    jp   return_zero_in_A_5B7A
5AE9: CB 5F       bit  3,a
5AEB: CC D5 B0    call z,display_error_text_B075
5AEE: CB 8F       res  1,a
5AF0: CB 9F       res  3,a
5AF2: CB D7       set  2,a
5AF4: 32 87 60    ld   (players_type_human_or_cpu_flags_C02D),a
5AF7: C3 DA 5B    jp   return_zero_in_A_5B7A
5AFA: FE 55       cp   $55
5AFC: C2 56 5B    jp   nz,$5B5C
5AFF: DD 21 00 63 ld   ix,map_index_C900
5B03: DD 7E 01    ld   a,(ix+$01)
5B06: FE 55       cp   $55
5B08: CA 0F 5B    jp   z,$5B0F
5B0B: DD 21 02 63 ld   ix,unknown_C908
5B0F: CD A1 5B    call $5BA1
5B12: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5B15: E6 0F       and  $0F
5B17: FE 0F       cp   $0F
5B19: C2 40 5B    jp   nz,$5B40
5B1C: 3A 01 63    ld   a,(unknown_C901)
5B1F: FE 51       cp   $51
5B21: C2 98 5B    jp   nz,$5B32
5B24: 21 03 63    ld   hl,unknown_C909
5B27: 11 01 63    ld   de,unknown_C901
5B2A: 01 09 00    ld   bc,$0003
5B2D: ED B0       ldir
5B2F: C3 DA 5B    jp   return_zero_in_A_5B7A
5B32: 21 01 63    ld   hl,unknown_C901
5B35: 11 03 63    ld   de,unknown_C909
5B38: 01 09 00    ld   bc,$0003
5B3B: ED B0       ldir
5B3D: C3 DA 5B    jp   return_zero_in_A_5B7A
5B40: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
5B43: FE 0B       cp   $0B
5B45: C2 47 5B    jp   nz,$5B4D
5B48: CB 86       res  0,(hl)
5B4A: C3 DA 5B    jp   return_zero_in_A_5B7A
5B4D: CB 8E       res  1,(hl)
5B4F: C3 DA 5B    jp   return_zero_in_A_5B7A
5B52: 21 62 60    ld   hl,unknown_C0C8
5B55: 06 10       ld   b,$10
5B57: 36 00       ld   (hl),$00
5B59: 23          inc  hl
5B5A: 10 FB       djnz $5B57
5B5C: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5B5F: CB 57       bit  2,a
5B61: CA CB 5B    jp   z,$5B6B
5B64: DD 21 00 63 ld   ix,map_index_C900
5B68: CD A1 5B    call $5BA1
5B6B: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5B6E: CB 5F       bit  3,a
5B70: CA DA 5B    jp   z,return_zero_in_A_5B7A
5B73: DD 21 02 63 ld   ix,unknown_C908
5B77: CD A1 5B    call $5BA1
return_zero_in_A_5B7A:
5B7A: 3E 00       ld   a,$00
5B7C: C9          ret

5B7D: DD 21 02 63 ld   ix,unknown_C908
5B81: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5B84: CB 57       bit  2,a
5B86: CA 27 5B    jp   z,$5B8D
5B89: DD 21 00 63 ld   ix,map_index_C900
5B8D: DD 46 01    ld   b,(ix+$01)
5B90: DD 70 05    ld   (ix+$05),b
5B93: 21 6C 59    ld   hl,table_53C6
5B96: 7E          ld   a,(hl)
5B97: DD 77 01    ld   (ix+$01),a
5B9A: DD 75 08    ld   (ix+$02),l
5B9D: DD 74 09    ld   (ix+$03),h
5BA0: C9          ret
5BA1: 3A 11 63    ld   a,(background_and_state_bits_C911)
5BA4: CB 7F       bit  7,a
5BA6: CA 6A 5B    jp   z,$5BCA
5BA9: DD 6E 08    ld   l,(ix+$02)
5BAC: DD 66 09    ld   h,(ix+$03)
5BAF: 01 01 00    ld   bc,$0001
5BB2: 09          add  hl,bc
5BB3: 7E          ld   a,(hl)
5BB4: FE FF       cp   $FF
5BB6: C2 60 5B    jp   nz,$5BC0
5BB9: 23          inc  hl
5BBA: 4E          ld   c,(hl)
5BBB: 23          inc  hl
5BBC: 46          ld   b,(hl)
5BBD: C5          push bc
5BBE: E1          pop  hl
5BBF: 7E          ld   a,(hl)
5BC0: DD 77 01    ld   (ix+$01),a
5BC3: DD 75 08    ld   (ix+$02),l
5BC6: DD 74 09    ld   (ix+$03),h
5BC9: C9          ret
5BCA: DD 6E 08    ld   l,(ix+$02)
5BCD: DD 66 09    ld   h,(ix+$03)
5BD0: 01 01 00    ld   bc,$0001
5BD3: 09          add  hl,bc
5BD4: 7E          ld   a,(hl)
5BD5: 47          ld   b,a
5BD6: E6 F0       and  $F0
5BD8: FE 40       cp   $40
5BDA: C2 E8 5B    jp   nz,$5BE2
5BDD: DD 7E 05    ld   a,(ix+$05)
5BE0: B0          or   b
5BE1: 47          ld   b,a
5BE2: DD 70 01    ld   (ix+$01),b
5BE5: DD 75 08    ld   (ix+$02),l
5BE8: DD 74 09    ld   (ix+$03),h
5BEB: 23          inc  hl
5BEC: 7E          ld   a,(hl)
5BED: FE FF       cp   $FF
5BEF: C0          ret  nz
5BF0: DD 77 04    ld   (ix+$04),a
5BF3: C9          ret
5BF4: 3A 10 63    ld   a,(computer_skill_C910)
5BF7: A7          and  a
5BF8: CA 05 56    jp   z,$5C05
5BFB: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5BFE: E6 09       and  $03
5C00: FE 09       cp   $03
5C02: C2 0F 56    jp   nz,$5C0F
5C05: 3E 01       ld   a,$01
5C07: 06 01       ld   b,$01
5C09: CD 57 B0    call task_manipulation_B05D
5C0C: CD 51 B0    call task_yield_B051
5C0F: 01 9E A0    ld   bc,$A03E
5C12: CD 90 B0    call fill_video_and_attribute_memory_B030
5C15: 21 9C D7    ld   hl,table_7D36
5C18: CD 96 B0    call display_multicolor_text_B03C
5C1B: CD 7C DA    call $7AD6
5C1E: CD B4 B0    call display_players_rank_B0B4
5C21: 3E 00       ld   a,$00
5C23: CD 12 B0    call $B018
5C26: 3A 10 63    ld   a,(computer_skill_C910)
5C29: 87          add  a,a
5C2A: 87          add  a,a
5C2B: 87          add  a,a
5C2C: 4F          ld   c,a
5C2D: 06 00       ld   b,$00
5C2F: 21 8D 57    ld   hl,table_5D27
5C32: 11 00 6D    ld   de,referee_x_pos_C700
5C35: ED B0       ldir
5C37: DD 21 E0 60 ld   ix,unknown_C0E0
5C3B: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5C3E: CB 57       bit  2,a
5C40: C2 4D 56    jp   nz,$5C47
5C43: DD 21 E9 60 ld   ix,unknown_C0E3
5C47: FD 21 01 6D ld   iy,unknown_C701
5C4B: DD 7E 00    ld   a,(ix+$00)
5C4E: DD E5       push ix
5C50: DD 21 ED 57 ld   ix,table_5DE7
5C54: CD 8D 5E    call $5E27
5C57: DD E1       pop  ix
5C59: DD 7E 01    ld   a,(ix+$01)
5C5C: DD E5       push ix
5C5E: DD 21 0D 5E ld   ix,table_5E07
5C62: CD 8D 5E    call $5E27
5C65: DD E1       pop  ix
5C67: DD 7E 08    ld   a,(ix+$02)
5C6A: DD 21 FD 57 ld   ix,table_5DF7
5C6E: CD 8D 5E    call $5E27
5C71: 21 FA 56    ld   hl,table_5CFA
5C74: CD 96 B0    call display_multicolor_text_B03C
5C77: 3E 00       ld   a,$00
5C79: 32 4A 61    ld   (unknown_C14A),a
5C7C: 32 CD 61    ld   (match_timer_C167),a
5C7F: 21 07 19    ld   hl,$130D
5C82: 16 32       ld   d,$98
5C84: CD 00 C5    call $6500
5C87: 3E D2       ld   a,$78
5C89: CD 5A B0    call suspend_this_task_B05A
5C8C: A7          and  a
5C8D: C4 D5 B0    call nz,display_error_text_B075
5C90: 3A 10 63    ld   a,(computer_skill_C910)
5C93: 3D          dec  a
5C94: 32 43 61    ld   (unknown_C149),a
5C97: FD 21 00 6D ld   iy,referee_x_pos_C700
5C9B: 3A 43 61    ld   a,(unknown_C149)
5C9E: FE FF       cp   $FF
5CA0: CA 7F 56    jp   z,$5CDF
5CA3: 87          add  a,a
5CA4: 87          add  a,a
5CA5: 87          add  a,a
5CA6: 4F          ld   c,a
5CA7: 06 00       ld   b,$00
5CA9: FD 09       add  iy,bc
5CAB: FD E5       push iy
5CAD: D1          pop  de
5CAE: 21 1F 57    ld   hl,table_5D1F
5CB1: 01 02 00    ld   bc,$0008
5CB4: ED B0       ldir
5CB6: 3E 02       ld   a,$08
5CB8: CD D8 B0    call play_sound_B072
5CBB: 21 4A 61    ld   hl,unknown_C14A
5CBE: 7E          ld   a,(hl)
5CBF: C6 01       add  a,$01
5CC1: 27          daa
5CC2: 77          ld   (hl),a
5CC3: 32 CD 61    ld   (match_timer_C167),a
5CC6: 16 32       ld   d,$98
5CC8: 21 07 19    ld   hl,$130D
5CCB: CD 00 C5    call $6500
5CCE: 3E 05       ld   a,$05
5CD0: CD 5C 5E    call $5E56
5CD3: 21 43 61    ld   hl,unknown_C149
5CD6: 35          dec  (hl)
5CD7: 3E 0F       ld   a,$0F
5CD9: CD 5A B0    call suspend_this_task_B05A
5CDC: C3 3D 56    jp   $5C97
5CDF: CD DC 5E    call $5E76
5CE2: 3E 80       ld   a,$20
5CE4: CD D8 B0    call play_sound_B072
5CE7: 3E D2       ld   a,$78
5CE9: CD 5A B0    call suspend_this_task_B05A
5CEC: A7          and  a
5CED: C4 D5 B0    call nz,display_error_text_B075
5CF0: 3E 01       ld   a,$01
5CF2: 06 01       ld   b,$01
5CF4: CD 57 B0    call task_manipulation_B05D
5CF7: CD 51 B0    call task_yield_B051
table_5CFA:
	dc.b	0x07,0x13,0x05,0x98,0x00,0x98,0x00,0x98 ; table_5CFA
	dc.b	0x3e,0x78,0x21,0x98,0x3e,0x78,0x3e,0x78 ; $5d02
	dc.b	0x3e,0x78,0x3e,0x78,0x32,0x98,0x3e,0x78 ; $5d0a
	dc.b	0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; $5d12
	dc.b	0x00,0x98,0x00,0x98,0xff ; $5d1a
table_5D1F:
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; table_5D1F
table_5D27:
	dc.b	0x28,0x00,0x00,0x48,0x28,0x00,0x00,0x58 ; table_5D27
	dc.b	0x48,0x00,0x00,0x48,0x48,0x00,0x00,0x58 ; $5d2f
	dc.b	0x68,0x00,0x00,0x48,0x68,0x00,0x00,0x58 ; $5d37
	dc.b	0x88,0x00,0x00,0x48,0x88,0x00,0x00,0x58 ; $5d3f
	dc.b	0xa8,0x00,0x00,0x48,0xa8,0x00,0x00,0x58 ; $5d47
	dc.b	0xc8,0x00,0x00,0x48,0xc8,0x00,0x00,0x58 ; $5d4f
	dc.b	0x28,0x00,0x00,0x70,0x28,0x00,0x00,0x80 ; $5d57
	dc.b	0x48,0x00,0x00,0x70,0x48,0x00,0x00,0x80 ; $5d5f
	dc.b	0x68,0x00,0x00,0x70,0x68,0x00,0x00,0x80 ; $5d67
	dc.b	0x88,0x00,0x00,0x70,0x88,0x00,0x00,0x80 ; $5d6f
	dc.b	0xa8,0x00,0x00,0x70,0xa8,0x00,0x00,0x80 ; $5d77
	dc.b	0xc8,0x00,0x00,0x70,0xc8,0x00,0x00,0x80 ; $5d7f
	dc.b	0x28,0x00,0x00,0xa8,0x28,0x00,0x00,0xb8 ; $5d87
	dc.b	0x48,0x00,0x00,0xa8,0x48,0x00,0x00,0xb8 ; $5d8f
	dc.b	0x68,0x00,0x00,0xa8,0x68,0x00,0x00,0xb8 ; $5d97
	dc.b	0x88,0x00,0x00,0xa8,0x88,0x00,0x00,0xb8 ; $5d9f
	dc.b	0xa8,0x00,0x00,0xa8,0xa8,0x00,0x00,0xb8 ; $5da7
	dc.b	0xc8,0x00,0x00,0xa8,0xc8,0x00,0x00,0xb8 ; $5daf
	dc.b	0x28,0x00,0x00,0xd0,0x28,0x00,0x00,0xe0 ; $5db7
	dc.b	0x48,0x00,0x00,0xd0,0x48,0x00,0x00,0xe0 ; $5dbf
	dc.b	0x68,0x00,0x00,0xd0,0x68,0x00,0x00,0xe0 ; $5dc7
	dc.b	0x88,0x00,0x00,0xd0,0x88,0x00,0x00,0xe0 ; $5dcf
	dc.b	0xa8,0x00,0x00,0xd0,0xa8,0x00,0x00,0xe0 ; $5dd7
	dc.b	0xc8,0x00,0x00,0xd0,0xc8,0x00,0x00,0xe0 ; $5ddf
table_5DE7:
	dc.b	0x88,0x52,0x89,0x52,0xc0,0x52,0xc1,0x52 ; table_5DE7
	dc.b	0x48,0x52,0x49,0x52,0x28,0x52,0x29,0x52 ; $5def
table_5DF7:
	dc.b	0xb0,0x52,0xb1,0x52,0x50,0x54,0x51,0x54 ; table_5DF7
	dc.b	0xd0,0x52,0xd1,0x52,0x98,0x51,0x99,0x51 ; $5dff
table_5E07:
	dc.b	0xa0,0x52,0xa1,0x52,0xa8,0x54,0xa9,0x54 ; table_5E07
	dc.b	0xc8,0x51,0xc9,0x51,0x68,0x53,0x69,0x53 ; $5e0f
	dc.b	0x88,0x52,0x89,0x52,0xc0,0x52,0xc1,0x52 ; $5e17
	dc.b	0x48,0x52,0x49,0x52,0x28,0x52,0x29,0x52 ; $5e1f

5E27: 06 02       ld   b,$08
5E29: CB 3F       srl  a
5E2B: DA 9C 5E    jp   c,$5E36
5E2E: 11 04 00    ld   de,$0004
5E31: DD 19       add  ix,de
5E33: 10 F4       djnz $5E29
5E35: C9          ret

5E36: DD 6E 00    ld   l,(ix+$00)
5E39: DD 66 01    ld   h,(ix+$01)
5E3C: FD 75 00    ld   (iy+$00),l
5E3F: FD 74 01    ld   (iy+$01),h
5E42: DD 6E 08    ld   l,(ix+$02)
5E45: DD 66 09    ld   h,(ix+$03)
5E48: FD 75 04    ld   (iy+$04),l
5E4B: FD 74 05    ld   (iy+$05),h
5E4E: 11 02 00    ld   de,$0008
5E51: FD 19       add  iy,de
5E53: C3 8E 5E    jp   $5E2E
5E56: DD 21 77 60 ld   ix,unknown_C0DD
5E5A: DD 86 01    add  a,(ix+$01)
5E5D: 27          daa
5E5E: DD 77 01    ld   (ix+$01),a
5E61: DD 7E 00    ld   a,(ix+$00)
5E64: CE 00       adc  a,$00
5E66: 27          daa
5E67: DD 77 00    ld   (ix+$00),a
5E6A: 21 77 60    ld   hl,unknown_C0DD
5E6D: 16 32       ld   d,$98
5E6F: 01 19 18    ld   bc,$1213
5E72: CD 9F B0    call display_text_color_2_B03F
5E75: C9          ret
5E76: 06 04       ld   b,$04
5E78: C5          push bc
5E79: 3E 00       ld   a,$00
5E7B: CD 5C 5E    call $5E56
5E7E: 3E 14       ld   a,$14
5E80: CD 5A B0    call suspend_this_task_B05A
5E83: A7          and  a
5E84: C4 D5 B0    call nz,display_error_text_B075
5E87: 21 00 5F    ld   hl,table_5F00
5E8A: 16 32       ld   d,$98
5E8C: CD 93 B0    call display_text_B039
5E8F: 3E 14       ld   a,$14
5E91: CD 5A B0    call suspend_this_task_B05A
5E94: A7          and  a
5E95: C4 D5 B0    call nz,display_error_text_B075
5E98: C1          pop  bc
5E99: 10 77       djnz $5E78
5E9B: 01 04 14    ld   bc,$1404
5E9E: DD 21 62 60 ld   ix,unknown_C0C8
5EA2: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
5EA5: CB 57       bit  2,a
5EA7: C2 B1 5E    jp   nz,$5EB1
5EAA: 01 0C 14    ld   bc,$1406
5EAD: DD 21 70 60 ld   ix,unknown_C0D0
5EB1: FD 21 77 60 ld   iy,unknown_C0DD
5EB5: DD 7E 01    ld   a,(ix+$01)
5EB8: FD 86 01    add  a,(iy+$01)
5EBB: 27          daa
5EBC: DD 77 01    ld   (ix+$01),a
5EBF: DD 7E 00    ld   a,(ix+$00)
5EC2: FD 8E 00    adc  a,(iy+$00)
5EC5: 27          daa
5EC6: DD 77 00    ld   (ix+$00),a
5EC9: C5          push bc
5ECA: DD E5       push ix
5ECC: 2A 60 60    ld   hl,(unknown_C0C0)
5ECF: 7D          ld   a,l
5ED0: 6C          ld   l,h
5ED1: 67          ld   h,a
5ED2: DD 46 00    ld   b,(ix+$00)
5ED5: DD 4E 01    ld   c,(ix+$01)
5ED8: A7          and  a
5ED9: ED 42       sbc  hl,bc
5EDB: D2 E3 5E    jp   nc,$5EE9
5EDE: 11 60 60    ld   de,unknown_C0C0
5EE1: DD E5       push ix
5EE3: E1          pop  hl
5EE4: 01 09 00    ld   bc,$0003
5EE7: ED B0       ldir
5EE9: DD E1       pop  ix
5EEB: C1          pop  bc
5EEC: 16 32       ld   d,$98
5EEE: DD E5       push ix
5EF0: E1          pop  hl
5EF1: CD 9F B0    call display_text_color_2_B03F
5EF4: 01 08 14    ld   bc,$1402
5EF7: 21 60 60    ld   hl,unknown_C0C0
5EFA: 16 32       ld   d,$98
5EFC: CD 9F B0    call display_text_color_2_B03F
5EFF: C9          ret
table_5F00:
	dc.b	0x12,0x13,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; table_5F00
	dc.b	0xff ; $5f08
; <> HL
; check level number < 8 > 10 whatever
5F09: 3A 76 60    ld   a,(level_number_C0DC)
5F0C: FE 02       cp   $08
5F0E: DA 1F 5F    jp   c,$5F1F
5F11: 23          inc  hl
5F12: FE 10       cp   $10
5F14: DA 17 5F    jp   c,$5F1D
5F17: 23          inc  hl
5F18: D6 10       sub  $10
5F1A: C3 1F 5F    jp   $5F1F
5F1D: D6 02       sub  $08
5F1F: 3C          inc  a
5F20: 47          ld   b,a
5F21: AF          xor  a
5F22: 37          scf
5F23: CB 17       rl   a
5F25: 10 F6       djnz $5F23
5F27: B6          or   (hl)
5F28: 77          ld   (hl),a
5F29: C9          ret

5F2A: 01 91 A4    ld   bc,$A431
5F2D: CD 90 B0    call fill_video_and_attribute_memory_B030
5F30: 21 E3 29    ld   hl,table_83e9
5F33: CD 96 B0    call display_multicolor_text_B03C
5F36: 21 C0 A8    ld   hl,table_a260
5F39: CD 96 B0    call display_multicolor_text_B03C
5F3C: 21 9C D7    ld   hl,table_7D36
5F3F: CD 96 B0    call display_multicolor_text_B03C
5F42: CD B4 B0    call display_players_rank_B0B4
5F45: CD 7C DA    call $7AD6
5F48: 3E 00       ld   a,$00
5F4A: CD 12 B0    call $B018
5F4D: 21 06 C0    ld   hl,table_600C
5F50: CD 96 B0    call display_multicolor_text_B03C
5F53: 21 8E C0    ld   hl,table_602E
5F56: 16 A2       ld   d,$A8
5F58: CD 93 B0    call display_text_B039
5F5B: CD C3 B0    call check_coin_ports_B069
5F5E: E6 06       and  $0C
5F60: 32 4F 61    ld   (unknown_C14F),a
5F63: 06 4C       ld   b,$46
5F65: C5          push bc
5F66: 3E 09       ld   a,$03
5F68: CD 5A B0    call suspend_this_task_B05A
5F6B: A7          and  a
5F6C: C4 D5 B0    call nz,display_error_text_B075
5F6F: CD C3 B0    call check_coin_ports_B069
5F72: E6 06       and  $0C
5F74: C1          pop  bc
5F75: C2 F2 5F    jp   nz,$5FF8
5F78: 32 4F 61    ld   (unknown_C14F),a
5F7B: 10 E2       djnz $5F65
5F7D: 01 19 0C    ld   bc,$0613
5F80: 11 97 A0    ld   de,$a03d
5F83: 21 0E 12    ld   hl,$180E
5F86: CD 1B B0    call fill_rectangle_B01B
5F89: 3E 04       ld   a,$04
5F8B: CD 5D B0    call schedule_task_to_start_B057
5F8E: 3E 0A       ld   a,$0A
5F90: CD 5D B0    call schedule_task_to_start_B057
5F93: A7          and  a
5F94: C4 D5 B0    call nz,display_error_text_B075
5F97: 3E 0B       ld   a,$0B
5F99: CD 5D B0    call schedule_task_to_start_B057
5F9C: A7          and  a
5F9D: C4 D5 B0    call nz,display_error_text_B075
5FA0: 3E 02       ld   a,$08
5FA2: CD 5D B0    call schedule_task_to_start_B057
5FA5: A7          and  a
5FA6: C4 D5 B0    call nz,display_error_text_B075
5FA9: 3E 03       ld   a,$09
5FAB: CD 5D B0    call schedule_task_to_start_B057
5FAE: A7          and  a
5FAF: C4 D5 B0    call nz,display_error_text_B075
5FB2: CD C3 B0    call check_coin_ports_B069
5FB5: E6 06       and  $0C
5FB7: 32 4F 61    ld   (unknown_C14F),a
5FBA: 3E 09       ld   a,$03
; within this B05A call the computer performs the current technique
; animation
5FBC: CD 5A B0    call suspend_this_task_B05A
5FBF: A7          and  a
5FC0: C2 71 5F    jp   nz,$5FD1
5FC3: CD C3 B0    call check_coin_ports_B069
5FC6: E6 06       and  $0C
5FC8: C2 08 C0    jp   nz,$6002
5FCB: 32 4F 61    ld   (unknown_C14F),a
5FCE: C3 BA 5F    jp   $5FBA
5FD1: 3E C4       ld   a,$64
5FD3: CD 5A B0    call suspend_this_task_B05A
5FD6: 3E 0F       ld   a,$0F
5FD8: 06 80       ld   b,$20
5FDA: CD 57 B0    call task_manipulation_B05D
5FDD: A7          and  a
5FDE: C4 D5 B0    call nz,display_error_text_B075
5FE1: 3E D2       ld   a,$78
5FE3: CD 5A B0    call suspend_this_task_B05A
5FE6: A7          and  a
5FE7: C4 D5 B0    call nz,display_error_text_B075
5FEA: 3E 01       ld   a,$01
5FEC: 06 01       ld   b,$01
5FEE: CD 57 B0    call task_manipulation_B05D
5FF1: A7          and  a
5FF2: C4 D5 B0    call nz,display_error_text_B075
5FF5: CD 51 B0    call task_yield_B051
5FF8: 3A 4F 61    ld   a,(unknown_C14F)
5FFB: A7          and  a
5FFC: CA EA 5F    jp   z,$5FEA
5FFF: C3 DB 5F    jp   $5F7B
6002: 3A 4F 61    ld   a,(unknown_C14F)
6005: A7          and  a
6006: CA EA 5F    jp   z,$5FEA
6009: C3 BA 5F    jp   $5FBA
table_600C:
	dc.b	0x06,0x05,0xc9,0x02,0xca,0x02,0xcb,0x02 ; table_600C
	dc.b	0xcc,0x02,0xcd,0x02,0xce,0x02,0xcf,0x02 ; $6014
	dc.b	0xfe,0x06,0x06,0xd0,0x02,0x49,0x02,0x4a ; $601c
	dc.b	0x02,0x4b,0x02,0x4c,0x02,0x4d,0x02,0x4e ; $6024
	dc.b	0x02,0xff ; $602c
table_602E:
	dc.b	0x09,0x0e,0x12,0x0f,0x3c,0x22,0x18,0x1e ; table_602E
	dc.b	0x3c,0x0d,0x18,0x3c,0x17,0x18,0x1d,0xfe ; $6036
	dc.b	0x06,0x10,0x20,0x0a,0x17,0x1d,0x3c,0x19 ; $603e
	dc.b	0x1b ; $6046
6047: 0A          ld   a,(bc)
6048: 06 17       ld   b,$1D
604A: 18 06       jr   $6058
604C: 0E 96       ld   c,$3C
604E: 13          inc  de
604F: 1B          dec  de
6050: 0E 16       ld   c,$1C
6052: 16 FE       ld   d,$FE
6054: 0C          inc  c
6055: 18 13       jr   $6070
6057: 15          dec  d
6058: 0A          ld   a,(bc)
6059: 88          adc  a,b
605A: 0E 1B       ld   c,$1B
605C: 96          sub  (hl)
605D: 16 17       ld   d,$1D
605F: 0A          ld   a,(bc)
6060: 1B          dec  de
6061: 17          rla
6062: 96          sub  (hl)
6063: 0B          dec  bc
6064: 1E 17       ld   e,$1D
6066: 17          rla
6067: 12          ld   (de),a
6068: 1D          dec  e
6069: FF          rst  $38
; probably bullshit above
606A: FD 21 80 68 ld   iy,unknown_C220
606E: 0E 00       ld   c,$00
6070: 06 00       ld   b,$00
6072: 21 00 C9    ld   hl,table_6300
6075: 09          add  hl,bc
6076: FD 75 0D    ld   (iy+$07),l
6079: FD 74 02    ld   (iy+$08),h
607C: 7E          ld   a,(hl)
607D: FD 77 03    ld   (iy+$09),a
6080: 3E 0D       ld   a,$07
6082: FD 77 0A    ld   (iy+$0a),a
6085: 3E 00       ld   a,$00
6087: FD 77 0B    ld   (iy+$0b),a
608A: 21 8E 60    ld   hl,periodic_counter_16bit_C02E
608D: 56          ld   d,(hl)
608E: 1E 09       ld   e,$03
6090: CD 0C B0    call random_B006
6093: FD 77 06    ld   (iy+$0c),a
6096: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
6099: CB 5F       bit  3,a
609B: C2 23 C1    jp   nz,$6189
609E: 3E 00       ld   a,$00
60A0: CD 5A B0    call suspend_this_task_B05A
60A3: FE 06       cp   $0C
60A5: C4 D5 B0    call nz,display_error_text_B075
60A8: FD 21 39 C9 ld   iy,table_6393
60AC: DD 21 C0 68 ld   ix,player_2_struct_C260
60B0: DD 6E 0D    ld   l,(ix+$07)
60B3: DD 7E 02    ld   a,(ix+$08)
60B6: E6 DF       and  $7F
60B8: 67          ld   h,a
60B9: 06 00       ld   b,$00
60BB: FD 5E 00    ld   e,(iy+$00)
60BE: FD 56 01    ld   d,(iy+$01)
60C1: A7          and  a
60C2: EB          ex   de,hl
60C3: ED 52       sbc  hl,de
60C5: CA EC C0    jp   z,$60E6
60C8: EB          ex   de,hl
60C9: FD 23       inc  iy
60CB: FD 23       inc  iy
60CD: FD 7E 00    ld   a,(iy+$00)
60D0: FD A6 01    and  (iy+$01)
60D3: FE FF       cp   $FF
60D5: CA CC C1    jp   z,$6166
60D8: FE FE       cp   $FE
60DA: C2 BB C0    jp   nz,$60BB
60DD: FD 23       inc  iy
60DF: FD 23       inc  iy
60E1: 06 FF       ld   b,$FF
60E3: C3 BB C0    jp   $60BB
60E6: FD 21 80 68 ld   iy,unknown_C220
60EA: 78          ld   a,b
60EB: A7          and  a
60EC: C2 15 C1    jp   nz,$6115
60EF: 3A CB 68    ld   a,(unknown_C26B)
60F2: A7          and  a
60F3: C2 CC C1    jp   nz,$6166
60F6: FD 7E 03    ld   a,(iy+$09)
60F9: CD 5A B0    call suspend_this_task_B05A
60FC: A7          and  a
60FD: C4 D5 B0    call nz,display_error_text_B075
6100: FD 21 80 68 ld   iy,unknown_C220
6104: FD 7E 0A    ld   a,(iy+$0a)		; current practice technique index (decreasing to $FF)
6107: FE FF       cp   $FF
6109: CA CC C1    jp   z,$6166			; practice done
610C: FD 35 0A    dec  (iy+$0a)			; decrease index
; 1 player mode - display the technique name in "practice"
610F: CD E6 C1    call display_practice_technique_name_61EC
6112: C3 CC C1    jp   $6166
6115: 06 98       ld   b,$32
6117: C5          push bc
6118: 3E 01       ld   a,$01
611A: CD 5A B0    call suspend_this_task_B05A
611D: A7          and  a
611E: C4 D5 B0    call nz,display_error_text_B075
6121: C1          pop  bc
6122: 05          dec  b
6123: CA 59 C1    jp   z,$6153
6126: FD 21 C0 68 ld   iy,player_2_struct_C260
612A: DD 21 40 68 ld   ix,player_1_struct_C240
612E: FD 6E 0D    ld   l,(iy+$07)
6131: FD 66 02    ld   h,(iy+$08)
6134: DD 5E 0D    ld   e,(ix+$07)
6137: DD 56 02    ld   d,(ix+$08)
613A: A7          and  a
613B: ED 52       sbc  hl,de
613D: C2 1D C1    jp   nz,$6117
6140: FD 21 80 68 ld   iy,unknown_C220
6144: FD 34 0B    inc  (iy+$0b)
6147: 3E 04       ld   a,$04
6149: 06 08       ld   b,$02
614B: CD 57 B0    call task_manipulation_B05D
614E: 3E 08       ld   a,$02
6150: CD 12 B0    call $B018
6153: 3E 00       ld   a,$00
6155: 32 CB 68    ld   (unknown_C26B),a
6158: CD 90 C8    call $6230
615B: FD 21 80 68 ld   iy,unknown_C220
615F: FD 7E 0A    ld   a,(iy+$0a)
6162: A7          and  a
6163: CA D4 C1    jp   z,$6174
6166: 3E 0B       ld   a,$0B
6168: 06 07       ld   b,$0D
616A: CD 57 B0    call task_manipulation_B05D
616D: A7          and  a
616E: C4 D5 B0    call nz,display_error_text_B075
6171: C3 3C C0    jp   $6096
6174: 3E 0B       ld   a,$0B
6176: 06 07       ld   b,$0D
6178: CD 57 B0    call task_manipulation_B05D
617B: 3E 08       ld   a,$02
617D: 06 0F       ld   b,$0F
617F: CD 57 B0    call task_manipulation_B05D
6182: A7          and  a
6183: C4 D5 B0    call nz,display_error_text_B075
6186: C3 3C C0    jp   $6096
6189: 3E 01       ld   a,$01
618B: CD 5A B0    call suspend_this_task_B05A
618E: A7          and  a
618F: CA B4 C1    jp   z,$61B4
6192: FE 03       cp   $09
6194: CA 23 C1    jp   z,$6189
6197: FE 06       cp   $0C
6199: C4 D5 B0    call nz,display_error_text_B075
619C: CD BD 97    call $3DB7
619F: 32 CB 68    ld   (unknown_C26B),a
61A2: AF          xor  a
61A3: 32 C6 68    ld   (unknown_C26C),a
61A6: 3E 0B       ld   a,$0B
61A8: 06 07       ld   b,$0D
61AA: CD 57 B0    call task_manipulation_B05D
61AD: A7          and  a
61AE: C4 D5 B0    call nz,display_error_text_B075
61B1: C3 23 C1    jp   $6189
61B4: FD 21 80 68 ld   iy,unknown_C220
61B8: FD 7E 0A    ld   a,(iy+$0a)
61BB: FE FF       cp   $FF
61BD: CA 23 C1    jp   z,$6189
61C0: FD 35 03    dec  (iy+$09)
61C3: C2 23 C1    jp   nz,$6189
61C6: 3E C4       ld   a,$64
61C8: FD 77 03    ld   (iy+$09),a
; during practice (2 player mode)
; decrements C22A: number of techniques to mimic
61CB: FD 35 0A    dec  (iy+$0a)
61CE: FD 7E 0A    ld   a,(iy+$0a)
61D1: FE FF       cp   $FF
61D3: CA E8 C1    jp   z,$61E2	; end of practice
61D6: CD 90 C8    call $6230
61D9: FD 7E 0A    ld   a,(iy+$0a)
61DC: CD E6 C1    call display_practice_technique_name_61EC
61DF: C3 23 C1    jp   $6189
61E2: 3E 08       ld   a,$02
61E4: 06 0F       ld   b,$0F
61E6: CD 57 B0    call task_manipulation_B05D
61E9: C3 23 C1    jp   $6189


; called with decreasing A (10 -> 0)
; and uses a lookup table to get the proper move names
; < a: index in table
; < iy: table pointer ($C220)


display_practice_technique_name_61EC:
61EC: 87          add  a,a
61ED: 87          add  a,a
61EE: 4F          ld   c,a
61EF: 06 00       ld   b,$00
61F1: C5          push bc
61F2: FD 7E 06    ld   a,(iy+$0c)
61F5: CB 27       sla  a
61F7: 4F          ld   c,a
61F8: 06 00       ld   b,$00
61FA: DD 21 C1 C9 ld   ix,practice_table_end_6361
61FE: DD 09       add  ix,bc
6200: DD 6E 00    ld   l,(ix+$00)
6203: DD 66 01    ld   h,(ix+$01)
6206: E5          push hl
6207: DD E1       pop  ix
6209: C1          pop  bc
620A: DD 09       add  ix,bc
; practice
620C: DD 7E 00    ld   a,(ix+$00)		; technique id loaded
620F: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
6212: CB 5E       bit  3,(hl)
6214: C2 1A C8    jp   nz,$621A
; computer is showing the moves: load technique in player 2 structure
6217: 32 CB 68    ld   (unknown_C26B),a
621A: DD E5       push ix
621C: DD 7E 01    ld   a,(ix+$01)
621F: CD 5E C8    call $625E
6222: DD E1       pop  ix
6224: DD 6E 08    ld   l,(ix+$02)
6227: DD 66 09    ld   h,(ix+$03)
622A: 16 32       ld   d,$98
622C: CD 93 B0    call display_text_B039
622F: C9          ret
6230: 21 CD C9    ld   hl,table_6367
6233: 11 00 6F    ld   de,temp_numeric_buffer_CF00
6236: 01 86 00    ld   bc,$002C
6239: ED B0       ldir
623B: 21 00 6F    ld   hl,temp_numeric_buffer_CF00
623E: CD 96 B0    call display_multicolor_text_B03C
6241: 3E 11       ld   a,$11
6243: 32 00 6F    ld   (temp_numeric_buffer_CF00),a
6246: 32 0B 6F    ld   (unknown_CF0B),a
6249: 32 1C 6F    ld   (unknown_CF16),a
624C: 32 81 6F    ld   (unknown_CF21),a
624F: 21 00 6F    ld   hl,temp_numeric_buffer_CF00
6252: CD 96 B0    call display_multicolor_text_B03C
6255: 21 D9 C4    ld   hl,table_6473
6258: 16 32       ld   d,$98
625A: CD 93 B0    call display_text_B039
625D: C9          ret
625E: 21 7E C8    ld   hl,table_62DE
6261: 11 00 6F    ld   de,temp_numeric_buffer_CF00
6264: 01 88 00    ld   bc,$0022
6267: ED B0       ldir
6269: F5          push af
626A: 17          rla
626B: 17          rla
626C: 17          rla
626D: 17          rla
626E: 17          rla
626F: E6 0F       and  $0F
6271: CD 3D C8    call $6297
6274: DD 21 00 6F ld   ix,temp_numeric_buffer_CF00
6278: 3E 18       ld   a,$12
627A: DD 77 00    ld   (ix+$00),a
627D: DD 77 0D    ld   (ix+$07),a
6280: 3E 14       ld   a,$14
6282: DD 77 0E    ld   (ix+$0e),a
6285: DD 77 19    ld   (ix+$13),a
6288: 3E 11       ld   a,$11
628A: DD 77 12    ld   (ix+$18),a
628D: DD 77 17    ld   (ix+$1d),a
6290: F1          pop  af
6291: E6 0F       and  $0F
6293: CD 3D C8    call $6297
6296: C9          ret
6297: 0E 00       ld   c,$00
6299: 1F          rra
629A: DA AD C8    jp   c,$62A7
629D: 0C          inc  c
629E: F5          push af
629F: 79          ld   a,c
62A0: FE 04       cp   $04
62A2: F1          pop  af
62A3: C2 33 C8    jp   nz,$6299
62A6: C9          ret
62A7: CB 21       sla  c
62A9: 06 00       ld   b,$00
62AB: DD 21 6E C8 ld   ix,table_62CE
62AF: FD 21 C0 68 ld   iy,player_2_struct_C260
62B3: FD CB 02 DE bit  7,(iy+$08)
62B7: CA BE C8    jp   z,$62BE
62BA: DD 21 7C C8 ld   ix,table_62D6
62BE: DD 09       add  ix,bc
62C0: DD 6E 00    ld   l,(ix+$00)
62C3: DD 66 01    ld   h,(ix+$01)
62C6: CD 96 B0    call display_multicolor_text_B03C
62C9: C9          ret
table_62CE:
	dc.b	0x0e,0xcf,0x18,0xcf,0x00,0xcf,0x07,0xcf ; table_62CE
table_62D6:
	dc.b	0x18,0xcf,0x0e,0xcf,0x00,0xcf,0x07,0xcf ; table_62D6
table_62DE:
	dc.b	0x0c,0x1c,0xac,0x88,0xad,0x88,0xff,0x0c ; table_62DE
	dc.b	0x1f,0xb6,0x88,0xb7,0x88,0xff,0x0e,0x1d ; $62e6
	dc.b	0xb1,0x88,0xfe,0x0e,0x1e,0xb5,0x88,0xff ; $62ee
	dc.b	0x0b,0x1d,0xae,0x88,0xfe,0x0b,0x1e,0xb2 ; $62f6
	dc.b	0x88,0xff ; $62fe
table_6300:
	dc.b	0x2d ; table_6300

; practice table of move names words (lunge, front, back ...) and ids
; and positions to show them so the player(s) can execute them
;
; it's more difficult in 2-player mode because some moves are ambiguous
; ex: lunge punch or foot sweep exist as 2 different moves but there are
; only 3 sequences of 8 moves so no big surprises after a while
;
; format:
; move_id  ????  text address
; the sequences are iterated decreasing
;
; one possible sequence is (see <===) front kick, back kick,
practice_table_6301:
	dc.b	$11,$14,$44,$64	; lunge punch (high, forward)
	dc.b	$05,$02,$C3,$63	; back kick
	dc.b	$09,$82,$E9,$63	; foot sweep
	dc.b	$0A,$01,$F8,$63	; front kick
	dc.b	$0B,$21,$07,$64	; back round kick
	dc.b	$10,$24,$44,$64	; lunge punch (high, still)
	dc.b	$14,$08,$66,$64	; low kick
	dc.b	$0F,$04,$35,$64	; round kick  <==== first move of sequence #1

	dc.b	$08,$42,$D1,$63	; jumping back kick
	dc.b	$10,$24,$44,$64	; lunge punch (high, still)
	dc.b	$13,$84,$54,$64	; reverse punch
	dc.b	$0F,$04,$35,$64	; round kick
	dc.b	$09,$82,$E9,$63	; foot sweep (back)
	dc.b	$14,$08,$66,$64	; low kick
	dc.b	$05,$02,$C3,$63	; back kick
	dc.b	$0A,$01,$F8,$63	; front kick   <==== start of sequence #2

	dc.b	$08,$42,$D1,$63	; jumping back kick
	dc.b	$0F,$04,$35,$64	; round kick
	dc.b	$09,$82,$E9,$63	; foot sweep (back)
	dc.b	$10,$24,$44,$64	; lunge punch
	dc.b	$14,$08,$66,$64	; low kick
	dc.b	$05,$02,$C3,$63	; back kick
	dc.b	$0A,$01,$F8,$63	; front kick
practice_table_end_6361:
	dc.b	$11,$14,$44,$64	; lunge punch  <==== start of sequence #3
	dc.b	0x01,0x63,0x21,0x63,0x41,0x63 ; practice_table_end_6361
table_6367:
	dc.b	0x0b,0x1c,0x3c,0x88,0xac,0xd8,0xad,0xd8 ; table_6367
	dc.b	0x3c,0x88,0xfe,0x0b,0x1d,0xae,0xd8,0xaf ; $636f
	dc.b	0x88,0xb0,0x88,0xb1,0xd8,0xfe,0x0b,0x1e ; $6377
	dc.b	0xb2,0xd8,0xb3,0x88,0xb4,0x88,0xb5,0xd8 ; $637f
	dc.b	0xfe,0x0b,0x1f,0x3c,0x88,0xb6,0xd8,0xb7 ; $6387
	dc.b	0xd8,0x3c,0x88,0xff ; $638f
table_6393:
	dc.b	0x89,0x0a,0x92,0x0a,0x9b,0x0a,0xad,0x0a ; table_6393
	dc.b	0xc8,0x0a,0xa4,0x0a,0xb6,0x0a,0xbf,0x0a ; $639b
	dc.b	0xfe,0xfe,0xc9,0x0c,0xdb,0x0c,0x50,0x0d ; $63a3
	dc.b	0xe0,0x0d,0x55,0x0e,0x24,0x0f,0x99,0x0f ; $63ab
	dc.b	0x17,0x10,0xa7,0x10,0x13,0x11,0x76,0x11 ; $63b3
	dc.b	0xeb,0x11,0xde,0x12,0x53,0x13,0xff,0xff ; $63bb
	dc.b	0x04,0x1d,0x0b,0x0a,0x0c,0x14,0xfe,0x04 ; $63c3
	dc.b	0x1e,0x14,0x12,0x0c,0x14,0xff ; $63cb
; "JUMPING"
table_63D1:
	dc.b	0x03,0x1d,0x13,0x1e,0x16,0x19,0x12,0x17 ; table_63D1
	dc.b	0x10,0xfe,0x03,0x1e,0x0b,0x0a,0x0c,0x14 ; $63d9
	dc.b	0xfe,0x03,0x1f,0x14,0x12,0x0c,0x14,0xff ; $63e1
	dc.b	0x04,0x1d,0x0f,0x18,0x18,0x1d,0xfe,0x04 ; $63e9
	dc.b	0x1e,0x1c,0x20,0x0e,0x0e,0x19,0xff,0x04 ; $63f1
	dc.b	0x1d,0x0f,0x1b,0x18,0x17,0x1d,0xfe,0x04 ; $63f9
	dc.b	0x1e,0x14,0x12,0x0c,0x14,0xff,0x04,0x1d ; $6401
	dc.b	0x0b,0x0a,0x0c,0x14,0xfe,0x04,0x1e,0x1b ; $6409
	dc.b	0x18,0x1e,0x17,0x0d,0xfe,0x04,0x1f,0x14 ; $6411
	dc.b	0x12,0x0c,0x14,0xff,0x03,0x1d,0x13,0x1e ; $6419
	dc.b	0x16,0x19,0x12,0x17,0x10,0xfe,0x03,0x1e ; $6421
	dc.b	0x1c,0x12,0x0d,0x0e,0xfe,0x03,0x1f,0x14 ; $6429
	dc.b	0x12,0x0c,0x14,0xff,0x04,0x1d,0x1b,0x18 ; $6431
	dc.b	0x1e,0x17,0x0d,0xfe,0x04,0x1e,0x14,0x12 ; $6439
	dc.b	0x0c,0x14,0xff ; $6441
; lunge
table_6444:
	dc.b	0x04,0x1d,0x15,0x1e,0x17,0x10,0x0e,0xfe ; table_6444
	dc.b	0x04,0x1e,0x19,0x1e,0x17,0x0c,0x11,0xff ; $644c
	dc.b	0x03,0x1d,0x1b,0x0e,0x1f,0x0e,0x1b,0x1c ; $6454
	dc.b	0x0e,0xfe,0x03,0x1e,0x19,0x1e,0x17,0x0c ; $645c
	dc.b	0x11,0xff,0x04,0x1d,0x15,0x18,0x20,0xfe ; $6464
	dc.b	0x04,0x1e,0x14,0x12,0x0c,0x14,0xff ; $646c
table_6473:
	dc.b	0x03,0x1d,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; table_6473
	dc.b	0x3c,0xfe,0x03,0x1e,0x3c,0x3c,0x3c,0x3c ; $647b
	dc.b	0x3c,0x3c,0x3c,0xfe,0x03,0x1f,0x3c,0x3c ; $6483
	dc.b	0x3c,0x3c,0x3c,0x3c,0x3c,0xff ; $648b

6491: 3A 11 63    ld   a,(background_and_state_bits_C911)
6494: E6 DF       and  $7F
6496: FE 10       cp   $10
6498: DA 3E C4    jp   c,$649E
649B: CD 51 B0    call task_yield_B051
; initialize match timer to 30 seconds (BCD)
649E: 21 90 00    ld   hl,$0030
64A1: DD 21 CD 61 ld   ix,match_timer_C167
64A5: DD 75 00    ld   (ix+$00),l
64A8: DD 74 01    ld   (ix+$01),h
64AB: CD FB C4    call $64FB
64AE: 3E 00       ld   a,$00
64B0: CD 5A B0    call suspend_this_task_B05A
64B3: FE 03       cp   $09
64B5: CA AE C4    jp   z,$64AE
64B8: FE 0A       cp   $0A
64BA: C4 D5 B0    call nz,display_error_text_B075
64BD: 3E 96       ld   a,$3C
64BF: CD 5A B0    call suspend_this_task_B05A
64C2: FE 03       cp   $09
64C4: CA AE C4    jp   z,$64AE
64C7: A7          and  a
64C8: C4 D5 B0    call nz,display_error_text_B075
64CB: 3A CD 61    ld   a,(match_timer_C167)
64CE: D6 01       sub  $01
64D0: 27          daa
64D1: 32 CD 61    ld   (match_timer_C167),a
64D4: 3A C2 61    ld   a,(unknown_C168)
64D7: DE 00       sbc  a,$00
64D9: 27          daa
64DA: 32 C2 61    ld   (unknown_C168),a
64DD: FE 33       cp   $99
64DF: CA E2 C4    jp   z,$64E8
64E2: CD FB C4    call $64FB
64E5: C3 B7 C4    jp   $64BD
64E8: 3E 00       ld   a,$00
64EA: 32 CD 61    ld   (match_timer_C167),a
64ED: 3E 08       ld   a,$02
64EF: 06 02       ld   b,$08
64F1: CD 57 B0    call task_manipulation_B05D
64F4: A7          and  a
64F5: C4 D5 B0    call nz,display_error_text_B075
64F8: CD 51 B0    call task_yield_B051
64FB: 16 32       ld   d,$98
64FD: 21 0F 05    ld   hl,$050F
6500: 22 00 6F    ld   (temp_numeric_buffer_CF00),hl
6503: 3E FF       ld   a,$FF
6505: 32 0C 6F    ld   (unknown_CF06),a
6508: 3A CD 61    ld   a,(match_timer_C167)
650B: 47          ld   b,a
650C: E6 0F       and  $0F
650E: 6F          ld   l,a
650F: 62          ld   h,d
6510: 22 04 6F    ld   (address_of_current_player_move_byte_CF04),hl
6513: 78          ld   a,b
6514: CB 3F       srl  a
6516: CB 3F       srl  a
6518: CB 3F       srl  a
651A: CB 3F       srl  a
651C: E6 0F       and  $0F
651E: 6F          ld   l,a
651F: 22 08 6F    ld   (unknown_CF02),hl
6522: 21 00 6F    ld   hl,temp_numeric_buffer_CF00
6525: CD 96 B0    call display_multicolor_text_B03C
6528: C9          ret

6529: AF          xor  a
652A: CD 5A B0    call suspend_this_task_B05A
652D: F5          push af
652E: 78          ld   a,b
652F: DD 21 F2 6D ld   ix,unknown_C7F8
6533: FD 21 40 61 ld   iy,unknown_C140
6537: FE 08       cp   $02
6539: CA C6 C5    jp   z,$656C
653C: FE 0D       cp   $07
653E: CA C6 C5    jp   z,$656C
6541: FE 1D       cp   $17
6543: CA C6 C5    jp   z,$656C
6546: FD 21 40 68 ld   iy,player_1_struct_C240
654A: FE 03       cp   $09
654C: CA C6 C5    jp   z,$656C
654F: FE 0A       cp   $0A
6551: CA C6 C5    jp   z,$656C
6554: FD 21 C0 68 ld   iy,player_2_struct_C260
6558: FE 0B       cp   $0B
655A: CA E9 C5    jp   z,$65E3
655D: FD 21 20 69 ld   iy,unknown_C380
6561: FE 14       cp   $14
6563: CA 68 C5    jp   z,$65C2
6566: CD 4E B0    call load_struct_C100_from_A_index_B04E
6569: C3 BD C5    jp   $65B7
656C: FD 7E 0A    ld   a,(iy+$0a)
656F: D6 4C       sub  $46
6571: DD 77 09    ld   (ix+$03),a
6574: FD 7E 03    ld   a,(iy+$09)
6577: D6 0D       sub  $07
6579: DD 77 00    ld   (ix+$00),a
657C: 3E 01       ld   a,$01
657E: DD 77 08    ld   (ix+$02),a
6581: FD 21 FB C5 ld   iy,table_65FB
6585: F1          pop  af
6586: A7          and  a
6587: CC 83 C5    call z,$6529
658A: FE 07       cp   $0D
658C: D4 D5 B0    call nc,display_error_text_B075
658F: 4F          ld   c,a
6590: 87          add  a,a
6591: 81          add  a,c
6592: 4F          ld   c,a
6593: 06 00       ld   b,$00
6595: FD 09       add  iy,bc
6597: FD 7E 00    ld   a,(iy+$00)
659A: DD 77 01    ld   (ix+$01),a
659D: FD 7E 01    ld   a,(iy+$01)
65A0: DD B6 08    or   (ix+$02)
65A3: DD 77 08    ld   (ix+$02),a
65A6: 3E 5A       ld   a,$5A
65A8: CD 5A B0    call suspend_this_task_B05A
65AB: A7          and  a
65AC: C2 87 C5    jp   nz,$652D
65AF: 3E 00       ld   a,$00
65B1: 32 F2 6D    ld   (unknown_C7F8),a
65B4: C3 83 C5    jp   $6529
65B7: FD 7E 0A    ld   a,(iy+$0a)
65BA: D6 12       sub  $18
65BC: DD 77 09    ld   (ix+$03),a
65BF: C3 D4 C5    jp   $6574
65C2: FD 7E 0A    ld   a,(iy+$0a)
65C5: D6 09       sub  $03
65C7: DD 77 09    ld   (ix+$03),a
65CA: 3E 0C       ld   a,$06
65CC: FD CB 02 DE bit  7,(iy+$08)
65D0: CA 75 C5    jp   z,$65D5
65D3: 3E E6       ld   a,$EC
65D5: FD 86 03    add  a,(iy+$09)
65D8: DD 77 00    ld   (ix+$00),a
65DB: 3E 08       ld   a,$02
65DD: DD 77 08    ld   (ix+$02),a
65E0: C3 21 C5    jp   $6581
65E3: FD 7E 0A    ld   a,(iy+$0a)
65E6: D6 4C       sub  $46
65E8: DD 77 09    ld   (ix+$03),a
65EB: FD 7E 03    ld   a,(iy+$09)
65EE: D6 0D       sub  $07
65F0: DD 77 00    ld   (ix+$00),a
65F3: 3E 08       ld   a,$02
65F5: DD 77 08    ld   (ix+$02),a
65F8: C3 21 C5    jp   $6581
table_65FB:
	dc.b	0x00,0x00,0x00,0xf1,0x30,0x01,0xf2,0x30 ; table_65FB
	dc.b	0x02,0xf3,0x30,0x03,0xf4,0x30,0x04,0xf5 ; $6603
	dc.b	0x30,0x05,0xf6,0x30,0x06,0xf7,0x30,0x07 ; $660b
	dc.b	0xf8,0x30,0x08,0xf9,0x30,0x09,0xfa,0x30 ; $6613
	dc.b	0x0a,0xe0,0x40,0x0b,0xe1,0x40,0x0c,0x67 ; $661b
	dc.b	0x4d,0x7a,0x67,0xf5,0x69,0x67,0xee,0x69 ; $6623
	dc.b	0x67,0x6b,0x6a,0x9a,0x00,0xc7 ; $662b
6631: 32 EA 61    ld   (unknown_C1EA),a
6634: 3A 09 6D    ld   a,(unknown_C703)
6637: 32 EB 61    ld   (unknown_C1EB),a
663A: 2A 62 60    ld   hl,(unknown_C0C8)
663D: 22 72 60    ld   (unknown_C0D8),hl
6640: 2A 70 60    ld   hl,(unknown_C0D0)
6643: 22 7A 60    ld   (unknown_C0DA),hl
; init player points to both zero
6646: 21 00 00    ld   hl,$0000
6649: 22 1A 63    ld   (player_1_points_C91A),hl
664C: 22 16 63    ld   (player_2_points_C91A),hl
664F: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
6652: E6 09       and  $03
6654: FE 09       cp   $03
6656: C2 5F CC    jp   nz,$665F
6659: CD 6F CB    call $6BCF
665C: CD EE CB    call $6BEE
665F: 3E 90       ld   a,$30
6661: CD 5A B0    call suspend_this_task_B05A
6664: A7          and  a
6665: C4 D5 B0    call nz,display_error_text_B075
6668: 01 09 08    ld   bc,$0203
666B: FD 21 E0 61 ld   iy,unknown_C1E0
666F: FD 7E 0A    ld   a,(iy+$0a)
6672: C6 10       add  a,$10
6674: 57          ld   d,a
6675: FD 7E 0B    ld   a,(iy+$0b)
6678: D6 12       sub  $18
667A: 5F          ld   e,a
667B: 26 0A       ld   h,$0A
667D: CD CA DA    call $7A6A
6680: 01 17 01    ld   bc,$011D
6683: FD 7E 0A    ld   a,(iy+$0a)
6686: C6 10       add  a,$10
6688: 57          ld   d,a
6689: FD 7E 0B    ld   a,(iy+$0b)
668C: D6 02       sub  $08
668E: 5F          ld   e,a
668F: DD 21 B6 6D ld   ix,unknown_C7BC
6693: 26 05       ld   h,$05
6695: CD CE DA    call $7A6E
6698: CD 52 DA    call or_50_to_C7BE_7A58
669B: 3E 85       ld   a,$25
669D: CD D8 B0    call play_sound_B072
66A0: 3E 09       ld   a,$03
66A2: 06 0A       ld   b,$0A
66A4: CD 57 B0    call task_manipulation_B05D
66A7: A7          and  a
66A8: C4 D5 B0    call nz,display_error_text_B075
66AB: 3E 96       ld   a,$3C
66AD: CD 5A B0    call suspend_this_task_B05A
66B0: C5          push bc
66B1: F5          push af
66B2: CD 47 DA    call $7A4D
66B5: F1          pop  af
66B6: C1          pop  bc
66B7: A7          and  a
66B8: C2 00 CD    jp   nz,$6700
66BB: 3E 0A       ld   a,$0A
66BD: 06 0A       ld   b,$0A
66BF: CD 57 B0    call task_manipulation_B05D
66C2: A7          and  a
66C3: C4 D5 B0    call nz,display_error_text_B075
66C6: 3E 0B       ld   a,$0B
66C8: 06 0A       ld   b,$0A
66CA: CD 57 B0    call task_manipulation_B05D
66CD: A7          and  a
66CE: C4 D5 B0    call nz,display_error_text_B075
66D1: 3A 00 6D    ld   a,(referee_x_pos_C700)
66D4: D6 10       sub  $10
66D6: 32 E6 61    ld   (unknown_C1EC),a
66D9: C6 80       add  a,$20
66DB: 32 E7 61    ld   (unknown_C1ED),a
66DE: 3E EA       ld   a,$EA
66E0: 32 03 6D    ld   (unknown_C709),a
66E3: 3E 14       ld   a,$14
66E5: CD 5A B0    call suspend_this_task_B05A
66E8: A7          and  a
66E9: C2 00 CD    jp   nz,$6700
66EC: 3A E3 61    ld   a,(referee_walk_direction_C1E9)
66EF: 0E F6       ld   c,$FC
66F1: A7          and  a
66F2: CA FD CC    jp   z,$66F7
66F5: 0E 04       ld   c,$04
66F7: CD 09 CB    call $6B03
66FA: CD 80 CB    call $6B20
66FD: C3 E9 CC    jp   $66E3
6700: F5          push af
6701: C5          push bc
6702: CD CB CA    call $6A6B
6705: C1          pop  bc
6706: F1          pop  af
6707: FE 02       cp   $08
6709: C2 17 C2    jp   nz,$681D
670C: 3E 01       ld   a,$01
670E: CD 85 CA    call $6A25
6711: 01 05 08    ld   bc,$0205
6714: FD 21 E0 61 ld   iy,unknown_C1E0
6718: FD 7E 0A    ld   a,(iy+$0a)
671B: C6 10       add  a,$10
671D: 57          ld   d,a
671E: FD 7E 0B    ld   a,(iy+$0b)
6721: D6 12       sub  $18
6723: 5F          ld   e,a
6724: 26 05       ld   h,$05
6726: CD CA DA    call $7A6A
6729: 01 17 01    ld   bc,$011D
672C: FD 7E 0A    ld   a,(iy+$0a)
672F: C6 10       add  a,$10
6731: 57          ld   d,a
6732: FD 7E 0B    ld   a,(iy+$0b)
6735: D6 02       sub  $08
6737: 5F          ld   e,a
6738: DD 21 B6 6D ld   ix,unknown_C7BC
673C: 26 05       ld   h,$05
673E: CD CE DA    call $7A6E
6741: CD 52 DA    call or_50_to_C7BE_7A58
6744: 3E 84       ld   a,$24
6746: CD D8 B0    call play_sound_B072
6749: 3E D0       ld   a,$70
674B: CD 5A B0    call suspend_this_task_B05A
674E: A7          and  a
674F: C4 D5 B0    call nz,display_error_text_B075
6752: CD 47 DA    call $7A4D
6755: CD CB CA    call $6A6B
6758: 3E 96       ld   a,$3C
675A: CD 5A B0    call suspend_this_task_B05A
675D: 01 0D 08    ld   bc,$0207
6760: FD 21 E0 61 ld   iy,unknown_C1E0
6764: FD 7E 0A    ld   a,(iy+$0a)
6767: C6 10       add  a,$10
6769: 57          ld   d,a
676A: FD 7E 0B    ld   a,(iy+$0b)
676D: D6 12       sub  $18
676F: 5F          ld   e,a
6770: 26 01       ld   h,$01
6772: CD CA DA    call $7A6A
6775: 01 17 01    ld   bc,$011D
6778: FD 7E 0A    ld   a,(iy+$0a)
677B: C6 10       add  a,$10
677D: 57          ld   d,a
677E: FD 7E 0B    ld   a,(iy+$0b)
6781: D6 02       sub  $08
6783: 5F          ld   e,a
6784: DD 21 B6 6D ld   ix,unknown_C7BC
6788: 26 05       ld   h,$05
678A: CD CE DA    call $7A6E
678D: CD 52 DA    call or_50_to_C7BE_7A58
6790: 3E 82       ld   a,$28
6792: CD D8 B0    call play_sound_B072
6795: 3E 96       ld   a,$3C
6797: CD 5A B0    call suspend_this_task_B05A
679A: CD 47 DA    call $7A4D
679D: 21 16 63    ld   hl,player_2_points_C91A
67A0: 3A 1A 63    ld   a,(player_1_points_C91A)
67A3: BE          cp   (hl)
67A4: CA A7 CD    jp   z,$67AD
67A7: D2 EA CD    jp   nc,$67EA
67AA: C3 B2 CD    jp   $67B8
67AD: 23          inc  hl
67AE: 3A 1B 63    ld   a,(unknown_C91B)
67B1: BE          cp   (hl)
67B2: CA A2 C3    jp   z,$69A8
67B5: D2 EA CD    jp   nc,$67EA
67B8: 3E 09       ld   a,$03
67BA: CD 85 CA    call $6A25
67BD: CD D3 C6    call $6C79
67C0: 3E 83       ld   a,$29
67C2: CD D8 B0    call play_sound_B072
67C5: 3E 90       ld   a,$30
67C7: CD 5A B0    call suspend_this_task_B05A
67CA: 3E 0B       ld   a,$0B
67CC: 06 18       ld   b,$12
67CE: CD 57 B0    call task_manipulation_B05D
67D1: 3E 0A       ld   a,$0A
67D3: 06 19       ld   b,$13
67D5: CD 57 B0    call task_manipulation_B05D
67D8: 3E 62       ld   a,$C8
67DA: CD 5A B0    call suspend_this_task_B05A
67DD: 3E 08       ld   a,$02
67DF: 47          ld   b,a
67E0: CD 57 B0    call task_manipulation_B05D
67E3: A7          and  a
67E4: C4 D5 B0    call nz,display_error_text_B075
67E7: CD 51 B0    call task_yield_B051
67EA: 3E 08       ld   a,$02
67EC: CD 85 CA    call $6A25
67EF: CD B8 C6    call $6CB2
67F2: 3E 8A       ld   a,$2A
67F4: CD D8 B0    call play_sound_B072
67F7: 3E 90       ld   a,$30
67F9: CD 5A B0    call suspend_this_task_B05A
67FC: 3E 0A       ld   a,$0A
67FE: 06 18       ld   b,$12
6800: CD 57 B0    call task_manipulation_B05D
6803: 3E 0B       ld   a,$0B
6805: 06 19       ld   b,$13
6807: CD 57 B0    call task_manipulation_B05D
680A: 3E 62       ld   a,$C8
680C: CD 5A B0    call suspend_this_task_B05A
680F: 3E 08       ld   a,$02
6811: 06 01       ld   b,$01
6813: CD 57 B0    call task_manipulation_B05D
6816: A7          and  a
6817: C4 D5 B0    call nz,display_error_text_B075
681A: CD 51 B0    call task_yield_B051
681D: F5          push af
681E: C5          push bc
681F: 3E 82       ld   a,$28
6821: CD 5A B0    call suspend_this_task_B05A
6824: A7          and  a
6825: C4 D5 B0    call nz,display_error_text_B075
6828: 3E 0F       ld   a,$0F
682A: 06 03       ld   b,$09
682C: CD 57 B0    call task_manipulation_B05D
682F: C1          pop  bc
6830: F1          pop  af
6831: C5          push bc
6832: FE 04       cp   $04
6834: CA 9F C2    jp   z,$683F
6837: FE 05       cp   $05
6839: CA EA C2    jp   z,$68EA
683C: CD D5 B0    call display_error_text_B075
683F: 3E 8D       ld   a,$27
6841: CD D8 B0    call play_sound_B072
6844: 3E 09       ld   a,$03
6846: 06 03       ld   b,$09
6848: CD 57 B0    call task_manipulation_B05D
684B: A7          and  a
684C: C4 D5 B0    call nz,display_error_text_B075
684F: CD 86 C6    call clear_text_6C2C
6852: C1          pop  bc
6853: 78          ld   a,b
6854: FE 0A       cp   $0A
6856: C2 A8 C2    jp   nz,$68A2
6859: FD 21 E0 61 ld   iy,unknown_C1E0
685D: FD 6E 0D    ld   l,(iy+$07)
6860: FD 66 02    ld   h,(iy+$08)
6863: CD EC C6    call display_scoring_technique_6CE6
6866: 3E 08       ld   a,$02
6868: CD 85 CA    call $6A25
686B: CD B8 C6    call $6CB2
686E: 3A 1A 63    ld   a,(player_1_points_C91A)
6871: 3C          inc  a
6872: FE 08       cp   $02
6874: C2 36 C2    jp   nz,$689C
6877: 32 1A 63    ld   (player_1_points_C91A),a
687A: CD 97 CB    call $6B3D
687D: 3E 0A       ld   a,$0A
687F: 06 18       ld   b,$12
6881: CD 57 B0    call task_manipulation_B05D
6884: 3E C4       ld   a,$64
6886: CD 5A B0    call suspend_this_task_B05A
6889: 3E 08       ld   a,$02
688B: 06 01       ld   b,$01
688D: CD 57 B0    call task_manipulation_B05D
6890: A7          and  a
6891: C4 D5 B0    call nz,display_error_text_B075
6894: 3E 09       ld   a,$03
6896: CD 54 B0    call resume_task_B054
6899: CD 51 B0    call task_yield_B051
689C: 32 1A 63    ld   (player_1_points_C91A),a
689F: C3 53 C3    jp   $6959
68A2: FD 21 E0 61 ld   iy,unknown_C1E0
68A6: FD 6E 0D    ld   l,(iy+$07)
68A9: FD 66 02    ld   h,(iy+$08)
68AC: CD EC C6    call display_scoring_technique_6CE6
68AF: 3E 09       ld   a,$03
68B1: CD 85 CA    call $6A25
68B4: CD D3 C6    call $6C79
68B7: 3A 16 63    ld   a,(player_2_points_C91A)
68BA: 3C          inc  a
68BB: FE 08       cp   $02
68BD: C2 E4 C2    jp   nz,$68E4
68C0: 32 16 63    ld   (player_2_points_C91A),a
68C3: CD DD CB    call $6B77
68C6: 3E 0B       ld   a,$0B
68C8: 06 18       ld   b,$12
68CA: CD 57 B0    call task_manipulation_B05D
68CD: 3E 62       ld   a,$C8
68CF: CD 5A B0    call suspend_this_task_B05A
68D2: 3E 08       ld   a,$02
68D4: 47          ld   b,a
68D5: CD 57 B0    call task_manipulation_B05D
68D8: A7          and  a
68D9: C4 D5 B0    call nz,display_error_text_B075
68DC: 3E 09       ld   a,$03
68DE: CD 54 B0    call resume_task_B054
68E1: CD 51 B0    call task_yield_B051
68E4: 32 16 63    ld   (player_2_points_C91A),a
68E7: C3 53 C3    jp   $6959
68EA: 3E 8C       ld   a,$26
68EC: CD D8 B0    call play_sound_B072
68EF: 3E 09       ld   a,$03
68F1: 06 03       ld   b,$09
68F3: CD 57 B0    call task_manipulation_B05D
68F6: A7          and  a
68F7: C4 D5 B0    call nz,display_error_text_B075
68FA: CD 86 C6    call clear_text_6C2C
68FD: C1          pop  bc
68FE: 78          ld   a,b
68FF: FE 0A       cp   $0A
6901: C2 90 C3    jp   nz,$6930
6904: FD 21 E0 61 ld   iy,unknown_C1E0
6908: FD 6E 0D    ld   l,(iy+$07)
690B: FD 66 02    ld   h,(iy+$08)
690E: CD EC C6    call display_scoring_technique_6CE6
6911: 3E 08       ld   a,$02
6913: CD 85 CA    call $6A25
6916: CD B8 C6    call $6CB2
6919: 3A 1B 63    ld   a,(unknown_C91B)
691C: 3C          inc  a
691D: FE 08       cp   $02
691F: C2 8A C3    jp   nz,$692A
6922: 3E 00       ld   a,$00
6924: 32 1B 63    ld   (unknown_C91B),a
6927: C3 CE C2    jp   $686E
692A: 32 1B 63    ld   (unknown_C91B),a
692D: C3 53 C3    jp   $6959
6930: FD 21 E0 61 ld   iy,unknown_C1E0
6934: FD 6E 0D    ld   l,(iy+$07)
6937: FD 66 02    ld   h,(iy+$08)
693A: CD EC C6    call display_scoring_technique_6CE6
693D: 3E 09       ld   a,$03
693F: CD 85 CA    call $6A25
6942: CD D3 C6    call $6C79
6945: 3A 17 63    ld   a,(unknown_C91D)
6948: 3C          inc  a
6949: FE 08       cp   $02
694B: C2 5C C3    jp   nz,$6956
694E: 3E 00       ld   a,$00
6950: 32 17 63    ld   (unknown_C91D),a
6953: C3 BD C2    jp   $68B7
6956: 32 17 63    ld   (unknown_C91D),a
6959: 3E B0       ld   a,$B0
695B: CD 5A B0    call suspend_this_task_B05A
695E: CD 47 DA    call $7A4D
6961: CD 97 CB    call $6B3D
6964: CD DD CB    call $6B77
6967: 3E 96       ld   a,$3C
6969: CD 5A B0    call suspend_this_task_B05A
696C: A7          and  a
696D: C4 D5 B0    call nz,display_error_text_B075
6970: 3E 0A       ld   a,$0A
6972: 06 00       ld   b,$00
6974: CD 57 B0    call task_manipulation_B05D
6977: A7          and  a
6978: C4 D5 B0    call nz,display_error_text_B075
697B: 3E 0B       ld   a,$0B
697D: 06 00       ld   b,$00
697F: CD 57 B0    call task_manipulation_B05D
6982: A7          and  a
6983: C4 D5 B0    call nz,display_error_text_B075
6986: CD CB CA    call $6A6B
6989: 21 5C CF    ld   hl,table_6f56
698C: CD 96 B0    call display_multicolor_text_B03C
698F: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
6992: E6 09       and  $03
6994: FE 09       cp   $03
6996: C2 36 C3    jp   nz,$699C
6999: CD EE CB    call $6BEE
699C: 3E 1E       ld   a,$1E
699E: CD 5A B0    call suspend_this_task_B05A
69A1: A7          and  a
69A2: C4 D5 B0    call nz,display_error_text_B075
69A5: C3 C2 CC    jp   $6668
69A8: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
69AB: FE 05       cp   $05
69AD: CA B2 CD    jp   z,$67B8
69B0: FE 0A       cp   $0A
69B2: CA EA CD    jp   z,$67EA
69B5: 2A 62 60    ld   hl,(unknown_C0C8)
69B8: 7D          ld   a,l
69B9: 6C          ld   l,h
69BA: 67          ld   h,a
69BB: ED 5B 72 60 ld   de,(unknown_C0D8)
69BF: 7B          ld   a,e
69C0: 5A          ld   e,d
69C1: 57          ld   d,a
69C2: A7          and  a
69C3: ED 52       sbc  hl,de
69C5: E5          push hl
69C6: 2A 70 60    ld   hl,(unknown_C0D0)
69C9: 7D          ld   a,l
69CA: 6C          ld   l,h
69CB: 67          ld   h,a
69CC: ED 5B 7A 60 ld   de,(unknown_C0DA)
69D0: 7B          ld   a,e
69D1: 5A          ld   e,d
69D2: 57          ld   d,a
69D3: A7          and  a
69D4: ED 52       sbc  hl,de
69D6: D1          pop  de
69D7: A7          and  a
69D8: ED 52       sbc  hl,de
69DA: CA E9 C3    jp   z,$69E3
69DD: DA EA CD    jp   c,$67EA
69E0: D2 B2 CD    jp   nc,$67B8
69E3: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
69E6: CB 5F       bit  3,a
69E8: C2 EA CD    jp   nz,$67EA
69EB: C3 B2 CD    jp   $67B8
69EE: 21 5C CF    ld   hl,table_6f56
69F1: CD 96 B0    call display_multicolor_text_B03C
69F4: C9          ret
69F5: 21 0D CA    ld   hl,table_6A07
69F8: 11 00 6F    ld   de,temp_numeric_buffer_CF00
69FB: 01 88 00    ld   bc,$0022
69FE: ED B0       ldir
6A00: 21 00 6F    ld   hl,temp_numeric_buffer_CF00
6A03: CD 96 B0    call display_multicolor_text_B03C
6A06: C9          ret
table_6A07:
	dc.b	0x06,0x02,0xd3,0x10,0xd3,0x10,0xd4,0x98 ; table_6A07
	dc.b	0xd5,0x98,0xb3,0x9a,0xd3,0x10,0xd3,0x10 ; $6a0f
	dc.b	0xfe,0x07,0x03,0xd3,0x10,0xd8,0x98,0xd9 ; $6a17
	dc.b	0x98,0xda,0x98,0xd3,0x10,0xff ; $6a1f
6A25: FD 21 00 6D ld   iy,referee_x_pos_C700
6A29: 3D          dec  a
6A2A: 87          add  a,a
6A2B: 4F          ld   c,a
6A2C: 06 00       ld   b,$00
6A2E: DD 21 53 CA ld   ix,table_6A59
6A32: DD 09       add  ix,bc
6A34: DD 6E 00    ld   l,(ix+$00)
6A37: DD 66 01    ld   h,(ix+$01)
6A3A: E5          push hl
6A3B: DD E1       pop  ix
6A3D: DD 7E 00    ld   a,(ix+$00)
6A40: FD 77 05    ld   (iy+$05),a
6A43: DD 7E 01    ld   a,(ix+$01)
6A46: FD B6 0C    or   (iy+$06)
6A49: FD 77 0C    ld   (iy+$06),a
6A4C: DD 7E 08    ld   a,(ix+$02)
6A4F: FD 77 07    ld   (iy+$0d),a
6A52: DD 7E 09    ld   a,(ix+$03)
6A55: FD 77 11    ld   (iy+$11),a
6A58: C9          ret
table_6A59:
	dc.b	0x5f,0x6a,0x67,0x6a,0x63,0x6a,0xef,0x00 ; table_6A59
	dc.b	0xee,0xed,0xeb,0x00,0x00,0xed,0xeb,0x80 ; $6a61
	dc.b	0xee,0x00 ; $6a69
6A6B: DD 21 E1 CA ld   ix,referee_start_position_table_6AE1
; start position for referee
6A6F: 3A 11 63    ld   a,(background_and_state_bits_C911)
6A72: CB BF       res  7,a
6A74: 87          add  a,a
6A75: 4F          ld   c,a
6A76: 06 00       ld   b,$00
6A78: DD 09       add  ix,bc
6A7A: DD 66 00    ld   h,(ix+$00)
6A7D: DD 6E 01    ld   l,(ix+$01)
6A80: DD 21 75 CA ld   ix,table_6AD5
6A84: FD 21 00 6D ld   iy,referee_x_pos_C700
6A88: FD 74 00    ld   (iy+$00),h
6A8B: FD 74 04    ld   (iy+$04),h
6A8E: FD 74 02    ld   (iy+$08),h
6A91: 7C          ld   a,h
6A92: D6 10       sub  $10
6A94: FD 77 06    ld   (iy+$0c),a
6A97: C6 80       add  a,$20
6A99: FD 77 10    ld   (iy+$10),a
6A9C: FD 75 09    ld   (iy+$03),l
6A9F: 7D          ld   a,l
6AA0: C6 10       add  a,$10
6AA2: FD 77 0D    ld   (iy+$07),a
6AA5: C6 10       add  a,$10
6AA7: FD 77 0B    ld   (iy+$0b),a
6AAA: 7D          ld   a,l
6AAB: C6 04       add  a,$04
6AAD: FD 77 0F    ld   (iy+$0f),a
6AB0: FD 77 19    ld   (iy+$13),a
6AB3: FD 21 01 6D ld   iy,unknown_C701
6AB7: DD 7E 00    ld   a,(ix+$00)
6ABA: FE FF       cp   $FF
6ABC: C8          ret  z
6ABD: FD 77 00    ld   (iy+$00),a
6AC0: DD 7E 01    ld   a,(ix+$01)
6AC3: FD 77 01    ld   (iy+$01),a
6AC6: DD 23       inc  ix
6AC8: DD 23       inc  ix
6ACA: FD 23       inc  iy
6ACC: FD 23       inc  iy
6ACE: FD 23       inc  iy
6AD0: FD 23       inc  iy
6AD2: C3 BD CA    jp   $6AB7
table_6AD5:
	dc.b	0xe7,0x44,0xe8,0x44,0xe9,0x44,0x00,0x45 ; table_6AD5
	dc.b	0x00,0x45,0xff,0xff ; $6add
referee_start_position_table_6AE1:
	dc.b	0xc0,0x48,0x78,0x70,0x78,0x58,0x78,0x70 ; referee_start_position_table_6AE1
	dc.b	0x78,0x70,0x78,0x70,0x78,0x70,0x78,0x70 ; $6ae9
	dc.b	0x78,0x70,0x91,0x70,0x78,0x70,0x88,0x58 ; $6af1
	dc.b	0x78,0x70,0x78,0x70,0x78,0x70,0x78,0x70 ; $6af9
	dc.b	0x78,0x58 ; $6b01
6B03: DD 21 00 6D ld   ix,referee_x_pos_C700
6B07: 11 04 00    ld   de,$0004
6B0A: 06 05       ld   b,$05
6B0C: DD 7E 00    ld   a,(ix+$00)
6B0F: 81          add  a,c
6B10: DD 77 00    ld   (ix+$00),a
6B13: DD 19       add  ix,de
6B15: 10 F5       djnz $6B0C
6B17: 3A 0A 6D    ld   a,(unknown_C70A)
6B1A: EE 20       xor  $80
6B1C: 32 0A 6D    ld   (unknown_C70A),a
6B1F: C9          ret
6B20: FD 21 E0 61 ld   iy,unknown_C1E0
6B24: 3A 00 6D    ld   a,(referee_x_pos_C700)
6B27: FD BE 06    cp   (iy+$0c)		; min referee x
6B2A: D2 99 CB    jp   nc,$6B33
6B2D: 3E FF       ld   a,$FF
6B2F: 32 E3 61    ld   (referee_walk_direction_C1E9),a
6B32: C9          ret
6B33: FD BE 07    cp   (iy+$0d)		; max referee x for this stage
6B36: D8          ret  c
6B37: 3E 00       ld   a,$00
6B39: 32 E3 61    ld   (referee_walk_direction_C1E9),a
6B3C: C9          ret

6B3D: 21 0C 08    ld   hl,$0206		; immediate
6B40: 11 64 CB    ld   de,table_6BC4
6B43: 3A 1A 63    ld   a,(player_1_points_C91A)
6B46: FE 00       cp   $00
6B48: CA 56 CB    jp   z,$6B5C
6B4B: 21 0D 08    ld   hl,$0207		; immediate
6B4E: 11 6D CB    ld   de,table_6BC7
6B51: FE 01       cp   $01
6B53: CA 56 CB    jp   z,$6B5C
6B56: 21 0C 08    ld   hl,$0206		; immediate
6B59: 11 6A CB    ld   de,table_6BCA
6B5C: CD B1 CB    call $6BB1
6B5F: 21 0D 09    ld   hl,$0307		; immediate
6B62: 11 64 CB    ld   de,table_6BC4
6B65: 3A 1B 63    ld   a,(unknown_C91B)
6B68: FE 00       cp   $00
6B6A: CA D9 CB    jp   z,$6B73
6B6D: 21 0D 09    ld   hl,$0307		; immediate
6B70: 11 6D CB    ld   de,table_6BC7
6B73: CD B1 CB    call $6BB1
6B76: C9          ret
6B77: 21 0B 08    ld   hl,$020B		; immediate
6B7A: 11 64 CB    ld   de,table_6BC4
6B7D: 3A 16 63    ld   a,(player_2_points_C91A)
6B80: FE 00       cp   $00
6B82: CA 3C CB    jp   z,$6B96
6B85: 21 0B 08    ld   hl,$020B		; immediate
6B88: 11 6D CB    ld   de,table_6BC7
6B8B: FE 01       cp   $01
6B8D: CA 3C CB    jp   z,$6B96
6B90: 21 0B 08    ld   hl,$020B		; immediate
6B93: 11 6A CB    ld   de,table_6BCA
6B96: CD B1 CB    call $6BB1
6B99: 21 0B 09    ld   hl,$030B		; immediate
6B9C: 11 64 CB    ld   de,table_6BC4
6B9F: 3A 17 63    ld   a,(unknown_C91D)
6BA2: FE 00       cp   $00
6BA4: CA A7 CB    jp   z,$6BAD
6BA7: 21 0B 09    ld   hl,$030B		; immediate
6BAA: 11 6D CB    ld   de,table_6BC7
6BAD: CD B1 CB    call $6BB1
6BB0: C9          ret
6BB1: 22 00 6F    ld   (temp_numeric_buffer_CF00),hl
6BB4: EB          ex   de,hl
6BB5: 11 08 6F    ld   de,unknown_CF02
6BB8: 01 0C 00    ld   bc,$0006
6BBB: ED B0       ldir
6BBD: 21 00 6F    ld   hl,temp_numeric_buffer_CF00
6BC0: CD 96 B0    call display_multicolor_text_B03C
6BC3: C9          ret
table_6BC4:
	dc.b	0xd3,0x10,0xff ; table_6BC4
table_6BC7:
	dc.b	0xd3,0x58,0xff ; table_6BC7
table_6BCA:
	dc.b	0xd3,0x58,0xd3,0x58,0xff ; table_6BCA
6BCF: 06 09       ld   b,$03
6BD1: C5          push bc
6BD2: CD EE CB    call $6BEE
6BD5: 3E 0F       ld   a,$0F
6BD7: CD 5A B0    call suspend_this_task_B05A
6BDA: A7          and  a
6BDB: C4 D5 B0    call nz,display_error_text_B075
6BDE: CD 86 C6    call clear_text_6C2C
6BE1: 3E 0F       ld   a,$0F
6BE3: CD 5A B0    call suspend_this_task_B05A
6BE6: A7          and  a
6BE7: C4 D5 B0    call nz,display_error_text_B075
6BEA: C1          pop  bc
6BEB: 10 E4       djnz $6BD1
6BED: C9          ret
6BEE: 21 53 C6    ld   hl,table_6C59
6BF1: 16 30       ld   d,$90
6BF3: CD 93 B0    call display_text_B039
6BF6: 21 0D 0C    ld   hl,$0607
6BF9: 22 00 6F    ld   (temp_numeric_buffer_CF00),hl
6BFC: 3A 42 61    ld   a,(unknown_C148)
6BFF: 6F          ld   l,a
6C00: 26 32       ld   h,$98
6C02: 22 08 6F    ld   (unknown_CF02),hl
6C05: 21 96 32    ld   hl,table_983c
6C08: 22 04 6F    ld   (address_of_current_player_move_byte_CF04),hl
6C0B: 21 8C 32    ld   hl,table_9826
6C0E: 22 0C 6F    ld   (unknown_CF06),hl
6C11: 21 96 32    ld   hl,table_983c
6C14: 22 02 6F    ld   (unknown_CF08),hl
6C17: 3A 4D 61    ld   a,(unknown_C147)
6C1A: 6F          ld   l,a
6C1B: 26 30       ld   h,$90
6C1D: 22 0A 6F    ld   (unknown_CF0A),hl
6C20: 3E FF       ld   a,$FF
6C22: 32 06 6F    ld   (unknown_CF0C),a
6C25: 21 00 6F    ld   hl,temp_numeric_buffer_CF00
6C28: CD 96 B0    call display_multicolor_text_B03C
6C2B: C9          ret
; empty text to erase previous values
clear_text_6C2C:
6C2C: 21 95 C6    ld   hl,table_6C35
6C2F: 16 30       ld   d,$90
6C31: CD 93 B0    call display_text_B039
6C34: C9          ret

table_6C35:
	dc.b	0x05,0x05,0x38,0x3c,0x3c,0x3c,0x3c,0x3c ; table_6C35
	dc.b	0x3c,0x3c,0x3c,0xfe,0x05,0x06,0x38,0x3c ; $6c3d
	dc.b	0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0xfe ; $6c45
	dc.b	0x05,0x07,0x39,0x3a,0x3a,0x3a,0x3a,0x3a ; $6c4d
	dc.b	0x3a,0x3a,0x3a,0xff ; $6c55
table_6C59:
	dc.b	0x05,0x05,0xe0,0xe1,0xdd,0xdd,0xdd,0xdd ; table_6C59
	dc.b	0xdd,0xe2,0xe3,0xfe,0x05,0x06,0xcd,0xfe ; $6c61
	dc.b	0x0d,0x06,0xd0,0xfe,0x05,0x07,0xe6,0xe7 ; $6c69
	dc.b	0xe8,0xe8,0xe8,0xe8,0xe8,0xe9,0xea,0xff ; $6c71
6C79: 01 0B 08    ld   bc,$020B
6C7C: FD 21 E0 61 ld   iy,unknown_C1E0
6C80: FD 7E 0A    ld   a,(iy+$0a)
6C83: C6 10       add  a,$10
6C85: 57          ld   d,a
6C86: FD 7E 0B    ld   a,(iy+$0b)
6C89: D6 12       sub  $18
6C8B: 5F          ld   e,a
6C8C: 26 05       ld   h,$05
6C8E: CD CA DA    call $7A6A
6C91: 01 65 01    ld   bc,$01C5
6C94: FD 7E 0A    ld   a,(iy+$0a)
6C97: C6 10       add  a,$10
6C99: 57          ld   d,a
6C9A: FD 7E 0B    ld   a,(iy+$0b)
6C9D: D6 02       sub  $08
6C9F: 5F          ld   e,a
6CA0: DD 21 B6 6D ld   ix,unknown_C7BC
6CA4: 26 05       ld   h,$05
6CA6: CD CE DA    call $7A6E
6CA9: CD 52 DA    call or_50_to_C7BE_7A58
6CAC: 3E 45       ld   a,$45
6CAE: 32 BE 6D    ld   (unknown_C7BE),a
6CB1: C9          ret
6CB2: 01 07 08    ld   bc,$020D
6CB5: FD 21 E0 61 ld   iy,unknown_C1E0
6CB9: FD 7E 0A    ld   a,(iy+$0a)
6CBC: D6 80       sub  $20
6CBE: 57          ld   d,a
6CBF: FD 7E 0B    ld   a,(iy+$0b)
6CC2: D6 12       sub  $18
6CC4: 5F          ld   e,a
6CC5: 26 05       ld   h,$05
6CC7: CD CA DA    call $7A6A
6CCA: 01 16 01    ld   bc,$011C
6CCD: FD 7E 0A    ld   a,(iy+$0a)
6CD0: D6 10       sub  $10
6CD2: 57          ld   d,a
6CD3: FD 7E 0B    ld   a,(iy+$0b)
6CD6: D6 02       sub  $08
6CD8: 5F          ld   e,a
6CD9: DD 21 B6 6D ld   ix,unknown_C7BC
6CDD: 26 05       ld   h,$05
6CDF: CD CE DA    call $7A6E
6CE2: CD 52 DA    call or_50_to_C7BE_7A58
6CE5: C9          ret

display_scoring_technique_6CE6:
6CE6: CB BC       res  7,h
6CE8: DD 21 1E C7 ld   ix,table_6D1E
6CEC: FD 21 9E C7 ld   iy,table_6D3E
6CF0: DD 5E 00    ld   e,(ix+$00)
6CF3: DD 56 01    ld   d,(ix+$01)
6CF6: EB          ex   de,hl
6CF7: A7          and  a
6CF8: ED 52       sbc  hl,de
6CFA: CA 14 C7    jp   z,$6D14
6CFD: EB          ex   de,hl
6CFE: DD 23       inc  ix
6D00: DD 23       inc  ix
6D02: FD 23       inc  iy
6D04: FD 23       inc  iy
6D06: DD 7E 00    ld   a,(ix+$00)
6D09: DD A6 01    and  (ix+$01)
6D0C: FE FF       cp   $FF
6D0E: C2 F0 C6    jp   nz,$6CF0
6D11: CD D5 B0    call display_error_text_B075
6D14: FD 6E 00    ld   l,(iy+$00)
6D17: FD 66 01    ld   h,(iy+$01)
6D1A: CD 96 B0    call display_multicolor_text_B03C
6D1D: C9          ret
table_6D1E:
	dc.b	0xc0,0x0c,0xd2,0x0c,0x47,0x0d,0xd7,0x0d ; table_6D1E
	dc.b	0x4c,0x0e,0xaf,0x0e,0x1b,0x0f,0x90,0x0f ; $6d26
	dc.b	0x0e,0x10,0x9e,0x10,0x0a,0x11,0x6d,0x11 ; $6d2e
	dc.b	0xe2,0x11,0xd5,0x12,0x4a,0x13,0xff,0xff ; $6d36
table_6D3E:
	dc.b	0x3b,0x6e,0x3b,0x6e,0x51,0x6e,0x78,0x6e ; table_6D3E
	dc.b	0x90,0x6e,0x24,0x6f,0xa8,0x6e,0x0a,0x6f ; $6d46
	dc.b	0xcb,0x6e,0x78,0x6e,0xf2,0x6e,0x0a,0x6f ; $6d4e
	dc.b	0x0a,0x6f,0x24,0x6f,0x42,0x6f,0xff,0xff ; $6d56
6D5E: 3A 11 63    ld   a,(background_and_state_bits_C911)
6D61: CB BF       res  7,a
6D63: FE 59       cp   $53
6D65: C2 CF C7    jp   nz,$6D6F
6D68: 26 D2       ld   h,$78
6D6A: 2E 42       ld   l,$48
6D6C: C3 2B C7    jp   $6D8B
6D6F: FE 10       cp   $10
6D71: DC 51 B0    call c,task_yield_B051
6D74: FE 80       cp   $20
6D76: D4 51 B0    call nc,task_yield_B051
6D79: E6 0F       and  $0F
6D7B: 87          add  a,a
6D7C: 4F          ld   c,a
6D7D: 06 00       ld   b,$00
6D7F: DD 21 E1 CA ld   ix,referee_start_position_table_6AE1
6D83: DD 09       add  ix,bc
6D85: DD 66 00    ld   h,(ix+$00)
6D88: DD 6E 01    ld   l,(ix+$01)
6D8B: FD 21 00 6D ld   iy,referee_x_pos_C700
6D8F: FD 74 00    ld   (iy+$00),h
6D92: FD 74 04    ld   (iy+$04),h
6D95: FD 74 02    ld   (iy+$08),h
6D98: 7C          ld   a,h
6D99: C6 10       add  a,$10
6D9B: FD 77 06    ld   (iy+$0c),a
6D9E: FD 75 09    ld   (iy+$03),l
6DA1: 7D          ld   a,l
6DA2: C6 10       add  a,$10
6DA4: FD 77 0D    ld   (iy+$07),a
6DA7: C6 10       add  a,$10
6DA9: FD 77 0B    ld   (iy+$0b),a
6DAC: 7D          ld   a,l
6DAD: C6 04       add  a,$04
6DAF: FD 77 0F    ld   (iy+$0f),a
6DB2: 3E 44       ld   a,$44
6DB4: FD 36 01 ED ld   (iy+$01),$E7
6DB8: FD 36 05 E2 ld   (iy+$05),$E8
6DBC: FD 36 03 E3 ld   (iy+$09),$E9
6DC0: FD 77 08    ld   (iy+$02),a
6DC3: FD 77 0C    ld   (iy+$06),a
6DC6: FD 77 0A    ld   (iy+$0a),a
6DC9: FD 36 0E 45 ld   (iy+$0e),$45
6DCD: 3E 00       ld   a,$00
6DCF: CD 5A B0    call suspend_this_task_B05A
6DD2: FE 80       cp   $20
6DD4: C4 D5 B0    call nz,display_error_text_B075
6DD7: FD 21 00 6D ld   iy,referee_x_pos_C700
6DDB: FD 36 07 E6 ld   (iy+$0d),$EC
6DDF: FD 36 05 EB ld   (iy+$05),$EB
6DE3: 01 01 08    ld   bc,$0201
6DE6: FD 7E 00    ld   a,(iy+$00)
6DE9: C6 10       add  a,$10
6DEB: 57          ld   d,a
6DEC: FD 7E 09    ld   a,(iy+$03)
6DEF: D6 12       sub  $18
6DF1: 5F          ld   e,a
6DF2: 26 01       ld   h,$01
6DF4: CD CA DA    call $7A6A
6DF7: 01 1A 01    ld   bc,$011A
6DFA: FD 7E 00    ld   a,(iy+$00)
6DFD: C6 90       add  a,$30
6DFF: 57          ld   d,a
6E00: FD 7E 09    ld   a,(iy+$03)
6E03: D6 12       sub  $18
6E05: 5F          ld   e,a
6E06: 26 01       ld   h,$01
6E08: DD 21 62 6D ld   ix,unknown_C7C8
6E0C: CD CE DA    call $7A6E
6E0F: 01 1B 01    ld   bc,$011B
6E12: FD 7E 00    ld   a,(iy+$00)
6E15: C6 10       add  a,$10
6E17: 57          ld   d,a
6E18: FD 7E 09    ld   a,(iy+$03)
6E1B: D6 02       sub  $08
6E1D: 5F          ld   e,a
6E1E: DD 21 B6 6D ld   ix,unknown_C7BC
6E22: 26 01       ld   h,$01
6E24: CD CE DA    call $7A6E
6E27: CD 52 DA    call or_50_to_C7BE_7A58
6E2A: 21 BE 6D    ld   hl,unknown_C7BE
6E2D: CB FE       set  7,(hl)
6E2F: 3E 96       ld   a,$3C
6E31: CD 5A B0    call suspend_this_task_B05A
6E34: A7          and  a
6E35: C4 D5 B0    call nz,display_error_text_B075
6E38: CD 51 B0    call task_yield_B051
table_6f56:
	dc.b	0x06,0x05,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; table_6f56
	dc.b	0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; $6f5e
	dc.b	0xfe,0x06,0x06,0x3c,0x98,0x3c,0x98,0x3c ; $6f66
	dc.b	0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c ; $6f6e
	dc.b	0x98,0xfe,0x06,0x07,0x3a,0x90,0x3a,0x90 ; $6f76
	dc.b	0x3a,0x90,0x3a,0x90,0x3a,0x90,0x3a,0x90 ; $6f7e
	dc.b	0x3a,0x90,0xff ; $6f86



6F89: 3A 11 63    ld   a,(background_and_state_bits_C911)
6F8C: CB BF       res  7,a
6F8E: FE 80       cp   $20
6F90: DC D5 B0    call c,display_error_text_B075
6F93: FE 50       cp   $50
6F95: D4 D5 B0    call nc,display_error_text_B075
6F98: FE 40       cp   $40
6F9A: D2 AB D9    jp   nc,$73AB
6F9D: FE 90       cp   $30
6F9F: D2 B5 D1    jp   nc,$71B5
6FA2: DD 21 10 63 ld   ix,computer_skill_C910
6FA6: DD 6E 08    ld   l,(ix+$02)
6FA9: DD 66 09    ld   h,(ix+$03)
6FAC: 23          inc  hl
6FAD: 23          inc  hl
6FAE: 7E          ld   a,(hl)
6FAF: FE FF       cp   $FF
6FB1: C2 B6 CF    jp   nz,$6FBC
6FB4: 21 59 DD    ld   hl,table_7753
6FB7: 16 32       ld   d,$98
6FB9: CD 93 B0    call display_text_B039
6FBC: 3A 11 63    ld   a,(background_and_state_bits_C911)
6FBF: CB BF       res  7,a
6FC1: D6 80       sub  $20
6FC3: 87          add  a,a
6FC4: 87          add  a,a
6FC5: 4F          ld   c,a
6FC6: 06 00       ld   b,$00
6FC8: DD 21 BB D4 ld   ix,table_74bb
6FCC: DD 09       add  ix,bc
6FCE: DD 66 00    ld   h,(ix+$00)
6FD1: DD 6E 01    ld   l,(ix+$01)
6FD4: DD 4E 08    ld   c,(ix+$02)
6FD7: DD 46 09    ld   b,(ix+$03)
6FDA: FD 21 D6 6D ld   iy,unknown_C77C
6FDE: FD 74 00    ld   (iy+$00),h
6FE1: FD 75 09    ld   (iy+$03),l
6FE4: FD 74 04    ld   (iy+$04),h
6FE7: 7D          ld   a,l
6FE8: C6 10       add  a,$10
6FEA: FD 77 0D    ld   (iy+$07),a
6FED: 7C          ld   a,h
6FEE: D6 82       sub  $28
6FF0: FD 77 02    ld   (iy+$08),a
6FF3: 16 10       ld   d,$10
6FF5: 82          add  a,d
6FF6: FD 77 06    ld   (iy+$0c),a
6FF9: 82          add  a,d
6FFA: FD 77 10    ld   (iy+$10),a
6FFD: 82          add  a,d
6FFE: FD 77 14    ld   (iy+$14),a
7001: 82          add  a,d
7002: FD 77 12    ld   (iy+$18),a
7005: 82          add  a,d
7006: FD 77 16    ld   (iy+$1c),a
7009: 7D          ld   a,l
700A: D6 12       sub  $18
700C: FD 77 0B    ld   (iy+$0b),a
700F: FD 77 0F    ld   (iy+$0f),a
7012: FD 77 19    ld   (iy+$13),a
7015: FD 77 1D    ld   (iy+$17),a
7018: FD 77 1B    ld   (iy+$1b),a
701B: FD 77 1F    ld   (iy+$1f),a
701E: C5          push bc
701F: FD 71 01    ld   (iy+$01),c
7022: FD 70 08    ld   (iy+$02),b
7025: 0C          inc  c
7026: FD 71 05    ld   (iy+$05),c
7029: FD 70 0C    ld   (iy+$06),b
702C: 3E 4D       ld   a,$47
702E: 06 6D       ld   b,$C7
7030: 0E 7C       ld   c,$D6
7032: FD 71 03    ld   (iy+$09),c
7035: FD 77 0A    ld   (iy+$0a),a
7038: FD 71 07    ld   (iy+$0d),c
703B: FD 77 0E    ld   (iy+$0e),a
703E: FD 36 11 7D ld   (iy+$11),$D7
7042: FD 77 18    ld   (iy+$12),a
7045: FD 36 15 72 ld   (iy+$15),$D8
7049: FD 77 1C    ld   (iy+$16),a
704C: FD 71 13    ld   (iy+$19),c
704F: FD 70 1A    ld   (iy+$1a),b
7052: FD 71 17    ld   (iy+$1d),c
7055: FD 70 1E    ld   (iy+$1e),b
7058: C1          pop  bc
7059: DD 21 60 61 ld   ix,unknown_C1C0
705D: DD 71 0D    ld   (ix+$07),c
7060: DD 71 0B    ld   (ix+$0b),c
7063: 3E 08       ld   a,$02
7065: 81          add  a,c
7066: DD 77 03    ld   (ix+$09),a
7069: DD 77 07    ld   (ix+$0d),a
706C: DD 70 02    ld   (ix+$08),b
706F: DD 70 0A    ld   (ix+$0a),b
7072: DD 70 06    ld   (ix+$0c),b
7075: CB F8       set  7,b
7077: DD 70 0E    ld   (ix+$0e),b
707A: DD 6E 0D    ld   l,(ix+$07)
707D: DD 66 02    ld   h,(ix+$08)
7080: FD 75 01    ld   (iy+$01),l
7083: FD 74 08    ld   (iy+$02),h
7086: FD 36 11 72 ld   (iy+$11),$D8
708A: FD 36 18 6D ld   (iy+$12),$C7
708E: FD 36 15 7D ld   (iy+$15),$D7
7092: FD 36 1C 6D ld   (iy+$16),$C7
7096: DD E5       push ix
7098: FD E5       push iy
709A: 3E 14       ld   a,$14
709C: CD 5A B0    call suspend_this_task_B05A
709F: A7          and  a
70A0: C4 D5 B0    call nz,display_error_text_B075
70A3: FD E1       pop  iy
70A5: DD E1       pop  ix
70A7: FD 36 11 7D ld   (iy+$11),$D7
70AB: FD 36 18 4D ld   (iy+$12),$47
70AF: FD 36 15 72 ld   (iy+$15),$D8
70B3: FD 36 1C 4D ld   (iy+$16),$47
70B7: DD E5       push ix
70B9: FD E5       push iy
70BB: 3E 14       ld   a,$14
70BD: CD 5A B0    call suspend_this_task_B05A
70C0: A7          and  a
70C1: C4 D5 B0    call nz,display_error_text_B075
70C4: FD E1       pop  iy
70C6: DD E1       pop  ix
70C8: DD 6E 03    ld   l,(ix+$09)
70CB: DD 66 0A    ld   h,(ix+$0a)
70CE: FD 75 01    ld   (iy+$01),l
70D1: FD 74 08    ld   (iy+$02),h
70D4: FD 36 11 72 ld   (iy+$11),$D8
70D8: FD 36 18 6D ld   (iy+$12),$C7
70DC: FD 36 15 7D ld   (iy+$15),$D7
70E0: FD 36 1C 6D ld   (iy+$16),$C7
70E4: DD E5       push ix
70E6: FD E5       push iy
70E8: 3E 14       ld   a,$14
70EA: CD 5A B0    call suspend_this_task_B05A
70ED: A7          and  a
70EE: C4 D5 B0    call nz,display_error_text_B075
70F1: FD E1       pop  iy
70F3: DD E1       pop  ix
70F5: FD 36 11 7D ld   (iy+$11),$D7
70F9: FD 36 18 4D ld   (iy+$12),$47
70FD: FD 36 15 72 ld   (iy+$15),$D8
7101: FD 36 1C 4D ld   (iy+$16),$47
7105: DD E5       push ix
7107: FD E5       push iy
7109: 3E 14       ld   a,$14
710B: CD 5A B0    call suspend_this_task_B05A
710E: A7          and  a
710F: C4 D5 B0    call nz,display_error_text_B075
7112: FD E1       pop  iy
7114: DD E1       pop  ix
7116: DD 6E 0B    ld   l,(ix+$0b)
7119: DD 66 06    ld   h,(ix+$0c)
711C: FD 75 01    ld   (iy+$01),l
711F: FD 74 08    ld   (iy+$02),h
7122: FD 36 11 72 ld   (iy+$11),$D8
7126: FD 36 18 6D ld   (iy+$12),$C7
712A: FD 36 15 7D ld   (iy+$15),$D7
712E: FD 36 1C 6D ld   (iy+$16),$C7
7132: DD E5       push ix
7134: FD E5       push iy
7136: 3E 14       ld   a,$14
7138: CD 5A B0    call suspend_this_task_B05A
713B: A7          and  a
713C: C4 D5 B0    call nz,display_error_text_B075
713F: FD E1       pop  iy
7141: DD E1       pop  ix
7143: FD 36 11 7D ld   (iy+$11),$D7
7147: FD 36 18 4D ld   (iy+$12),$47
714B: FD 36 15 72 ld   (iy+$15),$D8
714F: FD 36 1C 4D ld   (iy+$16),$47
7153: DD E5       push ix
7155: FD E5       push iy
7157: 3E 14       ld   a,$14
7159: CD 5A B0    call suspend_this_task_B05A
715C: A7          and  a
715D: C4 D5 B0    call nz,display_error_text_B075
7160: FD E1       pop  iy
7162: DD E1       pop  ix
7164: DD 6E 07    ld   l,(ix+$0d)
7167: DD 66 0E    ld   h,(ix+$0e)
716A: FD 75 01    ld   (iy+$01),l
716D: FD 74 08    ld   (iy+$02),h
7170: FD 36 11 72 ld   (iy+$11),$D8
7174: FD 36 18 6D ld   (iy+$12),$C7
7178: FD 36 15 7D ld   (iy+$15),$D7
717C: FD 36 1C 6D ld   (iy+$16),$C7
7180: DD E5       push ix
7182: FD E5       push iy
7184: 3E 14       ld   a,$14
7186: CD 5A B0    call suspend_this_task_B05A
7189: A7          and  a
718A: C4 D5 B0    call nz,display_error_text_B075
718D: FD E1       pop  iy
718F: DD E1       pop  ix
7191: FD 36 11 7D ld   (iy+$11),$D7
7195: FD 36 18 4D ld   (iy+$12),$47
7199: FD 36 15 72 ld   (iy+$15),$D8
719D: FD 36 1C 4D ld   (iy+$16),$47
71A1: DD E5       push ix
71A3: FD E5       push iy
71A5: 3E 14       ld   a,$14
71A7: CD 5A B0    call suspend_this_task_B05A
71AA: A7          and  a
71AB: C4 D5 B0    call nz,display_error_text_B075
71AE: FD E1       pop  iy
71B0: DD E1       pop  ix
71B2: C3 DA D0    jp   $707A
71B5: 3A 14 63    ld   a,(unknown_C914)
71B8: FE FF       cp   $FF
71BA: C2 62 D1    jp   nz,$71C8
71BD: 21 4B D5    ld   hl,table_754b
71C0: 11 E4 6D    ld   de,unknown_C7E4
71C3: 01 10 00    ld   bc,$0010
71C6: ED B0       ldir
71C8: 3A 11 63    ld   a,(background_and_state_bits_C911)
71CB: CB BF       res  7,a
71CD: D6 90       sub  $30
71CF: 87          add  a,a
71D0: 87          add  a,a
71D1: 4F          ld   c,a
71D2: 06 00       ld   b,$00
71D4: DD 21 EB D4 ld   ix,table_74eb
71D8: DD 09       add  ix,bc
71DA: DD 66 00    ld   h,(ix+$00)
71DD: DD 6E 01    ld   l,(ix+$01)
71E0: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
71E3: CB 57       bit  2,a
71E5: C2 E6 D1    jp   nz,$71EC
71E8: 3E 40       ld   a,$40
71EA: 84          add  a,h
71EB: 67          ld   h,a
71EC: DD 4E 08    ld   c,(ix+$02)
71EF: DD 46 09    ld   b,(ix+$03)
71F2: FD 21 D6 6D ld   iy,unknown_C77C
71F6: FD 74 00    ld   (iy+$00),h
71F9: FD 74 04    ld   (iy+$04),h
71FC: FD 75 09    ld   (iy+$03),l
71FF: 3E 10       ld   a,$10
7201: 85          add  a,l
7202: FD 77 0D    ld   (iy+$07),a
7205: FD 71 01    ld   (iy+$01),c
7208: FD 70 08    ld   (iy+$02),b
720B: 0C          inc  c
720C: FD 71 05    ld   (iy+$05),c
720F: FD 70 0C    ld   (iy+$06),b
7212: 0C          inc  c
7213: DD 21 60 61 ld   ix,unknown_C1C0
7217: DD 71 03    ld   (ix+$09),c
721A: E5          push hl
721B: 7C          ld   a,h
721C: D6 80       sub  $20
721E: 57          ld   d,a
721F: 7D          ld   a,l
7220: D6 82       sub  $28
7222: 5F          ld   e,a
7223: 01 F4 05    ld   bc,$05F4
7226: 26 4D       ld   h,$47
7228: CD CA DA    call $7A6A
722B: E1          pop  hl
722C: E5          push hl
722D: FD 21 B6 6D ld   iy,unknown_C7BC
7231: 3E 02       ld   a,$08
7233: 84          add  a,h
7234: FD 77 00    ld   (iy+$00),a
7237: 7D          ld   a,l
7238: D6 12       sub  $18
723A: FD 77 09    ld   (iy+$03),a
723D: FD 36 01 20 ld   (iy+$01),$80
7241: FD 36 08 4D ld   (iy+$02),$47
7245: E1          pop  hl
7246: 7C          ld   a,h
7247: D6 82       sub  $28
7249: 47          ld   b,a
724A: C6 10       add  a,$10
724C: 4F          ld   c,a
724D: 7D          ld   a,l
724E: D6 80       sub  $20
7250: 6F          ld   l,a
7251: FD 21 00 6D ld   iy,referee_x_pos_C700
7255: FD 70 00    ld   (iy+$00),b
7258: FD 70 04    ld   (iy+$04),b
725B: FD 71 02    ld   (iy+$08),c
725E: FD 70 06    ld   (iy+$0c),b
7261: FD 71 10    ld   (iy+$10),c
7264: FD 70 14    ld   (iy+$14),b
7267: FD 71 12    ld   (iy+$18),c
726A: FD 70 16    ld   (iy+$1c),b
726D: FD 71 80    ld   (iy+$20),c
7270: FD 75 0B    ld   (iy+$0b),l
7273: FD 75 0D    ld   (iy+$07),l
7276: 3E 10       ld   a,$10
7278: 85          add  a,l
7279: FD 77 09    ld   (iy+$03),a
727C: FD 77 0F    ld   (iy+$0f),a
727F: FD 77 19    ld   (iy+$13),a
7282: C6 10       add  a,$10
7284: FD 77 1D    ld   (iy+$17),a
7287: FD 77 1B    ld   (iy+$1b),a
728A: C6 10       add  a,$10
728C: FD 77 1F    ld   (iy+$1f),a
728F: FD 77 89    ld   (iy+$23),a
7292: 3E 21       ld   a,$81
7294: FD 77 01    ld   (iy+$01),a
7297: 3C          inc  a
7298: FD 77 05    ld   (iy+$05),a
729B: 3C          inc  a
729C: FD 77 03    ld   (iy+$09),a
729F: 3E 01       ld   a,$01
72A1: FD 77 07    ld   (iy+$0d),a
72A4: 3C          inc  a
72A5: FD 77 11    ld   (iy+$11),a
72A8: 3C          inc  a
72A9: FD 77 15    ld   (iy+$15),a
72AC: 3C          inc  a
72AD: FD 77 13    ld   (iy+$19),a
72B0: 3C          inc  a
72B1: FD 77 17    ld   (iy+$1d),a
72B4: 3C          inc  a
72B5: FD 77 81    ld   (iy+$21),a
72B8: 3E 41       ld   a,$41
72BA: FD 77 08    ld   (iy+$02),a
72BD: FD 77 0C    ld   (iy+$06),a
72C0: FD 77 0A    ld   (iy+$0a),a
72C3: 06 41       ld   b,$41
72C5: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
72C8: CB 57       bit  2,a
72CA: C2 6F D8    jp   nz,$72CF
72CD: 06 48       ld   b,$42
72CF: FD 70 0E    ld   (iy+$0e),b
72D2: FD 70 18    ld   (iy+$12),b
72D5: FD 70 1C    ld   (iy+$16),b
72D8: FD 70 1A    ld   (iy+$1a),b
72DB: FD 70 1E    ld   (iy+$1e),b
72DE: FD 70 88    ld   (iy+$22),b
72E1: FD 21 74 6D ld   iy,unknown_C7D4
72E5: 7C          ld   a,h
72E6: D6 82       sub  $28
72E8: FD 77 00    ld   (iy+$00),a
72EB: FD 77 02    ld   (iy+$08),a
72EE: C6 10       add  a,$10
72F0: FD 77 04    ld   (iy+$04),a
72F3: FD 77 06    ld   (iy+$0c),a
72F6: 7D          ld   a,l
72F7: D6 04       sub  $04
72F9: FD 77 09    ld   (iy+$03),a
72FC: FD 77 0D    ld   (iy+$07),a
72FF: C6 10       add  a,$10
7301: FD 77 0B    ld   (iy+$0b),a
7304: FD 77 0F    ld   (iy+$0f),a
7307: FD 36 08 41 ld   (iy+$02),$41
730B: FD 36 0C 61 ld   (iy+$06),$C1
730F: FD 36 0A 45 ld   (iy+$0a),$45
7313: FD 36 0E 65 ld   (iy+$0e),$C5
7317: 0E 00       ld   c,$00
7319: C5          push bc
731A: DD 21 00 6D ld   ix,referee_x_pos_C700
731E: CB 41       bit  0,c
7320: C2 83 D9    jp   nz,$7329
7323: 21 3F D9    ld   hl,table_739f
7326: C3 86 D9    jp   $732C
7329: 21 A5 D9    ld   hl,table_73a5
732C: DD 21 01 6D ld   ix,unknown_C701
7330: 11 04 00    ld   de,$0004
7333: 06 0C       ld   b,$06
7335: 7E          ld   a,(hl)
7336: DD 77 00    ld   (ix+$00),a
7339: DD 19       add  ix,de
733B: 23          inc  hl
733C: 10 FD       djnz $7335
733E: 3E 1B       ld   a,$1B
7340: CD 5A B0    call suspend_this_task_B05A
7343: A7          and  a
7344: C4 D5 B0    call nz,display_error_text_B075
7347: DD 21 60 61 ld   ix,unknown_C1C0
734B: DD 7E 03    ld   a,(ix+$09)
734E: 32 D7 6D    ld   (unknown_C77D),a
7351: C1          pop  bc
7352: 79          ld   a,c
7353: FE 02       cp   $08
7355: D2 CC D9    jp   nc,$7366
7358: FD 21 D6 6D ld   iy,unknown_C77C
735C: FD 35 00    dec  (iy+$00)
735F: FD 35 04    dec  (iy+$04)
7362: 0C          inc  c
7363: C3 13 D9    jp   $7319
7366: FD 21 74 6D ld   iy,unknown_C7D4
736A: FD 36 01 C5 ld   (iy+$01),$65
736E: FD 36 05 C5 ld   (iy+$05),$65
7372: FD 36 03 CC ld   (iy+$09),$66
7376: FD 36 07 CC ld   (iy+$0d),$66
737A: FD E5       push iy
737C: 3E 10       ld   a,$10
737E: CD 5A B0    call suspend_this_task_B05A
7381: FD E1       pop  iy
7383: FD 36 01 CD ld   (iy+$01),$67
7387: FD 36 05 CD ld   (iy+$05),$67
738B: FD 36 03 C2 ld   (iy+$09),$68
738F: FD 36 07 C2 ld   (iy+$0d),$68
7393: FD E5       push iy
7395: 3E 10       ld   a,$10
7397: CD 5A B0    call suspend_this_task_B05A
739A: FD E1       pop  iy
739C: C3 CC D9    jp   $7366
table_739f:
	dc.b	0x00,0x00,0x00,0x01,0x02,0x03 ; table_739f
table_73a5:
	dc.b	0x81,0x82,0x83,0x07,0x08,0x09 ; table_73a5
73AB: 3A 11 63    ld   a,(background_and_state_bits_C911)
73AE: CB BF       res  7,a
73B0: D6 40       sub  $40
73B2: 87          add  a,a
73B3: 87          add  a,a
73B4: 4F          ld   c,a
73B5: 06 00       ld   b,$00
73B7: DD 21 1B D5 ld   ix,table_751b
73BB: DD 09       add  ix,bc
73BD: DD 66 00    ld   h,(ix+$00)
73C0: DD 6E 01    ld   l,(ix+$01)
73C3: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
73C6: CB 57       bit  2,a
73C8: C2 6F D9    jp   nz,$73CF
73CB: 3E D2       ld   a,$78
73CD: 84          add  a,h
73CE: 67          ld   h,a
73CF: DD 4E 08    ld   c,(ix+$02)
73D2: DD 46 09    ld   b,(ix+$03)
73D5: FD 21 D6 6D ld   iy,unknown_C77C
73D9: FD 74 00    ld   (iy+$00),h
73DC: FD 75 09    ld   (iy+$03),l
73DF: 3E 10       ld   a,$10
73E1: 85          add  a,l
73E2: FD 77 0D    ld   (iy+$07),a
73E5: FD 74 04    ld   (iy+$04),h
73E8: FD 71 01    ld   (iy+$01),c
73EB: FD 70 08    ld   (iy+$02),b
73EE: 0C          inc  c
73EF: FD 71 05    ld   (iy+$05),c
73F2: FD 70 0C    ld   (iy+$06),b
73F5: E5          push hl
73F6: 7C          ld   a,h
73F7: D6 90       sub  $30
73F9: 57          ld   d,a
73FA: 7D          ld   a,l
73FB: D6 82       sub  $28
73FD: 5F          ld   e,a
73FE: 01 F3 05    ld   bc,$05F9
7401: 26 4A       ld   h,$4A
7403: CD CA DA    call $7A6A
7406: E1          pop  hl
7407: E5          push hl
7408: FD 21 B6 6D ld   iy,unknown_C7BC
740C: 3E 02       ld   a,$08
740E: 84          add  a,h
740F: FD 77 00    ld   (iy+$00),a
7412: 7D          ld   a,l
7413: D6 12       sub  $18
7415: FD 77 09    ld   (iy+$03),a
7418: FD 36 01 86 ld   (iy+$01),$2C
741C: FD 36 08 45 ld   (iy+$02),$45
7420: E1          pop  hl
7421: 7C          ld   a,h
7422: D6 82       sub  $28
7424: 47          ld   b,a
7425: C6 10       add  a,$10
7427: 4F          ld   c,a
7428: 7D          ld   a,l
7429: D6 10       sub  $10
742B: FD 21 00 6D ld   iy,referee_x_pos_C700
742F: FD 70 00    ld   (iy+$00),b
7432: FD 71 04    ld   (iy+$04),c
7435: FD 70 02    ld   (iy+$08),b
7438: FD 71 06    ld   (iy+$0c),c
743B: FD 70 10    ld   (iy+$10),b
743E: FD 71 14    ld   (iy+$14),c
7441: FD 77 09    ld   (iy+$03),a
7444: FD 77 0D    ld   (iy+$07),a
7447: C6 10       add  a,$10
7449: FD 77 0B    ld   (iy+$0b),a
744C: FD 77 0F    ld   (iy+$0f),a
744F: C6 10       add  a,$10
7451: FD 77 19    ld   (iy+$13),a
7454: FD 77 1D    ld   (iy+$17),a
7457: 21 6E 41    ld   hl,$41CE		; immediate
745A: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
745D: CB 57       bit  2,a
745F: C2 C5 D4    jp   nz,$7465
7462: 21 6E 48    ld   hl,$42CE		; immediate
7465: FD 75 01    ld   (iy+$01),l
7468: FD 74 08    ld   (iy+$02),h
746B: 23          inc  hl
746C: FD 75 05    ld   (iy+$05),l
746F: FD 74 0C    ld   (iy+$06),h
7472: 23          inc  hl
7473: FD 75 03    ld   (iy+$09),l
7476: FD 74 0A    ld   (iy+$0a),h
7479: 23          inc  hl
747A: FD 75 07    ld   (iy+$0d),l
747D: FD 74 0E    ld   (iy+$0e),h
7480: 23          inc  hl
7481: FD 75 11    ld   (iy+$11),l
7484: FD 74 18    ld   (iy+$12),h
7487: 23          inc  hl
7488: FD 75 15    ld   (iy+$15),l
748B: FD 74 1C    ld   (iy+$16),h
748E: 3E 82       ld   a,$28
7490: CD 5A B0    call suspend_this_task_B05A
7493: A7          and  a
7494: C4 D5 B0    call nz,display_error_text_B075
7497: FD 21 00 6D ld   iy,referee_x_pos_C700
749B: FD 36 01 74 ld   (iy+$01),$D4
749F: FD 36 05 75 ld   (iy+$05),$D5
74A3: 3E 82       ld   a,$28
74A5: CD 5A B0    call suspend_this_task_B05A
74A8: A7          and  a
74A9: C4 D5 B0    call nz,display_error_text_B075
74AC: FD 21 00 6D ld   iy,referee_x_pos_C700
74B0: FD 36 01 6E ld   (iy+$01),$CE
74B4: FD 36 05 6F ld   (iy+$05),$CF
74B8: C3 2E D4    jp   $748E
table_74bb:
	dc.b	0x78,0xa0,0x28,0x52,0x78,0xc0,0xc8,0x51 ; table_74bb
	dc.b	0x78,0xa0,0x48,0x52,0x78,0xc0,0xa8,0x54 ; $74c3
	dc.b	0x78,0xc0,0xc0,0x52,0x78,0xc0,0xd0,0x52 ; $74cb
	dc.b	0x78,0xc0,0xa0,0x52,0x78,0xc0,0x88,0x52 ; $74d3
	dc.b	0x78,0xc0,0x50,0x54,0x78,0xc0,0x98,0x51 ; $74db
	dc.b	0x78,0xc0,0xb0,0x52,0x78,0xa0,0x68,0x53 ; $74e3
table_74eb:
	dc.b	0x70,0xa0,0x2b,0x52,0x70,0xc0,0xcb,0x51 ; table_74eb
	dc.b	0x70,0xa0,0x4b,0x52,0x70,0xc0,0xab,0x54 ; $74f3
	dc.b	0x70,0xc0,0xc3,0x52,0x70,0xc0,0xd3,0x52 ; $74fb
	dc.b	0x70,0xc0,0xa3,0x52,0x70,0xc0,0x8b,0x52 ; $7503
	dc.b	0x70,0xc0,0x53,0x54,0x70,0xc0,0x9b,0x51 ; $750b
	dc.b	0x70,0xc0,0xb3,0x52,0x70,0xa0,0x6b,0x53 ; $7513
table_751b:
	dc.b	0x48,0xa0,0x2e,0x52,0x48,0xc0,0xce,0x51 ; table_751b
	dc.b	0x48,0xa0,0x4e,0x52,0x48,0xc0,0xae,0x54 ; $7523
	dc.b	0x48,0xc0,0xc6,0x52,0x48,0xc0,0xd6,0x52 ; $752b
	dc.b	0x48,0xc0,0xa6,0x52,0x48,0xc0,0x8e,0x52 ; $7533
	dc.b	0x48,0xc0,0x56,0x54,0x48,0xc0,0x9e,0x51 ; $753b
	dc.b	0x48,0xc0,0xb6,0x52,0x48,0xa0,0x6e,0x53 ; $7543
table_754b:
	dc.b	0x64,0x19,0x46,0x80,0x60,0x1a,0x46,0x90 ; table_754b
	dc.b	0x70,0x1b,0x46,0x90,0x80,0x1c,0x46,0x90 ; $7553
	dc.b	0x9e,0x00 ; $755b
755B: 3E 00       ld   a,$00
755D: 32 4B 68    ld   (current_move_C24B),a
7560: 3A 11 63    ld   a,(background_and_state_bits_C911)
7563: CB BF       res  7,a
7565: FE 10       cp   $10
7567: DA DB A9    jp   c,fight_mainloop_A37B
756A: 47          ld   b,a
756B: E6 F0       and  $F0
756D: FE 10       cp   $10
756F: C2 2C D5    jp   nz,$7586
7572: 78          ld   a,b
7573: E6 0F       and  $0F
7575: 87          add  a,a
7576: 4F          ld   c,a
7577: 06 00       ld   b,$00
7579: DD 21 3F D5 ld   ix,table_759F
757D: DD 09       add  ix,bc
757F: DD 6E 00    ld   l,(ix+$00)
7582: DD 66 01    ld   h,(ix+$01)
7585: E9          jp   (hl)
7586: FE 50       cp   $50
7588: C2 D5 B0    jp   nz,display_error_text_B075
758B: 78          ld   a,b
758C: E6 0F       and  $0F
758E: 87          add  a,a
758F: 4F          ld   c,a
7590: 06 00       ld   b,$00
7592: DD 21 61 D5 ld   ix,table_75C1
7596: DD 09       add  ix,bc
7598: DD 6E 00    ld   l,(ix+$00)
759B: DD 66 01    ld   h,(ix+$01)
759E: E9          jp   (hl)
table_759F:
	dc.w	$75cd ; table_759F
	dc.w	$75cd ; $75a1
	dc.w	$75cd ; $75a3
	dc.w	$75cd ; $75a5
	dc.w	$75cd ; $75a7
	dc.w	$75cd ; $75a9
	dc.w	$75cd ; $75ab
	dc.w	$75cd ; $75ad
	dc.w	$75cd ; $75af
	dc.w	$75cd ; $75b1
	dc.w	$75cd ; $75b3
	dc.w	$75cd ; $75b5
	dc.w	$75cd ; $75b7
	dc.w	$75cd ; $75b9
	dc.w	$75cd ; $75bb
	dc.w	$75cd ; $75bd
	dc.w	display_error_text_B075 ; $75bf
table_75C1:
	dc.w	fight_mainloop_A37B ; table_75C1
	dc.w	$0000 ; $75c3
	dc.w	$0000 ; $75c5
	dc.w	$75cd ; $75c7
	dc.w	$0000 ; $75c9
	dc.w	display_error_text_B075 ; $75cb
75CD: 3E 00       ld   a,$00
75CF: CD 5A B0    call suspend_this_task_B05A
75D2: FE 03       cp   $09
75D4: CA 67 D5    jp   z,$75CD
75D7: FE 06       cp   $0C
75D9: C4 D5 B0    call nz,display_error_text_B075
75DC: CD BD 97    call $3DB7
75DF: 32 4B 68    ld   (current_move_C24B),a
75E2: AF          xor  a
75E3: 32 46 68    ld   (unknown_C24C),a
75E6: 3E 0A       ld   a,$0A
75E8: 06 07       ld   b,$0D
75EA: CD 57 B0    call task_manipulation_B05D
75ED: A7          and  a
75EE: C4 D5 B0    call nz,display_error_text_B075
75F1: C3 67 D5    jp   $75CD
75F4: DD 21 58 DC ld   ix,table_7652
75F8: DD E5       push ix
75FA: DD 46 01    ld   b,(ix+$01)
75FD: C5          push bc
75FE: 3E 00       ld   a,$00
7600: CD 5A B0    call suspend_this_task_B05A
7603: FE 06       cp   $0C
7605: C4 D5 B0    call nz,display_error_text_B075
7608: C1          pop  bc
7609: DD E1       pop  ix
760B: DD 7E 00    ld   a,(ix+$00)
760E: 32 4B 68    ld   (current_move_C24B),a
7611: 05          dec  b
7612: CA 8C DC    jp   z,$7626
7615: DD E5       push ix
7617: C5          push bc
7618: 3E 0A       ld   a,$0A
761A: 06 07       ld   b,$0D
761C: CD 57 B0    call task_manipulation_B05D
761F: A7          and  a
7620: C4 D5 B0    call nz,display_error_text_B075
7623: C3 FE D5    jp   $75FE
7626: DD E5       push ix
7628: 3E 0A       ld   a,$0A
762A: 06 07       ld   b,$0D
762C: CD 57 B0    call task_manipulation_B05D
762F: A7          and  a
7630: C4 D5 B0    call nz,display_error_text_B075
7633: DD E1       pop  ix
7635: DD 23       inc  ix
7637: DD 23       inc  ix
7639: DD 7E 00    ld   a,(ix+$00)
763C: FE FF       cp   $FF
763E: CC 4A DC    call z,$764A
7641: DD E5       push ix
7643: C5          push bc
7644: DD 46 01    ld   b,(ix+$01)
7647: C3 FE D5    jp   $75FE
764A: 3E 00       ld   a,$00
764C: CD 5A B0    call suspend_this_task_B05A
764F: C3 4A DC    jp   $764A
table_7652:
	dc.b	0x17,0x0c,0x13,0x0c,0xff ; table_7652
7657: 3E 00       ld   a,$00
7659: 32 CB 68    ld   (unknown_C26B),a
765C: 3A 11 63    ld   a,(background_and_state_bits_C911)
765F: CB BF       res  7,a
7661: FE 10       cp   $10
7663: DA DB A9    jp   c,fight_mainloop_A37B
7666: 47          ld   b,a
7667: E6 F0       and  $F0
7669: FE 10       cp   $10
766B: C2 28 DC    jp   nz,$7682
766E: 78          ld   a,b
766F: E6 0F       and  $0F
7671: 87          add  a,a
7672: 4F          ld   c,a
7673: 06 00       ld   b,$00
7675: DD 21 3B DC ld   ix,table_769B
7679: DD 09       add  ix,bc
767B: DD 6E 00    ld   l,(ix+$00)
767E: DD 66 01    ld   h,(ix+$01)
7681: E9          jp   (hl)
7682: FE 50       cp   $50
7684: C2 D5 B0    jp   nz,display_error_text_B075
7687: 78          ld   a,b
7688: E6 0F       and  $0F
768A: 87          add  a,a
768B: 4F          ld   c,a
768C: 06 00       ld   b,$00
768E: DD 21 B7 DC ld   ix,table_76BD
7692: DD 09       add  ix,bc
7694: DD 6E 00    ld   l,(ix+$00)
7697: DD 66 01    ld   h,(ix+$01)
769A: E9          jp   (hl)
table_769B:
	dc.w	$772c ; table_769B
	dc.w	$772c ; $769d
	dc.w	$772c ; $769f
	dc.w	$772c ; $76a1
	dc.w	$772c ; $76a3
	dc.w	$772c ; $76a5
	dc.w	$772c ; $76a7
	dc.w	$772c ; $76a9
	dc.w	$772c ; $76ab
	dc.w	$772c ; $76ad
	dc.w	$772c ; $76af
	dc.w	$772c ; $76b1
	dc.w	$772c ; $76b3
	dc.w	$772c ; $76b5
	dc.w	$772c ; $76b7
	dc.w	$772c ; $76b9
	dc.w	display_error_text_B075 ; $76bb
table_76BD:
	dc.w	fight_mainloop_A37B ; table_76BD
	dc.w	$0000 ; $76bf
	dc.w	$0000 ; $76c1
	dc.w	$606a ; $76c3
	dc.w	$0000 ; $76c5
	dc.w	display_error_text_B075 ; $76c7
76C9: DD 21 8D DD ld   ix,table_7727
76CD: DD E5       push ix
76CF: DD 46 01    ld   b,(ix+$01)
76D2: C5          push bc
76D3: 3E 00       ld   a,$00
76D5: CD 5A B0    call suspend_this_task_B05A
76D8: FE 06       cp   $0C
76DA: C4 D5 B0    call nz,display_error_text_B075
76DD: C1          pop  bc
76DE: DD E1       pop  ix
76E0: DD 7E 00    ld   a,(ix+$00)
76E3: 32 CB 68    ld   (unknown_C26B),a
76E6: 05          dec  b
76E7: CA FB DC    jp   z,$76FB
76EA: DD E5       push ix
76EC: C5          push bc
76ED: 3E 0B       ld   a,$0B
76EF: 06 07       ld   b,$0D
76F1: CD 57 B0    call task_manipulation_B05D
76F4: A7          and  a
76F5: C4 D5 B0    call nz,display_error_text_B075
76F8: C3 79 DC    jp   $76D3
76FB: DD E5       push ix
76FD: 3E 0B       ld   a,$0B
76FF: 06 07       ld   b,$0D
7701: CD 57 B0    call task_manipulation_B05D
7704: A7          and  a
7705: C4 D5 B0    call nz,display_error_text_B075
7708: DD E1       pop  ix
770A: DD 23       inc  ix
770C: DD 23       inc  ix
770E: DD 7E 00    ld   a,(ix+$00)
7711: FE FF       cp   $FF
7713: CC 1F DD    call z,$771F
7716: DD E5       push ix
7718: DD 46 01    ld   b,(ix+$01)
771B: C5          push bc
771C: C3 79 DC    jp   $76D3
771F: 3E 00       ld   a,$00
7721: CD 5A B0    call suspend_this_task_B05A
7724: C3 1F DD    jp   $771F
table_7727:
	dc.b	0x17,0x0c,0x0b,0x0c,0xff ; table_7727
772C: 3E 00       ld   a,$00
772E: CD 5A B0    call suspend_this_task_B05A
7731: FE 03       cp   $09
7733: CA 86 DD    jp   z,$772C
7736: FE 06       cp   $0C
7738: C4 D5 B0    call nz,display_error_text_B075
773B: CD BD 97    call $3DB7
773E: 32 CB 68    ld   (unknown_C26B),a
7741: AF          xor  a
7742: 32 C6 68    ld   (unknown_C26C),a
7745: 3E 0B       ld   a,$0B
7747: 06 07       ld   b,$0D
7749: CD 57 B0    call task_manipulation_B05D
774C: A7          and  a
774D: C4 D5 B0    call nz,display_error_text_B075
7750: C3 86 DD    jp   $772C
table_7753:
	dc.b	0x0a,0x0c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; table_7753
	dc.b	0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0xfe,0x0a ; $775b
	dc.b	0x0d,0x3c,0x0f,0x12,0x17,0x0a,0x15,0x3c ; $7763
	dc.b	0x10,0x0a,0x16,0x0e,0x3c,0xfe,0x0a,0x0e ; $776b
	dc.b	0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; $7773
	dc.b	0x3c,0x3c,0x3c,0x3c,0xff ; $777b
7780: 21 33 DD    ld   hl,table_7799
7783: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
7786: CB 57       bit  2,a
7788: C2 2E DD    jp   nz,$778E
778B: 21 A4 DD    ld   hl,table_77a4
778E: 16 32       ld   d,$98
7790: CD 93 B0    call display_text_B039
7793: 3E 20       ld   a,$80
7795: CD 5A B0    call suspend_this_task_B05A
7798: C9          ret
table_7799:
	dc.b	0x0c,0x0e,0x19,0x15,0x0a,0x22,0x0e,0x1b ; table_7799
	dc.b	0x3c,0x01,0xff ; $77a1
table_77a4:
	dc.b	0x0c,0x0e,0x19,0x15,0x0a,0x22,0x0e,0x1b ; table_77a4
	dc.b	0x3c,0x02,0xff,0x17,0x07,0x1d,0x12,0x16 ; $77ac
	dc.b	0x0e,0x3c,0x03,0x00,0xff ; $77b4
table_77b9:
	dc.b	0x0a,0x0c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; table_77b9
	dc.b	0x3c,0x3c,0x3c,0x3c,0x3c,0xfe,0x0a,0x0d ; $77c1
	dc.b	0x3c,0x10,0x0a,0x16,0x0e,0x3c,0x18,0x1f ; $77c9
	dc.b	0x0e,0x1b,0x3c,0xfe,0x0a,0x0e,0x3c,0x3c ; $77d1
	dc.b	0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; $77d9
	dc.b	0x3c,0xff ; $77e1
table_77e3:
	dc.b	0x06,0x05,0xc1,0x92,0xc2,0x92,0xc3,0x92 ; table_77e3
	dc.b	0xc4,0x92,0xc5,0x92,0xc6,0x92,0xc7,0x92 ; $77eb
	dc.b	0xfe,0x06,0x06,0xc8,0x92,0x4f,0x92,0x50 ; $77f3
	dc.b	0x92,0x51,0x92,0x52,0x92,0x53,0x92,0x54 ; $77fb
	dc.b	0x92,0xfe,0x06,0x07,0x55,0x92,0x56,0x92 ; $7803
	dc.b	0x57,0x92,0x58,0x92,0x59,0x92,0x5a,0x92 ; $780b
	dc.b	0x5b,0x92,0xff ; $7813
table_7816:
	dc.b	0x05,0x0a,0x15,0x18,0x1c,0x0e,0x1b,0x3c ; table_7816
	dc.b	0x1d,0x18,0x3c,0x0c,0x18,0x17,0x1d,0x12 ; $781e
	dc.b	0x17,0x1e,0x0e,0x3c,0x0f,0x12,0x10,0x11 ; $7826
	dc.b	0x1d,0xfe,0x02,0x0c,0x12,0x17,0x1c,0x0e ; $782e
	dc.b	0x1b,0x1d,0x3c,0x0c,0x18,0x12,0x17,0x3c ; $7836
	dc.b	0x20,0x12,0x1d,0x11,0x12,0x17,0x3c,0x01 ; $783e
	dc.b	0x05,0x3c,0x1c,0x0e,0x0c,0x18,0x17,0x0d ; $7846
	dc.b	0xfe,0x05,0x0e,0x20,0x12,0x17,0x17,0x0e ; $784e
	dc.b	0x1b,0x3c,0x1d,0x18,0x3c,0x0c,0x18,0x17 ; $7856
	dc.b	0x1d,0x12,0x17,0x1e,0x0e,0xfe,0x09,0x10 ; $785e
	dc.b	0x1c,0x12,0x17,0x10,0x15,0x0e,0x3c,0x19 ; $7866
	dc.b	0x15,0x0a,0x22,0xfe,0x07,0x12,0x19,0x1b ; $786e
	dc.b	0x0e,0x1c,0x1c,0x3c,0x01,0x19,0x3c,0x0b ; $7876
	dc.b	0x1e,0x1d,0x1d,0x18,0x17 ; $787e
table_7883:
	dc.b	0xff ; table_7883
table_7884:
	dc.b	0x09,0x0c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; table_7884
	dc.b	0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; $788c
	dc.b	0xfe,0x09,0x0d,0x3c,0x02,0x19,0x3c,0x10 ; $7894
	dc.b	0x0a,0x16,0x0e,0x3c,0x18,0x1f,0x0e,0x1b ; $789c
	dc.b	0x3c,0xfe,0x09,0x0e,0x3c,0x3c,0x3c,0x3c ; $78a4
	dc.b	0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; $78ac
	dc.b	0x3c,0x3c,0xff ; $78b4
table_78b7:
	dc.b	0x09,0x0c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; table_78b7
	dc.b	0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; $78bf
	dc.b	0xfe,0x09,0x0d,0x3c,0x01,0x19,0x3c,0x10 ; $78c7
	dc.b	0x0a,0x16,0x0e,0x3c,0x18,0x1f,0x0e,0x1b ; $78cf
	dc.b	0x3c,0xfe,0x09,0x0e,0x3c,0x3c,0x3c,0x3c ; $78d7
	dc.b	0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; $78df
	dc.b	0x3c,0x3c,0xff ; $78e7

78EA: 3E 01       ld   a,$01
78EC: CD D8 B0    call play_sound_B072
78EF: 01 96 10    ld   bc,$103C
78F2: CD 90 B0    call fill_video_and_attribute_memory_B030
78F5: 21 EA A0    ld   hl,table_a0ea
78F8: CD 96 B0    call display_multicolor_text_B03C
78FB: 21 33 D3    ld   hl,product_of_data_east_str_7999
78FE: CD 96 B0    call display_multicolor_text_B03C
7901: 3E 1E       ld   a,$1E
7903: CD 5A B0    call suspend_this_task_B05A
7906: A7          and  a
7907: C4 D5 B0    call nz,display_error_text_B075
790A: 3E 02       ld   a,$08
790C: CD 5D B0    call schedule_task_to_start_B057
790F: 3E 03       ld   a,$09
7911: CD 5D B0    call schedule_task_to_start_B057
7914: 3E 0A       ld   a,$0A
7916: CD 5D B0    call schedule_task_to_start_B057
7919: 3E 0B       ld   a,$0B
791B: CD 5D B0    call schedule_task_to_start_B057
791E: 06 1E       ld   b,$1E
7920: C5          push bc
7921: 21 D8 D3    ld   hl,player_vs_player_str_7972
7924: CD 96 B0    call display_multicolor_text_B03C
7927: 3E 14       ld   a,$14
7929: CD 5A B0    call suspend_this_task_B05A
792C: 21 57 D3    ld   hl,spaces_str_795D
792F: 16 32       ld   d,$98
7931: CD 93 B0    call display_text_B039
7934: 3E 14       ld   a,$14
7936: CD 5A B0    call suspend_this_task_B05A
7939: C1          pop  bc
793A: 10 E4       djnz $7920
793C: 3E 02       ld   a,$08
793E: CD 54 B0    call resume_task_B054
7941: 3E 03       ld   a,$09
7943: CD 54 B0    call resume_task_B054
7946: 3E 0A       ld   a,$0A
7948: CD 54 B0    call resume_task_B054
794B: 3E 0B       ld   a,$0B
794D: CD 54 B0    call resume_task_B054
7950: 3E 01       ld   a,$01
7952: 47          ld   b,a
7953: CD 57 B0    call task_manipulation_B05D
7956: A7          and  a
7957: C4 D5 B0    call nz,display_error_text_B075
795A: CD 51 B0    call task_yield_B051
	; spaces
spaces_str_795D:
	dc.b	0x06,0x1c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; spaces_str_795D
	dc.b	0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c ; $7965
	dc.b	0x3c,0x3c,0x3c,0x3c,0xff ; $796d
	; "player vs player"
player_vs_player_str_7972:
	dc.b	0x06,0x1c,0x3c,0x98,0x19,0x98,0x15,0x98 ; player_vs_player_str_7972
	dc.b	0x0a,0x98,0x22,0x98,0x0e,0x98,0x1b,0x98 ; $797a
	dc.b	0x3c,0x98,0x1f,0x98,0x1c,0x98,0x3c,0x98 ; $7982
	dc.b	0x19,0x90,0x15,0x90,0x0a,0x90,0x22,0x90 ; $798a
	dc.b	0x0e,0x90,0x1b,0x90,0x3c,0x90,0xff ; $7992
	; "product of data east"
product_of_data_east_str_7999:
	dc.b	0x01,0x1f,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; product_of_data_east_str_7999
	dc.b	0x3c,0x98,0x3c,0x98,0x19,0x98,0x1b,0x98 ; $79a1
	dc.b	0x18,0x98,0x0d,0x98,0x1e,0x98,0x0c,0x98 ; $79a9
	dc.b	0x1d,0x98,0x3c,0x98,0x18,0x98,0x0f,0x98 ; $79b1
	dc.b	0x3c,0x98,0x0d,0x98,0x0a,0x98,0x1d,0x98 ; $79b9
	dc.b	0x0a,0x98,0x3c,0x98,0x0e,0x98,0x0a,0x98 ; $79c1
	dc.b	0x1c,0x98,0x1d,0x98,0x3c,0x98,0x3c,0x98 ; $79c9
	dc.b	0x3c,0x98,0x3c,0x98,0xff,0x01,0x06,0xff ; $79d1
; object appearing rate according to level
; max level is 24. 24/4 = 6 so more than half of the
; table isn't used
; maybe it's a remnant of the first version, where evade stages
; were twice as frequent
evade_object_period_table_79D9:
	dc.b	0x78,0x6e,0x64,0x5a,0x55,0x50,0x4b,0x46 ; evade_object_period_table_79D9
	dc.b	0x41,0x3c,0x37,0x37,0x37,0x37,0x37,0x37 ; $79e1
79E9: 21 08 6D    ld   hl,unknown_C702
79EC: 11 04 00    ld   de,$0004
79EF: 06 1E       ld   b,$1E
79F1: 3E 40       ld   a,$40
79F3: F5          push af
79F4: B6          or   (hl)
79F5: 77          ld   (hl),a
79F6: F1          pop  af
79F7: 19          add  hl,de
79F8: 10 F3       djnz $79F3
79FA: C9          ret
79FB: DD 21 82 6D ld   ix,unknown_C728
79FF: DD 72 00    ld   (ix+$00),d
7A02: DD 71 01    ld   (ix+$01),c
7A05: DD 36 08 05 ld   (ix+$02),$05
7A09: DD 73 09    ld   (ix+$03),e
7A0C: C5          push bc
7A0D: 01 04 00    ld   bc,$0004
7A10: DD 09       add  ix,bc
7A12: C1          pop  bc
7A13: 3E 10       ld   a,$10
7A15: 82          add  a,d
7A16: 57          ld   d,a
7A17: 0C          inc  c
7A18: 10 E5       djnz $79FF
7A1A: C9          ret
7A1B: 21 BE 6D    ld   hl,unknown_C7BE
7A1E: 11 04 00    ld   de,$0004
7A21: 06 0F       ld   b,$0F
7A23: 3E 40       ld   a,$40
7A25: F5          push af
7A26: B6          or   (hl)
7A27: 77          ld   (hl),a
7A28: F1          pop  af
7A29: 19          add  hl,de
7A2A: 10 F3       djnz $7A25
7A2C: C9          ret
7A2D: DD 21 60 6D ld   ix,unknown_C7C0
7A31: DD 72 00    ld   (ix+$00),d
7A34: DD 71 01    ld   (ix+$01),c
7A37: DD 36 08 05 ld   (ix+$02),$05
7A3B: DD 73 09    ld   (ix+$03),e
7A3E: C5          push bc
7A3F: 01 04 00    ld   bc,$0004
7A42: DD 09       add  ix,bc
7A44: C1          pop  bc
7A45: 3E 10       ld   a,$10
7A47: 82          add  a,d
7A48: 57          ld   d,a
7A49: 0C          inc  c
7A4A: 10 E5       djnz $7A31
7A4C: C9          ret
7A4D: 21 B6 6D    ld   hl,unknown_C7BC
7A50: 06 10       ld   b,$10
7A52: 36 00       ld   (hl),$00
7A54: 23          inc  hl
7A55: 10 FB       djnz $7A52
7A57: C9          ret

or_50_to_C7BE_7A58:
7A58: 21 BE 6D    ld   hl,unknown_C7BE
7A5B: 11 04 00    ld   de,$0004
7A5E: 06 04       ld   b,$04
7A60: 3E 50       ld   a,$50
7A62: F5          push af
7A63: B6          or   (hl)
7A64: 77          ld   (hl),a
7A65: F1          pop  af
7A66: 19          add  hl,de
7A67: 10 F3       djnz $7A62
7A69: C9          ret

7A6A: DD 21 60 6D ld   ix,unknown_C7C0
7A6E: DD 72 00    ld   (ix+$00),d
7A71: DD 71 01    ld   (ix+$01),c
7A74: DD 74 08    ld   (ix+$02),h
7A77: DD 73 09    ld   (ix+$03),e
7A7A: C5          push bc
7A7B: 01 04 00    ld   bc,$0004
7A7E: DD 09       add  ix,bc
7A80: C1          pop  bc
7A81: 3E 10       ld   a,$10
7A83: 82          add  a,d
7A84: 57          ld   d,a
7A85: 0C          inc  c
7A86: 10 EC       djnz $7A6E
7A88: C9          ret

7A89: DD 21 18 DB ld   ix,table_7B12
7A8D: 3A 11 63    ld   a,(background_and_state_bits_C911)
7A90: CB BF       res  7,a
7A92: FE 50       cp   $50
7A94: DA 32 DA    jp   c,$7A98
7A97: C9          ret
7A98: E6 0F       and  $0F
7A9A: 87          add  a,a
7A9B: 87          add  a,a
7A9C: 4F          ld   c,a
7A9D: 06 00       ld   b,$00
7A9F: DD 21 18 DB ld   ix,table_7B12
7AA3: DD 09       add  ix,bc
7AA5: DD 7E 00    ld   a,(ix+$00)
7AA8: DD A6 01    and  (ix+$01)
7AAB: FE FF       cp   $FF
7AAD: C8          ret  z
7AAE: DD 4E 00    ld   c,(ix+$00)
7AB1: DD 46 01    ld   b,(ix+$01)
7AB4: DD E5       push ix
7AB6: CD 90 B0    call fill_video_and_attribute_memory_B030
7AB9: DD E1       pop  ix
7ABB: DD 6E 08    ld   l,(ix+$02)
7ABE: DD 66 09    ld   h,(ix+$03)
7AC1: 7E          ld   a,(hl)
7AC2: 23          inc  hl
7AC3: A6          and  (hl)
7AC4: FE FF       cp   $FF
7AC6: C8          ret  z
7AC7: 2B          dec  hl
7AC8: E5          push hl
7AC9: 5E          ld   e,(hl)
7ACA: 23          inc  hl
7ACB: 56          ld   d,(hl)
7ACC: EB          ex   de,hl
7ACD: CD 96 B0    call display_multicolor_text_B03C
7AD0: E1          pop  hl
7AD1: 23          inc  hl
7AD2: 23          inc  hl
7AD3: C3 61 DA    jp   $7AC1
7AD6: 3A 98 60    ld   a,(unknown_C032)
7AD9: CB 4F       bit  1,a
7ADB: C8          ret  z
7ADC: 3A 11 63    ld   a,(background_and_state_bits_C911)
7ADF: FE 54       cp   $54
7AE1: CA EE DA    jp   z,$7AEE
7AE4: FE 59       cp   $53
7AE6: CA EE DA    jp   z,$7AEE
7AE9: CD B1 B0    call is_title_screen_demo_mode_B0B1
7AEC: A7          and  a
7AED: C8          ret  z
7AEE: 01 0C 14    ld   bc,$1406
7AF1: 21 08 DB    ld   hl,two_p_color_text_7B02
7AF4: C5          push bc
7AF5: CD 96 B0    call display_multicolor_text_B03C
7AF8: C1          pop  bc
7AF9: 21 70 60    ld   hl,unknown_C0D0
7AFC: 16 32       ld   d,$98
7AFE: CD 9F B0    call display_text_color_2_B03F
7B01: C9          ret
two_p_color_text_7B02:
	dc.b	0x14,0x05,0x02,0x98,0x1e,0x98,0x19,0x98 ; two_p_color_text_7B02
	dc.b	0xfe,0x18,0x06,0x00,0x98,0x00,0x98,0xff ; $7b0a
table_7B12:
	dc.b	0x3f,0x90,0x4a,0x7b,0x3d,0xa0,0x50,0x7b ; table_7B12
	dc.b	0x31,0xa4,0x56,0x7b,0x3c,0xf8,0x5c,0x7b ; $7b1a
	dc.b	0x3c,0xf8,0x80,0x7b,0x3f,0xd8,0x62,0x7b ; $7b22
	dc.b	0x3d,0x98,0x68,0x7b,0x3e,0xf8,0x6e,0x7b ; $7b2a
	dc.b	0x3c,0xf8,0x74,0x7b,0x3e,0xf8,0x7a,0x7b ; $7b32
	dc.b	0x3d,0xc6,0x86,0x7b,0x3d,0xf0,0x8c,0x7b ; $7b3a
	dc.b	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff ; $7b42
	dc.b	0x16,0x81,0x36,0x7d,0xff,0xff,0xae,0x7e ; $7b4a
	dc.b	0x36,0x7d,0xff,0xff,0xe9,0x83,0x36,0x7d ; $7b52
	dc.b	0xff,0xff,0x4a,0x87,0x36,0x7d,0xff,0xff ; $7b5a
	dc.b	0xf0,0x89,0x36,0x7d,0xff,0xff,0x78,0x8c ; $7b62
	dc.b	0x36,0x7d,0xff,0xff,0x49,0x8e,0x36,0x7d ; $7b6a
	dc.b	0xff,0xff,0x81,0x91,0x36,0x7d,0xff,0xff ; $7b72
	dc.b	0x4b,0x94,0x36,0x7d,0xff,0xff,0x1a,0x97 ; $7b7a
	dc.b	0x36,0x7d,0xff,0xff,0x9f,0x99,0x36,0x7d ; $7b82
	dc.b	0xff,0xff,0xb8,0x9c,0x36,0x7d,0xff,0xff ; $7b8a
display_start_message_7b92:
7B92: 3A 84 60    ld   a,(nb_credits_minus_one_C024)
7B95: 21 AC DB    ld   hl,start_1P_message_7BA6
7B98: FE 00       cp   $00
7B9A: CA A0 DB    jp   z,$7BA0
7B9D: 21 6A DB    ld   hl,start_2P_message_7BCA
7BA0: 16 32       ld   d,$98
7BA2: CD 93 B0    call display_text_B039
7BA5: C9          ret
start_1P_message_7BA6:
	dc.b	0x05,0x0a,0x19,0x1b,0x0e,0x1c,0x1c,0x3c ; table_7BA6
	dc.b	0x01,0x19,0x3c,0x0b,0x1e,0x1d,0x1d,0x18 ; $7bae
	dc.b	0x17,0x3c,0x0f,0x18,0x1b,0xfe,0x09,0x0c ; $7bb6
	dc.b	0x1c,0x12,0x17,0x10,0x15,0x0e,0x3c,0x19 ; $7bbe
	dc.b	0x15,0x0a,0x22,0xff ; $7bc6
start_2P_message_7BCA:
	dc.b	0x05,0x0a,0x19,0x1b,0x0e,0x1c,0x1c,0x3c ; table_7BCA
	dc.b	0x01,0x19,0x3c,0x0b,0x1e,0x1d,0x1d,0x18 ; $7bd2
	dc.b	0x17,0x3c,0x0f,0x18,0x1b,0xfe,0x09,0x0c ; $7bda
	dc.b	0x1c,0x12,0x17,0x10,0x15,0x0e,0x3c,0x19 ; $7be2
	dc.b	0x15,0x0a,0x22,0xfe,0x05,0x0e,0x19,0x1b ; $7bea
	dc.b	0x0e,0x1c,0x1c,0x3c,0x02,0x19,0x3c,0x0b ; $7bf2
	dc.b	0x1e,0x1d,0x1d,0x18,0x17,0x3c,0x0f,0x18 ; $7bfa
	dc.b	0x1b,0xfe,0x04,0x10,0x0f,0x12,0x10,0x11 ; $7c02
	dc.b	0x1d,0x3c,0x0b,0x0e,0x1d,0x20,0x0e,0x0e ; $7c0a
	dc.b	0x17,0x3c,0x19,0x15,0x0a,0x22,0x0e,0x1b ; $7c12
	dc.b	0x1c,0xff ; $7c1a

display_credits_7C1C:
7C1C: 21 54 D6    ld   hl,credit_text_7C54
7C1F: 16 32       ld   d,$98
7C21: CD 93 B0    call display_text_B039
7C24: 21 16 1F    ld   hl,$1F1C
7C27: 22 00 6F    ld   (temp_numeric_buffer_CF00),hl
; at least during "press 1P button" screen
; check number of credits, maybe to display them
; as there's a "daa" instruction (bcd conversion)
7C2A: 3A 84 60    ld   a,(nb_credits_minus_one_C024)
7C2D: C6 01       add  a,$01
7C2F: 27          daa
7C30: 47          ld   b,a
7C31: DD 21 00 6F ld   ix,temp_numeric_buffer_CF00
7C35: E6 0F       and  $0F
7C37: DD 77 09    ld   (ix+$03),a
7C3A: 78          ld   a,b
7C3B: CB 3F       srl  a
7C3D: CB 3F       srl  a
7C3F: CB 3F       srl  a
7C41: CB 3F       srl  a
7C43: DD 77 08    ld   (ix+$02),a
7C46: 3E FF       ld   a,$FF
7C48: DD 77 04    ld   (ix+$04),a
7C4B: 21 00 6F    ld   hl,temp_numeric_buffer_CF00
7C4E: 16 32       ld   d,$98
7C50: CD 93 B0    call display_text_B039
7C53: C9          ret
credit_text_7C54:
	dc.b	0x15,0x1f,0x0c,0x1b,0x0e,0x0d,0x12,0x1d ; credit_7C54
	dc.b	0xff ; $7c5c
7C5D: 3A 11 63    ld   a,(background_and_state_bits_C911)
7C60: FE 54       cp   $54
7C62: 3E 08       ld   a,$02
7C64: CA D2 D6    jp   z,$7C78
7C67: 3A 11 63    ld   a,(background_and_state_bits_C911)
7C6A: FE 59       cp   $53
7C6C: 3E 08       ld   a,$02
7C6E: CA D2 D6    jp   z,$7C78
7C71: CD B1 B0    call is_title_screen_demo_mode_B0B1
7C74: A7          and  a
7C75: CC 51 B0    call z,task_yield_B051
7C78: 3D          dec  a
7C79: 87          add  a,a
7C7A: 4F          ld   c,a
7C7B: 06 00       ld   b,$00
7C7D: DD 21 0C D7 ld   ix,table_7D06
7C81: DD 09       add  ix,bc
7C83: DD 6E 00    ld   l,(ix+$00)
7C86: DD 66 01    ld   h,(ix+$01)
7C89: E5          push hl
7C8A: 01 04 00    ld   bc,$0004
7C8D: 09          add  hl,bc
7C8E: E5          push hl
7C8F: FD E1       pop  iy
7C91: E1          pop  hl
7C92: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
7C95: CB 57       bit  2,a
7C97: C2 3E D6    jp   nz,$7C9E
7C9A: 01 04 00    ld   bc,$0004
7C9D: 09          add  hl,bc
7C9E: E5          push hl
7C9F: DD E1       pop  ix
7CA1: DD E5       push ix
7CA3: FD E5       push iy
7CA5: DD 6E 00    ld   l,(ix+$00)
7CA8: DD 66 01    ld   h,(ix+$01)
7CAB: CD 96 B0    call display_multicolor_text_B03C
7CAE: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
7CB1: E6 06       and  $0C
7CB3: FE 06       cp   $0C
7CB5: C2 61 D6    jp   nz,$7CC1
7CB8: FD 6E 00    ld   l,(iy+$00)
7CBB: FD 66 01    ld   h,(iy+$01)
7CBE: CD 96 B0    call display_multicolor_text_B03C
7CC1: 3E 82       ld   a,$28
7CC3: CD 5A B0    call suspend_this_task_B05A
7CC6: FD E1       pop  iy
7CC8: DD E1       pop  ix
7CCA: A7          and  a
7CCB: C2 FA D6    jp   nz,$7CFA
7CCE: DD E5       push ix
7CD0: FD E5       push iy
7CD2: DD 6E 08    ld   l,(ix+$02)
7CD5: DD 66 09    ld   h,(ix+$03)
7CD8: CD 96 B0    call display_multicolor_text_B03C
7CDB: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
7CDE: E6 06       and  $0C
7CE0: FE 06       cp   $0C
7CE2: C2 EE D6    jp   nz,$7CEE
7CE5: FD 6E 08    ld   l,(iy+$02)
7CE8: FD 66 09    ld   h,(iy+$03)
7CEB: CD 96 B0    call display_multicolor_text_B03C
7CEE: 3E 82       ld   a,$28
7CF0: CD 5A B0    call suspend_this_task_B05A
7CF3: FD E1       pop  iy
7CF5: DD E1       pop  ix
7CF7: C3 A1 D6    jp   $7CA1
7CFA: DD E5       push ix
7CFC: 3E 00       ld   a,$00
7CFE: CD 5A B0    call suspend_this_task_B05A
7D01: DD E1       pop  ix
7D03: C3 A1 D6    jp   $7CA1
	dc.b	0x69,0xa1,0x7c
table_7D06:
	dc.w	table_7d0a ; $7d06
	dc.w	table_7d0a ; $7d08
table_7d0a:
	dc.w	table_7d12 ; $7d0a
	dc.w	table_7d1b ; $7d0c
	dc.w	table_7d24 ; $7d0e
	dc.w	table_7d2d ; $7d10
table_7d12:
	; 1UP
	dc.b	0x14,0x03,0x01,0x98,0x1e,0x98,0x19,0x98 ; $7d12
	dc.b	0xff ; $7d1a
table_7d1b:
	dc.b	0x14,0x03,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; $7d1b
	dc.b	0xff ; $7d23
table_7d24:
	; 2UP
	dc.b	0x14,0x05,0x02,0x98,0x1e,0x98,0x19,0x98 ; $7d24
	dc.b	0xff ; $7d2c
table_7d2d:
	dc.b	0x14,0x05,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; $7d2d
	dc.b	0xff ; $7d35
table_7D36:
	dc.b	0x05,0x00,0xc6,0x90,0xc7,0x90,0xc8,0x90 ; table_7D36
	dc.b	0xc8,0x90,0xc8,0x90,0xc8,0x90,0xc8,0x90 ; $7d3e
	dc.b	0xc9,0x90,0xca,0x90,0x1b,0x91,0x1b,0x91 ; $7d46
	dc.b	0x1b,0x91,0x1b,0x91,0xcb,0x90,0xc8,0x90 ; $7d4e
	dc.b	0xc8,0x90,0xc8,0x90,0xc8,0x90,0xc8,0x90 ; $7d56
	dc.b	0xc8,0x90,0xc9,0x90,0xcc,0x90,0xfe,0x05 ; $7d5e
	dc.b	0x01,0xcd,0x90,0xce,0x98,0xcf,0x98,0x3c ; $7d66
	dc.b	0x98,0x3c,0x98,0x3c,0x98,0xce,0x90,0xcf ; $7d6e
	dc.b	0x90,0xd0,0x90,0xd1,0x90,0xd2,0x90,0xd6 ; $7d76
	dc.b	0x90,0xd6,0x90,0xe4,0x90,0x11,0x98,0x12 ; $7d7e
	dc.b	0x98,0x1c,0x98,0x0c,0x98,0x18,0x98,0x1b ; $7d86
	dc.b	0x98,0x0e,0x98,0xe5,0x90,0xfe,0x05,0x02 ; $7d8e
	dc.b	0xcd,0x90,0xd3,0x10,0xd3,0x10,0xd4,0x98 ; $7d96
	dc.b	0xd5,0x98,0xb3,0x9a,0xd3,0x10,0xd3,0x10 ; $7d9e
	dc.b	0xd0,0x90,0xd6,0x90,0xd6,0x90,0xd6,0x90 ; $7da6
	dc.b	0xd6,0x90,0xe4,0x90,0x3c,0x98,0x3c,0x98 ; $7dae
	dc.b	0x02,0x98,0x00,0x98,0x00,0x98,0x00,0x98 ; $7db6
	dc.b	0x00,0x98,0xe5,0x90,0xfe,0x05,0x03,0xcd ; $7dbe
	dc.b	0x90,0x3c,0x98,0xd3,0x10,0xd8,0x98,0xd9 ; $7dc6
	dc.b	0x98,0xda,0x98,0xd3,0x10,0x3c,0x98,0xd0 ; $7dce
	dc.b	0x90,0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c ; $7dd6
	dc.b	0x98,0xe4,0x90,0x3c,0x98,0x01,0x98,0x1e ; $7dde
	dc.b	0x98,0x19,0x98,0x3c,0x98,0x3c,0x98,0x3c ; $7de6
	dc.b	0x98,0xe5,0x90,0xfe,0x05,0x04,0xdb,0x90 ; $7dee
	dc.b	0xdc,0x90,0xdd,0x90,0xdd,0x90,0xdd,0x90 ; $7df6
	dc.b	0xdd,0x90,0xdd,0x90,0xde,0x90,0xdf,0x90 ; $7dfe
	dc.b	0x1d,0x20,0x12,0x20,0x16,0x20,0x0e,0x20 ; $7e06
	dc.b	0xe4,0x90,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; $7e0e
	dc.b	0x3c,0x98,0x3c,0x98,0x00,0x98,0x00,0x98 ; $7e16
	dc.b	0xe5,0x90,0xfe,0x05,0x05,0x38,0x90,0x3c ; $7e1e
	dc.b	0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c ; $7e26
	dc.b	0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c ; $7e2e
	dc.b	0x20,0x03,0x98,0x00,0x98,0x3c,0x20,0xe4 ; $7e36
	dc.b	0x90,0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c ; $7e3e
	dc.b	0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98,0xe5 ; $7e46
	dc.b	0x90,0xfe,0x05,0x06,0x38,0x90,0x3c,0x98 ; $7e4e
	dc.b	0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; $7e56
	dc.b	0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c,0x20 ; $7e5e
	dc.b	0x3c,0x20,0x3c,0x20,0x3c,0x20,0xe4,0x90 ; $7e66
	dc.b	0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; $7e6e
	dc.b	0x3c,0x98,0x3c,0x98,0x3c,0x98,0xe5,0x90 ; $7e76
	dc.b	0xfe,0x05,0x07,0x39,0x90,0x3a,0x90,0x3a ; $7e7e
	dc.b	0x90,0x3a,0x90,0x3a,0x90,0x3a,0x90,0x3a ; $7e86
	dc.b	0x90,0x3a,0x90,0x3a,0x90,0x4a,0x90,0x4a ; $7e8e
	dc.b	0x90,0x4a,0x90,0x4a,0x90,0xeb,0x90,0xec ; $7e96
	dc.b	0x90,0xec,0x90,0xec,0x90,0xec,0x90,0xec ; $7e9e
	dc.b	0x90,0xec,0x90,0xed,0x90,0xee,0x90,0xff ; $7ea6
	dc.b	0x02,0x00,0x3d,0x28,0x3d,0x28,0x3d,0x28 ; $7eae
	dc.b	0xfe,0x1b,0x00,0x3d,0x28,0x3d,0x28,0x3d ; $7eb6
	dc.b	0x28,0xfe,0x02,0x01,0x3d,0x28,0x3d,0x28 ; $7ebe
	dc.b	0x3d,0x28,0xfe,0x1b,0x01,0x3d,0x28,0x3d ; $7ec6
	dc.b	0x28,0x3d,0x28,0xfe,0x02,0x02,0x3f,0x5b ; $7ece
	dc.b	0x3f,0x5b,0x3f,0x5b,0xfe,0x1b,0x02,0x3f ; $7ed6
	dc.b	0x5b,0x3f,0x5b,0x3f,0x5b,0xfe,0x02,0x03 ; $7ede
	dc.b	0x40,0x5b,0x40,0x5b,0x40,0x5b,0xfe,0x1b ; $7ee6
	dc.b	0x03,0x40,0x5b,0x40,0x5b,0x40,0x5b,0xfe ; $7eee
	dc.b	0x02,0x04,0x41,0x03,0x42,0x03,0x41,0x03 ; $7ef6
	dc.b	0xfe,0x1b,0x04,0x42,0x03,0x41,0x03,0x42 ; $7efe
	dc.b	0x03,0xfe,0x02,0x05,0x41,0x03,0x42,0x03 ; $7f06
	dc.b	0x41,0x03,0xfe,0x1b,0x05,0x42,0x03,0x41 ; $7f0e
	dc.b	0x03,0x42,0x03,0xfe,0x02,0x06,0x41,0x03 ; $7f16
	dc.b	0x42,0x03,0x41,0x03,0xfe,0x1b,0x06,0x42 ; $7f1e
	dc.b	0x03,0x41,0x03,0x42,0x03,0xfe,0x02,0x07 ; $7f26
	dc.b	0x41,0x03,0x42,0x03,0x41,0x03,0xfe,0x1b ; $7f2e
	dc.b	0x07,0x42,0x03,0x41,0x03,0x42,0x03,0xfe ; $7f36
	dc.b	0x02,0x08,0x41,0x03,0x42,0x03,0x41,0x03 ; $7f3e
	dc.b	0x42,0x03,0x41,0x03,0x42,0x03,0x41,0x03 ; $7f46
	dc.b	0x41,0x03,0x3c,0x00,0x3c,0x00,0x3c,0x00 ; $7f4e
	dc.b	0x3c,0x03,0x43,0x03,0x42,0x03,0x41,0x03 ; $7f56
	dc.b	0x42,0x03,0x41,0x03,0x42,0x03,0x41,0x03 ; $7f5e
	dc.b	0x42,0x03,0x41,0x03,0x42,0x03,0x41,0x03 ; $7f66
	dc.b	0x42,0x03,0x41,0x03,0x42,0x03,0x41,0x03 ; $7f6e
	dc.b	0x42,0x03,0xfe,0x02,0x09,0x41,0x03,0x42 ; $7f76
	dc.b	0x03,0x41,0x03,0x42,0x03,0x41,0x03,0x42 ; $7f7e
	dc.b	0x03,0x41,0x03,0x41,0x03,0x3c,0x00,0x3c ; $7f86
	dc.b	0x00,0x3c,0x00,0x3c,0x03,0x43,0x03,0x42 ; $7f8e
	dc.b	0x03,0x41,0x03,0x42,0x03,0x41,0x03,0x42 ; $7f96
	dc.b	0x03,0x41,0x03,0x42,0x03,0x41,0x03,0x42 ; $7f9e
	dc.b	0x03,0x41,0x03,0x42,0x03,0x41,0x03,0x42 ; $7fa6
	dc.b	0x03,0x41,0x03,0x42,0x03,0xfe,0x02,0x0a ; $7fae
	dc.b	0x41,0x03,0x42,0x03,0x41,0x03,0x42,0x03 ; $7fb6
	dc.b	0x41,0x03,0x42,0x03,0x41,0x03,0x41,0x03 ; $7fbe
	dc.b	0x3c,0x00,0x3c,0x00,0x3c,0x00,0x3c,0x03 ; $7fc6
	dc.b	0x43,0x03,0x42,0x03,0x41,0x03,0x42,0x03 ; $7fce
	dc.b	0x41,0x03,0x42,0x03,0x41,0x03,0x42,0x03 ; $7fd6
	dc.b	0x41,0x03,0x42,0x03,0x41,0x03,0x42,0x03 ; $7fde
	dc.b	0x41,0x03,0x42,0x03,0x41,0x03,0x42,0x03 ; $7fe6
	dc.b	0xfe,0x02,0x0b,0x41,0x03,0x42,0x03,0x41 ; $7fee
	dc.b	0x03,0x42,0x03,0x41,0x03,0x42,0x03,0x41 ; $7ff6
	dc.b	0x03,0x41,0x03,0x3c,0x00,0x3c,0x00,0x3c ; $7ffe
	dc.b	0x00,0x3c,0x03,0x43,0x03,0x42,0x03,0x41 ; $8006
	dc.b	0x03,0x42,0x03,0x41,0x03,0x42,0x03,0x41 ; $800e
	dc.b	0x03,0x42,0x03,0x41,0x03,0x42,0x03,0x41 ; $8016
	dc.b	0x03,0x42,0x03,0x41,0x03,0x42,0x03,0x41 ; $801e
	dc.b	0x03,0x42,0x03,0xfe,0x02,0x0c,0x3d,0x5b ; $8026
	dc.b	0x3f,0x5b,0x3f,0x5b,0x3f,0x5b,0x3f,0x5b ; $802e
	dc.b	0x3f,0x5b,0x3f,0x5b,0x3f,0x5b,0x3c,0x00 ; $8036
	dc.b	0x3c,0x00,0x3c,0x00,0x3c,0x03,0x3d,0x5b ; $803e
	dc.b	0x3f,0x5b,0x3f,0x5b,0x3f,0x5b,0x3f,0x5b ; $8046
	dc.b	0x3f,0x5b,0x3f,0x5b,0x3f,0x5b,0x3f,0x5b ; $804e
	dc.b	0x3f,0x5b,0x3d,0x5b,0x3f,0x5b,0x3f,0x5b ; $8056
	dc.b	0x3f,0x5b,0x3f,0x5b,0x3f,0x5b,0xfe,0x02 ; $805e
	dc.b	0x0d,0x3e,0x5b,0x40,0x5b,0x40,0x5b,0x40 ; $8066
	dc.b	0x5b,0x40,0x5b,0x40,0x5b,0x40,0x5b,0x40 ; $806e
	dc.b	0x5b,0x3c,0x00,0x3c,0x00,0x3c,0x00,0x3c ; $8076
	dc.b	0x03,0x3e,0x5b,0x40,0x5b,0x40,0x5b,0x40 ; $807e
	dc.b	0x5b,0x40,0x5b,0x40,0x5b,0x40,0x5b,0x40 ; $8086
	dc.b	0x5b,0x40,0x5b,0x40,0x5b,0x3e,0x5b,0x40 ; $808e
	dc.b	0x5b,0x40,0x5b,0x40,0x5b,0x40,0x5b,0x40 ; $8096
	dc.b	0x5b,0xfe,0x02,0x0e,0x3d,0x28,0x3d,0x28 ; $809e
	dc.b	0x3d,0x28,0x3d,0x28,0x3d,0x28,0x3d,0x28 ; $80a6
	dc.b	0x3d,0x28,0x3d,0x28,0x3a,0x2b,0x3a,0x2b ; $80ae
	dc.b	0x3a,0x2b,0x3b,0x2b,0x3d,0x28,0x3d,0x28 ; $80b6
	dc.b	0x3d,0x28,0x3d,0x28,0x3d,0x28,0x3d,0x28 ; $80be
	dc.b	0x3d,0x28,0x3d,0x28,0x3d,0x28,0x3d,0x28 ; $80c6
	dc.b	0x3d,0x28,0x3d,0x28,0x3d,0x28,0x3d,0x28 ; $80ce
	dc.b	0x3d,0x28,0x3d,0x28,0xfe,0x02,0x0f,0x3d ; $80d6
	dc.b	0x28,0x3d,0x28,0x3d,0x28,0x3d,0x28,0x3d ; $80de
	dc.b	0x28,0x3d,0x28,0x3d,0x28,0x3d,0x28,0x3d ; $80e6
	dc.b	0x28,0x3d,0x28,0x3d,0x28,0x3d,0x28,0x3d ; $80ee
	dc.b	0x28,0x3d,0x28,0x3d,0x28,0x3d,0x28,0x3d ; $80f6
	dc.b	0x28,0x3d,0x28,0x3d,0x28,0x3d,0x28,0x3d ; $80fe
	dc.b	0x28,0x3d,0x28,0x3d,0x28,0x3d,0x28,0x3d ; $8106
	dc.b	0x28,0x3d,0x28,0x3d,0x28,0x3d,0x28,0xff ; $810e
	dc.b	0x05,0x09,0x63,0x8b,0x3f,0x88,0x64,0x8b ; $8116
	dc.b	0xfe,0x03,0x0a,0x63,0x8b,0x3f,0x88,0x3f ; $811e
	dc.b	0x88,0x3f,0x88,0x3f,0x88,0x3f,0x88,0x64 ; $8126
	dc.b	0x8b,0xfe,0x02,0x0b,0x63,0x8b,0x3f,0x88 ; $812e
	dc.b	0x3f,0x88,0x3f,0x88,0x3f,0x88,0x3f,0x88 ; $8136
	dc.b	0x3f,0x88,0x3f,0x88,0x3f,0x88,0x64,0x8b ; $813e
	dc.b	0xfe,0x02,0x0c,0x65,0x8b,0x3f,0x88,0x3f ; $8146
	dc.b	0x88,0x3f,0x88,0x3f,0x88,0x3f,0x88,0x3f ; $814e
	dc.b	0x88,0x3f,0x88,0x3f,0x88,0x66,0x8b,0xfe ; $8156
	dc.b	0x04,0x0d,0x65,0x8b,0x3f,0x88,0x3f,0x88 ; $815e
	dc.b	0x66,0x8b,0x65,0x8b,0x3f,0x88,0x66,0x8b ; $8166
	dc.b	0xfe,0x0e,0x0c,0x63,0x8b,0x3f,0x88,0x3f ; $816e
	dc.b	0x88,0x64,0x8b,0xfe,0x0d,0x0d,0x63,0x8b ; $8176
	dc.b	0x3f,0x88,0x3f,0x88,0x3f,0x88,0x66,0x8b ; $817e
	dc.b	0xfe,0x0d,0x0e,0x65,0x8b,0x66,0x8b,0x65 ; $8186
	dc.b	0x8b,0x66,0x8b,0xfe,0x16,0x0d,0x5b,0xdb ; $818e
	dc.b	0x5b,0xdb,0x5b,0xdb,0x5b,0xdb,0x5b,0xdb ; $8196
	dc.b	0x5b,0xdb,0x5b,0xdb,0x5b,0xdb,0xfe,0x15 ; $819e
	dc.b	0x0e,0x50,0xdb,0x5c,0x7b,0x4f,0x7b,0x5c ; $81a6
	dc.b	0x7b,0x4f,0x7b,0x4f,0x7b,0x4f,0x7b,0x5c ; $81ae
	dc.b	0x7b,0x4f,0x7b,0xfe,0x14,0x0f,0x51,0xdb ; $81b6
	dc.b	0x4f,0x7b,0x5c,0x7b,0x4f,0x7b,0x4f,0x7b ; $81be
	dc.b	0x5c,0x7b,0x4f,0x7b,0x4f,0x7b,0x4f,0x7b ; $81c6
	dc.b	0x5c,0x7b,0xfe,0x15,0x10,0x52,0xdb,0x4f ; $81ce
	dc.b	0x7b,0x55,0xa3,0x57,0xa3,0x4f,0x7b,0x5c ; $81d6
	dc.b	0x7b,0x55,0xa3,0x57,0xa3,0x55,0xa3,0xfe ; $81de
	dc.b	0x16,0x11,0x52,0xdb,0x69,0x9b,0x62,0x9b ; $81e6
	dc.b	0x57,0xa3,0x55,0xa3,0x3f,0xa0,0x61,0x9b ; $81ee
	dc.b	0x62,0x9b,0xfe,0x17,0x12,0x67,0x63,0x69 ; $81f6
	dc.b	0x9b,0x3f,0xa0,0x3f,0xa0,0x62,0x9b,0x61 ; $81fe
	dc.b	0x9b,0x3f,0xa0,0xfe,0x18,0x13,0x5d,0x63 ; $8206
	dc.b	0x69,0x9b,0x61,0x9b,0x3f,0xa0,0x62,0x9b ; $820e
	dc.b	0x59,0xa3,0xfe,0x18,0x14,0x5e,0x63,0x6a ; $8216
	dc.b	0x9b,0x61,0x9b,0x3f,0xa0,0x58,0xa3,0x5c ; $821e
	dc.b	0x7b,0xfe,0x18,0x15,0x5f,0x63,0x69,0x9b ; $8226
	dc.b	0x59,0xa3,0x5a,0xa3,0x4f,0x7b,0x5c,0x7b ; $822e
	dc.b	0xfe,0x18,0x16,0x60,0x63,0x58,0x7b,0x4f ; $8236
	dc.b	0x7b,0x5c,0x7b,0x5c,0x7b,0x4f,0x7b,0xfe ; $823e
	dc.b	0x18,0x17,0x5d,0x63,0x57,0x7b,0x5c,0x7b ; $8246
	dc.b	0x4f,0x7b,0x4f,0x7b,0x5c,0x7b,0xfe,0x02 ; $824e
	dc.b	0x16,0x5b,0xdb,0x5b,0xdb,0xfe,0x02,0x17 ; $8256
	dc.b	0x4f,0x7b,0x4f,0x7b,0x53,0xdb,0xfe,0x02 ; $825e
	dc.b	0x18,0x44,0x7b,0x4d,0x9b,0x4e,0x9b,0x3f ; $8266
	dc.b	0x98,0x3f,0x98,0x4e,0x9b,0x4e,0x9b,0x3f ; $826e
	dc.b	0x98,0x4e,0x9b,0x4e,0x9b,0x3f,0x98,0x4e ; $8276
	dc.b	0x9b,0x3f,0x98,0x4d,0x9b,0x3f,0x98,0x3f ; $827e
	dc.b	0x98,0x4e,0x9b,0x4e,0x9b,0x4e,0x9b,0x3f ; $8286
	dc.b	0x98,0x3f,0x98,0x4e,0x9b,0x3f,0x98,0x4e ; $828e
	dc.b	0x9b,0x3f,0x98,0x4e,0x9b,0x4e,0x9b,0x46 ; $8296
	dc.b	0x7b,0xfe,0x02,0x19,0x4c,0x9b,0x4d,0x9b ; $829e
	dc.b	0x4c,0x9b,0x4d,0x9b,0x4c,0x9b,0x4d,0x9b ; $82a6
	dc.b	0x4c,0x9b,0x4d,0x9b,0x4c,0x9b,0x4c,0x9b ; $82ae
	dc.b	0x4d,0x9b,0x4d,0x9b,0x4c,0x9b,0x4d,0x9b ; $82b6
	dc.b	0x4c,0x9b,0x4d,0x9b,0x4d,0x9b,0x4d,0x9b ; $82be
	dc.b	0x4d,0x9b,0x4d,0x9b,0x4c,0x9b,0x4c,0x9b ; $82c6
	dc.b	0x4d,0x9b,0x4d,0x9b,0x4c,0x9b,0x4d,0x9b ; $82ce
	dc.b	0x4c,0x9b,0x4c,0x9b,0xfe,0x02,0x1a,0x4a ; $82d6
	dc.b	0x9b,0x4b,0x9b,0x4a,0x9b,0x4b,0x9b,0x4a ; $82de
	dc.b	0x9b,0x4b,0x9b,0x4a,0x9b,0x4a,0x9b,0x4a ; $82e6
	dc.b	0x9b,0x4b,0x9b,0x4b,0x9b,0x4b,0x9b,0x4a ; $82ee
	dc.b	0x9b,0x4b,0x9b,0x4b,0x9b,0x4a,0x9b,0x4a ; $82f6
	dc.b	0x9b,0x4b,0x9b,0x4b,0x9b,0x4a,0x9b,0x4b ; $82fe
	dc.b	0x9b,0x4a,0x9b,0x4b,0x9b,0x4b,0x9b,0x4b ; $8306
	dc.b	0x9b,0x4a,0x9b,0x4a,0x9b,0x4b,0x9b,0xfe ; $830e
	dc.b	0x02,0x1b,0x45,0x53,0x48,0x9b,0x49,0x9b ; $8316
	dc.b	0x49,0x9b,0x49,0x9b,0x48,0x9b,0x48,0x9b ; $831e
	dc.b	0x48,0x9b,0x49,0x9b,0x49,0x9b,0x48,0x9b ; $8326
	dc.b	0x49,0x9b,0x48,0x9b,0x49,0x9b,0x49,0x9b ; $832e
	dc.b	0x49,0x9b,0x48,0x9b,0x48,0x9b,0x49,0x9b ; $8336
	dc.b	0x48,0x9b,0x49,0x9b,0x48,0x9b,0x48,0x9b ; $833e
	dc.b	0x49,0x9b,0x49,0x9b,0x48,0x9b,0x49,0x9b ; $8346
	dc.b	0x47,0x53,0xfe,0x02,0x1c,0x4f,0x7b,0x4f ; $834e
	dc.b	0x7b,0x4f,0x7b,0x4f,0x7b,0x4f,0x7b,0x53 ; $8356
	dc.b	0xdb,0xfe,0x16,0x1c,0x50,0xdb,0x4f,0x7b ; $835e
	dc.b	0x4f,0x7b,0x5c,0x7b,0x4f,0x7b,0x5c,0x7b ; $8366
	dc.b	0x4f,0x7b,0x4f,0x7b,0xfe,0x02,0x1d,0x4f ; $836e
	dc.b	0x7b,0x5c,0x7b,0x4f,0x7b,0x4f,0x7b,0x5c ; $8376
	dc.b	0x7b,0x4f,0x7b,0x53 ; $837e
table_8382:
	dc.b	0xdb,0xfe,0x15,0x1d,0x50,0xdb,0x4f,0x7b ; table_8382
	dc.b	0x5c,0x7b,0x5c,0x7b,0x4f,0x7b,0x5c,0x7b ; $838a
	dc.b	0x4f,0x7b,0x5c,0x7b,0x4f,0x7b,0xfe,0x02 ; $8392
	dc.b	0x1e,0x4f,0x7b,0x4f,0x7b,0x4f,0x7b,0x5c ; $839a
	dc.b	0x7b,0x4f,0x7b,0x5c,0x7b,0x4f,0x7b,0x54 ; $83a2
	dc.b	0xdb,0xfe,0x15,0x1e,0x52,0xdb,0x5c,0x7b ; $83aa
	dc.b	0x4f,0x7b,0x4f,0x7b,0x5c,0x7b,0x4f,0x7b ; $83b2
	dc.b	0x5c,0x7b,0x4f,0x7b,0x4f,0x7b,0xfe,0x02 ; $83ba
	dc.b	0x1f,0x4f,0x7b,0x5c,0x7b,0x4f,0x7b,0x4f ; $83c2
	dc.b	0x7b,0x5c,0x7b,0x4f,0x7b,0x5c,0x7b,0x53 ; $83ca
	dc.b	0xdb,0xfe,0x15,0x1f,0x50,0xdb,0x4f,0x7b ; $83d2
	dc.b	0x5c,0x7b,0x4f,0x7b,0x4f,0x7b,0x4f,0x7b ; $83da
	dc.b	0x4f,0x7b,0x4f,0x7b,0x4f,0x7b,0xff ; $83e2
table_83e9:
	dc.b	0x02,0x00,0x2f,0x0c,0x23,0x0c,0x30,0x0c ; $83e9
	dc.b	0xfe,0x02,0x01,0x31,0xa4,0x24,0x0c,0x29 ; $83f1
	dc.b	0x0c,0xfe,0x02,0x02,0x31,0xa4,0x24,0x0c ; $83f9
	dc.b	0x2b,0x0c,0xfe,0x02,0x03,0x2e,0x0c,0x24 ; $8401
	dc.b	0x0c,0x2a,0x0c,0xfe,0x02,0x04,0x30,0x0c ; $8409
	dc.b	0x23,0x0c,0x2c,0x0c,0xfe,0x02,0x05,0x29 ; $8411
	dc.b	0x0c,0x24,0x0c,0x2d,0x0c,0xfe,0x02,0x06 ; $8419
	dc.b	0x2b,0x0c,0x23,0x0c,0x2f,0x0c,0xfe,0x02 ; $8421
	dc.b	0x07,0x2a,0x0c,0x24,0x0c,0x31,0xa4,0xfe ; $8429
	dc.b	0x1b,0x00,0x24,0x0c,0x2e,0x0c,0x2f,0x0c ; $8431
	dc.b	0xfe,0x1b,0x01,0x23,0x0c,0x30,0x0c,0x2d ; $8439
	dc.b	0x0c,0xfe,0x1b,0x02,0x24,0x0c,0x31,0xa4 ; $8441
	dc.b	0x2f,0x0c,0xfe,0x1b,0x03,0x23,0x0c,0x2d ; $8449
	dc.b	0x0c,0x2e,0x0c,0xfe,0x1b,0x04,0x24,0x0c ; $8451
	dc.b	0x2f,0x0c,0x30,0x0c,0xfe,0x1b,0x05,0x23 ; $8459
	dc.b	0x0c,0x31,0xa4,0x29,0x0c,0xfe,0x1b,0x06 ; $8461
	dc.b	0x24,0x0c,0x31,0xa4,0x2b,0x0c,0xfe,0x1b ; $8469
	dc.b	0x07,0x23,0x0c,0x29,0x0c,0x2a,0x0c,0xfe ; $8471
	dc.b	0x02,0x08,0x2c,0x0c,0x23,0x0c,0x31,0xa4 ; $8479
	dc.b	0x1d,0x84,0x1e,0x84,0x1f,0x84,0x24,0x0c ; $8481
	dc.b	0x31,0xa4,0x31,0xa4,0x24,0x0c,0x27,0x0c ; $8489
	dc.b	0x28,0x0c,0x31,0xa4,0x23,0x0c,0x29,0x0c ; $8491
	dc.b	0x2a,0x0c,0x31,0xa4,0x29,0x0c,0x2a,0x0c ; $8499
	dc.b	0x31,0xa4,0x23,0x0c,0x31,0xa4,0x25,0x0c ; $84a1
	dc.b	0x26,0x0c,0x31,0xa4,0x24,0x0c,0x2b,0x0c ; $84a9
	dc.b	0x2c,0x0c,0xfe,0x02,0x09,0x20,0x84,0x24 ; $84b1
	dc.b	0x0c,0x22,0x84,0x0a,0xb4,0x31,0xa4,0x31 ; $84b9
	dc.b	0xa4,0x18,0x84,0x19,0x84,0x1a,0x84,0x31 ; $84c1
	dc.b	0xa4,0x31,0xa4,0x25,0x0c,0x26,0x0c,0x24 ; $84c9
	dc.b	0x0c,0x2b,0x0c,0x2c,0x0c,0x31,0xa4,0x2b ; $84d1
	dc.b	0x0c,0x2c,0x0c,0x31,0xa4,0x24,0x0c,0x31 ; $84d9
	dc.b	0xa4,0x27,0x0c,0x28,0x0c,0x0a,0xb4,0x29 ; $84e1
	dc.b	0x0c,0x2a,0x0c,0x31,0xa4,0xfe,0x02,0x0a ; $84e9
	dc.b	0x1d,0x84,0x23,0x0c,0x1f,0x84,0x31,0xa4 ; $84f1
	dc.b	0x31,0xa4,0x1c,0x84,0x13,0x84,0x14,0x84 ; $84f9
	dc.b	0x15,0x84,0x16,0x84,0x31,0xa4,0x27,0x0c ; $8501
	dc.b	0x28,0x0c,0x17,0x84,0x18,0x84,0x19,0x84 ; $8509
	dc.b	0x1a,0x84,0x31,0xa4,0x31,0xa4,0x31,0xa4 ; $8511
	dc.b	0x23,0x0c,0x31,0xa4,0x31,0xa4,0x31,0xa4 ; $8519
	dc.b	0x31,0xa4,0x2b,0x0c,0x2c,0x0c,0x20,0x84 ; $8521
	dc.b	0xfe,0x02,0x0b,0x31,0xa4,0x24,0x0c,0x31 ; $8529
	dc.b	0xa4,0x0a,0xb4,0x31,0xa4,0x1b,0x84,0x0d ; $8531
	dc.b	0x84,0x0e,0x84,0x0f,0x84,0x10,0x84,0x31 ; $8539
	dc.b	0xa4,0x31,0xa4,0x11,0x84,0x12,0x84,0x13 ; $8541
	dc.b	0x84,0x14,0x84,0x15,0x84,0x16,0x84,0x0a ; $8549
	dc.b	0xb4,0x31,0xa4,0x24,0x0c,0x31,0xa4,0x09 ; $8551
	dc.b	0xb4,0x0a,0xb4,0x29,0x0c,0x2a,0x0c,0x31 ; $8559
	dc.b	0xa4,0x1d,0x84,0xfe,0x03,0x0c,0x23,0x0c ; $8561
	dc.b	0xfe,0x0e,0x0c,0x0b,0x84,0x0c,0x84,0x0d ; $8569
	dc.b	0x84,0x0e,0x84,0x0f,0x84,0x10,0x84,0x31 ; $8571
	dc.b	0xa4,0x31,0xa4,0x31,0xa4,0x31,0xa4,0x31 ; $8579
	dc.b	0xa4,0x31,0xa4,0x2b,0x0c,0x2c,0x0c,0xfe ; $8581
	dc.b	0x03,0x0d,0x24,0x0c,0xfe,0x0b,0x0d,0x09 ; $8589
	dc.b	0xb4,0x0a,0xb4,0xfe,0x16,0x0d,0x0a,0xb4 ; $8591
	dc.b	0x09,0xb4,0x0a,0xb4,0xfe,0x0a,0x0e,0x0a ; $8599
	dc.b	0xb4,0xfe,0x05,0x0f,0x09,0xb4,0x0a,0xb4 ; $85a1
	dc.b	0xfe,0x14,0x0f,0x0a,0xb4,0xfe,0x02,0x12 ; $85a9
	dc.b	0x0a,0xb4,0xfe,0x1c,0x13,0x0a,0xb4,0xfe ; $85b1
	dc.b	0x16,0x17,0x09,0xb4,0xfe,0x08,0x18,0x0a ; $85b9
	dc.b	0xb4,0xfe,0x19,0x18,0x0a,0xb4,0xfe,0x02 ; $85c1
	dc.b	0x19,0x0a,0xb4,0x31,0xa4,0x0a,0xb4,0x0a ; $85c9
	dc.b	0xb4,0xfe,0x10,0x19,0x0a,0xb4,0x0a,0xb4 ; $85d1
	dc.b	0x09,0xb4,0xfe,0x17,0x19,0x09,0xb4,0xfe ; $85d9
	dc.b	0x1c,0x19,0x09,0xb4,0x0a,0xb4,0xfe,0x02 ; $85e1
	dc.b	0x1a,0x08,0xa4,0x06,0xa4,0x05,0xa4,0x05 ; $85e9
	dc.b	0xa4,0x05,0xa4,0x08,0xa4,0x06,0xa4,0x06 ; $85f1
	dc.b	0xa4,0x07,0xa4,0x05,0xa4,0x06,0xa4,0x07 ; $85f9
	dc.b	0xa4,0x08,0xa4,0x08,0xa4,0x05,0xa4,0x05 ; $8601
	dc.b	0xa4,0x05,0xa4,0x07,0xa4,0x05,0xa4,0x05 ; $8609
	dc.b	0xa4,0x08,0xa4,0x06,0xa4,0x06,0xa4,0x06 ; $8611
	dc.b	0xa4,0x07,0xa4,0x05,0xa4,0x06,0xa4,0x08 ; $8619
	dc.b	0xa4,0xfe,0x02,0x1b,0x3e,0xa0,0x3e,0xa0 ; $8621
	dc.b	0x3e,0xa0,0x3e,0xa0,0x3e,0xa0,0x3e,0xa0 ; $8629
	dc.b	0x3e,0xa0,0x3e,0xa0,0x3e,0xa0,0x3e,0xa0 ; $8631
	dc.b	0x3e,0xa0,0x3e,0xa0,0x3e,0xa0,0x3e,0xa0 ; $8639
	dc.b	0x3e,0xa0,0x3e,0xa0,0x3e,0xa0,0x3e,0xa0 ; $8641
	dc.b	0x3e,0xa0,0x3e,0xa0,0x3e,0xa0,0x3e,0xa0 ; $8649
	dc.b	0x3e,0xa0,0x3e,0xa0,0x3e,0xa0,0x3e,0xa0 ; $8651
	dc.b	0x3e,0xa0,0x3e,0xa0,0xfe,0x02,0x1c,0x32 ; $8659
	dc.b	0xdc,0x32,0xdc,0x03,0xdc,0x04,0xdc,0x00 ; $8661
	dc.b	0x8c,0x01,0xdc,0x02,0xdc,0x32,0xdc,0x32 ; $8669
	dc.b	0xdc,0x32,0xdc,0x32,0xdc,0x32,0xdc,0x04 ; $8671
	dc.b	0xdc,0x01,0xdc,0x02,0xdc,0x32,0xdc,0x03 ; $8679
	dc.b	0xdc,0x04,0xdc,0x00,0x8c,0x01,0xdc,0x04 ; $8681
	dc.b	0xdc,0x00,0x8c,0x01,0xdc,0x02,0xdc,0x32 ; $8689
	dc.b	0xdc,0x32,0xdc,0x03,0xdc,0x04,0xdc,0xfe ; $8691
	dc.b	0x02,0x1d,0x00,0x8c,0x00,0x8c,0x00,0x8c ; $8699
	dc.b	0x00,0x8c,0x68,0x8b,0x00,0x8c,0x68,0x8b ; $86a1
	dc.b	0x00,0x8c,0x00,0x8c,0x00,0x8c,0x68,0x8b ; $86a9
	dc.b	0x00,0x8c,0x68,0x8b,0x00,0x8c,0x00,0x8c ; $86b1
	dc.b	0x3c,0x88,0x00,0x8c,0x68,0x8b,0x3c,0x88 ; $86b9
	dc.b	0x00,0x8c,0x00,0x8c,0x68,0x8b,0x68,0x8b ; $86c1
	dc.b	0x00,0x8c,0x3c,0x88,0x00,0x8c,0x68,0x8b ; $86c9
	dc.b	0x00,0x8c,0xfe,0x02,0x1e,0x00,0x8c,0x3c ; $86d1
	dc.b	0x88,0x00,0x8c,0x68,0x8b,0x00,0x8c,0x68 ; $86d9
	dc.b	0x8b,0x00,0x8c,0x00,0x8c,0x3c,0x88,0x00 ; $86e1
	dc.b	0x8c,0x68,0x8b,0x00,0x8c,0x00,0x8c,0x68 ; $86e9
	dc.b	0x8b,0x3c,0x88,0x00,0x8c,0x68,0x8b,0x00 ; $86f1
	dc.b	0x8c,0x68,0x8b,0x00,0x8c,0x68,0x8b,0x00 ; $86f9
	dc.b	0x8c,0x3c,0x88,0x00,0x8c,0x00,0x8c,0x00 ; $8701
	dc.b	0x8c,0x00,0x8c,0x68,0x8b,0xfe,0x02,0x1f ; $8709
	dc.b	0x00,0x8c,0x00,0x8c,0x00,0x8c,0x00,0x8c ; $8711
	dc.b	0x00,0x8c,0x00,0x8c,0x3c,0x88,0x00,0x8c ; $8719
	dc.b	0x00,0x8c,0x00,0x8c,0x00,0x8c,0x00,0x8c ; $8721
	dc.b	0x00,0x8c,0x00,0x8c,0x00,0x8c,0x00,0x8c ; $8729
	dc.b	0x00,0x8c,0x00,0x8c,0x00,0x8c,0x00,0x8c ; $8731
	dc.b	0x00,0x8c,0x00,0x8c,0x00,0x8c,0x00,0x8c ; $8739
	dc.b	0x00,0x8c,0x00,0x8c,0x00,0x8c,0x00,0x8c ; $8741
	dc.b	0xff,0x02,0x00,0x3c,0xd0,0x3c,0xd0,0x3c ; $8749
	dc.b	0xd0,0xfe,0x1b,0x00,0x3c,0xd0,0x3c,0xd0 ; $8751
	dc.b	0x3c,0xd0,0xfe,0x02,0x01,0x3c,0xd0,0x3c ; $8759
	dc.b	0xd0,0x3c,0xd0,0xfe,0x1b,0x01,0x3c,0xd0 ; $8761
	dc.b	0x3c,0xd0,0x3c,0xd0,0xfe,0x02,0x02,0x5c ; $8769
	dc.b	0xd4,0x5c,0xd4,0x5c,0xd4,0xfe,0x1b,0x02 ; $8771
	dc.b	0x3c,0xd0,0x3c,0xd0,0x3c,0xd0,0xfe,0x02 ; $8779
	dc.b	0x03,0x5e,0xd4,0x5d,0xd4,0x5e,0xd4,0xfe ; $8781
	dc.b	0x1b,0x03,0x6e,0xdc,0x3c,0xd0,0x3c,0xd0 ; $8789
	dc.b	0xfe,0x02,0x04,0x60,0xd4,0x5f,0xd4,0x60 ; $8791
	dc.b	0xd4,0xfe,0x1b,0x04,0x3f,0xd8,0x73,0xdc ; $8799
	dc.b	0x6e,0xdc,0xfe,0x02,0x05,0x62,0xd4,0x8b ; $87a1
	dc.b	0xd6,0x62,0xd4,0xfe,0x1b,0x05,0x3f,0xd8 ; $87a9
	dc.b	0x3f,0xd8,0x3f,0xd8,0xfe,0x02,0x06,0x5d ; $87b1
	dc.b	0xd4,0x5e,0xd4,0x5d,0xd4,0xfe,0x1b,0x06 ; $87b9
	dc.b	0x3f,0xd8,0x3f,0xd8,0x3f,0xd8,0xfe,0x02 ; $87c1
	dc.b	0x07,0x5f,0xd4,0x60,0xd4,0x5f,0xd4,0xfe ; $87c9
	dc.b	0x1b,0x07,0x3f,0xd8,0x3f,0xd8,0x3f,0xd8 ; $87d1
	dc.b	0xfe,0x02,0x08,0x64,0xd4,0x65,0xd4,0x64 ; $87d9
	dc.b	0xd4,0x65,0xd4,0x64,0xd4,0x66,0xd4,0x3c ; $87e1
	dc.b	0xd8,0x3c,0xd8,0x6e,0xdc,0x3c,0xd8,0x3c ; $87e9
	dc.b	0xd8,0x3c,0xd8,0x3c,0xd8,0x3c,0xd8,0x3c ; $87f1
	dc.b	0xd8,0x37,0xd4,0x34,0xd4,0x34,0xd4,0x34 ; $87f9
	dc.b	0xd4,0x34,0xd4,0x34,0xd4,0x34,0xd4,0x34 ; $8801
	dc.b	0xd4,0x34,0xd4,0x34,0xd4,0x34,0xd4,0x3a ; $8809
	dc.b	0xd4,0x3f,0x54,0xfe,0x02,0x09,0x76,0xac ; $8811
	dc.b	0x76,0xac,0x76,0xac,0x76,0xac,0x76,0xac ; $8819
	dc.b	0x3c,0xd0,0x3c,0xd0,0x72,0xdc,0x3f,0xd8 ; $8821
	dc.b	0x73,0xdc,0x3c,0xd0,0x3c,0xd0,0x3c,0xd0 ; $8829
	dc.b	0x3c,0xd0,0x3c,0xd0,0x38,0xd4,0x35,0xd4 ; $8831
	dc.b	0x35,0xd4,0x35,0xd4,0x35,0xd4,0x35,0xd4 ; $8839
	dc.b	0x35,0xd4,0x35,0xd4,0x35,0xd4,0x35,0xd4 ; $8841
	dc.b	0x3d,0xd4,0x3b,0x2c,0x40,0x54,0xfe,0x02 ; $8849
	dc.b	0x0a,0x76,0xac,0x76,0xac,0x6b,0xa4,0x6c ; $8851
	dc.b	0xa4,0x76,0xac,0x3c,0xd0,0x3c,0xd0,0x71 ; $8859
	dc.b	0xdc,0x3f,0xd8,0x74,0xdc,0x3c,0x88,0x3c ; $8861
	dc.b	0x88,0x41,0xd4,0x42,0xd4,0x42,0xd4,0x39 ; $8869
	dc.b	0xfc,0x36,0xfc,0x36,0xfc,0x36,0xfc,0x36 ; $8871
	dc.b	0xfc,0x36,0xfc,0x36,0xfc,0x36,0xfc,0x36 ; $8879
	dc.b	0xfc,0x36,0xfc,0x3e,0xfc,0x3c,0x2c,0x42 ; $8881
	dc.b	0xd4,0xfe,0x02,0x0b,0x69,0xa4,0x76,0xac ; $8889
	dc.b	0x6a,0xa4,0x6d,0xa4,0x76,0xac,0x6e,0xdc ; $8891
	dc.b	0x3c,0xd0,0x70,0xdc,0x3f,0xd8,0x75,0xdc ; $8899
	dc.b	0x3c,0xd0,0x6e,0xdc,0x43,0xd4,0x45,0x2c ; $88a1
	dc.b	0x45,0x2c,0x45,0x2c,0x3d,0x28,0x3d,0x28 ; $88a9
	dc.b	0x47,0x54,0x48,0x54,0x48,0x54,0x48,0x54 ; $88b1
	dc.b	0x48,0x54,0x48,0x54,0x3d,0x28,0x3d,0x28 ; $88b9
	dc.b	0x44,0xd4,0x45,0x2c,0xfe,0x02,0x0c,0x3f ; $88c1
	dc.b	0xd8,0x67,0xa4,0x3f,0xd8,0x3f,0xd8,0x67 ; $88c9
	dc.b	0xa4,0x3f,0xd8,0x6f,0xdc,0x3f,0xd8,0x3f ; $88d1
	dc.b	0xd8,0x3f,0xd8,0x6f,0xdc,0x3f,0xd8,0x6f ; $88d9
	dc.b	0xdc,0x46,0xcc,0x46,0xcc,0x46,0xcc,0x3d ; $88e1
	dc.b	0x28,0x3d,0x28,0x49,0x54,0x3f,0xd8,0x3f ; $88e9
	dc.b	0xd8,0x3f,0xd8,0x3f,0xd8,0x3f,0xd8,0x3d ; $88f1
	dc.b	0x28,0x3d,0x28,0x3c,0x00,0x46,0xcc,0xfe ; $88f9
	dc.b	0x02,0x0d,0x3f,0xd8,0x3f,0xd8,0x3f,0xd8 ; $8901
	dc.b	0x3f,0xd8,0x3f,0xd8,0x3f,0xd8,0x3f,0xd8 ; $8909
	dc.b	0x3f,0xd8,0x3f,0xd8,0x3f,0xd8,0x3f,0xd8 ; $8911
	dc.b	0x3f,0xd8,0x3f,0xd8,0x46,0xcc,0x46,0xcc ; $8919
	dc.b	0x46,0xcc,0x3d,0x28,0x3d,0x28,0x49,0x54 ; $8921
	dc.b	0x3f,0xd8,0x3f,0xd8,0x3f,0xd8,0x3f,0xd8 ; $8929
	dc.b	0x3f,0xd8,0x3d,0x28,0x3d,0x28,0x3c,0x00 ; $8931
	dc.b	0x46,0xcc,0xfe,0x02,0x0e,0x59,0x54,0x58 ; $8939
	dc.b	0x54,0x59,0x54,0x58,0x54,0x59,0x54,0x58 ; $8941
	dc.b	0x54,0x59,0x54,0x58,0x54,0x59,0x54,0x58 ; $8949
	dc.b	0x54,0x59,0x54,0x58,0x54,0x59,0x54,0x46 ; $8951
	dc.b	0xcc,0x46,0xcc,0x46,0xcc,0x3d,0x28,0x3d ; $8959
	dc.b	0x28,0x49,0x54,0x3f,0xd8,0x3f,0xd8,0x3f ; $8961
	dc.b	0xd8,0x4f,0x54,0x50,0x54,0x3d,0x28,0x3d ; $8969
	dc.b	0x28,0x3c,0x00,0x46,0xcc,0xfe,0x02,0x0f ; $8971
	dc.b	0x5b,0x54,0x5a,0x54,0x5b,0x54,0x5a,0x54 ; $8979
	dc.b	0x5b,0x54,0x5a,0x54,0x5b,0x54,0x5a,0x54 ; $8981
	dc.b	0x5b,0x54,0x5a,0x54,0x5b,0x54,0x5a,0x54 ; $8989
	dc.b	0x5b,0x54,0x46,0xcc,0x46,0xcc,0x46,0xcc ; $8991
	dc.b	0x3d,0x28,0x3d,0x28,0x4a,0x54,0x4b,0x54 ; $8999
	dc.b	0x4c,0x54,0x4d,0x54,0x4e,0x54,0x4e,0x54 ; $89a1
	dc.b	0x3d,0x28,0x3d,0x28,0x3c,0x00,0x46,0xcc ; $89a9
	dc.b	0xfe,0x0f,0x10,0x3c,0x00,0x3c,0x00,0x51 ; $89b1
	dc.b	0xd4,0x52,0x2c,0x52,0x2c,0x53,0xd4,0x77 ; $89b9
	dc.b	0xd4,0x77,0xd4,0x77,0xd4,0x77,0xd4,0x77 ; $89c1
	dc.b	0xd4,0x52,0x2c,0x52,0x2c,0x54,0xd4,0x3c ; $89c9
	dc.b	0x00,0xfe,0x10,0x11,0x57,0xfc,0x77,0xd4 ; $89d1
	dc.b	0x77,0xd4,0x77,0xd4,0x77,0xd4,0x77,0xd4 ; $89d9
	dc.b	0x77,0xd4,0x77,0xd4,0x77,0xd4,0x77,0xd4 ; $89e1
	dc.b	0x77,0xd4,0x56,0xfc,0x55,0xfc,0xff,0x02 ; $89e9
	dc.b	0x00,0x3c,0x88,0x3c,0x88,0x3c,0x88,0x3c ; $89f1
	dc.b	0x88,0xfe,0x1a,0x00,0x3c,0x88,0x3c,0x88 ; $89f9
	dc.b	0x7c,0x94,0x7d,0x94,0xfe,0x02,0x01,0x3c ; $8a01
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88,0xfe ; $8a09
	dc.b	0x1a,0x01,0x3c,0x88,0x79,0x8c,0x7e,0x94 ; $8a11
	dc.b	0x7f,0x94,0xfe,0x02,0x02,0x3c,0x88,0x3c ; $8a19
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0xfe,0x1a,0x02 ; $8a21
	dc.b	0x74,0x8c,0x7b,0xc4,0xcd,0x74,0xd7,0x74 ; $8a29
	dc.b	0xfe,0x02,0x03,0x3c,0x88,0x3c,0x88,0x3c ; $8a31
	dc.b	0x88,0x3c,0x88,0xfe,0x1a,0x03,0x3d,0x70 ; $8a39
	dc.b	0x78,0x74,0x80,0x74,0x81,0x74,0xfe,0x02 ; $8a41
	dc.b	0x04,0x3c,0x88,0x3c,0x88,0x3c,0x88,0x3c ; $8a49
	dc.b	0x88,0xfe,0x1a,0x04,0x3d,0x70,0x85,0x74 ; $8a51
	dc.b	0x82,0x74,0x83,0x74,0xfe,0x02,0x05,0x3c ; $8a59
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88,0xfe ; $8a61
	dc.b	0x1a,0x05,0x86,0x74,0x87,0x74,0x3d,0x70 ; $8a69
	dc.b	0x84,0x3c,0xfe,0x02,0x06,0x3c,0x88,0x3c ; $8a71
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0xfe,0x1a,0x06 ; $8a79
	dc.b	0x3d,0x70,0x88,0x74,0x89,0x74,0x84,0x3c ; $8a81
	dc.b	0xfe,0x02,0x07,0xc6,0x94,0xc7,0x8c,0xc4 ; $8a89
	dc.b	0x8c,0xc5,0x94,0xfe,0x1a,0x07,0x90,0x74 ; $8a91
	dc.b	0x8a,0x74,0x8b,0x74,0x3d,0x70,0xfe,0x02 ; $8a99
	dc.b	0x08,0xcb,0x8c,0xc8,0x74,0xc9,0x74,0xca ; $8aa1
	dc.b	0x8c,0xcc,0x8c,0x3c,0x88,0x3c,0x88,0x3c ; $8aa9
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88,0x3c ; $8ab1
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88,0x3c ; $8ab9
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88,0x3c ; $8ac1
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0x9d,0x64,0x3d ; $8ac9
	dc.b	0x70,0x92,0x74,0x8c,0x74,0x8d,0x74,0x91 ; $8ad1
	dc.b	0x74,0xfe,0x02,0x09,0x9d,0x64,0xd0,0x3c ; $8ad9
	dc.b	0xd2,0x74,0xd5,0xa4,0xa9,0xdc,0x3f,0xd8 ; $8ae1
	dc.b	0x3f,0xd8,0xa9,0xdc,0x3f,0xd8,0x3f,0xd8 ; $8ae9
	dc.b	0x3f,0xd8,0xa9,0xdc,0xa9,0xdc,0xa9,0xdc ; $8af1
	dc.b	0x3f,0xd8,0xa9,0xdc,0x3f,0xd8,0x3f,0xd8 ; $8af9
	dc.b	0xa9,0xdc,0xa9,0xdc,0x3f,0xd8,0xa9,0xdc ; $8b01
	dc.b	0x9f,0xa4,0x3d,0x70,0x3d,0x70,0x8e,0x74 ; $8b09
	dc.b	0x8f,0x74,0x93,0x74,0xfe,0x02,0x0a,0xcf ; $8b11
	dc.b	0xa4,0xd1,0x3c,0xd3,0x74,0xd4,0x74,0xaa ; $8b19
	dc.b	0xa4,0xab,0xa4,0xaa,0xa4,0xab,0xa4,0xaa ; $8b21
	dc.b	0xa4,0xab,0xa4,0xb0,0xdc,0xb1,0xdc,0xaa ; $8b29
	dc.b	0xa4,0xab,0xa4,0xaa,0xa4,0xab,0xa4,0xaa ; $8b31
	dc.b	0xa4,0xab,0xa4,0xaa,0xa4,0xab,0xa4,0xaa ; $8b39
	dc.b	0xa4,0xab,0xa4,0x9e,0x74,0x3d,0x70,0x84 ; $8b41
	dc.b	0x3c,0x98,0x74,0x94,0x74,0x95,0x74,0xfe ; $8b49
	dc.b	0x02,0x0b,0xce,0xa4,0xd0,0x3c,0xd1,0x3c ; $8b51
	dc.b	0xd6,0xa4,0xa8,0x34,0xa8,0x34,0xae,0xdc ; $8b59
	dc.b	0xaf,0xdc,0xac,0xdc,0xad,0xdc,0xb2,0xdc ; $8b61
	dc.b	0xb3,0xdc,0xa8,0x34,0xa8,0x34,0xa8,0x34 ; $8b69
	dc.b	0xa8,0x34,0xa8,0x34,0xa8,0x34,0xa8,0x34 ; $8b71
	dc.b	0xa8,0x34,0xa8,0x34,0xa0,0xa4,0x3d,0x70 ; $8b79
	dc.b	0x84,0x3c,0x9c,0x3c,0x9a,0x74,0x96,0x74 ; $8b81
	dc.b	0x97,0x74,0xfe,0x02,0x0c,0xa8,0x34,0xa8 ; $8b89
	dc.b	0x34,0xa8,0x34,0xa8,0x34,0xa8,0x34,0xa8 ; $8b91
	dc.b	0x34,0xb9,0xdc,0x3c,0x88,0x3c,0x88,0x3c ; $8b99
	dc.b	0x88,0xb4,0xdc,0xa8,0x34,0xa8,0x34,0xa8 ; $8ba1
	dc.b	0x34,0xa8,0x34,0xa8,0x34,0xa8,0x34,0xa8 ; $8ba9
	dc.b	0x34,0xa8,0x34,0xa8,0x34,0xa8,0x34,0xa2 ; $8bb1
	dc.b	0xa4,0x3d,0x70,0x3d,0x70,0x3d,0x70,0x99 ; $8bb9
	dc.b	0x74,0x9b,0x74,0x9c,0x3c,0xfe,0x02,0x0d ; $8bc1
	dc.b	0xa8,0x34,0xa8,0x34,0xa8,0x34,0xa8,0x34 ; $8bc9
	dc.b	0xb8,0xdc,0xba,0xdc,0xbb,0xdc,0x3c,0x88 ; $8bd1
	dc.b	0x3c,0x88,0x3c,0x88,0xb5,0xdc,0xa8,0x34 ; $8bd9
	dc.b	0xa8,0x34,0xa8,0x34,0xa8,0x34,0xa8,0x34 ; $8be1
	dc.b	0xa8,0x34,0xa8,0x34,0xa8,0x34,0xa8,0x34 ; $8be9
	dc.b	0xa8,0x34,0xa1,0xa4,0x3d,0x70,0x3d,0x70 ; $8bf1
	dc.b	0x3d,0x70,0x84,0x3c,0x9c,0x3c,0x3d,0xa0 ; $8bf9
	dc.b	0xfe,0x02,0x0e,0xa8,0x34,0xbf,0xdc,0xbc ; $8c01
	dc.b	0xdc,0xbd,0xdc,0x3c,0x88,0x3c,0x88,0x3c ; $8c09
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88,0xb7 ; $8c11
	dc.b	0xdc,0xa8,0x34,0xa8,0x34,0xa8,0x34,0xa8 ; $8c19
	dc.b	0x34,0xa8,0x34,0xa8,0x34,0xa8,0x34,0xa8 ; $8c21
	dc.b	0x34,0xa8,0x34,0xa8,0x34,0xa3,0xa4,0x3d ; $8c29
	dc.b	0x70,0x9c,0x3c,0x3d,0x70,0x84,0x3c,0x3d ; $8c31
	dc.b	0x70,0x9c,0x3c,0xfe,0x02,0x0f,0xc2,0x7c ; $8c39
	dc.b	0xbe,0xdc,0xc0,0xdc,0xc1,0xdc,0xc0,0xdc ; $8c41
	dc.b	0xc1,0xdc,0xc1,0xdc,0xc0,0xdc,0xc0,0xdc ; $8c49
	dc.b	0xc1,0xdc,0xc3,0x7c,0xc2,0x7c,0xc3,0x7c ; $8c51
	dc.b	0xc2,0x7c,0xc2,0x7c,0xc2,0x7c,0xc3,0x7c ; $8c59
	dc.b	0xc3,0x7c,0xc2,0x7c,0xc3,0x7c,0xc2,0x7c ; $8c61
	dc.b	0xa4,0xa4,0xa5,0xa4,0xa4,0xa4,0xa5,0xa4 ; $8c69
	dc.b	0xa6,0xa4,0xa6,0xa4,0xa7,0xa4,0xff,0x02 ; $8c71
	dc.b	0x00,0x3c,0x88,0x3c,0x88,0x3c,0x88,0xfe ; $8c79
	dc.b	0x1b,0x00,0x3c,0x88,0x3c,0x88,0x3c,0x88 ; $8c81
	dc.b	0xfe,0x02,0x01,0x3c,0x88,0x3c,0x88,0x3c ; $8c89
	dc.b	0x88,0xfe,0x1b,0x01,0x3c,0x88,0x3c,0x88 ; $8c91
	dc.b	0x3c,0x88,0xfe,0x02,0x02,0x3c,0x88,0x3c ; $8c99
	dc.b	0x88,0x3c,0x88,0xfe,0x1b,0x02,0x3c,0x88 ; $8ca1
	dc.b	0x3c,0x88,0x3c,0x88,0xfe,0x02,0x03,0x3c ; $8ca9
	dc.b	0x88,0x30,0x65,0x31,0x65,0xfe,0x02,0x04 ; $8cb1
	dc.b	0x35,0x65,0x32,0x65,0x33,0x65,0xfe,0x02 ; $8cb9
	dc.b	0x05,0x3f,0x60,0x36,0x65,0x3f,0x60,0xfe ; $8cc1
	dc.b	0x1b,0x03,0x34,0x65,0x37,0x65,0x38,0x65 ; $8cc9
	dc.b	0xfe,0x1b,0x04,0x33,0x65,0x32,0x65,0x33 ; $8cd1
	dc.b	0x65,0xfe,0x1b,0x05,0x3f,0x60,0x36,0x65 ; $8cd9
	dc.b	0x3f,0x60,0xfe,0x02,0x06,0xf8,0x9c,0xf9 ; $8ce1
	dc.b	0x9c,0xfa,0x9c,0xfe,0x1b,0x06,0xf9,0x9c ; $8ce9
	dc.b	0xfa,0x9c,0xf8,0x9c,0xfe,0x02,0x07,0xfd ; $8cf1
	dc.b	0xa4,0x00,0xa5,0xfe,0x1b,0x07,0xfd,0xa4 ; $8cf9
	dc.b	0x00,0xa5,0xfe,0x02,0x08,0xfc,0xa4,0xfb ; $8d01
	dc.b	0xa4,0x01,0xa5,0xfe,0x10,0x08,0xea,0xa4 ; $8d09
	dc.b	0xeb,0xa4,0xee,0xa4,0xfe,0x19,0x08,0xda ; $8d11
	dc.b	0x24,0xdd,0x24,0xfc,0xa4,0xfb,0xa4,0x01 ; $8d19
	dc.b	0xa5,0xfe,0x0f,0x09,0xe7,0xa4,0xe9,0xa4 ; $8d21
	dc.b	0xec,0xa4,0xed,0xa4,0xfe,0x18,0x09,0xd8 ; $8d29
	dc.b	0x24,0xd9,0x24,0xdc,0x24,0xdb,0x24,0xfe ; $8d31
	dc.b	0x02,0x0a,0xea,0xa4,0xeb,0xa4,0xee,0xa4 ; $8d39
	dc.b	0xfe,0x09,0x0a,0xda,0x24,0xdd,0x24,0xfe ; $8d41
	dc.b	0x0f,0x0a,0xe6,0xa4,0xe8,0xa4,0xf0,0xa4 ; $8d49
	dc.b	0xef,0xa4,0xfe,0x17,0x0a,0xda,0x24,0x3c ; $8d51
	dc.b	0x20,0xd9,0x24,0xdc,0x24,0x3c,0x20,0xdd ; $8d59
	dc.b	0x24,0xfe,0x02,0x0b,0xe9,0xa4,0xec,0xa4 ; $8d61
	dc.b	0xed,0xa4,0xfe,0x08,0x0b,0xd8,0x24,0xd9 ; $8d69
	dc.b	0x24,0xdc,0x24,0xdb,0x24,0xfe,0x0f,0x0b ; $8d71
	dc.b	0xe5,0xa4,0xe4,0xa4,0xf1,0xa4,0xfe,0x16 ; $8d79
	dc.b	0x0b,0xd8,0x24,0xd9,0x24,0x3c,0x20,0xe0 ; $8d81
	dc.b	0x24,0xe3,0x24,0x3c,0x20,0xdc,0x24,0xdb ; $8d89
	dc.b	0x24,0xfe,0x02,0x0c,0xe8,0xa4,0xf0,0xa4 ; $8d91
	dc.b	0xef,0xa4,0xfe,0x07,0x0c,0xda,0x24,0x3c ; $8d99
	dc.b	0x20,0xd9,0x24,0xdc,0x24,0x3c,0x20,0xdd ; $8da1
	dc.b	0x24,0xfe,0x15,0x0c,0xda,0x24,0x3c,0x20 ; $8da9
	dc.b	0xd9,0x24,0x3c,0x20,0xdf,0x24,0xe2,0x24 ; $8db1
	dc.b	0x3c,0x20,0xdc,0x24,0x3c,0x20,0xdd,0x24 ; $8db9
	dc.b	0xfe,0x02,0x0d,0xe4,0xa4,0xf1,0xa4,0xfe ; $8dc1
	dc.b	0x06,0x0d,0xd8,0x24,0xd9,0x24,0x3c,0x20 ; $8dc9
	dc.b	0xe0,0x24,0xe3,0x24,0x3c,0x20,0xdc,0x24 ; $8dd1
	dc.b	0xdb,0x24,0xfe,0x15,0x0d,0xf2,0x24,0xf4 ; $8dd9
	dc.b	0x24,0xf6,0x24,0x3c,0x20,0xde,0x24,0xe1 ; $8de1
	dc.b	0x24,0x3c,0x20,0xf7,0x24,0xf5,0x24,0xf3 ; $8de9
	dc.b	0x24,0xfe,0x05,0x0e,0xda,0x24,0x3c,0x20 ; $8df1
	dc.b	0xd9,0x24,0x3c,0x20,0xdf,0x24,0xe2,0x24 ; $8df9
	dc.b	0x3c,0x20,0xdc,0x24,0x3c,0x20,0xdd,0x24 ; $8e01
	dc.b	0xfe,0x05,0x0f,0xf2,0x24,0xf4,0x24,0xf6 ; $8e09
	dc.b	0x24,0x3c,0x20,0xde,0x24,0xe1,0x24,0x3c ; $8e11
	dc.b	0x20,0xf7,0x24,0xf5,0x24,0xf3,0x24,0xfe ; $8e19
	dc.b	0x19,0x10,0xea,0xa4,0xeb,0xa4,0xee,0xa4 ; $8e21
	dc.b	0xfe,0x18,0x11,0xe7,0xa4,0xe9,0xa4,0xec ; $8e29
	dc.b	0xa4,0xed,0xa4,0xfe,0x18,0x12,0xe6,0xa4 ; $8e31
	dc.b	0xe8,0xa4,0xf0,0xa4,0xef,0xa4,0xfe,0x18 ; $8e39
	dc.b	0x13,0xe5,0xa4,0xe4,0xa4,0xf1,0xa4,0xff ; $8e41
	dc.b	0x02,0x00,0x25,0x15,0x22,0x15,0x3c,0x00 ; $8e49
	dc.b	0xfe,0x1b,0x00,0x3c,0x88,0x3c,0x88,0x3c ; $8e51
	dc.b	0x88,0xfe,0x02,0x01,0x3d,0x10,0x3d,0x10 ; $8e59
	dc.b	0x25,0x15,0xfe,0x1b,0x01,0x3c,0x88,0x3c ; $8e61
	dc.b	0x88,0x3c,0x88,0xfe,0x02,0x02,0x3d,0x10 ; $8e69
	dc.b	0x1c,0x15,0x3d,0x10,0xfe,0x1b,0x02,0x3c ; $8e71
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0xfe,0x02,0x03 ; $8e79
	dc.b	0x3d,0x10,0x1c,0x15,0x3d,0x10,0xfe,0x1b ; $8e81
	dc.b	0x03,0x3c,0x88,0x3c,0x88,0x3c,0x88,0xfe ; $8e89
	dc.b	0x02,0x04,0x3d,0x10,0x3d,0x10,0x3d,0x10 ; $8e91
	dc.b	0xfe,0x1b,0x04,0x3c,0x88,0x3c,0x88,0x3c ; $8e99
	dc.b	0x88,0xfe,0x02,0x05,0x3d,0x10,0x3d,0x10 ; $8ea1
	dc.b	0x3d,0x10,0xfe,0x1b,0x05,0x3c,0x88,0x3c ; $8ea9
	dc.b	0x88,0x3c,0x88,0xfe,0x02,0x06,0x20,0x15 ; $8eb1
	dc.b	0x21,0x15,0x1f,0x15,0xfe,0x1b,0x06,0x3c ; $8eb9
	dc.b	0x88,0x30,0x65,0x31,0x65,0xfe,0x02,0x07 ; $8ec1
	dc.b	0x8c,0x16,0x23,0x15,0x24,0x15,0xfe,0x1b ; $8ec9
	dc.b	0x07,0x35,0x65,0x32,0x65,0x33,0x65,0xfe ; $8ed1
	dc.b	0x02,0x08,0x8c,0x16,0x3c,0x10,0x3c,0x10 ; $8ed9
	dc.b	0x1b,0x15,0x3d,0x10,0x3d,0x10,0x3c,0x00 ; $8ee1
	dc.b	0x3c,0x00,0x3c,0x00,0x3d,0x10,0x02,0x15 ; $8ee9
	dc.b	0x03,0x15,0x3c,0x88,0x3c,0x88,0x3c,0x88 ; $8ef1
	dc.b	0x3c,0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88 ; $8ef9
	dc.b	0x3c,0x88,0x3c,0x88,0x34,0x65,0x34,0x65 ; $8f01
	dc.b	0x35,0x65,0x36,0x65,0x3a,0x65,0x36,0x65 ; $8f09
	dc.b	0x3f,0x60,0xfe,0x02,0x09,0x8c,0x16,0x3c ; $8f11
	dc.b	0x10,0x3c,0x10,0x3c,0x00,0x3d,0x10,0x3d ; $8f19
	dc.b	0x10,0x0c,0x15,0x0d,0x15,0x3c,0x00,0x3d ; $8f21
	dc.b	0x10,0x04,0x15,0x05,0x15,0x3c,0x88,0x3c ; $8f29
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88,0x3c ; $8f31
	dc.b	0x88,0x3c,0x88,0x37,0x65,0x38,0x65,0x33 ; $8f39
	dc.b	0x65,0x3f,0x60,0x3a,0x65,0x3f,0x60,0x39 ; $8f41
	dc.b	0x65,0x3f,0x60,0x3f,0x60,0xfe,0x02,0x0a ; $8f49
	dc.b	0x8c,0x16,0x3c,0x10,0x3c,0x10,0x3c,0x00 ; $8f51
	dc.b	0x1c,0x15,0x3d,0x10,0x0e,0x15,0x0f,0x15 ; $8f59
	dc.b	0x12,0x15,0x3d,0x10,0x0a,0x15,0x05,0x15 ; $8f61
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x10,0x3c,0x10 ; $8f69
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x10,0x3c,0x10 ; $8f71
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x10,0x3c,0x10 ; $8f79
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x10,0x3c,0x10 ; $8f81
	dc.b	0xfe,0x02,0x0b,0x8c,0x16,0x3c,0x10,0x3c ; $8f89
	dc.b	0x10,0x1b,0x15,0x1e,0x15,0x3d,0x10,0x10 ; $8f91
	dc.b	0x15,0x11,0x15,0x13,0x15,0x3d,0x10,0x06 ; $8f99
	dc.b	0x15,0x05,0x15,0x3d,0x00,0x3f,0xfd,0x3d ; $8fa1
	dc.b	0x00,0x3d,0x00,0x3d,0x00,0x3f,0xfd,0x27 ; $8fa9
	dc.b	0x15,0x3c,0x10,0x3c,0x10,0x3c,0x10,0x3c ; $8fb1
	dc.b	0x10,0x3c,0x10,0x3c,0x10,0x3c,0x10,0x3c ; $8fb9
	dc.b	0x10,0x3c,0x10,0xfe,0x02,0x0c,0x8c,0x16 ; $8fc1
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x00,0x3d,0x10 ; $8fc9
	dc.b	0x3d,0x10,0x3c,0x00,0x3c,0x00,0x3c,0x00 ; $8fd1
	dc.b	0x3d,0x10,0x0a,0x15,0x05,0x15,0xfe,0x15 ; $8fd9
	dc.b	0x0c,0x27,0x15,0x3c,0x10,0x3c,0x10,0x3c ; $8fe1
	dc.b	0x10,0x3c,0x10,0x3c,0x10,0x3c,0x10,0x3c ; $8fe9
	dc.b	0x10,0x3c,0x10,0xfe,0x02,0x0d,0x8c,0x16 ; $8ff1
	dc.b	0x3c,0x10,0x3c,0x10,0x1b,0x15,0x3d,0x10 ; $8ff9
	dc.b	0x3d,0x10,0x3c,0x00,0x3c,0x00,0x3c,0x00 ; $9001
	dc.b	0x1c,0x15,0x08,0x15,0x09,0x15,0x3e,0x10 ; $9009
	dc.b	0x28,0x15,0x29,0x15,0x2a,0x15,0x3e,0x10 ; $9011
	dc.b	0x3e,0x10,0x3b,0xfd,0x3c,0xfd,0x27,0x15 ; $9019
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x10,0x3c,0x10 ; $9021
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x10,0xfe,0x02 ; $9029
	dc.b	0x0e,0x8c,0x16,0x3c,0x10,0x3c,0x10,0x3c ; $9031
	dc.b	0x00,0x3d,0x10,0x1c,0x15,0x3c,0x00,0x3c ; $9039
	dc.b	0x00,0x3c,0x00,0x1e,0x15,0x07,0x15,0xfe ; $9041
	dc.b	0x14,0x0e,0x3d,0xfd,0x3e,0xfd,0x3e,0x10 ; $9049
	dc.b	0x27,0x15,0x3c,0x10,0x3c,0x10,0x3c,0x10 ; $9051
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x10,0xfe,0x02 ; $9059
	dc.b	0x0f,0x8c,0x16,0x3c,0x10,0x3c,0x10,0x3c ; $9061
	dc.b	0x00,0x3d,0x10,0x1e,0x15,0x14,0x75,0x15 ; $9069
	dc.b	0x75,0x3c,0x00,0x0b,0x15,0x3e,0x10,0x28 ; $9071
	dc.b	0x15,0x29,0x15,0x2a,0x15,0xfe,0x16,0x0f ; $9079
	dc.b	0x2b,0x15,0x3e,0x10,0x27,0x15,0x3c,0x10 ; $9081
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x10,0x3c,0x10 ; $9089
	dc.b	0xfe,0x02,0x10,0x8c,0x16,0x3c,0x10,0x3c ; $9091
	dc.b	0x10,0x1b,0x15,0x3d,0x10,0x3d,0x10,0x16 ; $9099
	dc.b	0x25,0x17,0x25,0xfe,0x13,0x10,0x2b,0x15 ; $90a1
	dc.b	0xfe,0x19,0x10,0x27,0x15,0x3c,0x10,0x3c ; $90a9
	dc.b	0x10,0x3c,0x10,0x3c,0x10,0xfe,0x02,0x11 ; $90b1
	dc.b	0x8c,0x16,0x3c,0x10,0x3c,0x10,0x3c,0x00 ; $90b9
	dc.b	0x3d,0x10,0x3d,0x10,0x18,0x25,0x19,0xbd ; $90c1
	dc.b	0x2f,0x15,0xfe,0x18,0x11,0x2b,0x15,0x3e ; $90c9
	dc.b	0x10,0x27,0x15,0x3c,0x10,0x3c,0x10,0x3c ; $90d1
	dc.b	0x10,0xfe,0x02,0x12,0x8c,0x16,0x3c,0x10 ; $90d9
	dc.b	0x3c,0x10,0x3c,0x00,0x1c,0x15,0x3d,0x10 ; $90e1
	dc.b	0x1a,0xbd,0xfe,0x17,0x12,0x2b,0x15,0x3e ; $90e9
	dc.b	0x10,0x3e,0x10,0x2b,0x15,0x27,0x15,0x3c ; $90f1
	dc.b	0x10,0x3c,0x10,0xfe,0x02,0x13,0x8c,0x16 ; $90f9
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x00,0x1e,0x15 ; $9101
	dc.b	0x0b,0x15,0xfe,0x1a,0x13,0x2f,0x15,0x3e ; $9109
	dc.b	0x10,0x27,0x15,0x3c,0x10,0xfe,0x02,0x14 ; $9111
	dc.b	0x8c,0x16,0x3c,0x10,0x3c,0x10,0x1b,0x15 ; $9119
	dc.b	0x0b,0x15,0x2f,0x15,0x28,0x15,0x29,0x15 ; $9121
	dc.b	0x2a,0x15,0xfe,0x19,0x14,0x2f,0x15,0x3e ; $9129
	dc.b	0x10,0x2b,0x15,0x3e,0x10,0x27,0x15,0xfe ; $9131
	dc.b	0x02,0x15,0x8c,0x16,0x3c,0x10,0x26,0x15 ; $9139
	dc.b	0xfe,0x0f,0x15,0x2e,0x15,0x2f,0x15,0x2c ; $9141
	dc.b	0x15,0x2d,0x15,0xfe,0x1a,0x15,0x2b,0x15 ; $9149
	dc.b	0x3e,0x10,0x2b,0x15,0xfe,0x02,0x16,0x8c ; $9151
	dc.b	0x16,0x26,0x15,0xfe,0x02,0x17,0x26,0x15 ; $9159
	dc.b	0xfe,0x1b,0x18,0x2b,0x15,0xfe,0x1a,0x19 ; $9161
	dc.b	0x2b,0x15,0xfe,0x09,0x1a,0x2e,0x15,0x2f ; $9169
	dc.b	0x15,0x2c,0x15,0x2d,0x15,0xfe,0x07,0x1d ; $9171
	dc.b	0x2f,0x15,0xfe,0x17,0x1d,0x2f,0x15,0xff ; $9179
	dc.b	0x02,0x00,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $9181
	dc.b	0xfe,0x1b,0x00,0x3f,0x90,0x3f,0x90,0x3f ; $9189
	dc.b	0x90,0xfe,0x02,0x01,0x3f,0x90,0x3f,0x90 ; $9191
	dc.b	0x3f,0x90,0xfe,0x1b,0x01,0x3f,0x90,0x3f ; $9199
	dc.b	0x90,0x3f,0x90,0xfe,0x02,0x02,0x3f,0x90 ; $91a1
	dc.b	0x3f,0x90,0x3f,0x90,0xfe,0x1b,0x02,0x3f ; $91a9
	dc.b	0x90,0x3f,0x90,0x3f,0x90,0xfe,0x02,0x03 ; $91b1
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0xfe,0x1b ; $91b9
	dc.b	0x03,0x3f,0x90,0x3f,0x90,0x3f,0x90,0xfe ; $91c1
	dc.b	0x02,0x04,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $91c9
	dc.b	0xfe,0x1b,0x04,0x72,0x95,0x69,0x95,0x3f ; $91d1
	dc.b	0x90,0xfe,0x02,0x05,0x3f,0x90,0x3f,0x90 ; $91d9
	dc.b	0x3f,0x90,0xfe,0x1b,0x05,0x3d,0x90,0x68 ; $91e1
	dc.b	0x95,0x3f,0x90,0xfe,0x02,0x06,0x3f,0x90 ; $91e9
	dc.b	0x3f,0x90,0x3f,0x90,0xfe,0x1b,0x06,0x67 ; $91f1
	dc.b	0x95,0x3f,0x90,0x3f,0x90,0xfe,0x02,0x07 ; $91f9
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0xfe,0x1b ; $9201
	dc.b	0x07,0x3f,0x90,0x3f,0x90,0x3f,0x90,0xfe ; $9209
	dc.b	0x02,0x08,0x6c,0x95,0x72,0x95,0x69,0x95 ; $9211
	dc.b	0x6d,0x95,0x71,0x95,0x6d,0x95,0x72,0x95 ; $9219
	dc.b	0x69,0x95,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $9221
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0x65,0x95 ; $9229
	dc.b	0x3d,0x90,0x6a,0x95,0x6f,0x95,0x6a,0x95 ; $9231
	dc.b	0x6b,0x95,0x6a,0x95,0x66,0x95,0x67,0x95 ; $9239
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $9241
	dc.b	0x3f,0x90,0xfe,0x02,0x09,0x3d,0x90,0x6a ; $9249
	dc.b	0x95,0x6f,0x95,0x6f,0x95,0x6a,0x95,0x6b ; $9251
	dc.b	0x95,0x66,0x95,0x67,0x95,0x3f,0x90,0x3f ; $9259
	dc.b	0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f ; $9261
	dc.b	0x90,0x3f,0x90,0x6e,0x95,0x3f,0x90,0x3f ; $9269
	dc.b	0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f ; $9271
	dc.b	0x90,0x3f,0x90,0x6c,0x95,0x6d,0x95,0x72 ; $9279
	dc.b	0x95,0x69,0x95,0x71,0x95,0xfe,0x02,0x0a ; $9281
	dc.b	0x6e,0x95,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $9289
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $9291
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $9299
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $92a1
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $92a9
	dc.b	0x3f,0x90,0x3f,0x90,0x65,0x95,0x66,0x95 ; $92b1
	dc.b	0x70,0x95,0x6a,0x95,0x6a,0x95,0x68,0x95 ; $92b9
	dc.b	0xfe,0x02,0x0b,0x3f,0x90,0x3f,0x90,0x3f ; $92c1
	dc.b	0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f ; $92c9
	dc.b	0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f ; $92d1
	dc.b	0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f ; $92d9
	dc.b	0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f ; $92e1
	dc.b	0x90,0x3f,0x90,0x40,0x8d,0x41,0x8d,0x3f ; $92e9
	dc.b	0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f ; $92f1
	dc.b	0x90,0x3f,0x90,0xfe,0x02,0x0c,0x5d,0x95 ; $92f9
	dc.b	0x5e,0x95,0x5f,0x95,0x60,0x95,0x5d,0x95 ; $9301
	dc.b	0x61,0x95,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $9309
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $9311
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $9319
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $9321
	dc.b	0x42,0x8d,0x3f,0x90,0x3f,0x90,0x3f,0x90 ; $9329
	dc.b	0x3f,0x90,0x3f,0x90,0x3f,0x90,0xfe,0x02 ; $9331
	dc.b	0x0d,0x3c,0x90,0x3c,0x90,0x3c,0x90,0x3c ; $9339
	dc.b	0x90,0x3c,0x90,0x3c,0x90,0x64,0x95,0x62 ; $9341
	dc.b	0x95,0x63,0x95,0x62,0x95,0x63,0x95,0x61 ; $9349
	dc.b	0x95,0x5d,0x95,0x5f,0x95,0x5f,0x95,0x60 ; $9351
	dc.b	0x95,0x3f,0x90,0x3f,0x90,0x3f,0x90,0x43 ; $9359
	dc.b	0x95,0x43,0x95,0x44,0x95,0x45,0x95,0x46 ; $9361
	dc.b	0x95,0x3f,0x90,0x3f,0x90,0x3f,0x90,0x3f ; $9369
	dc.b	0x90,0xfe,0x07,0x0e,0x54,0xfd,0x53,0xfd ; $9371
	dc.b	0x52,0xfd,0x51,0xfd,0x50,0xfd,0x4f,0xfd ; $9379
	dc.b	0x4e,0xfd,0x4d,0xfd,0x4c,0xfd,0xfe,0x12 ; $9381
	dc.b	0x0e,0x4b,0xf5,0xfe,0x16,0x0e,0x4b,0xf5 ; $9389
	dc.b	0xfe,0x1a,0x0e,0x4b,0xf5,0xfe,0x02,0x0f ; $9391
	dc.b	0x51,0xfd,0x50,0xfd,0x4f,0xfd,0x4e,0xfd ; $9399
	dc.b	0x55,0xfd,0x55,0xfd,0x5a,0x05,0x5b,0x05 ; $93a1
	dc.b	0x5c,0x05,0x55,0xfd,0x4d,0xfd,0x4c,0xfd ; $93a9
	dc.b	0xfe,0x02,0x10,0x55,0xfd,0x55,0xfd,0x55 ; $93b1
	dc.b	0xfd,0x58,0x05,0x59,0x05,0x57,0x05,0x55 ; $93b9
	dc.b	0xfd,0x55,0xfd,0x4d,0xfd,0x4c,0xfd,0xfe ; $93c1
	dc.b	0x0f,0x10,0x4b,0xf5,0xfe,0x14,0x10,0x4b ; $93c9
	dc.b	0xf5,0xfe,0x02,0x11,0x56,0x05,0x57,0x05 ; $93d1
	dc.b	0x55,0xfd,0x55,0xfd,0x55,0xfd,0x55,0xfd ; $93d9
	dc.b	0x4d,0xfd,0x4c,0xfd,0xfe,0x0c,0x11,0x4b ; $93e1
	dc.b	0xf5,0xfe,0x16,0x11,0x4b,0xf5,0xfe,0x19 ; $93e9
	dc.b	0x11,0x4b,0xf5,0xfe,0x02,0x12,0x55,0xfd ; $93f1
	dc.b	0x55,0xfd,0x55,0xfd,0x55,0xfd,0x4d,0xfd ; $93f9
	dc.b	0x4c,0xfd,0xfe,0x1b,0x12,0x4b,0xf5,0xfe ; $9401
	dc.b	0x02,0x13,0x55,0xfd,0x55,0xfd,0x4d,0xfd ; $9409
	dc.b	0x4c,0xfd,0xfe,0x02,0x14,0x4d,0xfd,0x4c ; $9411
	dc.b	0xfd,0xfe,0x06,0x14,0x4a,0xf5,0xfe,0x09 ; $9419
	dc.b	0x15,0x4a,0xf5,0xfe,0x0f,0x16,0x4a,0xf5 ; $9421
	dc.b	0xfe,0x17,0x16,0x4a,0xf5,0xfe,0x0a,0x1b ; $9429
	dc.b	0x48,0xf5,0x49,0xf5,0xfe,0x13,0x1c,0x48 ; $9431
	dc.b	0xf5,0x49,0xf5,0xfe,0x18,0x1c,0x48,0xf5 ; $9439
	dc.b	0x49,0xf5,0xfe,0x0f,0x1c,0x48,0xf5,0x49 ; $9441
	dc.b	0xf5,0xff,0x02,0x00,0x3d,0x18,0x3d,0x18 ; $9449
	dc.b	0x3d,0x18,0xfe,0x1b,0x00,0x3d,0x18,0x3d ; $9451
	dc.b	0x18,0x3d,0x18,0xfe,0x02,0x01,0x3d,0x18 ; $9459
	dc.b	0x3d,0x18,0x3d,0x18,0xfe,0x1b,0x01,0x3d ; $9461
	dc.b	0x18,0x7b,0x1d,0x3d,0x18,0xfe,0x02,0x02 ; $9469
	dc.b	0x7b,0x1d,0x7c,0x1d,0x7d,0x1d,0xfe,0x1b ; $9471
	dc.b	0x02,0x7e,0x1d,0x3d,0x18,0x3d,0x18,0xfe ; $9479
	dc.b	0x02,0x03,0x3d,0x18,0x3d,0x18,0x3d,0x18 ; $9481
	dc.b	0xfe,0x1b,0x03,0x3d,0x18,0x3d,0x18,0x3d ; $9489
	dc.b	0x18,0xfe,0x02,0x04,0x3d,0x18,0x3d,0x18 ; $9491
	dc.b	0x7b,0x1d,0xfe,0x1b,0x04,0x80,0x1d,0x3d ; $9499
	dc.b	0x18,0x3d,0x18,0xfe,0x02,0x05,0x3d,0x18 ; $94a1
	dc.b	0x3d,0x18,0x3d,0x18,0xfe,0x1b,0x05,0x80 ; $94a9
	dc.b	0x1d,0x7d,0x1d,0x7e,0x1d,0xfe,0x02,0x06 ; $94b1
	dc.b	0x3c,0x00,0x3c,0x00,0xad,0xcd,0xfe,0x1b ; $94b9
	dc.b	0x06,0x80,0x1d,0x3d,0x18,0x3d,0x18,0xfe ; $94c1
	dc.b	0x02,0x07,0x3c,0x00,0x3c,0x00,0xac,0xcd ; $94c9
	dc.b	0xfe,0x1b,0x07,0x3c,0x00,0x3d,0x18,0x3d ; $94d1
	dc.b	0x18,0xfe,0x02,0x08,0x3c,0x00,0x3c,0x00 ; $94d9
	dc.b	0xac,0xcd,0xac,0xcd,0xac,0xcd,0xac,0xcd ; $94e1
	dc.b	0x7c,0x1d,0x7d,0x1d,0x7e,0x1d,0x3d,0x18 ; $94e9
	dc.b	0x3d,0x18,0x3d,0x18,0x3d,0x18,0x3d,0x18 ; $94f1
	dc.b	0x3d,0x18,0x3d,0x18,0x3d,0x18,0x3d,0x18 ; $94f9
	dc.b	0x7f,0x1d,0x80,0x1d,0x3c,0x00,0x3c,0x00 ; $9501
	dc.b	0x3c,0x00,0x80,0x1d,0x7f,0x1d,0x80,0x1d ; $9509
	dc.b	0x3d,0x18,0x3d,0x18,0xfe,0x02,0x09,0x3c ; $9511
	dc.b	0x00,0x3c,0x00,0xac,0xcd,0xac,0xcd,0xac ; $9519
	dc.b	0xcd,0xac,0xcd,0x3d,0x18,0x3d,0x18,0x3d ; $9521
	dc.b	0x18,0x3d,0x18,0x3d,0x18,0x3d,0x18,0x3d ; $9529
	dc.b	0x18,0x3d,0x18,0x7b,0x1d,0x7c,0x1d,0x7d ; $9531
	dc.b	0x1d,0x7e,0x1d,0x7f,0x1d,0x80,0x1d,0x7f ; $9539
	dc.b	0x1d,0x80,0x1d,0x7f,0x1d,0x3c,0x00,0x7f ; $9541
	dc.b	0x1d,0x80,0x1d,0x3d,0x18,0x3d,0x18,0xfe ; $9549
	dc.b	0x02,0x0a,0x3c,0x00,0x3c,0x00,0xac,0xcd ; $9551
	dc.b	0xac,0xcd,0xac,0xcd,0xac,0xcd,0x3d,0x18 ; $9559
	dc.b	0x3d,0x18,0x3d,0x18,0x3d,0x18,0x3d,0x18 ; $9561
	dc.b	0x3d,0x18,0x3d,0x18,0x7e,0x1d,0x3d,0x18 ; $9569
	dc.b	0x3d,0x18,0x3d,0x18,0x3d,0x18,0x7f,0x1d ; $9571
	dc.b	0x80,0x1d,0x7f,0x1d,0x80,0x1d,0x7f,0x1d ; $9579
	dc.b	0x3e,0x18,0x7f,0x1d,0x80,0x1d,0x81,0x1d ; $9581
	dc.b	0x82,0x1d,0xfe,0x02,0x0b,0x3c,0x00,0x3c ; $9589
	dc.b	0x00,0xac,0xcd,0xac,0xcd,0xac,0xcd,0xac ; $9591
	dc.b	0xcd,0xa2,0x15,0xa2,0x15,0xa2,0x15,0xa1 ; $9599
	dc.b	0x1d,0x3d,0x18,0x3d,0x18,0x3d,0x18,0x3d ; $95a1
	dc.b	0x18,0x3d,0x18,0x3d,0x18,0x3d,0x18,0x3d ; $95a9
	dc.b	0x18,0x7f,0x1d,0x80,0x1d,0x7f,0x1d,0x80 ; $95b1
	dc.b	0x1d,0x3c,0x00,0x3c,0x00,0x81,0x1d,0x82 ; $95b9
	dc.b	0x1d,0x85,0x1d,0x86,0x1d,0xfe,0x02,0x0c ; $95c1
	dc.b	0x3c,0x00,0x3c,0x00,0xac,0xcd,0xac,0xcd ; $95c9
	dc.b	0xac,0xcd,0xac,0xcd,0xa2,0x15,0xa2,0x15 ; $95d1
	dc.b	0xa2,0x15,0xa0,0x15,0x3d,0x18,0x9f,0x1d ; $95d9
	dc.b	0x9d,0x1d,0x99,0x1d,0x3d,0x18,0x3d,0x18 ; $95e1
	dc.b	0x3d,0x18,0x3d,0x18,0x3c,0x00,0x80,0x1d ; $95e9
	dc.b	0x3c,0x00,0x80,0x1d,0x7f,0x1d,0x80,0x1d ; $95f1
	dc.b	0x87,0x1d,0x88,0x1d,0x89,0x1d,0x8a,0x1d ; $95f9
	dc.b	0xfe,0x02,0x0d,0xab,0x15,0xab,0x15,0xab ; $9601
	dc.b	0x15,0xab,0x15,0xab,0x15,0xa6,0x15,0xa3 ; $9609
	dc.b	0x15,0xa4,0x15,0xa2,0x15,0x9b,0x1d,0x93 ; $9611
	dc.b	0xe5,0x3d,0x10,0x93,0xe5,0x9b,0x1d,0x3d ; $9619
	dc.b	0x18,0x93,0xe5,0x94,0x1d,0x3d,0x18,0x7f ; $9621
	dc.b	0x1d,0x3c,0x00,0x3c,0x00,0x80,0x1d,0x7f ; $9629
	dc.b	0x1d,0x80,0x1d,0x8b,0x1d,0x8c,0x1d,0x8d ; $9631
	dc.b	0x1d,0x8e,0x1d,0xfe,0x02,0x0e,0x3e,0x58 ; $9639
	dc.b	0x3e,0x58,0x3e,0x58,0x3e,0x58,0xa7,0x5d ; $9641
	dc.b	0x3e,0x58,0xaa,0x5d,0xa2,0x15,0xa2,0x15 ; $9649
	dc.b	0x9c,0x1d,0x93,0xe5,0x93,0xe5,0x93,0xe5 ; $9651
	dc.b	0x9c,0x1d,0x3d,0x18,0x93,0xe5,0x96,0x1d ; $9659
	dc.b	0x92,0x1d,0x7f,0x1d,0x80,0x1d,0x7f,0x1d ; $9661
	dc.b	0x80,0x1d,0x7f,0x1d,0x3c,0x00,0x8f,0x1d ; $9669
	dc.b	0x90,0x1d,0x91,0x1d,0x84,0x1d,0xfe,0x02 ; $9671
	dc.b	0x0f,0xa9,0x5d,0xa9,0x5d,0xa9,0x5d,0xa9 ; $9679
	dc.b	0x5d,0xa8,0x5d,0xa9,0x5d,0xaa,0x5d,0xa2 ; $9681
	dc.b	0x15,0xa2,0x15,0x9e,0x1d,0x3d,0x10,0x93 ; $9689
	dc.b	0xe5,0x93,0xe5,0x9e,0x1d,0x98,0x25,0x93 ; $9691
	dc.b	0xe5,0x97,0x1d,0x3c,0x00,0x7f,0x1d,0x80 ; $9699
	dc.b	0x1d,0x7f,0x1d,0x80,0x1d,0x7f,0x1d,0x3c ; $96a1
	dc.b	0x00,0x83,0x1d,0x84,0x1d,0x84,0x1d,0x84 ; $96a9
	dc.b	0x1d,0xfe,0x02,0x10,0xa9,0x5d,0xa9,0x5d ; $96b1
	dc.b	0xa9,0x5d,0xa9,0x5d,0xa8,0x5d,0xa9,0x5d ; $96b9
	dc.b	0xaa,0x5d,0xa2,0x15,0xa2,0x15,0x9e,0x1d ; $96c1
	dc.b	0x3d,0x10,0x3d,0x10,0x3d,0x10,0x9e,0x1d ; $96c9
	dc.b	0x9a,0x25,0x93,0xe5,0x3c,0x00,0x3c,0x00 ; $96d1
	dc.b	0x3c,0x00,0x3c,0x00,0x3c,0x00,0x3c,0x00 ; $96d9
	dc.b	0x3c,0x00,0x3c,0x00,0x83,0x1d,0x84,0x1d ; $96e1
	dc.b	0x84,0x1d,0x84,0x1d,0xfe,0x02,0x11,0x3f ; $96e9
	dc.b	0xd8,0x3f,0xd8,0x75,0xdd,0x76,0xdd,0x73 ; $96f1
	dc.b	0xdd,0x74,0xdd,0xfe,0x18,0x11,0x77,0xdd ; $96f9
	dc.b	0x78,0xdd,0x79,0xdd,0x7a,0xdd,0x3f,0xd8 ; $9701
	dc.b	0x3f,0xd8,0xfe,0x02,0x12,0x73,0xdd,0x74 ; $9709
	dc.b	0xdd,0xfe,0x1c,0x12,0x77,0xdd,0x78,0xdd ; $9711
	dc.b	0xff,0x02,0x00,0x3c,0x88,0x3c,0x88,0x3c ; $9719
	dc.b	0x88,0xfe,0x1b,0x00,0x3c,0x88,0x3c,0x88 ; $9721
	dc.b	0x3c,0x88,0xfe,0x02,0x01,0x3c,0x88,0x3c ; $9729
	dc.b	0x88,0x3c,0x88,0xfe,0x1b,0x01,0x3c,0x88 ; $9731
	dc.b	0x3c,0x88,0x3c,0x88,0xfe,0x02,0x02,0xae ; $9739
	dc.b	0x95,0xae,0x95,0xae,0x95,0xfe,0x1b,0x02 ; $9741
	dc.b	0x3c,0x88,0x3c,0x88,0x3c,0x88,0xfe,0x02 ; $9749
	dc.b	0x03,0xaf,0x15,0xaf,0x15,0xaf,0x15,0xfe ; $9751
	dc.b	0x1b,0x03,0x3c,0x88,0x3c,0x88,0x3c,0x88 ; $9759
	dc.b	0xfe,0x02,0x04,0xaf,0x15,0xaf,0x15,0xaf ; $9761
	dc.b	0x15,0xfe,0x1b,0x04,0x3c,0x88,0x3c,0x88 ; $9769
	dc.b	0x3c,0x88,0xfe,0x02,0x05,0xaf,0x15,0xaf ; $9771
	dc.b	0x15,0xaf,0x15,0xfe,0x1b,0x05,0x3c,0x88 ; $9779
	dc.b	0x3c,0x88,0x3c,0x88,0xfe,0x02,0x06,0xb0 ; $9781
	dc.b	0x15,0xb0,0x15,0xb0,0x15,0xfe,0x1b,0x06 ; $9789
	dc.b	0x3c,0x88,0x3c,0x88,0x3c,0x88,0xfe,0x02 ; $9791
	dc.b	0x07,0x3f,0x00,0x3f,0x00,0x3f,0x00,0xfe ; $9799
	dc.b	0x1b,0x07,0xc4,0xdd,0xc5,0xdd,0xc6,0xdd ; $97a1
	dc.b	0xfe,0x02,0x08,0x3f,0x00,0x3f,0x00,0x3f ; $97a9
	dc.b	0x00,0x3f,0x00,0x3f,0x00,0x3f,0x00,0x3f ; $97b1
	dc.b	0x00,0x3f,0x00,0x3f,0x00,0x3f,0x00,0x3f ; $97b9
	dc.b	0x00,0x3f,0x00,0x3f,0x00,0x3f,0x00,0x3f ; $97c1
	dc.b	0x00,0x3f,0x00,0x3f,0x00,0x3f,0x00,0x3c ; $97c9
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88,0x3c ; $97d1
	dc.b	0x88,0x3c,0x88,0x3c,0x88,0xcd,0xdd,0xce ; $97d9
	dc.b	0xdd,0xcf,0xdd,0xfe,0x02,0x09,0x3f,0x00 ; $97e1
	dc.b	0x3f,0x00,0xb1,0x05,0xb2,0x05,0x3f,0x00 ; $97e9
	dc.b	0x3f,0x00,0xb1,0x05,0xb2,0x05,0x3f,0x00 ; $97f1
	dc.b	0x3f,0x00,0xb1,0x05,0xb2,0x05,0x3f,0x00 ; $97f9
	dc.b	0x3f,0x00,0xb1,0x05,0xb2,0x05,0x3f,0x00 ; $9801
	dc.b	0x3f,0x00,0x3c,0x88,0x3c,0x88,0xb9,0x8d ; $9809
	dc.b	0xb8,0x8d,0xbf,0x8d,0xc0,0x8d,0x3c,0x88 ; $9811
	dc.b	0xe4,0xdd,0xe5,0xdd,0xe6,0xdd,0xfe,0x02 ; $9819
	dc.b	0x0a,0x3f,0x00,0x3f,0x00 ; $9821
table_9826:
	dc.b	0x3c,0x00,0xb3,0x05,0x3f,0x00,0x3f,0x00 ; table_9826
	dc.b	0x3c,0x00,0xb3,0x05,0x3f,0x00,0x3f,0x00 ; $982e
	dc.b	0x3c,0x00,0xb3,0x05,0x3f,0x00 ; $9836
table_983c:
	dc.b	0x3f,0x00,0x3c,0x00,0xb3,0x05,0x3f,0x00 ; $983c
	dc.b	0x3f,0x00,0x3c,0x88,0xbb,0x8d,0xba,0x8d ; $9844
	dc.b	0xbc,0x8d,0xbe,0x8d,0xc1,0x8d,0xe7,0xdd ; $984c
	dc.b	0xe8,0xdd,0xe9,0xdd,0xea,0xdd,0xfe,0x02 ; $9854
	dc.b	0x0b,0x3f,0x00,0x3f,0x00,0x3f,0x00,0x3f ; $985c
	dc.b	0x00,0x3f,0x00,0x3f,0x00,0x3f,0x00,0x3f ; $9864
	dc.b	0x00,0x3f,0x00,0x3f,0x00,0x3f,0x00,0x3f ; $986c
	dc.b	0x00,0x3f,0x00,0x3f,0x00,0x3f,0x00,0x3f ; $9874
	dc.b	0x00,0x3f,0x00,0x3f,0x00,0x3d,0x88,0x3d ; $987c
	dc.b	0x88,0xbd,0x8d,0x3d,0x88,0xe2,0x8d,0x3d ; $9884
	dc.b	0x88,0x3d,0x88,0x3d,0x88,0xc3,0xcd,0xc9 ; $988c
	dc.b	0x65,0xfe,0x02,0x0c,0xb5,0x05,0xb5,0x05 ; $9894
	dc.b	0xb5,0x05,0xb5,0x05,0xb5,0x05,0xb5,0x05 ; $989c
	dc.b	0xb5,0x05,0xb5,0x05,0xb5,0x05,0xb5,0x05 ; $98a4
	dc.b	0xb5,0x05,0xb5,0x05,0xb5,0x05,0xb5,0x05 ; $98ac
	dc.b	0xb5,0x05,0xb5,0x05,0xb5,0x05,0xb4,0x05 ; $98b4
	dc.b	0x3c,0x88,0x3c,0x88,0xc4,0xdd,0xc5,0xdd ; $98bc
	dc.b	0xc6,0xdd,0xc7,0xdd,0xc8,0xdd,0x3c,0x88 ; $98c4
	dc.b	0x3c,0x88,0xca,0x65,0xfe,0x02,0x0d,0xb6 ; $98cc
	dc.b	0x05,0xb6,0x05,0xb6,0x05,0xb6,0x05,0xb6 ; $98d4
	dc.b	0x05,0xb6,0x05,0xb6,0x05,0xb6,0x05,0xb6 ; $98dc
	dc.b	0x05,0xb6,0x05,0xb6,0x05,0xb6,0x05,0xb6 ; $98e4
	dc.b	0x05,0xb6,0x05,0xb6,0x05,0xb6,0x05,0xb6 ; $98ec
	dc.b	0x05,0xb7,0x05,0x3c,0x88,0x3c,0x88,0xcd ; $98f4
	dc.b	0xdd,0xce,0xdd,0xcf,0xdd,0xd0,0xdd,0xe3 ; $98fc
	dc.b	0x65,0xd3,0x65,0xd1,0x65,0xcb,0x65,0xfe ; $9904
	dc.b	0x02,0x0e,0xe0,0x05,0xe0,0x05,0xe0,0x05 ; $990c
	dc.b	0xe0,0x05,0xe0,0x05,0xe0,0x05,0xe0,0x05 ; $9914
	dc.b	0xe0,0x05,0xe0,0x05,0xe0,0x05,0xe0,0x05 ; $991c
	dc.b	0xe0,0x05,0xe0,0x05,0xe0,0x05,0xe0,0x05 ; $9924
	dc.b	0xe0,0x05,0xe0,0x05,0xe1,0x05,0x3c,0x88 ; $992c
	dc.b	0x3c,0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88 ; $9934
	dc.b	0x3c,0x88,0x3c,0x88,0xd4,0x65,0xd2,0x65 ; $993c
	dc.b	0x3c,0x88,0xfe,0x14,0x0f,0xd5,0xfd,0xd6 ; $9944
	dc.b	0xfd,0xeb,0xfd,0xeb,0xfd,0xd8,0xfd,0xd9 ; $994c
	dc.b	0xfd,0xeb,0xfd,0xeb,0xfd,0xd8,0xfd,0xd9 ; $9954
	dc.b	0xfd,0xfe,0x15,0x10,0xd7,0xfd,0xd5,0xfd ; $995c
	dc.b	0xd6,0xfd,0xeb,0xfd,0xeb,0xfd,0xd8,0xfd ; $9964
	dc.b	0xd9,0xfd,0xeb,0xfd,0xeb,0xfd,0xfe,0x17 ; $996c
	dc.b	0x11,0xd7,0xfd,0xda,0xfd,0xdb,0xfd,0xdc ; $9974
	dc.b	0xfd,0xdc,0xfd,0xde,0xfd,0xdf,0xfd,0xfe ; $997c
	dc.b	0x19,0x12,0xd7,0xfd,0xd5,0xfd,0xd6,0xfd ; $9984
	dc.b	0xeb,0xfd,0xeb,0xfd,0xfe,0x1b,0x13,0xd7 ; $998c
	dc.b	0xfd,0xda,0xfd,0xdb,0xfd,0xfe,0x1d,0x14 ; $9994
	dc.b	0xd7,0xfd,0xff,0x02,0x00,0x3c,0x10,0x3c ; $999c
	dc.b	0x10,0x3c,0x10,0xfe,0x1b,0x00,0x3c,0x10 ; $99a4
	dc.b	0x3c,0x10,0x3c,0x10,0xfe,0x02,0x01,0x3c ; $99ac
	dc.b	0x10,0x3c,0x10,0x3c,0x10,0xfe,0x1b,0x01 ; $99b4
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x10,0xfe,0x02 ; $99bc
	dc.b	0x02,0x3c,0x10,0x3c,0x10,0x3c,0x10,0xfe ; $99c4
	dc.b	0x1b,0x02,0x3c,0x10,0x3c,0x10,0x3c,0x10 ; $99cc
	dc.b	0xfe,0x02,0x03,0x3c,0x10,0x3c,0x10,0x3c ; $99d4
	dc.b	0x10,0xfe,0x1b,0x03,0x3c,0x10,0x3c,0x10 ; $99dc
	dc.b	0x3c,0x10,0xfe,0x02,0x04,0x3c,0x10,0x3c ; $99e4
	dc.b	0x10,0x3c,0x10,0xfe,0x1b,0x04,0x3c,0x10 ; $99ec
	dc.b	0x3c,0x10,0x3c,0x10,0xfe,0x02,0x05,0x3c ; $99f4
	dc.b	0x10,0x3c,0x10,0x3c,0x10,0xfe,0x1b,0x05 ; $99fc
	dc.b	0x3c,0x10,0x3c,0x10,0x3c,0x10,0xfe,0x02 ; $9a04
	dc.b	0x06,0x3c,0x10,0x3c,0x10,0x3c,0x10,0xfe ; $9a0c
	dc.b	0x1b,0x06,0x3c,0x10,0x3c,0x10,0x3c,0x10 ; $9a14
	dc.b	0xfe,0x02,0x07,0x3c,0x10,0x3c,0x10,0x3c ; $9a1c
	dc.b	0x10,0xfe,0x1b,0x07,0x3c,0x10,0x3c,0x10 ; $9a24
	dc.b	0x3c,0x10,0xfe,0x02,0x08,0xed,0x95,0xed ; $9a2c
	dc.b	0x95,0xed,0x95,0xed,0x95,0xed,0x95,0xed ; $9a34
	dc.b	0x95,0xed,0x95,0xed,0x95,0xed,0x95,0xed ; $9a3c
	dc.b	0x95,0xed,0x95,0xed,0x95,0xed,0x95,0xed ; $9a44
	dc.b	0x95,0xf0,0x95,0xf1,0x95,0xed,0x95,0xed ; $9a4c
	dc.b	0x95,0xed,0x95,0xed,0x95,0xed,0x95,0xed ; $9a54
	dc.b	0x95,0xed,0x95,0xed,0x95,0xed,0x95,0xed ; $9a5c
	dc.b	0x95,0xed,0x95,0xed,0x95,0xfe,0x02,0x09 ; $9a64
	dc.b	0xed,0x95,0xed,0x95,0xed,0x95,0xed,0x95 ; $9a6c
	dc.b	0xed,0x95,0xed,0x95,0xed,0x95,0xed,0x95 ; $9a74
	dc.b	0xed,0x95,0xed,0x95,0xed,0x95,0xed,0x95 ; $9a7c
	dc.b	0xed,0x95,0xed,0x95,0xf2,0x95,0xf3,0x95 ; $9a84
	dc.b	0xed,0x95,0xed,0x95,0xed,0x95,0xed,0x95 ; $9a8c
	dc.b	0xed,0x95,0xed,0x95,0xed,0x95,0xed,0x95 ; $9a94
	dc.b	0xed,0x95,0xed,0x95,0xed,0x95,0xed,0x95 ; $9a9c
	dc.b	0xfe,0x02,0x0a,0xec,0x95,0xec,0x95,0xec ; $9aa4
	dc.b	0x95,0xec,0x95,0xec,0x95,0xec,0x95,0xec ; $9aac
	dc.b	0x95,0xec,0x95,0xec,0x95,0xec,0x95,0xec ; $9ab4
	dc.b	0x95,0xec,0x95,0xec,0x95,0xef,0x95,0xf4 ; $9abc
	dc.b	0x95,0xec,0x95,0xec,0x95,0xec,0x95,0xec ; $9ac4
	dc.b	0x95,0xec,0x95,0xec,0x95,0xec,0x95,0xec ; $9acc
	dc.b	0x95,0xec,0x95,0xec,0x95,0xec,0x95,0xec ; $9ad4
	dc.b	0x95,0xec,0x95,0xfe,0x02,0x0b,0xec,0x95 ; $9adc
	dc.b	0xec,0x95,0xec,0x95,0xec,0x95,0xec,0x95 ; $9ae4
	dc.b	0xec,0x95,0xf9,0x8d,0xfa,0x8d,0xfd,0x8d ; $9aec
	dc.b	0x00,0x8e,0x01,0x8e,0x02,0x8e,0x03,0x8e ; $9af4
	dc.b	0xf5,0x95,0xf6,0x95,0x1c,0x8e,0x1d,0x8e ; $9afc
	dc.b	0x1e,0x8e,0x1f,0x8e,0x20,0x8e,0x21,0x8e ; $9b04
	dc.b	0x22,0x8e,0xec,0x95,0xec,0x95,0xec,0x95 ; $9b0c
	dc.b	0xec,0x95,0xec,0x95,0xec,0x95,0xfe,0x02 ; $9b14
	dc.b	0x0c,0xec,0x95,0xec,0x95,0xf9,0x8d,0xfa ; $9b1c
	dc.b	0x8d,0xfb,0x8d,0xfc,0x8d,0x3f,0x00,0x3f ; $9b24
	dc.b	0x00,0x3f,0x00,0x3f,0x00,0x18,0xc6,0x19 ; $9b2c
	dc.b	0xc6,0x1a,0xc6,0x1b,0xc6,0x27,0xc6,0x28 ; $9b34
	dc.b	0xc6,0x29,0xc6,0x2a,0xc6,0x3f,0x00,0x3f ; $9b3c
	dc.b	0x00,0x3f,0x00,0x3f,0x00,0x23,0x8e,0x24 ; $9b44
	dc.b	0x8e,0x25,0x8e,0x26,0x8e,0xec,0x95,0xec ; $9b4c
	dc.b	0x95,0xfe,0x02,0x0d,0xf7,0x8d,0xf8,0x8d ; $9b54
	dc.b	0x06,0x8e,0x07,0x8e,0x08,0x8e,0x09,0x8e ; $9b5c
	dc.b	0x14,0xc6,0x15,0xc6,0x16,0xc6,0x17,0xc6 ; $9b64
	dc.b	0x17,0xc6,0x17,0xc6,0x17,0xc6,0x17,0xc6 ; $9b6c
	dc.b	0x17,0xc6,0x17,0xc6,0x17,0xc6,0x17,0xc6 ; $9b74
	dc.b	0x17,0xc6,0x2b,0xc6,0x2c,0xc6,0x2d,0xc6 ; $9b7c
	dc.b	0x3f,0x00,0x3f,0x00,0x3f,0x00,0x3f,0x00 ; $9b84
	dc.b	0x23,0x8e,0x24,0x8e,0xfe,0x02,0x0e,0x04 ; $9b8c
	dc.b	0x8e,0x05,0x8e,0x0c,0x8e,0x0d,0x8e,0x12 ; $9b94
	dc.b	0xc6,0x13,0xc6,0x17,0xc6,0x17,0xc6,0x17 ; $9b9c
	dc.b	0xc6,0x17,0xc6,0x33,0xc6,0x32,0xc6,0x3c ; $9ba4
	dc.b	0xc0,0x3c,0xc0,0x3c,0xc0,0x3c,0xc0,0x30 ; $9bac
	dc.b	0xc6,0x31,0xc6,0x17,0xc6,0x17,0xc6,0x17 ; $9bb4
	dc.b	0xc6,0x17,0xc6,0x2e,0xc6,0x2f,0xc6,0x3f ; $9bbc
	dc.b	0x00,0x3f,0x00,0x3f,0x00,0x3f,0x00,0xfe ; $9bc4
	dc.b	0x02,0x0f,0x0a,0x8e,0x0b,0x8e,0x10,0xc6 ; $9bcc
	dc.b	0x11,0xc6,0x17,0xc6,0x17,0xc6,0x17,0xc6 ; $9bd4
	dc.b	0x17,0xc6,0x33,0xc6,0x32,0xc6,0x3c,0xc0 ; $9bdc
	dc.b	0x3c,0xc0,0x3c,0xc0,0x3c,0xc0,0x3c,0xc0 ; $9be4
	dc.b	0x3c,0xc0,0x3c,0xc0,0x3c,0xc0,0x30,0xc6 ; $9bec
	dc.b	0x31,0xc6,0x17,0xc6,0x17,0xc6,0x17,0xc6 ; $9bf4
	dc.b	0x17,0xc6,0x2e,0xc6,0x2f,0xc6,0x3f,0x00 ; $9bfc
	dc.b	0x3f,0x00,0xfe,0x02,0x10,0x0e,0xc6,0x0f ; $9c04
	dc.b	0xc6,0x3a,0xc6,0x3a,0xc6,0x36,0xb6,0x37 ; $9c0c
	dc.b	0xb6,0x3a,0xc6,0x3a,0xc6,0x35,0xb6,0x34 ; $9c14
	dc.b	0xb6,0x34,0xb6,0x34,0xb6,0x34,0xb6,0x34 ; $9c1c
	dc.b	0xb6,0x34,0xb6,0x34,0xb6,0x34,0xb6,0x34 ; $9c24
	dc.b	0xb6,0x34,0xb6,0x35,0xb6,0x3a,0xc6,0x3a ; $9c2c
	dc.b	0xc6,0x36,0xb6,0x37,0xb6,0x3a,0xc6,0x3a ; $9c34
	dc.b	0xc6,0x3e,0xc6,0x3f,0xc6,0xfe,0x02,0x11 ; $9c3c
	dc.b	0x3b,0xc6,0x3b,0xc6,0x3b,0xc6,0x3b,0xc6 ; $9c44
	dc.b	0x38,0xb6,0x39,0xb6,0x3b,0xc6,0x3b,0xc6 ; $9c4c
	dc.b	0x3b,0xc6,0x3b,0xc6,0x3b,0xc6,0x3b,0xc6 ; $9c54
	dc.b	0x3b,0xc6,0x3b,0xc6,0x3b,0xc6,0x3b,0xc6 ; $9c5c
	dc.b	0x3b,0xc6,0x3b,0xc6,0x3b,0xc6,0x3b,0xc6 ; $9c64
	dc.b	0x3b,0xc6,0x3b,0xc6,0x38,0xb6,0x39,0xb6 ; $9c6c
	dc.b	0x3b,0xc6,0x3b,0xc6,0x3b,0xc6,0x3b,0xc6 ; $9c74
	dc.b	0xfe,0x02,0x12,0x3c,0xc6,0x3c,0xc6,0x3c ; $9c7c
	dc.b	0xc6,0x3c,0xc6,0x3c,0xc6,0x3c,0xc6,0x3c ; $9c84
	dc.b	0xc6,0x3c,0xc6,0x3c,0xc6,0x3c,0xc6,0x3c ; $9c8c
	dc.b	0xc6,0x3c,0xc6,0x3c,0xc6,0x3c,0xc6,0x3c ; $9c94
	dc.b	0xc6,0x3c,0xc6,0x3c,0xc6,0x3c,0xc6,0x3c ; $9c9c
	dc.b	0xc6,0x3c,0xc6,0x3c,0xc6,0x3c,0xc6,0x3c ; $9ca4
	dc.b	0xc6,0x3c,0xc6,0x3c,0xc6,0x3c,0xc6,0x3c ; $9cac
	dc.b	0xc6,0x3c,0xc6,0xff,0x02,0x00,0x3d,0x30 ; $9cb4
	dc.b	0x3d,0x30,0x3d,0x30,0xfe,0x1b,0x00,0x3d ; $9cbc
	dc.b	0x30,0x3d,0x30,0x3d,0x30,0xfe,0x02,0x01 ; $9cc4
	dc.b	0x3d,0x30,0x3d,0x30,0x3d,0x30,0xfe,0x1b ; $9ccc
	dc.b	0x01,0x3d,0x30,0x82,0x36,0x3d,0x30,0xfe ; $9cd4
	dc.b	0x02,0x02,0x3d,0x30,0x3d,0x30,0x3d,0x30 ; $9cdc
	dc.b	0xfe,0x1b,0x02,0x80,0x36,0x81,0x36,0x3d ; $9ce4
	dc.b	0x30,0xfe,0x02,0x03,0x3d,0x30,0x81,0x36 ; $9cec
	dc.b	0x80,0x36,0xfe,0x1b,0x03,0x82,0x36,0x3d ; $9cf4
	dc.b	0x30,0x3d,0x30,0xfe,0x02,0x04,0x3d,0x30 ; $9cfc
	dc.b	0x80,0x36,0x81,0x36,0xfe,0x1b,0x04,0x3d ; $9d04
	dc.b	0x30,0x61,0x36,0x60,0x36,0xfe,0x02,0x05 ; $9d0c
	dc.b	0x82,0x36,0x3d,0x30,0x3d,0x30,0xfe,0x1b ; $9d14
	dc.b	0x05,0x64,0x36,0x62,0x36,0x63,0x36,0xfe ; $9d1c
	dc.b	0x02,0x06,0x3d,0x30,0x3d,0x30,0x3d,0x30 ; $9d24
	dc.b	0xfe,0x1b,0x06,0x65,0x36,0x3e,0x30,0x3e ; $9d2c
	dc.b	0x30,0xfe,0x02,0x07,0x3d,0x30,0x82,0x36 ; $9d34
	dc.b	0x3d,0x30,0xfe,0x1b,0x07,0x3e,0x30,0x3e ; $9d3c
	dc.b	0x30,0x3e,0x30,0xfe,0x02,0x08,0x3d,0x30 ; $9d44
	dc.b	0x3d,0x30,0x82,0x36,0x3d,0x30,0x81,0x36 ; $9d4c
	dc.b	0x80,0x36,0x81,0x36,0x3d,0x30,0x7d,0x36 ; $9d54
	dc.b	0x7c,0x36,0x3d,0x30,0x3d,0x30,0x3d,0x30 ; $9d5c
	dc.b	0x82,0x36,0x81,0x36,0x80,0x36,0x82,0x36 ; $9d64
	dc.b	0x3d,0x30,0x68,0x4e,0x67,0x36,0x66,0x36 ; $9d6c
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0x70,0x7e ; $9d74
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0xfe,0x02 ; $9d7c
	dc.b	0x09,0x3d,0x30,0x3d,0x30,0x46,0x4e,0x3d ; $9d84
	dc.b	0x30,0x3d,0x30,0x3d,0x30,0x82,0x36,0x3d ; $9d8c
	dc.b	0x30,0x7e,0x36,0x7f,0x36,0x3d,0x30,0x82 ; $9d94
	dc.b	0x36,0x81,0x36,0x80,0x36,0x80,0x36,0x81 ; $9d9c
	dc.b	0x36,0x3d,0x30,0x6a,0x4e,0x69,0x4e,0x6d ; $9da4
	dc.b	0x7e,0x6e,0x7e,0x6f,0x7e,0x84,0x7e,0x83 ; $9dac
	dc.b	0x7e,0x71,0x7e,0x75,0x7e,0x3e,0x78,0x3e ; $9db4
	dc.b	0x78,0xfe,0x02,0x0a,0x3d,0x30,0x3d,0x30 ; $9dbc
	dc.b	0x47,0x4e,0x48,0x4e,0x3d,0x30,0x43,0x4e ; $9dc4
	dc.b	0x46,0x4e,0x3d,0x30,0x3d,0x30,0x3d,0x30 ; $9dcc
	dc.b	0x3d,0x30,0x3d,0x30,0x3d,0x30,0x3d,0x30 ; $9dd4
	dc.b	0x82,0x36,0x3d,0x30,0x6a,0x4e,0x69,0x4e ; $9ddc
	dc.b	0x3c,0x48,0x3c,0x48,0x3c,0x48,0x3c,0x48 ; $9de4
	dc.b	0x3c,0x48,0x3c,0x48,0x72,0x7e,0x73,0x7e ; $9dec
	dc.b	0x74,0x7e,0x3e,0x78,0xfe,0x02,0x0b,0x3d ; $9df4
	dc.b	0x30,0x46,0x4e,0x47,0x4e,0x49,0x4e,0x44 ; $9dfc
	dc.b	0x4e,0x45,0x4e,0x47,0x4e,0x3d,0x30,0x3d ; $9e04
	dc.b	0x30,0x3d,0x30,0x3d,0x30,0x3d,0x30,0x3d ; $9e0c
	dc.b	0x30,0x3d,0x30,0x3d,0x30,0x3d,0x30,0x6c ; $9e14
	dc.b	0x4e,0x3c,0x48,0x3c,0x48,0x3c,0x48,0x3c ; $9e1c
	dc.b	0x48,0x3c,0x48,0x3c,0x48,0x3c,0x48,0x3c ; $9e24
	dc.b	0x48,0x3c,0x48,0x85,0x7e,0x3e,0x78,0xfe ; $9e2c
	dc.b	0x02,0x0c,0x3d,0x30,0x42,0x4e,0x44,0x4e ; $9e34
	dc.b	0x4a,0x4e,0x45,0x4e,0x45,0x4e,0x3d,0x30 ; $9e3c
	dc.b	0x3d,0x30,0x4d,0x36,0x4c,0x36,0x4b,0xa6 ; $9e44
	dc.b	0x0a,0xb4,0x31,0xa4,0x31,0xa4,0x31,0xa4 ; $9e4c
	dc.b	0x31,0xa4,0x31,0xa4,0x0a,0xb4,0x31,0xa4 ; $9e54
	dc.b	0x31,0xa4,0x4b,0xf5,0x3d,0x70,0x76,0xa6 ; $9e5c
	dc.b	0x77,0xa6,0x78,0xa6,0x79,0xa6,0x3e,0x78 ; $9e64
	dc.b	0x3e,0x78,0xfe,0x02,0x0d,0x3d,0x30,0x3d ; $9e6c
	dc.b	0x30,0x42,0x4e,0x43,0x4e,0x3d,0x30,0x3d ; $9e74
	dc.b	0x30,0x50,0x36,0x4f,0x36,0x4e,0x36,0x3e ; $9e7c
	dc.b	0x78,0x56,0xa6,0x3d,0x70,0x09,0xb4,0xfe ; $9e84
	dc.b	0x18,0x0d,0x09,0xb4,0x3d,0x70,0x09,0xb4 ; $9e8c
	dc.b	0x3d,0x70,0x7a,0xa6,0x7b,0xa6,0xfe,0x02 ; $9e94
	dc.b	0x0e,0x3d,0x30,0x3d,0x30,0x41,0x4e,0x3d ; $9e9c
	dc.b	0x30,0x53,0x36,0x52,0x36,0x51,0x36,0x3e ; $9ea4
	dc.b	0x78,0x58,0xa6,0x57,0xa6,0x0a,0xb4,0xfe ; $9eac
	dc.b	0x1c,0x0e,0x4b,0xf5,0xfe,0x02,0x0f,0x3d ; $9eb4
	dc.b	0x30,0x3d,0x30,0x40,0x4e,0x41,0x4e,0x54 ; $9ebc
	dc.b	0xa6,0x5a,0xa6,0x5a,0xa6,0x57,0xa6,0xfe ; $9ec4
	dc.b	0x19,0x0f,0x20,0x84,0x21,0x84,0x22,0x84 ; $9ecc
	dc.b	0xfe,0x02,0x10,0x4b,0xf5,0x3d,0x70,0x3d ; $9ed4
	dc.b	0x70,0x3d,0x70,0x0a,0xb4,0x3d,0x70,0x3d ; $9edc
	dc.b	0x70,0x3d,0x70,0x09,0xb4,0xfe,0x19,0x10 ; $9ee4
	dc.b	0x1d,0x84,0x1e,0x84,0x1f,0x84,0x0a,0xb4 ; $9eec
	dc.b	0x3d,0x70,0xfe,0x04,0x11,0x09,0xb4,0x3d ; $9ef4
	dc.b	0x70,0x3d,0x70,0x3d,0x70,0x48,0xf5,0x49 ; $9efc
	dc.b	0xf5,0xfe,0x1b,0x11,0x09,0xb4,0xfe,0x05 ; $9f04
	dc.b	0x12,0x09,0xb4,0xfe,0x1b,0x12,0x09,0xb4 ; $9f0c
	dc.b	0xfe,0x02,0x13,0x09,0xb4,0xfe,0x1c,0x13 ; $9f14
	dc.b	0x09,0xb4,0xfe,0x1a,0x14,0x0a,0xb4,0xfe ; $9f1c
	dc.b	0x1d,0x15,0x86,0xa6,0xfe,0x1a,0x16,0x0a ; $9f24
	dc.b	0xb4,0x3d,0x70,0x3d,0x70,0x87,0xa6,0xfe ; $9f2c
	dc.b	0x02,0x17,0x09,0xb4,0xfe,0x19,0x17,0x09 ; $9f34
	dc.b	0xb4,0x3d,0x70,0x3d,0x70,0x88,0xa6,0x3e ; $9f3c
	dc.b	0x78,0xfe,0x02,0x18,0x3d,0x70,0x0a,0xb4 ; $9f44
	dc.b	0x17,0x84,0x18,0x84,0x19,0x84,0x1a,0x84 ; $9f4c
	dc.b	0xfe,0x16,0x18,0x09,0xb4,0x3d,0x70,0x3d ; $9f54
	dc.b	0x70,0x3d,0x70,0x8a,0xa6,0x89,0xa6,0x3e ; $9f5c
	dc.b	0x78,0x3e,0x78,0xfe,0x02,0x19,0x3d,0x70 ; $9f64
	dc.b	0x11,0x84,0x12,0x84,0x13,0x84,0x14,0x84 ; $9f6c
	dc.b	0x15,0x84,0x16,0x84,0xfe,0x17,0x19,0x0a ; $9f74
	dc.b	0xb4,0x3d,0x70,0x88,0xa6,0x3e,0x78,0x3e ; $9f7c
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0xfe,0x03,0x1a ; $9f84
	dc.b	0x0b,0x84,0x0c,0x84,0x0d,0x84,0x0e,0x84 ; $9f8c
	dc.b	0x0f,0x84,0x10,0x84,0x3d,0x70,0x3d,0x70 ; $9f94
	dc.b	0x0a,0xb4,0x3d,0x70,0x3d,0x70,0x09,0xb4 ; $9f9c
	dc.b	0x3d,0x70,0x3d,0x70,0x3d,0x70,0x0a,0xb4 ; $9fa4
	dc.b	0x09,0xb4,0x5b,0xa6,0x5c,0xa6,0x5d,0xa6 ; $9fac
	dc.b	0x89,0xa6,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $9fb4
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0xfe,0x02 ; $9fbc
	dc.b	0x1b,0x4b,0xf5,0x3d,0x70,0x3d,0x70,0x3d ; $9fc4
	dc.b	0x70,0x3d,0x70,0x3d,0x70,0x3d,0x70,0x3d ; $9fcc
	dc.b	0x70,0x09,0xb4,0x3d,0x70,0x5b,0xa6,0x5c ; $9fd4
	dc.b	0xa6,0x5d,0xa6,0x5e,0xa6,0x5b,0xa6,0x5c ; $9fdc
	dc.b	0xa6,0x5d,0xa6,0x89,0xa6,0x3e,0x78,0x3e ; $9fe4
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $9fec
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $9ff4
	dc.b	0x78,0xfe,0x02,0x1c,0x5d,0xa6,0x89,0xa6 ; $9ffc
	dc.b	0x5f,0xa6,0x5d,0xa6,0x5c,0xa6,0x89,0xa6 ; $a004
	dc.b	0x5f,0xa6,0x5d,0xa6,0x5c,0xa6,0x89,0xa6 ; $a00c
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $a014
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $a01c
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $a024
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $a02c
	dc.b	0x3e,0x78,0x3e,0x78,0xfe,0x02,0x1d,0x3e ; $a034
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a03c
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a044
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a04c
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a054
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a05c
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a064
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0xfe ; $a06c
	dc.b	0x02,0x1e,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $a074
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $a07c
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $a084
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $a08c
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $a094
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $a09c
	dc.b	0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78 ; $a0a4
	dc.b	0x3e,0x78,0xfe,0x02,0x1f,0x3e,0x78,0x3e ; $a0ac
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a0b4
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a0bc
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a0c4
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a0cc
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a0d4
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0x3e,0x78,0x3e ; $a0dc
	dc.b	0x78,0x3e,0x78,0x3e,0x78,0xff ; $a0e4
table_a0ea:
	dc.b	0x0c,0x02,0x3f,0x18,0xbd,0x19,0xbe,0x19 ; table_a0ea
	dc.b	0x3f,0x18,0x3f,0x18,0xbf,0x19,0xc0,0x19 ; $a0f2
	dc.b	0xc1,0x19,0xfe,0x0c,0x03,0x3f,0x18,0xc2 ; $a0fa
	dc.b	0x19,0xc3,0x19,0xc4,0x19,0xc5,0x19,0xc6 ; $a102
	dc.b	0x19,0xc7,0x19,0xc8,0x19,0xfe,0x0c,0x04 ; $a10a
	dc.b	0xc9,0x19,0xca,0x19,0xcb,0x19,0xcc,0x19 ; $a112
	dc.b	0xcd,0x19,0xce,0x19,0xcf,0x19,0xfe,0x0c ; $a11a
	dc.b	0x05,0xd0,0x19,0xd1,0x19,0xd2,0x19,0xd3 ; $a122
	dc.b	0x19,0xd4,0x19,0xd5,0x19,0xd6,0x19,0xd7 ; $a12a
	dc.b	0x19,0xfe,0x0c,0x06,0xd8,0x19,0xd9,0x19 ; $a132
	dc.b	0xda,0x19,0xdb,0x19,0xdc,0x19,0xdd,0x19 ; $a13a
	dc.b	0xde,0x19,0xdf,0x19,0xfe,0x0c,0x07,0xe0 ; $a142
	dc.b	0x19,0xe1,0x19,0xe2,0x19,0xe3,0x19,0xe4 ; $a14a
	dc.b	0x19,0xe5,0x19,0xe6,0x19,0xe7,0x19,0xfe ; $a152
	dc.b	0x0c,0x08,0xe8,0x19,0xe9,0x19,0x3f,0x18 ; $a15a
	dc.b	0xea,0x19,0xeb,0x19,0xec,0x19,0xed,0x19 ; $a162
	dc.b	0xee,0x19,0xfe,0x0c,0x09,0xef,0x19,0xf0 ; $a16a
	dc.b	0x19,0xf1,0x19,0xf2,0x19,0xf3,0x19,0xf4 ; $a172
	dc.b	0x19,0xf5,0x19,0xf6,0x19,0xfe,0x0c,0x0a ; $a17a
	dc.b	0xf7,0x19,0xf8,0x19,0xf9,0x19,0xfa,0x19 ; $a182
	dc.b	0xfb,0x19,0xfc,0x19,0xfd,0x19,0xf6,0x1b ; $a18a
	dc.b	0xfe,0x0c,0x0b,0xf7,0x1b,0x00,0x1a,0x01 ; $a192
	dc.b	0x1a,0x02,0x1a,0x03,0x1a,0x3f,0x18,0x04 ; $a19a
	dc.b	0x1a,0xfe,0x0c,0x0c,0x3f,0x18,0x05,0x1a ; $a1a2
	dc.b	0x06,0x1a,0x07,0x1a,0x08,0x1a,0x09,0x1a ; $a1aa
	dc.b	0x0a,0x1a,0x0b,0x1a,0xfe,0x0c,0x0d,0x0c ; $a1b2
	dc.b	0x1a,0x0d,0x1a,0x0e,0x1a,0x0f,0x1a,0x10 ; $a1ba
	dc.b	0x1a,0x11,0x1a,0x12,0x1a,0x13,0x1a,0xfe ; $a1c2
	dc.b	0x0c,0x0e,0x14,0x1a,0x15,0x1a,0x16,0x1a ; $a1ca
	dc.b	0x17,0x1a,0x18,0x1a,0x19,0x1a,0x1a,0x1a ; $a1d2
	dc.b	0x1b,0x1a,0xfe,0x0c,0x0f,0x1c,0x1a,0x1d ; $a1da
	dc.b	0x1a,0x1e,0x1a,0x1f,0x1a,0x20,0x1a,0x21 ; $a1e2
	dc.b	0x1a,0xfe,0x0c,0x10,0x22,0x1a,0x23,0x1a ; $a1ea
	dc.b	0x3f,0x18,0x24,0x1a,0x25,0x1a,0x26,0x1a ; $a1f2
	dc.b	0xfe,0x0c,0x11,0x27,0x1a,0x28,0x1a,0x29 ; $a1fa
	dc.b	0x1a,0x2a,0x1a,0x2b,0x1a,0x2c,0x1a,0xfe ; $a202
	dc.b	0x0c,0x12,0x2d,0x1a,0x2e,0x1a,0x2f,0x1a ; $a20a
	dc.b	0x30,0x1a,0x31,0x1a,0x32,0x1a,0x33,0x1a ; $a212
	dc.b	0xfe,0x0c,0x13,0x34,0x1a,0x35,0x1a,0x36 ; $a21a
	dc.b	0x1a,0x37,0x1a,0x38,0x1a,0x39,0x1a,0x3a ; $a222
	dc.b	0x1a,0xfe,0x0c,0x14,0x3b,0x1a,0x3c,0x1a ; $a22a
	dc.b	0x3d,0x1a,0x3e,0x1a,0x3f,0x1a,0x40,0x1a ; $a232
	dc.b	0x41,0x1a,0xfe,0x0c,0x15,0xac,0x1a,0xad ; $a23a
	dc.b	0x1a,0x3f,0x18,0xae,0x1a,0xaf,0x1a,0xb0 ; $a242
	dc.b	0x1a,0xfe,0x0c,0x16,0xb1,0x1a,0xb2,0x1a ; $a24a
	dc.b	0xf0,0x1b,0xf1,0x1b,0xf2,0x1b,0xfe,0x0c ; $a252
	dc.b	0x17,0xf3,0x1b,0xf4,0x1b,0xff ; $a25a
table_a260:
	dc.b	0x02,0x1c,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; table_a260
	dc.b	0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; $a268
	dc.b	0x3c,0x98,0x3c,0x98,0x3c,0x88,0xac,0xd8 ; $a270
	dc.b	0xad,0xd8,0x3c,0x88,0x3c,0x98,0x3c,0x98 ; $a278
	dc.b	0x3c,0x88,0xac,0xd8,0xad,0xd8,0x3c,0x88 ; $a280
	dc.b	0x3c,0x98,0xb8,0xe0,0xb9,0xe0,0xba,0xe0 ; $a288
	dc.b	0xbb,0xe0,0xbc,0xe0,0xbd,0xe0,0xbe,0xe0 ; $a290
	dc.b	0x3f,0x10,0xfe,0x02,0x1d,0x3c,0x98,0x3c ; $a298
	dc.b	0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c ; $a2a0
	dc.b	0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98,0xae ; $a2a8
	dc.b	0xd8,0xaf,0x88,0xb0,0x88,0xb1,0xd8,0x3c ; $a2b0
	dc.b	0x98,0x3c,0x98,0xae,0xd8,0xaf,0x88,0xb0 ; $a2b8
	dc.b	0x88,0xb1,0xd8,0x3c,0x98,0xbf,0xe0,0xc0 ; $a2c0
	dc.b	0xe0,0xc1,0xe0,0xc2,0xe0,0xc3,0xe0,0xc4 ; $a2c8
	dc.b	0xe0,0xc5,0xe0,0x3f,0x10,0xfe,0x02,0x1e ; $a2d0
	dc.b	0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; $a2d8
	dc.b	0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98 ; $a2e0
	dc.b	0x3c,0x98,0xb2,0xd8,0xb3,0x88,0xb4,0x88 ; $a2e8
	dc.b	0xb5,0xd8,0x3c,0x98,0x3c,0x98,0xb2,0xd8 ; $a2f0
	dc.b	0xb3,0x88,0xb4,0x88,0xb5,0xd8,0x3c,0x98 ; $a2f8
	dc.b	0x42,0xe2,0x43,0xe2,0x44,0xe2,0x45,0xe2 ; $a300
	dc.b	0x46,0xe2,0x47,0xe2,0x48,0xe2,0x3c,0x98 ; $a308
	dc.b	0xfe,0x02,0x1f,0x3c,0x98,0x3c,0x98,0x3c ; $a310
	dc.b	0x98,0x3c,0x98,0x3c,0x98,0x3c,0x98,0x3c ; $a318
	dc.b	0x98,0x3c,0x98,0x3c,0x98,0x3c,0x88,0xb6 ; $a320
	dc.b	0xd8,0xb7,0xd8,0x3c,0x88,0x3c,0x98,0x3c ; $a328
	dc.b	0x98,0x3c,0x88,0xb6,0xd8,0xb7,0xd8,0x3c ; $a330
	dc.b	0x88,0x3c,0x98,0x3f,0x10,0x3f,0x10,0x3f ; $a338
	dc.b	0x10,0x3f,0x10,0x3f,0x10,0x3f,0x10,0x3f ; $a340
	dc.b	0x10,0x3f,0x10,0xff,0x00 ; $a348


move_human_player_A34D:
A34D: 3A 11 63    ld   a,(background_and_state_bits_C911)
A350: CB 7F       bit  7,a
A352: 3E 00       ld   a,$00
A354: C2 DA A9    jp   nz,$A37A		; special screens, don't move human player
A357: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
A35A: 3A 82 60    ld   a,(player_2_attack_flags_C028)
A35D: FE 03       cp   $09
A35F: 3E 00       ld   a,$00
A361: C2 C6 A9    jp   nz,$A36C
A364: CB 5E       bit  3,(hl)
A366: CA DA A9    jp   z,$A37A
A369: C3 D1 A9    jp   $A371
A36C: CB 56       bit  2,(hl)
A36E: CA DA A9    jp   z,$A37A
A371: CD BD 97    call $3DB7
; player (human) technique
A374: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; player 1: hl = C24B
A377: 77          ld   (hl),a
A378: 3E FF       ld   a,$FF
A37A: C9          ret

; roughly called every 60th frames, sometimes 2 times in the frame
; probably not or loosely synchronized with 60Hz interrupt
fight_mainloop_A37B:
A37B: CD 4B B0    call load_iy_with_player_structure_B04B
A37E: FD 36 10 00 ld   (iy+$10),$00
A382: AF          xor  a
A383: CD 5A B0    call suspend_this_task_B05A
A386: FE 03       cp   $09
A388: CA DB A9    jp   z,fight_mainloop_A37B
A38B: FE 06       cp   $0C
A38D: C4 D5 B0    call nz,display_error_text_B075

; this loops (outside the periodic interrupt)
; when players are shown and fight. either in the intro/demo
; or during a real fight
fight_mainloop_A390:
A390: CD 4B B0    call load_iy_with_player_structure_B04B
; now (1 player vs red CPU: iy = $C200)
A393: CD 82 A4    call update_players_struct_C2xx_A428
A396: CD 47 A9    call move_human_player_A34D
A399: A7          and  a
A39A: C2 10 A4    jp   nz,cpu_move_done_A410	; only humans: end
; 1 player mode: handle computer
A39D: DD 21 9B AA ld   ix,walk_frames_list_AA3B
A3A1: FD 6E 0D    ld   l,(iy+$07)
A3A4: FD 66 02    ld   h,(iy+$08)	; <= what the computer frame is
A3A7: E5          push hl
; the computer tries to find its own displayed frame in the various lists
; is the computer walking?
A3A8: CD 03 B0    call check_hl_in_ix_list_B009
A3AB: E1          pop  hl
A3AC: A7          and  a
; if walking/stands guard, computer can attack the player
A3AD: C2 9B A5    jp   nz,maybe_attack_opponent_A53B
A3B0: DD 21 47 AA ld   ix,jump_frames_list_AA4D
A3B4: E5          push hl
A3B5: CD 03 B0    call check_hl_in_ix_list_B009
A3B8: E1          pop  hl
A3B9: A7          and  a
A3BA: C2 66 AB    jp   nz,handle_cpu_land_from_jump_ABCC
A3BD: DD 21 C7 AA ld   ix,hitting_frame_list_AA6D
A3C1: E5          push hl
A3C2: CD 03 B0    call check_hl_in_ix_list_B009
A3C5: E1          pop  hl
A3C6: A7          and  a
A3C7: C2 E9 AB    jp   nz,full_blown_hit_ABE3	; missed cpu hit: let player react
; the rest of the routine is used to maintain block as long as needed
; (as long as opponent is performing the same menacing move or another
; move of the same attack height)
A3CA: DD 21 27 AA ld   ix,blocking_frame_list_AA8D
A3CE: E5          push hl
A3CF: CD 03 B0    call check_hl_in_ix_list_B009
A3D2: E1          pop  hl
A3D3: A7          and  a
A3D4: C2 FF AB    jp   nz,computer_completed_a_blocking_move_ABFF	; computer has completed a blocking move
A3D7: E5          push hl
A3D8: DD E1       pop  ix
A3DA: DD 7E 02    ld   a,(ix+$08)
A3DD: A7          and  a
A3DE: C2 62 A6    jp   nz,$ACC8		; move done
A3E1: C3 6B A6    jp   $ACCB		; move done

cpu_move_done_opponent_can_react_A3E4:
A3E4: 3A 11 63    ld   a,(background_and_state_bits_C911)
A3E7: CB BF       res  7,a	; clears bit 7
; this is during demo mode (blue "karate champ" background), 2 cpu players
; during cpu vs cpu demo (bridge), it's not $50
A3E9: FE 50       cp   $50
A3EB: CA 10 A4    jp   z,cpu_move_done_A410
A3EE: FD CB 10 4C bit  0,(iy+$10)
A3F2: C2 10 A4    jp   nz,cpu_move_done_A410
; we enter here when computer is about to attack, but (in lower difficulty levels < 16)
; it lets the opponent a chance to counter attack just before the attack
; the time for the opponent to react is smaller and smaller with increasing skill level
; attack has been already decided by functions that end up
; calling A3E4
A3F5: 21 CD A7    ld   hl,counter_attack_timer_table_AD67
A3F8: CD 6E A6    call let_opponent_react_depending_on_skill_level_ACCE
; something animation related must have been set up to handle the special (why?)
; case of counter attack with jump. Otherwise return code doesn't matter much
A3FB: FE 03       cp   $09
A3FD: CA DB A9    jp   z,fight_mainloop_A37B		; jump attack: loop back (without attacking)
A400: A7          and  a
A401: CA 03 A4    jp   z,$A409		; 0
A404: FE FF       cp   $FF
A406: C4 D5 B0    call nz,display_error_text_B075
; a = $FF: non jump counter attack has been launched by opponent
; iy is C220
; the attack move is already loaded in cpu C26B
A409: FD CB 10 6C set  0,(iy+$10)
A40D: C3 30 A9    jp   fight_mainloop_A390

; called after a non-attacking move (walk, sommersault, turn back...)
; but can also be called after deciding an attack...
cpu_move_done_A410:
A410: 3A 82 60    ld   a,(player_2_attack_flags_C028)
A413: FE 03       cp   $09
A415: 3E 0B       ld   a,$0B
A417: CA 16 A4    jp   z,$A41C
A41A: 3E 0A       ld   a,$0A
A41C: 06 07       ld   b,$0D
A41E: CD 57 B0    call task_manipulation_B05D
A421: A7          and  a
A422: C4 D5 B0    call nz,display_error_text_B075
A425: C3 DB A9    jp   fight_mainloop_A37B


update_players_struct_C2xx_A428:
A428: CD B7 B0    call disable_interrupts_B0BD		; calls disable_interrupts_BBE2 ???
A42B: ED 5B 4D 68 ld   de,(unknown_C247)		; load animation/position of player 1
A42F: 2A 43 68    ld   hl,(unknown_C249)		; load xy for player 1
A432: D9          exx  ; EXX exchanges BC, DE, and HL with shadow registers with BC', DE', and HL'.
A433: ED 5B CD 68 ld   de,(unknown_C267)		; load animation/position of player 2
A437: 2A C3 68    ld   hl,(unknown_C269)		; load xy for player 2
A43A: 3A 82 60    ld   a,(player_2_attack_flags_C028)
A43D: FE 03       cp   $09
A43F: CA 49 A4    jp   z,$A443
A442: D9          exx	; depending on the configuration (which is the human opponent), swap values
; frame ID (16 bit) in e and d
A443: FD 73 0D    ld   (iy+$07),e
A446: FD 72 02    ld   (iy+$08),d
; l: x coord (player 1: $C209) min $20
A449: FD 75 03    ld   (iy+$09),l
A44C: FD 74 0A    ld   (iy+$0a),h	 ;
A44F: D9          exx
; copy coords to opponent structure
A450: FD 73 0B    ld   (iy+$0b),e
A453: FD 72 06    ld   (iy+$0c),d
A456: FD 75 07    ld   (iy+$0d),l
A459: FD 74 0E    ld   (iy+$0e),h
A45C: CD 60 B0    call enable_interrupts_b0c0
A45F: FD CB 02 DE bit  7,(iy+$08)
A463: CA 20 A4    jp   z,$A480
A466: FD CB 02 BE res  7,(iy+$08)
A46A: FD 7E 03    ld   a,(iy+$09)
A46D: 2F          cpl
A46E: FD 77 03    ld   (iy+$09),a
A471: FD 7E 06    ld   a,(iy+$0c)
A474: EE 20       xor  $80
A476: FD 77 06    ld   (iy+$0c),a
A479: FD 7E 07    ld   a,(iy+$0d)
A47C: 2F          cpl
A47D: FD 77 07    ld   (iy+$0d),a
A480: 21 CB 68    ld   hl,unknown_C26B
A483: 3A 82 60    ld   a,(player_2_attack_flags_C028)
A486: FE 03       cp   $09
A488: CA 2E A4    jp   z,$A48E
A48B: 21 4B 68    ld   hl,current_move_C24B
A48E: 22 04 6F    ld   (address_of_current_player_move_byte_CF04),hl
A491: 23          inc  hl
A492: CD 3C A4    call $A496
A495: C9          ret

; sets attack distance (0,1,2)
A496: E5          push hl
A497: 36 00       ld   (hl),$00
A499: FD 36 0F 03 ld   (iy+$0f),$09
A49D: DD 21 00 6F ld   ix,temp_numeric_buffer_CF00
A4A1: 2A 93 A5    ld   hl,($A539)
A4A4: 22 08 6F    ld   (unknown_CF02),hl
A4A7: 21 83 A5    ld   hl,table_A529
A4AA: FD 56 07    ld   d,(iy+$0d)
A4AD: FD 5E 0E    ld   e,(iy+$0e)
A4B0: AF          xor  a
A4B1: FD 35 0F    dec  (iy+$0f)
A4B4: CA E5 A4    jp   z,$A4E5
A4B7: CD 0A A5    call $A50A
A4BA: A7          and  a
A4BB: CA 69 A4    jp   z,$A4C3
A4BE: 23          inc  hl
A4BF: 23          inc  hl
A4C0: C3 B0 A4    jp   $A4B0
A4C3: FD 7E 03    ld   a,(iy+$09)
A4C6: 86          add  a,(hl)
A4C7: DD 77 00    ld   (ix+$00),a
A4CA: 23          inc  hl
A4CB: 7E          ld   a,(hl)
A4CC: DD 77 01    ld   (ix+$01),a
A4CF: 23          inc  hl
A4D0: CD 48 B0    call is_point_in_rectangle_B042
A4D3: A7          and  a
A4D4: CA B0 A4    jp   z,$A4B0
A4D7: 3E 03       ld   a,$09
A4D9: FD 96 0F    sub  (iy+$0f)
A4DC: FD 77 0F    ld   (iy+$0f),a
A4DF: CB 3F       srl  a
A4E1: D2 E5 A4    jp   nc,$A4E5
A4E4: 3C          inc  a
A4E5: E1          pop  hl
A4E6: 77          ld   (hl),a
A4E7: FD 7E 07    ld   a,(iy+$0d)	; opponent x
A4EA: FD BE 03    cp   (iy+$09)		; player x
A4ED: DA FE A4    jp   c,$A4FE
; opponent is on the right
A4F0: FD CB 06 DE bit  7,(iy+$0c)
A4F4: C2 03 A5    jp   nz,$A509
A4F7: FD CB 0F FE set  7,(iy+$0f)
A4FB: C3 03 A5    jp   $A509
A4FE: FD CB 06 DE bit  7,(iy+$0c)
A502: CA 03 A5    jp   z,$A509
A505: FD CB 0F FE set  7,(iy+$0f)
A509: C9          ret

A50A: 7E          ld   a,(hl)
A50B: A7          and  a
A50C: FA 1A A5    jp   m,$A51A
A50F: FD 86 03    add  a,(iy+$09)
A512: 3E 00       ld   a,$00
A514: D2 82 A5    jp   nc,$A528
A517: C3 8C A5    jp   $A526
A51A: ED 44       neg
A51C: 47          ld   b,a
A51D: FD 7E 03    ld   a,(iy+$09)
A520: 90          sub  b
A521: 3E 00       ld   a,$00
A523: D2 82 A5    jp   nc,$A528
A526: 3E FF       ld   a,$FF
A528: C9          ret

table_A529:
	dc.b	0x58,0x17,0x40,0x17,0x28,0x17,0x00,0x27 ; table_A529
	dc.b	0xa0,0x17,0xb8,0x17,0xd0,0x17,0xe8,0x17 ; $a531
	dc.b	0x00,0xff ; $a539

; jump table depending on the value of iy+0xF
; this jumps to another jump table selector (which is not very performant
; as all the routines jumped to just load ix to a different value, a double
; jump could probably have been avoided. But who am I to criticize Z80 code ?
;
; note: block moves are probably triggered when cpu decides to move back and
; the player attacks at the same time (code $01)
;
maybe_attack_opponent_A53B
A53B: DD 21 4F A5 ld   ix,table_A54F
A53F: 06 00       ld   b,$00
A541: FD 4E 0F    ld   c,(iy+$0f); iy = C220: algebraic distance index (0-8 + facing direction bit 7)
A544: CB 21       sla  c		; times 2 (and gets rid of the direction bit)
A546: DD 09       add  ix,bc
A548: DD 6E 00    ld   l,(ix+$00)
A54B: DD 66 01    ld   h,(ix+$01)
A54E: E9          jp   (hl)

; fine distance 0-8 see table at the start of the file
table_A54F:
	dc.w	ai_load_table_opp_faces_very_far_A561	; 0
	dc.w	ai_load_table_opp_faces_far_A568		; 1
	dc.w	ai_load_table_opp_faces_close_A56F		; 2
	dc.w	ai_load_table_opp_faces_closer_A576	; 3
	dc.w	ai_load_table_opp_faces_closest_A57D	; 4
	dc.w	ai_load_table_opp_turns_back_far_A584 		; 5
	dc.w	ai_load_table_opp_turns_back_close_A58B 	; 6
	dc.w	ai_load_table_opp_turns_back_closer_A592	; 7
	dc.w	ai_load_table_opp_turns_back_closest_A599 	; 8

; p1 left, p2 right, far away (C20F = 0)
ai_jump_table_opp_faces_very_far_A561:
A561: DD 21 B1 A5 ld   ix,computer_ai_jump_table_all_move_towards_opponent_A651
A565: C3 37 A5    jp   jump_to_routine_from_table_A59D

; p1 left, p2 right, less far away (1)
ai_load_table_opp_faces_far_A568:
A568: DD 21 65 A5 ld   ix,ai_jump_table_opp_faces_far_A5C5
A56C: C3 37 A5    jp   jump_to_routine_from_table_A59D
; p1 left, p2 right, less far away (2)
ai_load_table_opp_faces_close_A56F:
A56F: DD 21 73 A5 ld   ix,ai_jump_table_opp_faces_close_A5D9
A573: C3 37 A5    jp   jump_to_routine_from_table_A59D
; p1 left, p2 right, less far away (3)
ai_load_table_opp_faces_closer_A576:
A576: DD 21 E7 A5 ld   ix,ai_jump_table_opp_faces_closer_A5ED
A57A: C3 37 A5    jp   jump_to_routine_from_table_A59D
; p1 left, p2 right, very close (4)
ai_load_table_opp_faces_closest_A57D:
A57D: DD 21 01 AC ld   ix,ai_jump_table_opp_faces_closest_A601
A581: C3 37 A5    jp   jump_to_routine_from_table_A59D
; p1 right, p2 left, far away (5)
ai_load_table_opp_turns_back_far_A584:
A584: DD 21 15 AC ld   ix,ai_jump_table_A615
A588: C3 37 A5    jp   jump_to_routine_from_table_A59D
; 6
ai_load_table_opp_turns_back_close_A58B:
A58B: DD 21 83 AC ld   ix,ai_jump_table_A629
A58F: C3 37 A5    jp   jump_to_routine_from_table_A59D
; 7
ai_load_table_opp_turns_back_closer_A592:
A592: DD 21 97 AC ld   ix,ai_jump_table_A63D
A596: C3 37 A5    jp   jump_to_routine_from_table_A59D
; p1 right, p2 left, very close (8)
; turn back (to face opponent)
ai_load_table_opp_turns_back_closest_A599:
A599: DD 21 51 AC ld   ix,computer_ai_jump_table_all_turn_back_A651
jump_to_routine_from_table_A59D
A59D: DD E5       push ix
A59F: CD C5 AC    call classify_opponent_move_start_A665	; retrieve value 1 -> 9
A5A2: DD E1       pop  ix
; a is the index of the routine in selected computer_ai_jump_table
; it cannot be 0
A5A4: 87          add  a,a
A5A5: 06 00       ld   b,$00
A5A7: 4F          ld   c,a
A5A8: DD 09       add  ix,bc
A5AA: DD 6E 00    ld   l,(ix+$00)
A5AD: DD 66 01    ld   h,(ix+$01)
; jump to the routine
A5B0: E9          jp   (hl)

; makes sense: players are far away, CPU just tries to get closer to player
; but can also change direction
computer_ai_jump_table_all_move_towards_opponent_A651:
	dc.w	display_error_text_B075                        ; what opponent does:
	dc.w	cpu_move_forward_towards_enemy_far_away_A6D4   ; 1: no particular stuff
	dc.w	cpu_move_forward_towards_enemy_far_away_A6D4   ; 2: frontal attack
	dc.w	cpu_move_forward_towards_enemy_far_away_A6D4   ; 3: rear attack
	dc.w	cpu_move_forward_towards_enemy_far_away_A6D4   ; 4: crouch
	dc.w	cpu_move_forward_towards_enemy_far_away_A6D4   ; 5 in-jump
	dc.w	cpu_move_forward_towards_enemy_far_away_A6D4   ; 6: sommersault forward
	dc.w	cpu_move_forward_towards_enemy_far_away_A6D4   ; 7: sommersault backwards
	dc.w	cpu_move_forward_towards_enemy_far_away_A6D4   ; 8: starting a jump
	dc.w	cpu_move_forward_towards_enemy_far_away_A6D4   ; 9: move not in list

ai_jump_table_opp_faces_far_A5C5
	dc.w	display_error_text_B075                             ; what opponent does:
	dc.w	cpu_move_forward_towards_enemy_A6E7	                ; 1: no particular stuff
	dc.w	cpu_forward_or_stop_if_facing_A6EF					; 2: frontal attack
	dc.w	cpu_forward_or_stop_if_not_facing_A700				; 3: rear attack
	dc.w	cpu_move_forward_towards_enemy_A6E7                 ; 4: crouch ($A711 jumps there)
	dc.w	cpu_move_forward_towards_enemy_A6E7                 ; 5 in-jump ($A714 jumps there)
	dc.w	cpu_forward_or_backward_depending_on_facing_A7D5	; 6: sommersault forward $A717	jumps there
	dc.w	cpu_backward_or_forward_depending_on_facing_A7E6	; 7: sommersault backwards $A71A	jumps there
	dc.w	cpu_move_forward_towards_enemy_A71D	                ; 8: starting a jump
	dc.w	cpu_move_forward_towards_enemy_A71D	                ; 9: move not in list

ai_jump_table_opp_faces_close_A5D9:
	dc.w	display_error_text_B075                             ; what opponent does:
	dc.w	attack_once_out_of_16_frames_else_walk_A725         ; 1: no particular stuff
	dc.w	cpu_avoids_low_attack_if_facing_else_maybe_attacks_A73F   ; 2: frontal attack
	dc.w	cpu_maybe_attacks_if_facing_else_avoids_low_attack_A786   ; 3: rear attack
	dc.w	just_walk_A7C5                                      ; 4: crouch
	dc.w	just_walk_A7CD                                      ; 5 in-jump
	dc.w	cpu_forward_or_backward_depending_on_facing_A7D5    ; 6: sommersault forward
	dc.w	cpu_backward_or_forward_depending_on_facing_A7E6    ; 7: sommersault backwards
	dc.w	attack_once_out_of_16_frames_else_walk_A725	        ; 8: starting a jump  $A7F7	jumps there
	dc.w	cpu_move_forward_towards_enemy_A7FA                 ; 9: move not in list

ai_jump_table_opp_faces_closer_A5ED
	dc.w	display_error_text_B075                             ; what opponent does:
	dc.w	pick_cpu_attack_A802                                ; 1: no particular stuff
	dc.w	cpu_reacts_to_low_attack_if_facing_else_attacks_A80C; 2: frontal attack
	dc.w	cpu_react_to_low_attack_or_perform_attack_A85B      ; 3: rear attack
	dc.w	cpu_small_chance_of_low_kick_else_walk_A893         ; 4: crouch
	dc.W	pick_cpu_attack_A802 ; was $A8A8                    ; 5 in-jump
	dc.W	pick_cpu_attack_A802 ; was $A8A8                    ; 6: sommersault forward
	dc.w	move_fwd_or_bwd_checking_sommersault_and_dir_A8E8   ; 7: sommersault backwards
	dc.w	pick_cpu_attack_A802  ; $A911 calls it              ; 8: starting a jump
	dc.w	pick_cpu_attack_A802  ; $A914 calls it              ; 9: move not in list

ai_jump_table_opp_faces_closest_A601
	dc.w	display_error_text_B075                             ; what opponent does:
	dc.w	get_out_of_edge_or_low_kick_A917                    ; 1: no particular stuff
	dc.w	cpu_reacts_to_low_attack_if_facing_else_attacks_A80C; 2: frontal attack $A92F
	dc.w	front_kick_or_fwd_sommersault_to_recenter_A94E      ; 3: rear attack                                    ; $A932 jumps there
	dc.w	perform_low_kick_A935	    						; 4: crouch                                      ; $A93D jumps there
	dc.w	front_kick_or_fwd_sommersault_to_recenter_A94E	    ; 5 in-jump                                      ; $A93D jumps there
	dc.w	high_attack_if_forward_sommersault_or_walk_A8AB	    ; 6: sommersault forward                        ; $A940 jumps there
	dc.w	move_fwd_or_bwd_checking_sommersault_and_dir_A8E8	; 7: sommersault backwards                     ; $A943 jumps there
	dc.w	perform_walk_back_A946                             ; 8: starting a jump
	dc.w	front_kick_or_fwd_sommersault_to_recenter_A94E      ; 9: move not in list

ai_jump_table_A615
	dc.w	display_error_text_B075
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
ai_jump_table_A629
	dc.w	display_error_text_B075
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
	dc.w	cpu_move_turn_around_A966
ai_jump_table_A63D
	dc.w	display_error_text_B075       ; what opponent does:
	dc.w	pick_cpu_attack_A96E        ; 1: no particular stuff
	dc.w	cpu_complex_reaction_to_front_attack_A980     ; 2: frontal attack
	dc.w	cpu_complex_reaction_to_rear_attack_A9D6                         ; 3: rear attack
	dc.w	foot_sweep_back_AA10  ; 4: crouch
	dc.w	pick_cpu_attack_A96E        ; 5 in-jump    $AA22
	dc.w	cpu_turn_back_AA25            ; 6: sommersault forward
	dc.w	cpu_turn_back_AA25            ; 7: sommersault backwards
	dc.w	pick_cpu_attack_A96E		  ; 8: starting a jump     $AA2D
	dc.w	pick_cpu_attack_A96E		  ; 9: move not in list      $AA30
computer_ai_jump_table_all_turn_back_A651:
	dc.w	display_error_text_B075
	dc.w	cpu_turn_back_AA33
	dc.w	cpu_turn_back_AA33
	dc.w	cpu_turn_back_AA33
	dc.w	cpu_turn_back_AA33
	dc.w	cpu_turn_back_AA33
	dc.w	cpu_turn_back_AA33
	dc.w	cpu_turn_back_AA33
	dc.w	cpu_turn_back_AA33
	dc.w	cpu_turn_back_AA33

; looks like jump table, then data, but not referenced?
A5B1:
	dc.b	0x75,0xb0,0xd4,0xa6,0xd4,0xa6,0xd4,0xa6 ; $a5b1
	dc.b	0xd4,0xa6,0xd4,0xa6,0xd4,0xa6,0xd4,0xa6 ; $a5b9
	dc.b	0xd4,0xa6,0xd4,0xa6,0x75,0xb0,0xe7,0xa6 ; $a5c1
	dc.b	0xef,0xa6,0x00,0xa7,0x11,0xa7,0x14,0xa7 ; $a5c9
	dc.b	0x17,0xa7,0x1a,0xa7,0x1d,0xa7,0x1d,0xa7 ; $a5d1
	dc.b	0x75,0xb0,0x25,0xa7,0x3f,0xa7,0x86,0xa7 ; ai_jump_table_opp_faces_close_A5D9
	dc.b	0xc5,0xa7,0xcd,0xa7,0xd5,0xa7,0xe6,0xa7 ; $a5e1
	dc.b	0xf7,0xa7,0xfa,0xa7,0x75,0xb0,0x02,0xa8 ; $a5e9
	dc.b	0x0c,0xa8,0x5b,0xa8,0x93,0xa8,0xa8,0xa8 ; $a5f1
	dc.b	0xab,0xa8,0xe8,0xa8,0x11,0xa9,0x14,0xa9 ; $a5f9
	dc.b	0x75,0xb0,0x17,0xa9,0x2f,0xa9,0x32,0xa9 ; $a601
	dc.b	0x35,0xa9,0x3d,0xa9,0x40,0xa9,0x43,0xa9 ; $a609
	dc.b	0x46,0xa9,0x4e,0xa9,0x75,0xb0,0x66,0xa9 ; $a611
	dc.b	0x66,0xa9,0x66,0xa9,0x66,0xa9,0x66,0xa9 ; $a619
	dc.b	0x66,0xa9,0x66,0xa9,0x66,0xa9,0x66,0xa9 ; $a621
	dc.b	0x75,0xb0,0x66,0xa9,0x66,0xa9,0x66,0xa9 ; $a629
	dc.b	0x66,0xa9,0x66,0xa9,0x66,0xa9,0x66,0xa9 ; $a631
	dc.b	0x66,0xa9,0x66,0xa9,0x75,0xb0,0x6e,0xa9 ; $a639
	dc.b	0x80,0xa9,0xd6,0xa9,0x10,0xaa,0x22,0xaa ; $a641
	dc.b	0x25,0xaa,0x25,0xaa,0x2d,0xaa,0x30,0xaa ; $a649
	dc.b	0x75,0xb0,0x33,0xaa,0x33,0xaa,0x33,0xaa ; computer_ai_jump_table_all_turn_back_A651
	dc.b	0x33,0xaa,0x33,0xaa,0x33,0xaa,0x33,0xaa ; $a659
	dc.b	0x33,0xaa,0x33,0xaa ; $a661
; given opponent moves (not distance), return a value between 1 and 9
; to be used in a per-distance/facing configuration jump table
; iy: points on C220 (the A.I. structure)
; 1: no particular stuff
; 2: frontal high attack
; 3: rear attack
; 4: crouch
; 5: in-jump
; 6: sommersault forward
; 7: sommersault backwards
; 8: starting a jump
; 9: move not in list
classify_opponent_move_start_A665:
A665: FD 6E 0B    ld   l,(iy+$0b)
A668: FD 66 06    ld   h,(iy+$0c)		; hl <= opponent frame
A66B: CB BC       res  7,h		; remove last bit (facing direction)
A66D: DD 21 9B AA ld   ix,walk_frames_list_AA3B
A671: E5          push hl
A672: CD 03 B0    call check_hl_in_ix_list_B009
A675: E1          pop  hl
A676: A7          and  a
A677: 3E 01       ld   a,$01
A679: C2 79 AC    jp   nz,move_found_A6D3
A67C: DD 21 B9 AA ld   ix,crouch_frame_list_AAB3	; load a table, there are 7 tables like this
A680: E5          push hl
A681: CD 03 B0    call check_hl_in_ix_list_B009
A684: E1          pop  hl
A685: A7          and  a
A686: 3E 04       ld   a,$04
A688: C2 79 AC    jp   nz,move_found_A6D3
A68B: DD 21 47 AA ld   ix,jump_frames_list_AA4D
A68F: E5          push hl
A690: CD 03 B0    call check_hl_in_ix_list_B009
A693: E1          pop  hl
A694: A7          and  a
A695: 3E 05       ld   a,$05
A697: C2 79 AC    jp   nz,move_found_A6D3
A69A: DD 21 35 AA ld   ix,forward_sommersault_frame_list_AA95
A69E: E5          push hl
A69F: CD 03 B0    call check_hl_in_ix_list_B009
A6A2: E1          pop  hl
A6A3: A7          and  a
A6A4: 3E 0C       ld   a,$06		; during forward sommersault (not at start)
A6A6: C2 79 AC    jp   nz,move_found_A6D3
A6A9: DD 21 A5 AA ld   ix,backwards_sommersault_frame_list_AAA5
A6AD: CD 03 B0    call check_hl_in_ix_list_B009
A6B0: A7          and  a
A6B1: 3E 0D       ld   a,$07		; during backwards sommersault (not at start)
A6B3: C2 79 AC    jp   nz,move_found_A6D3
A6B6: CD 76 AA    call opponent_starting_frontal_attack_AADC
A6B9: A7          and  a
A6BA: 3E 08       ld   a,$02		; frontal attack (very large move list!)
A6BC: C2 79 AC    jp   nz,move_found_A6D3
A6BF: CD ED AA    call opponent_starting_rear_attack_AAE7
A6C2: A7          and  a
A6C3: 3E 09       ld   a,$03
A6C5: C2 79 AC    jp   nz,move_found_A6D3
A6C8: CD 18 AB    call opponent_starting_a_sommersault_AB12
A6CB: A7          and  a
A6CC: 3E 02       ld   a,$08
A6CE: C2 79 AC    jp   nz,move_found_A6D3
A6D1: 3E 03       ld   a,$09
move_found_A6D3:
	C9          ret

; move forward with a special case TODO
cpu_move_forward_towards_enemy_far_away_A6D4:
A6D4: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; here writes to C26B (if player 2 CPU) to tell CPU to walk forward
; hl = C26B
A6D7: 36 08       ld   (hl),$02		; move forward
; iy=$C220
; C22D is roughly minus opponent x (CPL which inverts bits, performed at A47C)
; it actually is done to get 256-opponent x
A6D9: FD 7E 07    ld   a,(iy+$0d)
A6DC: FD BE 03    cp   (iy+$09)		; opponent x
A6DF: D2 E4 AC    jp   nc,$A6E4
; turn back if player is on the right (almost) half of the screen (difficult
; to achieve when both players are far away. Possible with well
; timed sommersaults)
A6E2: 36 0D       ld   (hl),$07
A6E4: C3 10 A4    jp   cpu_move_done_A410

; simplest & dumbest move forward
cpu_move_forward_towards_enemy_A6E7:
A6E7: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A6EA: 36 08       ld   (hl),$02
A6EC: C3 10 A4    jp   cpu_move_done_A410

; move if not facing, stop if facing
cpu_forward_or_stop_if_facing_A6EF:
A6EF: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A6F2: 36 00       ld   (hl),$00		; stop
A6F4: DD CB 0F DE bit  7,(ix+$0f)	; are players facing or back to back
A6F8: CA F7 AC    jp   z,$A6FD		; facing
; back to back: move
A6FB: 36 08       ld   (hl),$02
A6FD: C3 10 A4    jp   cpu_move_done_A410

; move if facing, stop if not facing
cpu_forward_or_stop_if_not_facing_A700:
A700: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A703: 36 00       ld   (hl),$00
A705: FD CB 0F DE bit  7,(iy+$0f)
A709: C2 0E AD    jp   nz,$A70E
A70C: 36 08       ld   (hl),$02
A70E: C3 10 A4    jp   cpu_move_done_A410

A711: C3 ED AC    jp   cpu_move_forward_towards_enemy_A6E7
A714: C3 ED AC    jp   cpu_move_forward_towards_enemy_A6E7
A717: C3 75 AD    jp   cpu_forward_or_backward_depending_on_facing_A7D5
A71A: C3 EC AD    jp   cpu_backward_or_forward_depending_on_facing_A7E6
; send "walk forward", exactly the same as A6E7
cpu_move_forward_towards_enemy_A71D:
A71D: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A720: 36 08       ld   (hl),$02
A722: C3 10 A4    jp   cpu_move_done_A410

; called by a jp (hl) when distance between players is "medium" (C26C 0 -> 1)
attack_once_out_of_16_frames_else_walk_A725
A725: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
A728: E6 0F       and  $0F
; periodic counter: decide an attack each 1/4s roughly
; (actually if reaches that point with the counter aligned on 16, not
; sure if it's each 1/4s)
A72A: C2 94 AD    jp   nz,$A734
A72D: CD 8E AB    call select_cpu_attack_AB2E
A730: A7          and  a
A731: C2 96 AD    jp   nz,$A73C	; a != 0 => attacked: always true
; returns 0: just walk, don't attack. Only reaches here because periodic
; counter is not a multiple of 16 (0x10)
A734: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; just send walk forward order to CPU
A737: 36 08       ld   (hl),$02
A739: C3 10 A4    jp   cpu_move_done_A410

A73C: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4

; if not facing, either attack or walk forward (50% chance each)
; if facing, react to low attack by walking forward/backwards or jump
cpu_avoids_low_attack_if_facing_else_maybe_attacks_A73F:
A73F: FD CB 0F DE bit  7,(iy+$0f)
A743: CA 57 AD    jp   z,$A75D
; not facing each other
A746: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
A749: E6 01       and  $01
; 50% chance attack
A74B: CA 55 AD    jp   z,$A755
A74E: CD 8E AB    call select_cpu_attack_AB2E
A751: A7          and  a
A752: C2 29 AD    jp   nz,$A783		; always true
; just walk, don't attack, one time out of 2
A755: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A758: 36 08       ld   (hl),$02
A75A: C3 20 AD    jp   $A780		; cpu_move_done_A410

; facing each other
A75D: CD 02 AB    call opponent_starting_low_kick_AB08
A760: A7          and  a
A761: CA C6 AD    jp   z,$A76C
; low kick: just walk
A764: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A767: 36 08       ld   (hl),$02
A769: C3 20 AD    jp   $A780
; react to foot sweep
A76C: CD F7 AA    call opponent_starting_low_attack_AAFD
A76F: A7          and  a
A770: CA DB AD    jp   z,$A77B
A773: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; evasive jump up
A776: 36 09       ld   (hl),$03
A778: C3 20 AD    jp   $A780
; move back / block possible attack
A77B: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A77E: 36 01       ld   (hl),$01

A780: C3 10 A4    jp   cpu_move_done_A410
A783: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4

cpu_maybe_attacks_if_facing_else_avoids_low_attack_A786:
A786: FD CB 0F DE bit  7,(iy+$0f)
A78A: C2 A4 AD    jp   nz,$A7A4
; facing each other
A78D: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
; 50% chance, (but by checking bit 1, so not the same value as below)
A790: CB 4F       bit  1,a
A792: CA 36 AD    jp   z,$A79C
A795: CD 8E AB    call select_cpu_attack_AB2E
A798: A7          and  a
A799: C2 68 AD    jp   nz,$A7C2		; always true
; just walk, don't attack
A79C: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A79F: 36 08       ld   (hl),$02
A7A1: C3 BF AD    jp   $A7BF
; not facing each other: if low attack, 50% chance of jump,
; 50% ; move back / block possible attack

A7A4: CD F7 AA    call opponent_starting_low_attack_AAFD
A7A7: CA BA AD    jp   z,$A7BA
A7AA: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
A7AD: CB 47       bit  0,a		; 50% chance
A7AF: C2 BA AD    jp   nz,$A7BA
A7B2: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; 50% chance evasive jump
A7B5: 36 09       ld   (hl),$03
A7B7: C3 BF AD    jp   $A7BF
; move back / block possible attack
A7BA: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A7BD: 36 01       ld   (hl),$01
A7BF: C3 10 A4    jp   cpu_move_done_A410
A7C2: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4

just_walk_A7C5:
A7C5: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A7C8: 36 08       ld   (hl),$02
A7CA: C3 10 A4    jp   cpu_move_done_A410

just_walk_A7CD:
A7CD: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A7D0: 36 08       ld   (hl),$02
A7D2: C3 10 A4    jp   cpu_move_done_A410

; move forward, except if back to back in which case
; move back / block possible attack
cpu_forward_or_backward_depending_on_facing_A7D5:
A7D5: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A7D8: 36 08       ld   (hl),$02
A7DA: FD CB 0F DE bit  7,(iy+$0f)
A7DE: C2 E9 AD    jp   nz,$A7E3
A7E1: 36 01       ld   (hl),$01
A7E3: C3 10 A4    jp   cpu_move_done_A410

; move backwards/block, except if back to back in which case move forwards
cpu_backward_or_forward_depending_on_facing_A7E6:
A7E6: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A7E9: 36 08       ld   (hl),$02
A7EB: FD CB 0F DE bit  7,(iy+$0f)
A7EF: CA F4 AD    jp   z,$A7F4
A7F2: 36 01       ld   (hl),$01
A7F4: C3 10 A4    jp   cpu_move_done_A410

A7F7: C3 85 AD    jp   attack_once_out_of_16_frames_else_walk_A725

; dumb move forward, same code exactly as A6E7
cpu_move_forward_towards_enemy_A7FA:
A7FA: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A7FD: 36 08       ld   (hl),$02
A7FF: C3 10 A4    jp   cpu_move_done_A410

; pick an attack
pick_cpu_attack_A802:
A802: CD 8E AB    call select_cpu_attack_AB2E
A805: A7          and  a
A806: CC D5 B0    call z,display_error_text_B075	; never called a != 0 always!
A809: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4

cpu_reacts_to_low_attack_if_facing_else_attacks_A80C:
A80C: FD CB 0F DE bit  7,(iy+$0f)  ; => C20F
A810: C2 4E A2    jp   nz,$A84E		; jumps if not facing each other
; players facing each other
A813: CD 02 AB    call opponent_starting_low_kick_AB08
A816: A7          and  a
A817: CA 81 A2    jp   z,$A821
; opponent starting low kick: react with jumping side kick
A81A: CD 22 AB    call perform_jumping_side_kick_if_level_2_AB88
A81D: A7          and  a
A81E: C2 55 A2    jp   nz,$A855
; low difficulty level or no low kick, check if starting low kick or foot sweep
A821: CD F7 AA    call opponent_starting_low_attack_AAFD
A824: A7          and  a
A825: CA 92 A2    jp   z,$A838
; react to foot sweep/low kick
A828: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A82B: 36 09       ld   (hl),$03		; evasive jump
A82D: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
A830: E6 09       and  $03
A832: CA 52 A2    jp   z,$A858
A835: C3 4C A2    jp   $A846
A838: CD F8 AA    call opponent_starting_high_attack_AAF2
A83B: A7          and  a
A83C: CA 4C A2    jp   z,$A846
A83F: CD 33 AB    call perform_foot_sweep_if_level_3_AB99
A842: A7          and  a
A843: C2 55 A2    jp   nz,$A855
A846: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; move back / block possible attack
A849: 36 01       ld   (hl),$01
A84B: C3 55 A2    jp   $A855		; and opponent has some time to react...

; routine duplicated a lot... pick an attack fails if 0 (which never happens)
A84E: CD 8E AB    call select_cpu_attack_AB2E
A851: A7          and  a
A852: CC D5 B0    call z,display_error_text_B075
A855: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4

A858: C3 10 A4    jp   cpu_move_done_A410

; if not facing, check if low attack: if low attack jump or move back/block (50%)
;                 if not low attack, then perform foot sweep if level >=3 else back
; if facing, select an attack
cpu_react_to_low_attack_or_perform_attack_A85B:
A85B: FD CB 0F DE bit  7,(iy+$0f)
A85F: CA 2C A2    jp   z,$A886
; not facing each other
A862: CD F7 AA    call opponent_starting_low_attack_AAFD
A865: A7          and  a
A866: CA DB A2    jp   z,$A87B
A869: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; avoid low attack by jump 50% of the time
A86C: 36 09       ld   (hl),$03
A86E: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
A871: CB 47       bit  0,a
A873: C2 30 A2    jp   nz,$A890
; else move back/block if player attacks
A876: 36 01       ld   (hl),$01
A878: C3 27 A2    jp   $A88D
; not starting low attack:
; move back/block unless skill level >= 3 in which case attacks with foot sweep
A87B: CD 33 AB    call perform_foot_sweep_if_level_3_AB99
A87E: C2 27 A2    jp   nz,$A88D
; move back/block
A881: 36 01       ld   (hl),$01
A883: C3 27 A2    jp   $A88D

; facing each other... pick an attack
A886: CD 8E AB    call select_cpu_attack_AB2E
;;A889: A7          and  a
;;A88A: CC D5 B0    call z,display_error_text_B075	; can't happen
A88D: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4

A890: C3 10 A4    jp   cpu_move_done_A410

cpu_small_chance_of_low_kick_else_walk_A893:
A893: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; decide a low kick once out of 8 ticks (12% chance of low kick)
A896: 36 14       ld   (hl),$14
A898: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
A89B: E6 0D       and  $07
A89D: CA A5 A2    jp   z,$A8A5
; just walk
A8A0: 36 08       ld   (hl),$02
A8A2: C3 10 A4    jp   cpu_move_done_A410

A8A5: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4

A8A8: C3 08 A2    jp   pick_cpu_attack_A802

high_attack_if_forward_sommersault_or_walk_A8AB:
A8AB: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A8AE: FD CB 0F DE bit  7,(iy+$0f)
A8B2: C2 6F A2    jp   nz,$A8CF
; not turning backs to each other
A8B5: E5          push hl
A8B6: DD 21 3B AA ld   ix,forward_sommersault_frame_list_end_AA9B
A8BA: FD 6E 0B    ld   l,(iy+$0b)
A8BD: FD 66 06    ld   h,(iy+$0c)
A8C0: CB BC       res  7,h
A8C2: CD 03 B0    call check_hl_in_ix_list_B009
A8C5: A7          and  a
A8C6: E1          pop  hl
A8C7: C2 6F A2    jp   nz,$A8CF		; end of forward sommersault: attack
; just walk forward
A8CA: 36 08       ld   (hl),$02
A8CC: C3 E5 A2    jp   $A8E5
; odds: lunge (0 - 25%), jumping kick (2,3 - 50%), round kick (1 - 25%)
A8CF: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
A8D2: 36 10       ld   (hl),$10		; rear+up lunge punch
A8D4: E6 09       and  $03
A8D6: CA E8 A2    jp   z,$A8E2
A8D9: 36 07       ld   (hl),$0D		; rather a jumping side kick
A8DB: FE 01       cp   $01
A8DD: CA E8 A2    jp   z,$A8E2
A8E0: 36 0F       ld   (hl),$0F		; rather a round kick
A8E2: C3 10 A4    jp   cpu_move_done_A410

A8E5: C3 10 A4    jp   cpu_move_done_A410

move_fwd_or_bwd_checking_sommersault_and_dir_A8E8:
A8E8: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A8EB: FD CB 0F DE bit  7,(iy+$0f)
A8EF: CA 06 A3    jp   z,$A90C		; not turning back to each other: goto "move back/block"
A8F2: E5          push hl
; check if opponent is performing sommersault (back) while
; turning backs to each other
A8F3: DD 21 A3 AA ld   ix,backwards_sommersault_frame_list_end_AAA9
A8F7: FD 6E 0B    ld   l,(iy+$0b)
A8FA: FD 66 06    ld   h,(iy+$0c)
A8FD: CB BC       res  7,h
A8FF: CD 03 B0    call check_hl_in_ix_list_B009
A902: A7          and  a
A903: E1          pop  hl
A904: C2 06 A3    jp   nz,$A90C
; not performing sommersault: move forward
A907: 36 08       ld   (hl),$02		; move forward
A909: C3 0E A3    jp   $A90E
; opponent is performing back sommersault when same facing
; direction: move back to avoid being a target to rear attack when opponent lands
A90C: 36 01       ld   (hl),$01		; move back
A90E: C3 10 A4    jp   cpu_move_done_A410

A911: C3 08 A2    jp   pick_cpu_attack_A802

A914: C3 08 A2    jp   pick_cpu_attack_A802

get_out_of_edge_or_low_kick_A917:
A917: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A91A: 36 14       ld   (hl),$14	; low kick
A91C: FD 7E 03    ld   a,(iy+$09)	; opponent x
A91F: FE 90       cp   $30		; if opponent almost completely on the left, don't attack, perform sommersault
A921: D2 83 A3    jp   nc,$A929
A924: 36 1D       ld   (hl),$17	; sommersault
A926: C3 10 A4    jp   cpu_move_done_A410	; immediate (it's not an attack)
A929: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4	; opponent can react to low kick

A92C: 00          nop
A92D: 00          nop
A92E: 00          nop
A92F: C3 06 A2    jp   cpu_reacts_to_low_attack_if_facing_else_attacks_A80C
A932: C3 4E A3    jp   front_kick_or_fwd_sommersault_to_recenter_A94E

perform_low_kick_A935:
A935: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A938: 36 14       ld   (hl),$14
A93A: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4

A93D: C3 4E A3    jp   front_kick_or_fwd_sommersault_to_recenter_A94E

A940: C3 AB A2    jp   high_attack_if_forward_sommersault_or_walk_A8AB

A943: C3 E2 A2    jp   move_fwd_or_bwd_checking_sommersault_and_dir_A8E8

perform_walk_back_A946:
A946: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A949: 36 01       ld   (hl),$01
A94B: C3 10 A4    jp   cpu_move_done_A410

front_kick_or_fwd_sommersault_to_recenter_A94E:
A94E: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; front kick
A951: 36 0A       ld   (hl),$0A
A953: FD 7E 03    ld   a,(iy+$09)		; C209: white player x coordinate
A956: FE 90       cp   $30		; far left?
A958: D2 C0 A3    jp   nc,$A960
; front sommersault if player x < $30 to get outside the border
A95B: 36 1D       ld   (hl),$17
A95D: C3 10 A4    jp   cpu_move_done_A410
A960: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4
A963: 00          nop
A964: 00          nop
A965: 00          nop

cpu_move_turn_around_A966:
A966: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A969: 36 0D       ld   (hl),$07		; turn around
A96B: C3 10 A4    jp   cpu_move_done_A410

pick_cpu_attack_A96E:
A96E: CD 8E AB    call select_cpu_attack_AB2E
;;A971: A7          and  a
;;A972: C2 D7 A3    jp   nz,$A97D   always true
; not reached so commented
;;A975: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;;A978: 36 0D       ld   (hl),$07		; turn around
;;A97A: C3 10 A4    jp   cpu_move_done_A410

A97D: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4


cpu_complex_reaction_to_front_attack_A980:
A980: FD CB 0F DE bit  7,(iy+$0f)
A984: C2 BB A3    jp   nz,$A9BB
; facing opponent, who is turning its back to cpu
; (this routine is only called from distance 07 or 87)
; it probably doesn't end up here very frequently (or never)
; I played a lot and I never ended up there...
A987: CD 02 AB    call opponent_starting_low_kick_AB08
A98A: A7          and  a
A98B: CA 35 A3    jp   z,$A995
; react to low kick by jumping back kick if facing
; (but, but... opponent is turning its back..., why????)
; the low kick, after that, cpu is turned the wrong way)
A98E: CD AA AB    call perform_jumping_back_kick_ABAA
A991: A7          and  a
A992: C2 79 A3    jp   nz,$A9D3	; always true
A995: CD F7 AA    call opponent_starting_low_attack_AAFD
A998: A7          and  a
A999: CA A6 A3    jp   z,$A9AC
; opponent is starting low attack
A99C: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A99F: 36 09       ld   (hl),$03	; jump to avoid low attack
A9A1: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
A9A4: E6 09       and  $03
A9A6: CA 70 A3    jp   z,$A9D0	; 25% chance: jump to avoid low attack
A9A9: C3 61 A3    jp   $A9C1	; 75% chance: turn back (and maybe get hit)
A9AC: CD F8 AA    call opponent_starting_high_attack_AAF2
A9AF: CA 61 A3    jp   z,$A9C1
; react to high attack by foot sweep, back (has a chance to land)
A9B2: CD BB AB    call perform_foot_sweep_back_ABBB
A9B5: C2 79 A3    jp   nz,$A9D3		; always true: end move
A9B8: C3 61 A3    jp   $A9C1
; back to back (not facing, but this routine is only used
; with distance $87 so computer is turning its back too)
; it happens sometimes, but opponent has to perform some frontal
; attack that cannot connect, like low kick...
A9BB: CD 8E AB    call select_cpu_attack_AB2E
A9BE: C2 79 A3    jp   nz,$A9D3
A9C1: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A9C4: 36 0D       ld   (hl),$07
A9C6: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
A9C9: CB 47       bit  0,a
A9CB: CA 70 A3    jp   z,$A9D0
; turn back or walk forward (50% chance)
A9CE: 36 08       ld   (hl),$02
A9D0: C3 10 A4    jp   cpu_move_done_A410
A9D3: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4


cpu_complex_reaction_to_rear_attack_A9D6:
A9D6: FD CB 0F DE bit  7,(iy+$0f)
A9DA: CA FE A3    jp   z,pick_cpu_attack_A9FE
A9DD: CD F7 AA    call opponent_starting_low_attack_AAFD
A9E0: A7          and  a
A9E1: CA F4 A3    jp   z,$A9F4
; starting low attack: jump to avoid it (75% chance)
; or turn back (25% chance)
A9E4: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
A9E7: 36 09       ld   (hl),$03
A9E9: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
A9EC: E6 09       and  $03
A9EE: CA 0A AA    jp   z,$AA0A
A9F1: C3 05 AA    jp   $AA05
; not starting low attack: perform foot sweep
A9F4: CD BB AB    call perform_foot_sweep_back_ABBB
A9F7: A7          and  a
A9F8: C2 07 AA    jp   nz,$AA0D		; always true
A9FB: C3 05 AA    jp   $AA05	; never reached
; facing each other: pick an attack
pick_cpu_attack_A9FE
A9FE: CD 8E AB    call select_cpu_attack_AB2E
AA01: A7          and  a
AA02: C2 07 AA    jp   nz,$AA0D
; turn back
AA05: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
AA08: 36 0D       ld   (hl),$07
AA0A: C3 10 A4    jp   cpu_move_done_A410
AA0D: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4

foot_sweep_back_AA10:
AA10: CD BB AB    call perform_foot_sweep_back_ABBB
;;AA13: A7          and  a
;;AA14: C2 1F AA    jp   nz,$AA1F	; always true
;;AA17: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;;AA1A: 36 0D       ld   (hl),$07
;;AA1C: C3 10 A4    jp   cpu_move_done_A410
AA1F: C3 E4 A9    jp   cpu_move_done_opponent_can_react_A3E4
AA22: C3 CE A3    jp   pick_cpu_attack_A96E

cpu_turn_back_AA25:
AA25: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
AA28: 36 0D       ld   (hl),$07
AA2A: C3 10 A4    jp   cpu_move_done_A410

AA2D: C3 CE A3    jp   pick_cpu_attack_A96E
AA30: C3 CE A3    jp   pick_cpu_attack_A96E

cpu_turn_back_AA33:
AA33: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
AA36: 36 0D       ld   (hl),$07
AA38: C3 10 A4    jp   cpu_move_done_A410

; collection of tables exploited by B009 at various points of the A.I. code
; probably specific animation frames of techniques so the computer
; can counter attack / react on them
;
; for example 890A (0A89 first item of the first list) is: stand guard facing left
; facing right this would be 8A89
; 8B22 would be the value in C22B if player starts a jump (joy up) facing right

walk_frames_list_AA3B:
	dc.b	0x89,0x0a,0x92,0x0a,0x9b,0x0a,0xa4,0x0a ; walk_frames_list_AA3B
	dc.b	0xad,0x0a,0xb6,0x0a,0xbf,0x0a,0xc8,0x0a ; $aa43
	dc.b	0xff,0xff ; $aa4b
jump_frames_list_AA4D:
	dc.b	0x22,0x0b,0x8e,0x0b,0x97,0x0b,0xa0,0x0b ; jump_frames_list_AA4D
	dc.b	0xa9,0x0b,0xb2,0x0b,0xbb,0x0b,0xc4,0x0b ; $aa55
	dc.b	0xcd,0x0b,0xd6,0x0b,0xdf,0x0b,0xe8,0x0b ; $aa5d
	dc.b	0xf1,0x0b,0xfa,0x0b,0x73,0x0b,0xff,0xff ; $aa65
	; frames where the blow reaches its end/is full blown (including jumping side kick...)
hitting_frame_list_AA6D:
	dc.b	0xc0,0x0c,0xd2,0x0c,0x47,0x0d,0xd7,0x0d ; hitting_frame_list_AA6D
	dc.b	0x4c,0x0e,0xaf,0x0e,0x1b,0x0f,0x90,0x0f ; $aa75
	dc.b	0x0e,0x10,0x9e,0x10,0x0a,0x11,0x6d,0x11 ; $aa7d
	dc.b	0xe2,0x11,0xd5,0x12,0x4a,0x13,0xff,0xff ; $aa85
  ; final moves of blocks
blocking_frame_list_AA8D:
	dc.b	0x88,0x1a,0xd0,0x1a,0x18,0x1b,0xff,0xff ; blocking_frame_list_AA8D
	;       uchiuke   sotouke     gedanbarai
	;       (high)    (medium)    (low)
forward_sommersault_frame_list_AA95:
	dc.b	0xad,0x13,0xb6,0x13,0xbf,0x13,0xc8,0x13 ; forward_sommersault_frame_list_AA95
	dc.b	0xd1,0x13,0xda,0x13,0xe3,0x13,0xff,0xff ; $aa9d
forward_sommersault_frame_list_end_AA9B
	dc.b	0xad,0x13,0xb6,0x13,0xbf,0x13,0xc8,0x13 ; forward_sommersault_frame_list_AA95
	dc.b	0xd1,0x13,0xda,0x13,0xe3,0x13,0xff,0xff ; $aa9d
backwards_sommersault_frame_list_AAA5:
	dc.b	0x45,0x12,0x4e,0x12 ; backwards_sommersault_frame_list_AAA5
	 ;     start  next frame
backwards_sommersault_frame_list_end_AAA9:
	dc.b	0x57,0x12,0x60,0x12,0x72,0x12,0x7b,0x12 ; backwards_sommersault_frame_list_end_AAA9
	dc.b	0xff,0xff ; $aab1
	 ;       zenith         frame  almost    landing
	 ;     of bwdsommersault after  landing
; player gets down, including foot sweep
; all frames are final frames of the moves. transition frames
; aren't listed
crouch_frame_list_AAB3:
	dc.b	0x27,0x0c,0xe0,0x0d,0xa7,0x10,0xde,0x12 ; crouch_frame_list_AAB3
	dc.b	0xff,0xff ; $aabb
	   ;     crouch  fwsb   fswf   reverse punch (800)
; some other tables loaded by the code below (accessed by a table too)
; one byte per attack
;
; codes aren't the same as attack commands but that's not really a problem
; thanks to the debugger and conditionnal breakpoints!!!
; computer fetches them in frame ids at offset 8
; in identify_opponent_current_move_AB1D
;
; $01: back kick
; $02: jumping side kick
; $03: foot sweep back
; $04: front kick
; $05: small reverse punch
; $06: back round kick
; $07: lunge punch 400
; $08: jumping side kick   ; side or back?????
; $09: foot sweep front
; $0A: round kick
; $0B: lunge punch 600
; $0C: lunge punch 1000
; $0D: reverse punch 800
; $0E: low kick
; $0F: ???? not in those tables
; $10: sommersault back/backwards
; $11: sommersault front/forward
; $12: sommersault back/backwards too!!

table_AABD:
	dc.b	0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b ; table_AABD
	dc.b	0x0c,0x0d,0x0e,0xff ; $aac5
table_AAC9:
	dc.b	0x01,0x02,0x03,0xff ; table_AAC9
table_high_attacks_AACD:
	dc.b	0x02,0x06,0x08,0x0a,0x0b,0x0c,0xff ; table_high_attacks_AACD
table_low_attacks_AAD4:
	dc.b	0x03,0x09,0x0e,0xff ; table_low_attacks_AAD4
table_sommersaults_AAD8:
	dc.b	0x10,0x11,0x12,0xff ; table_sommersaults_AAD8


opponent_starting_frontal_attack_AADC:
AADC: CD 17 AB    call identify_opponent_current_move_AB1D
AADF: DD 21 B7 AA ld   ix,table_AABD
AAE3: CD 0F B0    call table_linear_search_B00F
AAE6: C9          ret

; rear attack but not low attack. Just back kick jumping back kick
opponent_starting_rear_attack_AAE7:
AAE7: CD 17 AB    call identify_opponent_current_move_AB1D
AAEA: DD 21 63 AA ld   ix,table_AAC9
AAEE: CD 0F B0    call table_linear_search_B00F
AAF1: C9          ret

opponent_starting_high_attack_AAF2:
AAF2: CD 17 AB    call identify_opponent_current_move_AB1D
AAF5: DD 21 67 AA ld   ix,table_high_attacks_AACD
AAF9: CD 0F B0    call table_linear_search_B00F
AAFC: C9          ret

opponent_starting_low_attack_AAFD:
AAFD: CD 17 AB    call identify_opponent_current_move_AB1D
AB00: DD 21 74 AA ld   ix,table_low_attacks_AAD4
AB04: CD 0F B0    call table_linear_search_B00F
AB07: C9          ret

; return a = 0 if current frame is $0E (low kick)
opponent_starting_low_kick_AB08:
AB08: CD 17 AB    call identify_opponent_current_move_AB1D
AB0B: FE 0E       cp   $0E
AB0D: CA 11 AB    jp   z,$AB11
AB10: AF          xor  a
AB11: C9          ret

opponent_starting_a_sommersault_AB12:
AB12: CD 17 AB    call identify_opponent_current_move_AB1D
AB15: DD 21 72 AA ld   ix,table_sommersaults_AAD8
AB19: CD 0F B0    call table_linear_search_B00F
AB1C: C9          ret

; iy=C220, loads ix with current frame pointer of opponent, then
; identifies opponent exact frame/move (starting move probably)
identify_opponent_current_move_AB1D:
; load current frame pointer
AB1D: FD 4E 0B    ld   c,(iy+$0b)
AB20: FD 46 06    ld   b,(iy+$0c)
; remove direction bit
AB23: CB B8       res  7,b
AB25: C5          push bc
AB26: DD E1       pop  ix
; load at offset 8 to get move id. Ex 4 = front kick
AB28: DD 7E 02    ld   a,(ix+$08)
; reset move direction bit
AB2B: CB BF       res  7,a
AB2D: C9          ret

; > a: attack id (cf table at start of the source file)
; but this routine cannot return 0 because tables it points to don't contain 0
; furthermore, this routine is sometimes followed by a sanity check crashing with
; an error message if a is 0 on exit. Since it's random, how could the sanity check NOT fail?
;
; injecting values performs the move... or the move is discarded by caller

select_cpu_attack_AB2E:
AB2E: DD 21 52 AB ld   ix,master_cpu_move_table_AB58		; table of pointers of move tables
; choose the proper move list depending on facing & distance
AB32: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)	; <= C26B
AB35: 23          inc  hl
AB36: 7E          ld   a,(hl)	; get value in C26C: facing configuration/rough distance 0-4
AB37: 87          add  a,a
AB38: 4F          ld   c,a
AB39: 06 00       ld   b,$00
AB3B: DD 09       add  ix,bc
AB3D: DD 6E 00    ld   l,(ix+$00)
AB40: DD 66 01    ld   h,(ix+$01)
; get msb of 16 bit counter for randomness
AB43: ED 5B 8E 60 ld   de,(periodic_counter_16bit_C02E)
AB47: 5E          ld   e,(hl)	; pick a number 0-value of hl (not included)
AB48: 23          inc  hl	; skip number of values
AB49: E5          push hl
AB4A: CD 0C B0    call random_B006
AB4D: E1          pop  hl
AB4E: 06 00       ld   b,$00
AB50: 4F          ld   c,a
AB51: 09          add  hl,bc
; gets CPU move to make
AB52: 7E          ld   a,(hl)
AB53: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; gives attack order to the CPU
; only attack moves (not walk moves) are given here
AB56: 77          ld   (hl),a
AB57: C9          ret

; some moves are done or not depending on how the players are
; located and if current player can reach opponent with a blow
; (the CPU isn't going to perform a back move in the void)
; the direction of opponent isn't considered here
; (the 5 values relate to player struct + $0C)

master_cpu_move_table_AB58:
	dc.w  move_list_far_away_AB62	; far away (we don't care much about facing)
	dc.w  move_list_facing_mid_range_AB70		; mid-range, cpu faces opponent (who can face cpu or not...)
	dc.w  move_list_facing_close_range_AB7B		; close-range, cpu faces opponent
	dc.w  move_list_turning_back_AB84		; mid-range, cpu has its back turned on opponent
	dc.w  move_list_turning_back_AB84		; close-range, cpu has its back turned on opponent (same as above)

; move list starts by number of moves (for random pick)
; not the same move indexes as above, move indexes are listed at start of
; document
move_list_far_away_AB62:
	; 13 moves: back, jbk, footsweep, front kick/punch, back round, lunge, jsk, round, lunge, lunge, revpunch, lowk
	; the move doesn't really matter as it cannot connect (too far)
	dc.b	0x0d,0x05,0x08,0x09,0x0a,0x0b,0x0c,0x0d ; move_list_far_away_AB62
	dc.b	0x0e,0x0f,0x10,0x11,0x13,0x14 ; $ab6a
	; lunge backroundkick lungemedium jsk 0E(???) round lunge, lunge, revpunch, lowkick
move_list_facing_mid_range_AB70:
	dc.b	0x0a,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,0x10 ; move_list_facing_mid_range_AB70
	dc.b	0x11,0x13,0x14 ; $ab78
	; front kick, back round, lungemedium, jsk, round, lunge, revpunch, lowkick
move_list_facing_close_range_AB7B:
	; small reverse, back round, lungemediumj sk,...
	dc.b	0x08,0x0a,0x0b,0x0c,0x0d,0x0f,0x10,0x13 ; move_list_facing_close_range_AB7B
	dc.b	0x14 ; $ab83
	; list of only reverse attacks (mostly defensive, cpu turns its back on the opponent)
	; back kick jbk foot sweep back
move_list_turning_back_AB84:
	dc.b	0x03,0x05,0x08,0x09 ; move_list_turning_back_AB84

perform_jumping_side_kick_if_level_2_AB88:
AB88: 3A 10 63    ld   a,(computer_skill_C910)
AB8B: FE 01       cp   $01
AB8D: 3E 00       ld   a,$00
AB8F: DA 32 AB    jp   c,$AB98
; if level >= 1, perform jumping side kick, else do nothing
AB92: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
AB95: 3E 07       ld   a,$0D
AB97: 77          ld   (hl),a
AB98: C9          ret

; reacting to jumping side kick at close distance
perform_foot_sweep_if_level_3_AB99:
AB99: 3A 10 63    ld   a,(computer_skill_C910)
AB9C: FE 08       cp   $02
AB9E: 3E 00       ld   a,$00
ABA0: DA A3 AB    jp   c,$ABA9
; if level >= 2 perform a foot sweep
ABA3: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
ABA6: 3E 0E       ld   a,$0E
ABA8: 77          ld   (hl),a
ABA9: C9          ret

perform_jumping_back_kick_ABAA:
; useless, skill level is always >= 0
; maybe difficulty was pumped up since kchamp
; asm used defines for a level threshold
;;ABAA: 3A 10 63   ld   a,(computer_skill_C910)
;;ABAD: FE 00       cp   $00
;;ABAF: 3E 00       ld   a,$00
;;ABB1: DA BA AB    jp   c,$ABBA
ABB4: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
ABB7: 3E 02       ld   a,$08
ABB9: 77          ld   (hl),a
ABBA: C9          ret

perform_foot_sweep_back_ABBB:
; useless, skill level is always >= 0
;;ABBB: 3A 10 63    ld   a,(computer_skill_C910)
;;ABBE: FE 00       cp   $00
;;ABC0: 3E 00       ld   a,$00
;;ABC2: DA 6B AB    jp   c,$ABCB
ABC5: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
ABC8: 3E 03       ld   a,$09
ABCA: 77          ld   (hl),a
ABCB: C9          ret

; computer is jumping
handle_cpu_land_from_jump_ABCC:
ABCC: FD 6E 0D    ld   l,(iy+$07)
ABCF: FD 66 02    ld   h,(iy+$08)
ABD2: 11 D9 0B    ld   de,$0B73    ; jump frame
ABD5: A7          and  a
ABD6: ED 52       sbc  hl,de
ABD8: C2 E0 AB    jp   nz,$ABE0
ABDB: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; land if reaches a given point
ABDE: 36 00       ld   (hl),$00
ABE0: C3 10 A4    jp   cpu_move_done_A410

; computer just tried to hit player but failed
; now wait for player response (or not, if skill level is high enough)
full_blown_hit_ABE3:
ABE3: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
; tell CPU to stop moving / stand guard
ABE6: 36 00       ld   (hl),$00
ABE8: 21 EF A7    ld   hl,counter_attack_time_table_ADEF
ABEB: CD 6E A6    call let_opponent_react_depending_on_skill_level_ACCE
ABEE: FE 03       cp   $09
ABF0: CA DB A9    jp   z,fight_mainloop_A37B
ABF3: A7          and  a
ABF4: CA F6 AB    jp   z,$ABFC
ABF7: FE FF       cp   $FF
ABF9: C4 D5 B0    call nz,display_error_text_B075
ABFC: C3 10 A4    jp   cpu_move_done_A410

; called if the computer blocks, checks if computer must
; maintain the block depending on opponent current frame/move
; it will stop blocking as soon as the current opponent blow
; doesn't match the current computer block
computer_completed_a_blocking_move_ABFF:
ABFF: DD 21 29 A6 ld   ix,block_key_table_AC83
AC03: FD 5E 0D    ld   e,(iy+$07)
AC06: FD 56 02    ld   d,(iy+$08)
; look for de (computer current block frame) in key/value table
; the frames match high/medium/low attack moves that can be blocked
AC09: CD 06 B0    call key_value_linear_search_B00C
AC0C: A7          and  a
AC0D: C4 D5 B0    call nz,display_error_text_B075
AC10: E5          push hl
AC11: DD E1       pop  ix
; ix contains the corresponding pointer
; now load opponent frame
AC13: FD 6E 0B    ld   l,(iy+$0b)
AC16: FD 66 06    ld   h,(iy+$0c)
AC19: CB BC       res  7,h
; check if opponent performs some moves (facing computer block)...
AC1B: CD 03 B0    call check_hl_in_ix_list_B009
AC1E: A7          and  a
AC1F: CA 9E A6    jp   z,$AC3E	; opponent doesn't perform one of the moves
AC22: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
AC25: 36 00       ld   (hl),$00
AC27: 21 1D AE    ld   hl,counter_attack_time_table_AE17
AC2A: CD 6E A6    call let_opponent_react_depending_on_skill_level_ACCE
AC2D: FE 03       cp   $09
AC2F: CA DB A9    jp   z,fight_mainloop_A37B
AC32: A7          and  a
AC33: CA 20 A6    jp   z,$AC80
AC36: FE FF       cp   $FF
AC38: C4 D5 B0    call nz,display_error_text_B075
AC3B: C3 20 A6    jp   $AC80

; search for the same moves, but by attack id this time (not by frame id)
; 7 bit is set but it's still attack id
; it looks that the frame/move search isn't very reliable, this search
; looks very redundant (and in a lot of other parts of the code it's
; also done that way)
AC3E: DD 21 A7 A6 ld   ix,block_key_table_ACAD
AC42: FD 5E 0D    ld   e,(iy+$07)
AC45: FD 56 02    ld   d,(iy+$08)
AC48: CD 06 B0    call key_value_linear_search_B00C
AC4B: A7          and  a
AC4C: C4 D5 B0    call nz,display_error_text_B075
AC4F: E5          push hl
AC50: FD 6E 0B    ld   l,(iy+$0b)
AC53: FD 66 06    ld   h,(iy+$0c)
AC56: CB BC       res  7,h
AC58: E5          push hl
AC59: DD E1       pop  ix
AC5B: DD 7E 02    ld   a,(ix+$08)
AC5E: DD E1       pop  ix
AC60: CD 0F B0    call table_linear_search_B00F
AC63: A7          and  a
; if opponent is performing a move matching the block
AC64: C2 20 A6    jp   nz,$AC80
; move not found: stand guard, wait for opponent reaction
AC67: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
AC6A: 36 00       ld   (hl),$00
AC6C: 21 1D AE    ld   hl,counter_attack_time_table_AE17
AC6F: CD 6E A6    call let_opponent_react_depending_on_skill_level_ACCE
AC72: FE 03       cp   $09
AC74: CA DB A9    jp   z,fight_mainloop_A37B
AC77: A7          and  a
AC78: CA 20 A6    jp   z,$AC80
AC7B: FE FF       cp   $FF
AC7D: C4 D5 B0    call nz,display_error_text_B075
AC80: C3 10 A4    jp   cpu_move_done_A410


block_key_table_AC83:
	dc.w	0x1A88,table_AC91	; high block
	dc.w	0x1AD0,table_AC9D	; medium block
	dc.w	0x1B18,table_ACA3	; low block
	dc.w	0xFFFF
; hitting points of high techniques
	                  brkick (and next frame)    jskick (and landing)
table_AC91:
  dc.b	50 0D     24 0F                           17 10
    ;      lpunch 600      lpunch 1000
      dc.b  76 11            EB 11 FF FF
; hitting points of medium techniques
table_AC9D:
  dc.b	B8 0E 99 0F FF FF
; hitting points of low techniques
table_ACA3:
  dc.b	C9 0C DB 0C 55 0E DE 12 FF FF

block_key_table_ACAD:
	dc.w	0x1A88,high_attacks_ACBB	; high block
	dc.w	0x1AD0,medium_attacks_ACC1	; medium block
	dc.w	0x1B18,low_attacks_ACC4	; low block
	dc.w	0xFFFF
high_attacks_ACBB:
 dc.b	82 86 88 8B 8C FF ; jskick brkick jbkick lp600 lp1000
medium_attacks_ACC1:
	dc.b	85 87 FF ; weak reverse, lunge punch 400
low_attacks_ACC4:
	dc.b	81 84 8D FF  ; back kick, front kick, revpunch 800



ACC8: C3 10 A4    jp   cpu_move_done_A410
ACCB: C3 10 A4    jp   cpu_move_done_A410

; blocks a given number of frames (depending on table and level) during which
; the opponent has time to pre-react before the computed already decided
; attack is launched
; < hl pointer on a 4 pointer table containing each $20 values of data; each
; table corresponds to a difficulty setting (4 total)
; if upper-hard championship level >= 16: no time for player to react just before
; an attack
; > a: $00: attacks
; > a: $09: doesn't attack
let_opponent_react_depending_on_skill_level_ACCE:
ACCE: 3A 10 63    ld   a,(computer_skill_C910)
ACD1: FE 10       cp   $10
ACD3: 3E 00       ld   a,$00
ACD5: D2 1C A7    jp   nc,$AD16		; if level >= $10, skip the routine altogether

; this is called when skill level is < 16 (under high level of champ)
; game checks difficulty level at that point
; (in CMP high mode it doesn't matter)
ACD8: 3A 90 60    ld   a,(dip_switches_copy_C030)
ACDB: CB 3F       srl  a
ACDD: CB 3F       srl  a
ACDF: CB 3F       srl  a
ACE1: E6 0C       and  $06
; a = 0: difficulty: easy
; a = 2: difficulty: medium
; a = 4: difficulty: hard
; a = 6: difficulty: hardest
ACE3: 06 00       ld   b,$00
ACE5: 4F          ld   c,a
ACE6: 09          add  hl,bc
ACE7: 5E          ld   e,(hl)
ACE8: 23          inc  hl
ACE9: 56          ld   d,(hl)
; proper table (matching skill level) is loaded in de
; one of the table addresses is $AD8F for instance
; check skill level again
ACEA: 3A 10 63    ld   a,(computer_skill_C910)
ACED: CB 27       sla  a	; times 2
ACEF: 6F          ld   l,a
ACF0: 26 00       ld   h,$00
; offset for the byte value in the table
ACF2: 19          add  hl,de
; check those mysterious C148, C147 values that look = 0
; everywhere in the code it seems that the only thing that is done with
; them is that they're set to 0 so the code below is useless
; (a!=b!=0 would crank the difficulty up slightly, letting the program
; pick the (shorter) delay value after the current one (they come in pairs)
ACF3: 3A 42 61    ld   a,(unknown_C148)
ACF6: 47          ld   b,a
ACF7: 3A 4D 61    ld   a,(unknown_C147)
ACFA: B0          or   b
ACFB: CA FF A6    jp   z,$ACFF	; a=b=0: don't increase hl (harder)
ACFE: 23          inc  hl
ACFF: 7E          ld   a,(hl)
AD00: 47          ld   b,a
AD01: A7          and  a
AD02: 3E 00       ld   a,$00	; return value if a<=0
AD04: CA 1C A7    jp   z,$AD16	; if a=0, exit, attack immediately
AD07: FA 1C A7    jp   m,$AD16	; if a<0 exit, attack immediately
; a was strictly positive
AD0A: 78          ld   a,b	; restore read value of a (number of waiting frames)
AD0B: A7          and  a
AD0C: CC D5 B0    call z,display_error_text_B075	; can't happen! we just testedf it
AD0F: FD E5       push iy
; this can block cpu moves up to 1/2 second at low skill level
AD11: CD 13 A7    call let_opponent_react_AD19
AD14: FD E1       pop  iy
AD16: C9          ret


; never called in CMP hardest mode (level >= 16)
; < b # of frames to wait for opponent reaction. 30 frames = 1/2 second (easiest setting)
; > a:00 no opponent reaction
;    :09 opponent reacted with a jump (front/back) (from observation)
;    :ff opponent reacted with some other attack(exits before timeout)
;
; to clock that, I've used MAME breakpoint commands
; bpset AD19,1,{printf "enter: "; time; g}
; bpset AD64,1,{printf "exit: %02x ",a; time; g}

let_opponent_react_AD19:
; load proper opponent structure
AD19: FD 21 40 68 ld   iy,player_1_struct_C240
AD1D: 3A 82 60    ld   a,(player_2_attack_flags_C028)
AD20: FE 03       cp   $09
AD22: CA 83 A7    jp   z,$AD29
AD25: FD 21 C0 68 ld   iy,player_2_struct_C260
AD29: FD 6E 0D    ld   l,(iy+$07)
AD2C: FD 66 02    ld   h,(iy+$08)	; current player frame/stance id in hl
AD2F: CB BC       res  7,h			; remove direction of frame
AD31: E5          push hl
AD32: DD E1       pop  ix
AD34: FD 7E 19    ld   a,(iy+$13)
AD37: A7          and  a
AD38: CA 59 A7    jp   z,$AD53
AD3B: DD BE 02    cp   (ix+$08)
AD3E: CA 4E A7    jp   z,$AD4E
AD41: FD 7E 18    ld   a,(iy+$12)
AD44: A7          and  a
AD45: CA 59 A7    jp   z,$AD53
AD48: FD BE 0B    cp   (iy+$0b)
AD4B: C2 59 A7    jp   nz,$AD53
AD4E: 3E FF       ld   a,$FF	; opponent reacted: exit loop
AD50: C3 C4 A7    jp   $AD64
AD53: FD E5       push iy
AD55: C5          push bc
AD56: 3E 01       ld   a,$01
AD58: CD 5A B0    call suspend_this_task_B05A
AD5B: C1          pop  bc
AD5C: FD E1       pop  iy
AD5E: A7          and  a
AD5F: C2 C4 A7    jp   nz,$AD64
AD62: 10 65       djnz $AD29
AD64: C9          ret

AD65: 00          nop
AD66: 00          nop

; this is used for computer reaction, but also in a different way
; for animation speedup depending on the difficulty level
;
; for animation, only negative values are considered. Positive values
; are seen as 0 (no frame count decrease = no speed increase)
;
; for reaction time, negative values count as 0 (no time to react
; after a CPU attack)
;
counter_attack_timer_table_AD67:
	dc.w	$AD6F		; easy
	dc.w	$AD8F		; medium
	dc.w	$ADAF		; hard
	dc.w	$ADCF		; hardest

; $20 values per entry, number of frames to wait for opponent response
; just before cpu attacks (when an attack has been decided)
; first value matches skill 0, and so on. The values go in pair,
; a mysterious C148/C147 memory location allows to pick the second item,
; otherwise each skill level shifts 2 by 2. And after level 16, it's maxed out
; to -2 ($FE) for animation and 0 for reaction time
AD6F:
	dc.b	0x30,0x2d,0x2a,0x26,0x23,0x20,0x1d,0x1a ; $ad6f
	dc.b	0x17,0x14,0x10,0x0d,0x0a,0x07,0x04,0x00 ; $ad77
	dc.b	0x00,0x00,0x00,0x00,0xff,0xff,0xff,0xff ; $ad7f
	dc.b	0xff,0xfe,0xfe,0xfe,0xfe,0xfe,0xfe,0xfe ; $ad87
AD8F:
	dc.b	0x30,0x26,0x20,0x1b,0x17,0x13,0x10,0x0d ; $ad8f
	dc.b	0x0b,0x08,0x06,0x05,0x03,0x02,0x01,0x00 ; $ad97
	dc.b	0x00,0x00,0x00,0xff,0xff,0xff,0xfe,0xfe ; $ad9f
	dc.b	0xfe,0xfe,0xfe,0xfe,0xfe,0xfe,0xfe,0xfe ; $ada7
ADAF:
	dc.b	0x30,0x20,0x10,0x0e,0x0b,0x09,0x07,0x06 ; $adaf
	dc.b	0x05,0x04,0x03,0x02,0x02,0x01,0x00,0x00 ; $adb7
	dc.b	0x00,0x00,0xff,0xff,0xfe,0xfe,0xfe,0xfe ; $adbf
	dc.b	0xfe,0xfe,0xfe,0xfe,0xfe,0xfe,0xfe,0xfe ; $adc7
ADCF:
	dc.b	0x30,0x14,0x08,0x07,0x06,0x05,0x04,0x03 ; $adcf
	dc.b	0x02,0x02,0x01,0x01,0x00,0x00,0x00,0x00 ; $add7
	dc.b	0xff,0xff,0xff,0xfe,0xfe,0xfe,0xfe,0xfe ; $addf
	dc.b	0xfe,0xfe,0xfe,0xfe,0xfe,0xfe,0xfe,0xfe ; $ade7


counter_attack_time_table_ADEF:
	dc.w	$ADF7
	dc.w	$ADF7
	dc.w	$ADF7
	dc.w	$ADF7


ADF7:
	dc.b	0x20,0x20,0x18,0x18,0x18,0x18,0x10,0x10 ; $adf7
	dc.b	0x08,0x08,0x07,0x07,0x06,0x06,0x04,0x03 ; $adff
	dc.b	0x02,0x01,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae07
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae0f

counter_attack_time_table_AE17:
	dc.w	$AE1F
	dc.w	$AE1F
	dc.w	$AE1F
	dc.w	$AE1F

AE1F:
	dc.b	0x20,0x20,0x20,0x20,0x18,0x18,0x10,0x10 ; $ae1f
	dc.b	0x08,0x08,0x07,0x07,0x06,0x06,0x05,0x05 ; $ae27
	dc.b	0x04,0x04,0x03,0x03,0x02,0x02,0x01,0x01 ; $ae2f
	dc.b	0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01 ; $ae37
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae3f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae47
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae4f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae57
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae5f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae67
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae6f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae77
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae7f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae87
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae8f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae97
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $ae9f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aea7
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aeaf
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aeb7
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aebf
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aec7
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aecf
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aed7
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aedf
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aee7
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aeef
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aef7
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aeff
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af07
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af0f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af17
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af1f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af27
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af2f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af37
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af3f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af47
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af4f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af57
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af5f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af67
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af6f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af77
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af7f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af87
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af8f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af97
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $af9f
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $afa7
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $afaf
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $afb7
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $afbf
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $afc7
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $afcf
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $afd7
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $afdf
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $afe7
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $afef
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; $aff7
	dc.b	0x00 ; $afff
; a lot of redirected jumps
; doesn't help a lot when reversing...
B000: C3 69 B0    jp   multiply_de_B0C3
B003: C3 7B B0    jp   $B0DB
random_B006:
B006: C3 EE B0    jp   random_B0EE
B009: C3 FF B0    jp   check_hl_in_ix_list_B0FF
key_value_linear_search_B00C:
B00C: C3 84 B1    jp   key_value_linear_search_B124
table_linear_search_B00F:
B00F: C3 42 B1    jp   table_linear_search_B148
clear_player_structure_partial_b012:
B012: C3 56 B1    jp   clear_player_structure_partial_b15c
resume_tasks_b015:
B015: C3 D1 B1    jp   resume_tasks_b171
B018: C3 AB B1    jp   $B1AB
fill_rectangle_B01B:
B01B: C3 2E B8    jp   fill_rectangle_B28E
clear_C7xx_B01E:
B01E: C3 B8 B8    jp   clear_C7xx_B2B2
clear_zone_B021:
B021: C3 B7 B8    jp   clear_zone_B2BD
fill_zone_with_a_B024:
B024: C3 6A B8    jp   fill_zone_with_a_B2CA
B027: C3 73 B8    jp   $B2D9
B02A: C3 EC B8    jp   $B2E6
B02D: C3 FC B8    jp   compute_screen_address_from_XY_B2F6
fill_video_and_attribute_memory_B030:
B030: C3 1C B9    jp   fill_video_and_attribute_memory_B316
B033: C3 91 B9    jp   $B331
B036: C3 49 B9    jp   $B343
display_text_B039:
B039: C3 5D B9    jp   display_text_B357
display_multicolor_text_B03C:
B03C: C3 31 B9    jp   display_multicolor_text_B391
display_text_color_2_B03F:
B03F: C3 6E B9    jp   display_text_color_2_B3CE
is_point_in_rectangle_B042:
B042: C3 40 B4    jp   is_point_in_rectangle_B440

startup_B045:
B045: C3 C3 B4    jp   startup_B469
periodic_interrupt_B048:
B048: C3 8F BD    jp   on_periodic_interrupt_B72F
load_iy_with_player_structure_B04B:
B04B: C3 D4 B5    jp   load_iy_with_player_structure_B574
load_struct_C100_from_A_index_B04E:
B04E: C3 2E B5    jp   load_struct_C100_from_A_index_B58E
task_yield_B051:
B051: C3 A5 B5    jp   task_yield_B5A5
resume_task_B054:
B054: C3 67 B5    jp   resume_task_B5CD
schedule_task_to_start_B057:
B057: C3 80 BC    jp   schedule_task_to_start_B620
suspend_this_task_B05A:
B05A: C3 5E BC    jp   suspend_this_task_B65E
task_manipulation_B05D:
B05D: C3 AE BC    jp   task_manipulation_B6AE
set_normal_screen_b060:
B060: C3 D8 BB    jp   set_normal_screen_bb72
B063: C3 DA BB    jp   $BB7A
B066: C3 28 BB    jp   check_coin_ports_BB82
check_coin_ports_B069:
B069: C3 28 BB    jp   check_coin_ports_BB82
B06C: C3 38 BB    jp   get_dip_switches_BB92
B06F: C3 3C BB    jp   read_current_player_controls_BB96
play_sound_B072:
B072: C3 B5 BB    jp   play_sound_BBB5
display_error_text_B075:
B075: C3 2C B1    jp   display_error_text_B186
B078: C3 07 E0    jp   $E00D
B07B: C3 83 E0    jp   $E029
B07E: C3 B1 B8    jp   $B2B1
B081: C3 00 00    jp   $0000	; reboot not used
B084: C3 00 E0    jp   $E000
B087: C3 00 E0    jp   $E000
B08A: C3 00 E0    jp   $E000
B08D: C3 00 E0    jp   $E000
B090: C3 00 E0    jp   $E000
B093: C3 00 E0    jp   $E000
B096: C3 00 E0    jp   $E000
B099: C3 7E E1    jp   $E1DE
B09C: C3 FB E1    jp   $E1FB
B09F: C3 FB E1    jp   $E1FB
B0A2: C3 57 FD    jp   $F75D
B0A5: C3 00 00    jp   $0000
B0A8: C3 00 E0    jp   $E000
B0AB: C3 00 E0    jp   $E000
B0AE: C3 7F BB    jp   stop_sound_BBDF
is_title_screen_demo_mode_B0B1:
B0B1: C3 DE B8    jp   is_title_screen_demo_mode_B27E
display_players_rank_B0B4:
B0B4: C3 44 F7    jp   display_players_rank_FD44
read_p1_controls_B0B7:
B0B7: C3 A2 BB    jp   read_p1_controls_BBA8
read_p2_controls_B0BA:
B0BA: C3 A7 BB    jp   read_p2_controls_BBAD
disable_interrupts_B0BD:
B0BD: C3 E8 BB    jp   disable_interrupts_BBE2
enable_interrupts_b0c0:
B0C0: C3 E2 BB    jp   enable_interrupts_BBE2


; > d: term 1
; > e: term 2
; > de: product

multiply_de_B0C3:
B0C3: 21 00 00    ld   hl,$0000
B0C6: 06 00       ld   b,$00
B0C8: 4A          ld   c,d
B0C9: 3E 02       ld   a,$08
B0CB: CB 25       sla  l
B0CD: CB 14       rl   h
B0CF: CB 23       sla  e
B0D1: D2 75 B0    jp   nc,$B0D5
B0D4: 09          add  hl,bc
B0D5: 3D          dec  a
B0D6: C2 6B B0    jp   nz,$B0CB
B0D9: EB          ex   de,hl
B0DA: C9          ret

B0DB: AF          xor  a
B0DC: 06 10       ld   b,$10
B0DE: CB 25       sla  l
B0E0: CB 14       rl   h
B0E2: CB 17       rl   a
B0E4: BA          cp   d
B0E5: DA EB B0    jp   c,$B0EB
B0E8: 92          sub  d
B0E9: CB C5       set  0,l
B0EB: 10 F1       djnz $B0DE
B0ED: C9          ret

; random method
; < d: seed from timer
; < e: max value (not included)
; > a: value between 0 and e (not included)
; > d
random_B0EE:
B0EE: AF          xor  a	;  clears a
B0EF: 06 02       ld   b,$08  ; b <- $08	; do it 8 times at least
B0F1: CB 22       sla  d	; d *= 2
B0F3: CB 17       rl   a	; a <- 1 if carry set else 0
B0F5: BB          cp   e	; compare a with e
B0F6: DA F6 B0    jp   c,$B0FC	; if e >= a skip to djnz, repeat only if a == e
B0F9: 93          sub  e	; a <- a-e
B0FA: CB C2       set  0,d  ; d &= 1
B0FC: 10 F9       djnz $B0F1  ; repeat 8 times
B0FE: C9          ret

; < ix: table like walk_frames_list_AA3B, jump_frames_list_AA4D... 2 value list ending with FF FF
; < hl: frame word
; < bc
; > a 0 or $FF depending on value in hl & 0x7FFF found in list pointed in ix

check_hl_in_ix_list_B0FF:
B0FF: E5          push hl
B100: C1          pop  bc 	; save hl in bc
B101: C5          push bc
B102: E1          pop  hl	; restore hl (useless the first time but there's a loop)
B103: DD 5E 00    ld   e,(ix+$00)	; load first value of table e
B106: DD 56 01    ld   d,(ix+$01)	; load second value of table in d
B109: 7A          ld   a,d
B10A: A3          and  e
B10B: FE FF       cp   $FF	; check if both e and d are $FF
B10D: CA 88 B1    jp   z,$B122	; if so, end of scan
B110: A7          and  a	; clear carry for sbc operation
B111: ED 52       sbc  hl,de	; did we match de with hl ?
B113: CA 17 B1    jp   z,$B11D	; if so end, putting FF in a (found)
B116: DD 23       inc  ix
B118: DD 23       inc  ix
B11A: C3 01 B1    jp   $B101	; next value to scan
B11D: 3E FF       ld   a,$FF	; found
B11F: C3 89 B1    jp   $B123
; not found
B122: AF          xor  a	; a <= 0
B123: C9          ret

; another search routine (key value)
; < de: word to look for
; < ix: table to look into
; > a=0 found
; > if found loads hl with the word after
; the value of de found in ix list

key_value_linear_search_B124:
B124: 01 04 00    ld   bc,$0004
B127: DD 6E 00    ld   l,(ix+$00)
B12A: DD 66 01    ld   h,(ix+$01)
B12D: 7D          ld   a,l
B12E: A4          and  h
B12F: FE FF       cp   $FF
B131: CA 4D B1    jp   z,$B147	; h=a=$FF => end
B134: A7          and  a
B135: ED 52       sbc  hl,de
B137: CA 9F B1    jp   z,$B13F
B13A: DD 09       add  ix,bc	; add 4 to ix
B13C: C3 8D B1    jp   $B127
B13F: DD 6E 08    ld   l,(ix+$02)
B142: DD 66 09    ld   h,(ix+$03)
B145: 3E 00       ld   a,$00
B147: C9          ret

; < ix: pointer on table (ends with $FF)
; < a: value to look for
; > a = 0 if not found, else a is unchanged

table_linear_search_B148:
B148: DD 46 00    ld   b,(ix+$00)
; (clever way to test b against $FF without changing a probably)
B14B: 04          inc  b
B14C: CA 5A B1    jp   z,$B15A	; table ends by $FF: if 0 => end
B14F: DD BE 00    cp   (ix+$00)	; check if A == (ix)
B152: CA 5B B1    jp   z,$B15B	; found => exit
B155: DD 23       inc  ix		; else keep searching
B157: C3 42 B1    jp   table_linear_search_B148
B15A: AF          xor  a		; not found: set a to zero
B15B: C9          ret

* same as load_iy_with_player_structure_B574 except that here we multiply instead
* of shifting
* and add 7 as offset... it really seems that 2 programmers were competing here...

B15C: 3A 82 60    ld   a,(player_2_attack_flags_C028)
B15F: 57          ld   d,a
B160: 1E 80       ld   e,$20
B162: CD 69 B0    call multiply_de_B0C3
B165: 21 0D 61    ld   hl,unknown_C107
B168: 19          add  hl,de
B169: 06 13       ld   b,$19
B16B: 36 00       ld   (hl),$00
B16D: 23          inc  hl
B16E: 10 FB       djnz $B16B
B170: C9          ret

resume_tasks_b171:
B171: FE 12       cp   $18
B173: D4 2C B1    call nc,display_error_text_B186
B176: FD E5       push iy
B178: F5          push af
B179: CD 67 B5    call resume_task_B5CD
B17C: F1          pop  af
B17D: 3C          inc  a
B17E: FE 12       cp   $18
B180: C2 D2 B1    jp   nz,$B178
B183: FD E1       pop  iy
B185: C9          ret

display_error_text_B186:
B186: DD E1       pop  ix
B188: CD E8 BB    call disable_interrupts_BBE2
B18B: F5          push af
B18C: C5          push bc
B18D: D5          push de
B18E: E5          push hl
B18F: FD E5       push iy
B191: 21 A9 B1    ld   hl,error_text_B1A3	; ERROR
B194: 16 32       ld   d,$98
B196: CD 5D B9    call display_text_B357
B199: FD E1       pop  iy
B19B: E1          pop  hl
B19C: D1          pop  de
B19D: C1          pop  bc
B19E: F1          pop  af
; infinite loop, all registers are preserved, inc. call address
; probably used by the devs as an "assert failed" routine, where they could
; track down abnormal values before it really crashes
B19F: 00          nop
B1A0: C3 3F B1    jp   $B19F

error_text_B1A3:
	dc.b	0x0e,0x10,0x0e,0x1b,0x1b,0x18,0x1b,0xff ; error_text_B1A3
B1AB: FD E5       push iy
B1AD: F5          push af
B1AE: DD 21 62 60 ld   ix,unknown_C0C8
B1B2: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
B1B5: E6 06       and  $0C
B1B7: FE 06       cp   $0C
B1B9: CA 64 B1    jp   z,$B1C4
B1BC: CB 57       bit  2,a
B1BE: C2 7E B1    jp   nz,$B1DE
B1C1: C3 7A B1    jp   $B1DA
B1C4: 3A 82 60    ld   a,(player_2_attack_flags_C028)
B1C7: FE 0A       cp   $0A
B1C9: CA 7E B1    jp   z,$B1DE
B1CC: FE 0B       cp   $0B
B1CE: CA 7A B1    jp   z,$B1DA
B1D1: F1          pop  af
B1D2: F5          push af
B1D3: A7          and  a
B1D4: C4 2C B1    call nz,display_error_text_B186
B1D7: C3 7E B1    jp   $B1DE
B1DA: DD 21 70 60 ld   ix,unknown_C0D0
B1DE: F1          pop  af
B1DF: DD 86 01    add  a,(ix+$01)
B1E2: 27          daa
B1E3: DD 77 01    ld   (ix+$01),a
B1E6: DD 7E 00    ld   a,(ix+$00)
B1E9: CE 00       adc  a,$00
B1EB: 27          daa
B1EC: DD 77 00    ld   (ix+$00),a
B1EF: 2A 60 60    ld   hl,(unknown_C0C0)
B1F2: 7D          ld   a,l
B1F3: 6C          ld   l,h
B1F4: 67          ld   h,a
B1F5: DD 46 00    ld   b,(ix+$00)
B1F8: DD 4E 01    ld   c,(ix+$01)
B1FB: A7          and  a
B1FC: ED 42       sbc  hl,bc
B1FE: D2 06 B8    jp   nc,$B20C
B201: 11 60 60    ld   de,unknown_C0C0
B204: DD E5       push ix
B206: E1          pop  hl
B207: 01 09 00    ld   bc,$0003
B20A: ED B0       ldir
B20C: 21 60 60    ld   hl,unknown_C0C0
B20F: 16 32       ld   d,$98
B211: 3A 11 63    ld   a,(background_and_state_bits_C911)
B214: CB BF       res  7,a
B216: FE 54       cp   $54
B218: CA 8D B8    jp   z,$B227
B21B: FE 59       cp   $53
B21D: CA 8D B8    jp   z,$B227
B220: CD DE B8    call is_title_screen_demo_mode_B27E
B223: A7          and  a
B224: CA DB B8    jp   z,$B27B
B227: 01 08 14    ld   bc,$1402
B22A: CD 6E B9    call display_text_color_2_B3CE
B22D: 01 04 14    ld   bc,$1404
B230: 3A 11 63    ld   a,(background_and_state_bits_C911)
B233: CB BF       res  7,a
B235: FE 54       cp   $54
B237: CA 42 B8    jp   z,$B248
B23A: FE 59       cp   $53
B23C: CA 42 B8    jp   z,$B248
B23F: CD DE B8    call is_title_screen_demo_mode_B27E
B242: 01 04 14    ld   bc,$1404
B245: FE 08       cp   $02
B247: C0          ret  nz
B248: 16 32       ld   d,$98
B24A: 21 62 60    ld   hl,unknown_C0C8
B24D: CD 6E B9    call display_text_color_2_B3CE
B250: 3A 98 60    ld   a,(unknown_C032)
B253: CB 4F       bit  1,a
B255: CA DB B8    jp   z,$B27B
B258: 01 0C 14    ld   bc,$1406
B25B: 3A 11 63    ld   a,(background_and_state_bits_C911)
B25E: CB BF       res  7,a
B260: FE 54       cp   $54
B262: CA D9 B8    jp   z,$B273
B265: FE 59       cp   $53
B267: CA D9 B8    jp   z,$B273
B26A: CD DE B8    call is_title_screen_demo_mode_B27E
B26D: 01 0C 14    ld   bc,$1406
B270: FE 08       cp   $02
B272: C0          ret  nz
B273: 21 70 60    ld   hl,unknown_C0D0
B276: 16 32       ld   d,$98
B278: CD 6E B9    call display_text_color_2_B3CE
B27B: FD E1       pop  iy
B27D: C9          ret

is_title_screen_demo_mode_B27E:
B27E: 3A 11 63    ld   a,(background_and_state_bits_C911)
B281: CB BF       res  7,a
B283: FE 50       cp   $50		; demo mode?
B285: DA 2B B8    jp   c,$B28B
B288: 3E 00       ld   a,$00
B28A: C9          ret
B28B: 3E 08       ld   a,$02
B28D: C9          ret

; < BC: number of row/colums
; < DE: D=character, E=attribute
; < HL: start coords X,Y
fill_rectangle_B28E:
B28E: C5          push bc
B28F: E5          push hl
B290: C5          push bc
B291: D5          push de
B292: CD FC B8    call compute_screen_address_from_XY_B2F6
B295: D1          pop  de
B296: C1          pop  bc
B297: C5          push bc
B298: 73          ld   (hl),e
B299: 01 00 04    ld   bc,$0400
B29C: 09          add  hl,bc
B29D: 72          ld   (hl),d
B29E: 01 FF 09    ld   bc,$03FF
B2A1: A7          and  a
B2A2: ED 42       sbc  hl,bc
B2A4: C1          pop  bc
B2A5: 05          dec  b
B2A6: C2 3D B8    jp   nz,$B297
B2A9: E1          pop  hl
B2AA: 25          dec  h
B2AB: C1          pop  bc
B2AC: 0D          dec  c
B2AD: C2 2E B8    jp   nz,fill_rectangle_B28E
B2B0: C9          ret
B2B1: C9          ret

clear_C7xx_B2B2:
B2B2: AF          xor  a
B2B3: 21 00 6D    ld   hl,referee_x_pos_C700
B2B6: 01 FB 6D    ld   bc,unknown_C7FB
B2B9: CD 6A B8    call fill_zone_with_a_B2CA
B2BC: C9          ret

; < HL: pointer on zone to clear
; < BC: size
clear_zone_B2BD:
B2BD: DD E1       pop  ix			; return address in ix
B2BF: 36 00       ld   (hl),$00		; set to 0
B2C1: 23          inc  hl			; increment hl
B2C2: 0B          dec  bc			; decrement bc counter
B2C3: 78          ld   a,b			; test b=c=0
B2C4: B1          or   c
B2C5: C2 BF B8    jp   nz,$B2BF		; not 0, keep looping
B2C8: DD E9       jp   (ix)			; return to caller (what's wrong with ret?)

; < a: character to store
; < hl: address to store
; < bc: number of characters
fill_zone_with_a_B2CA:
B2CA: 03          inc  bc
B2CB: 57          ld   d,a
B2CC: 72          ld   (hl),d
B2CD: 23          inc  hl
B2CE: 79          ld   a,c
B2CF: BD          cp   l
B2D0: C2 66 B8    jp   nz,$B2CC
B2D3: 78          ld   a,b
B2D4: BC          cp   h
B2D5: C2 66 B8    jp   nz,$B2CC
B2D8: C9          ret
B2D9: CB 3C       srl  h
B2DB: CB 3C       srl  h
B2DD: CB 3C       srl  h
B2DF: CB 3D       srl  l
B2E1: CB 3D       srl  l
B2E3: CB 3D       srl  l
B2E5: C9          ret
B2E6: 26 00       ld   h,$00
B2E8: 6F          ld   l,a
B2E9: CB 25       sla  l
B2EB: CB 14       rl   h
B2ED: CB 25       sla  l
B2EF: CB 14       rl   h
B2F1: 11 00 6D    ld   de,referee_x_pos_C700
B2F4: 19          add  hl,de
B2F5: C9          ret

; < HL: X,Y
; > HL: screen address
compute_screen_address_from_XY_B2F6:
B2F6: 16 00       ld   d,$00
B2F8: 5C          ld   e,h
B2F9: CB 23       sla  e
B2FB: CB 12       rl   d
B2FD: CB 23       sla  e
B2FF: CB 12       rl   d
B301: CB 23       sla  e
B303: CB 12       rl   d
B305: CB 23       sla  e
B307: CB 12       rl   d
B309: CB 23       sla  e
B30B: CB 12       rl   d		; results in DE = H*32
B30D: AF          xor  a
B30E: 67          ld   h,a
B30F: 01 E0 79    ld   bc,$D3E0		; screen address
B312: 09          add  hl,bc
B313: ED 52       sbc  hl,de
B315: C9          ret

; fill video & attribute memory with an uniform value
; < c: what to set in video memory
; < b: what to set in attribute memory
;
fill_video_and_attribute_memory_B316:
B316: 21 00 70    ld   hl,$D000
B319: DD 21 00 74 ld   ix,$D400
B31D: 11 00 04    ld   de,$0400
B320: 71          ld   (hl),c
B321: 00          nop
B322: 00          nop
B323: 00          nop
B324: DD 70 00    ld   (ix+$00),b
B327: 23          inc  hl
B328: DD 23       inc  ix
B32A: 1B          dec  de
B32B: 7A          ld   a,d
B32C: B3          or   e
B32D: C2 80 B9    jp   nz,$B320
B330: C9          ret

B331: 23          inc  hl
B332: 23          inc  hl
B333: 03          inc  bc
B334: 03          inc  bc
B335: AF          xor  a
B336: 16 09       ld   d,$03
B338: 0A          ld   a,(bc)
B339: 8E          adc  a,(hl)
B33A: 27          daa
B33B: 77          ld   (hl),a
B33C: 2B          dec  hl
B33D: 0B          dec  bc
B33E: 15          dec  d
B33F: C2 92 B9    jp   nz,$B338
B342: C9          ret

B343: 23          inc  hl
B344: 23          inc  hl
B345: 03          inc  bc
B346: 03          inc  bc
B347: AF          xor  a
B348: 16 09       ld   d,$03
B34A: 0A          ld   a,(bc)
B34B: 5F          ld   e,a
B34C: 7E          ld   a,(hl)
B34D: 9B          sbc  a,e
B34E: 27          daa
B34F: 77          ld   (hl),a
B350: 2B          dec  hl
B351: 0B          dec  bc
B352: 15          dec  d
B353: C2 4A B9    jp   nz,$B34A
B356: C9          ret

; display text
; <  hl pointer on text
; : format x y text (not in ASCII, tile-index based), ends by $FF
; codes are:
; 0-9: digits
; 10-35: A-Z
; 0x3C: space
; 0xFE: line feed, goto next line
; 0xFF: end

; <  d  color attribute

display_text_B357:
B357: FD E5       push iy
B359: E5          push hl
B35A: FD E1       pop  iy
B35C: FD 7E 00    ld   a,(iy+$00)
B35F: 67          ld   h,a
B360: FD 23       inc  iy
B362: FD 7E 00    ld   a,(iy+$00)
B365: 6F          ld   l,a
B366: D5          push de
B367: CD FC B8    call compute_screen_address_from_XY_B2F6
B36A: D1          pop  de
B36B: FD 23       inc  iy
B36D: FD 7E 00    ld   a,(iy+$00)
B370: FE FF       cp   $FF				; end of string?
B372: CA 2E B9    jp   z,$B38E
; FE: end of string
B375: FE FE       cp   $FE
B377: C2 DF B9    jp   nz,$B37F
B37A: FD 23       inc  iy
B37C: C3 56 B9    jp   $B35C
B37F: 77          ld   (hl),a
B380: 01 00 04    ld   bc,$0400
B383: 09          add  hl,bc			; attribute memory
B384: 72          ld   (hl),d
B385: 01 80 04    ld   bc,$0420			; next line
B388: AF          xor  a
B389: ED 42       sbc  hl,bc
B38B: C3 CB B9    jp   $B36B
B38E: FD E1       pop  iy
B390: C9          ret

; display text with possible color change
; <  hl pointer on text
; : format x y text/attribute (not in ASCII, tile-index based), ends by $FF
display_multicolor_text_B391:
B391: FD E5       push iy
B393: E5          push hl
B394: FD E1       pop  iy
B396: FD 7E 00    ld   a,(iy+$00)
B399: 67          ld   h,a
B39A: FD 23       inc  iy
B39C: FD 7E 00    ld   a,(iy+$00)
B39F: 6F          ld   l,a
B3A0: CD FC B8    call compute_screen_address_from_XY_B2F6
B3A3: FD 23       inc  iy
B3A5: FD 7E 00    ld   a,(iy+$00)
B3A8: FE FF       cp   $FF
B3AA: CA 6B B9    jp   z,$B3CB
B3AD: FE FE       cp   $FE
B3AF: C2 BD B9    jp   nz,$B3B7
B3B2: FD 23       inc  iy
B3B4: C3 3C B9    jp   $B396
B3B7: 77          ld   (hl),a
B3B8: 01 00 04    ld   bc,$0400
B3BB: 09          add  hl,bc
B3BC: FD 23       inc  iy
B3BE: FD 7E 00    ld   a,(iy+$00)
B3C1: 77          ld   (hl),a
B3C2: 01 80 04    ld   bc,$0420
B3C5: AF          xor  a
B3C6: ED 42       sbc  hl,bc
B3C8: C3 A9 B9    jp   $B3A3
B3CB: FD E1       pop  iy
B3CD: C9          ret

; not sure of what it exactly does. It displays text at HL
display_text_color_2_B3CE:
B3CE: E5          push hl
B3CF: D5          push de
B3D0: 60          ld   h,b
B3D1: 69          ld   l,c
B3D2: CD FC B8    call compute_screen_address_from_XY_B2F6
B3D5: D1          pop  de
B3D6: 06 09       ld   b,$03
B3D8: FD E1       pop  iy
B3DA: 0E 00       ld   c,$00
B3DC: FD 7E 00    ld   a,(iy+$00)
B3DF: E6 F0       and  $F0
B3E1: CB 3F       srl  a
B3E3: CB 3F       srl  a
B3E5: CB 3F       srl  a
B3E7: CB 3F       srl  a
B3E9: A7          and  a
B3EA: CA F8 B9    jp   z,$B3F2
B3ED: 0E 01       ld   c,$01
B3EF: C3 FE B9    jp   $B3FE
B3F2: 0C          inc  c
B3F3: 0D          dec  c
B3F4: C2 FE B9    jp   nz,$B3FE
B3F7: 05          dec  b
B3F8: CA F7 B9    jp   z,$B3FD
B3FB: 3E 96       ld   a,$3C
B3FD: 04          inc  b
B3FE: 77          ld   (hl),a
B3FF: C5          push bc
B400: 01 00 04    ld   bc,$0400
B403: 09          add  hl,bc
B404: 72          ld   (hl),d
B405: A7          and  a
B406: ED 42       sbc  hl,bc
B408: 01 80 00    ld   bc,task_address_table_0020
B40B: AF          xor  a
B40C: ED 42       sbc  hl,bc
B40E: C1          pop  bc
B40F: FD 7E 00    ld   a,(iy+$00)
B412: E6 0F       and  $0F
B414: CA 16 B4    jp   z,$B41C
B417: 0E 01       ld   c,$01
B419: C3 82 B4    jp   $B428
B41C: 0C          inc  c
B41D: 0D          dec  c
B41E: C2 82 B4    jp   nz,$B428
B421: 05          dec  b
B422: CA 8D B4    jp   z,$B427
B425: 3E 96       ld   a,$3C
B427: 04          inc  b
B428: 77          ld   (hl),a
B429: C5          push bc
B42A: 01 00 04    ld   bc,$0400
B42D: 09          add  hl,bc
B42E: 72          ld   (hl),d
B42F: A7          and  a
B430: ED 42       sbc  hl,bc
B432: 01 80 00    ld   bc,task_address_table_0020
B435: AF          xor  a
B436: ED 42       sbc  hl,bc
B438: C1          pop  bc
B439: FD 23       inc  iy
B43B: 05          dec  b
B43C: C2 76 B9    jp   nz,$B3DC
B43F: C9          ret

; < ix: struct containing x,width,y,height
; < d: X
; < e: Y
; > a: 0 or FF
is_point_in_rectangle_B440:
B440: DD 7E 00    ld   a,(ix+$00)
B443: BA          cp   d
B444: CA 4A B4    jp   z,$B44A
B447: D2 CD B4    jp   nc,$B467
B44A: DD 86 01    add  a,(ix+$01)
B44D: BA          cp   d
B44E: DA CD B4    jp   c,$B467		; X out of range
B451: DD 7E 08    ld   a,(ix+$02)
B454: BB          cp   e
B455: CA 5B B4    jp   z,$B45B
B458: D2 CD B4    jp   nc,$B467
B45B: DD 86 09    add  a,(ix+$03)
B45E: BB          cp   e
B45F: DA CD B4    jp   c,$B467
B462: 3E FF       ld   a,$FF
B464: C3 C2 B4    jp   $B468
B467: AF          xor  a
B468: C9          ret

startup_B469:
B469: 3E 48       ld   a,$42
B46B: 32 81 67    ld   (unknown_CD21),a
B46E: 31 00 6F    ld   sp,temp_numeric_buffer_CF00			; set stack
B471: CD E8 BB    call disable_interrupts_BBE2
B474: ED 56       im   1				; set interrupt mode
B476: 31 00 6F    ld   sp,temp_numeric_buffer_CF00			; set stack again
; clear part of RAM
B479: 21 00 60    ld   hl,active_task_bit_table_C000
B47C: 01 20 00    ld   bc,$0080			; immediate value
B47F: CD B7 B8    call clear_zone_B2BD
B482: CD 41 BB    call init_ram_BB41
B485: 3E FF       ld   a,$FF
B487: 32 86 60    ld   (unknown_C02C),a
B48A: CD E2 BB    call enable_interrupts_BBE2

; this is called by most routines that want to yield control to this mainloop
jump_to_mainloop_B48D:
B48D: 31 00 6F    ld   sp,temp_numeric_buffer_CF00			; pops all calls
B490: CD E2 BB    call enable_interrupts_BBE2
; loop until one of the 2 timers/counters is nonzero
; jump at different locations
scheduler_loop_b493:
B493: 21 0C 60    ld   hl,unknown_C006
B496: 3A 83 60    ld   a,(nb_tasks_to_start_C029)
B499: A7          and  a
B49A: C2 AD B4    jp   nz,run_a_task_b4a7

B49D: 3A 8A 60    ld   a,(nb_suspended_tasks_C02A)
B4A0: A7          and  a
B4A1: C2 09 B5    jp   nz,resume_a_task_b503
B4A4: C3 39 B4    jp   scheduler_loop_b493

run_a_task_b4a7:
B4A7: AF          xor  a
B4A8: 57          ld   d,a
; check change of bitfield state $C006-$C00B notify bitfield changes
; looks like an event table: each routine can post events by setting
; bits, and the events are acknowledged by bitclears.
; depending on the bits set, we jump to different routines
B4A9: BE          cp   (hl)
B4AA: C2 B2 B4    jp   nz,$B4B8
B4AD: 2C          inc  l
B4AE: BE          cp   (hl)
B4AF: C2 B2 B4    jp   nz,$B4B8
B4B2: 2C          inc  l
B4B3: BE          cp   (hl)
B4B4: C2 B2 B4    jp   nz,$B4B8
B4B7: 2C          inc  l
B4B8: 7D          ld   a,l
B4B9: D6 0C       sub  $06		; if first 0, then sub 06 gives 0
B4BB: 5F          ld   e,a
B4BC: CB 03       rlc  e
B4BE: CB 03       rlc  e
B4C0: CB 03       rlc  e			; e*8
B4C2: 06 00       ld   b,$00
B4C4: 4E          ld   c,(hl)
B4C5: A7          and  a	; clear carry for next rl
B4C6: CB 11       rl   c
B4C8: CB 10       rl   b
B4CA: DD 21 D7 B2 ld   ix,table_B87D
B4CE: DD 09       add  ix,bc
B4D0: DD 46 00    ld   b,(ix+$00)
B4D3: DD 7E 01    ld   a,(ix+$01)
B4D6: 83          add  a,e
B4D7: 5F          ld   e,a
B4D8: 32 82 60    ld   (player_2_attack_flags_C028),a
B4DB: 78          ld   a,b
B4DC: AE          xor  (hl)
B4DD: 77          ld   (hl),a
B4DE: CB 03       rlc  e
B4E0: 16 00       ld   d,$00
B4E2: FD 21 85 B2 ld   iy,task_stack_buffer_table_B825
B4E6: FD 19       add  iy,de
; read address of stack top for task to run
B4E8: FD 6E 00    ld   l,(iy+$00)
B4EB: FD 66 01    ld   h,(iy+$01)
; set it
B4EE: F9          ld   sp,hl
; one less task to start
B4EF: 21 83 60    ld   hl,nb_tasks_to_start_C029
B4F2: 35          dec  (hl)
B4F3: FD 21 80 00 ld   iy,task_address_table_0020
B4F7: FD 19       add  iy,de
; get entrypoint address
B4F9: FD 6E 00    ld   l,(iy+$00)
B4FC: FD 66 01    ld   h,(iy+$01)
B4FF: CD E2 BB    call enable_interrupts_BBE2
; called several times at startup
; $5250
; $53D2
; $544F
; $6491
; $7C5D
; $6D5E
; $B099
; $B09C
; $B09F
;
; then called when screen changes

; and start the task
B502: E9          jp   (hl)

resume_a_task_b503:
B503: CD E8 BB    call disable_interrupts_BBE2
B506: 21 06 60    ld   hl,unknown_C00C
B509: FD 21 06 60 ld   iy,unknown_C00C
B50D: FD 7E 00    ld   a,(iy+$00)
B510: FD B6 01    or   (iy+$01)
B513: FD B6 08    or   (iy+$02)
B516: FD B6 09    or   (iy+$03)
B519: CA 27 B4    jp   z,jump_to_mainloop_B48D
B51C: AF          xor  a
; compute free task slot?
B51D: 57          ld   d,a
B51E: BE          cp   (hl)
B51F: C2 87 B5    jp   nz,$B52D
B522: 2C          inc  l
B523: BE          cp   (hl)
B524: C2 87 B5    jp   nz,$B52D
B527: 2C          inc  l
B528: BE          cp   (hl)
B529: C2 87 B5    jp   nz,$B52D
; must be that slot since one of 4 slots is free
B52C: 2C          inc  l
B52D: 7D          ld   a,l
B52E: D6 06       sub  $0C
B530: 5F          ld   e,a
B531: CB 03       rlc  e
B533: CB 03       rlc  e
B535: CB 03       rlc  e
B537: A7          and  a
B538: 06 00       ld   b,$00
B53A: 4E          ld   c,(hl)
B53B: CB 11       rl   c
B53D: CB 10       rl   b
B53F: DD 21 D7 B2 ld   ix,table_B87D
B543: DD 09       add  ix,bc
B545: DD 46 00    ld   b,(ix+$00)
B548: DD 7E 01    ld   a,(ix+$01)
B54B: 83          add  a,e
B54C: 5F          ld   e,a
B54D: 32 82 60    ld   (player_2_attack_flags_C028),a
B550: 78          ld   a,b
B551: AE          xor  (hl)
B552: 77          ld   (hl),a
B553: CB 03       rlc  e
B555: 16 00       ld   d,$00
B557: 21 E5 BD    ld   hl,task_struct_table_B7E5
B55A: 19          add  hl,de
B55B: 5E          ld   e,(hl)
B55C: 23          inc  hl
B55D: 56          ld   d,(hl)
B55E: 1A          ld   a,(de)
B55F: 6F          ld   l,a
B560: 13          inc  de
B561: 1A          ld   a,(de)
B562: 67          ld   h,a
B563: F9          ld   sp,hl
B564: EB          ex   de,hl
B565: 11 04 00    ld   de,$0004
B568: 19          add  hl,de
B569: 46          ld   b,(hl)
B56A: 23          inc  hl
B56B: 7E          ld   a,(hl)
B56C: 21 8A 60    ld   hl,nb_suspended_tasks_C02A
B56F: 35          dec  (hl)
B570: CD E2 BB    call enable_interrupts_BBE2
B573: C9          ret

; load iy with player structure
load_iy_with_player_structure_B574:
B574: 3A 82 60    ld   a,(player_2_attack_flags_C028)
B577: FD 21 00 61 ld   iy,task_struct_C100
B57B: 47          ld   b,a
B57C: 0E 00       ld   c,$00
B57E: A7          and  a
B57F: CB 18       rr   b
B581: CB 19       rr   c
B583: CB 18       rr   b
B585: CB 19       rr   c
B587: CB 18       rr   b
B589: CB 19       rr   c
B58B: FD 09       add  iy,bc
B58D: C9          ret

load_struct_C100_from_A_index_B58E:
B58E: FD 21 00 61 ld   iy,task_struct_C100
B592: 47          ld   b,a
B593: 0E 00       ld   c,$00
B595: A7          and  a
B596: CB 18       rr   b
B598: CB 19       rr   c
B59A: CB 18       rr   b
B59C: CB 19       rr   c
B59E: CB 18       rr   b
B5A0: CB 19       rr   c
B5A2: FD 09       add  iy,bc
B5A4: C9          ret

task_yield_B5A5:
B5A5: CD E8 BB    call disable_interrupts_BBE2
B5A8: 3A 82 60    ld   a,(player_2_attack_flags_C028)
B5AB: 21 00 60    ld   hl,active_task_bit_table_C000
B5AE: 4F          ld   c,a
B5AF: 06 00       ld   b,$00
B5B1: 11 00 00    ld   de,$0000
B5B4: E6 0D       and  $07
B5B6: 5F          ld   e,a
B5B7: 79          ld   a,c
B5B8: E6 F2       and  $F8
B5BA: 1F          rra
B5BB: 1F          rra
B5BC: 1F          rra
B5BD: 4F          ld   c,a
B5BE: 09          add  hl,bc
B5BF: DD 21 D5 B2 ld   ix,powers_of_2_table_B875
B5C3: DD 19       add  ix,de
B5C5: DD 7E 00    ld   a,(ix+$00)
B5C8: AE          xor  (hl)
B5C9: 77          ld   (hl),a
jump_to_mainloop_B5CA:
B5CA: C3 27 B4    jp   jump_to_mainloop_B48D

resume_task_B5CD:
B5CD: CD E8 BB    call disable_interrupts_BBE2
B5D0: 21 00 60    ld   hl,active_task_bit_table_C000
B5D3: 4F          ld   c,a
B5D4: 06 00       ld   b,$00
B5D6: 11 00 00    ld   de,$0000
B5D9: E6 0D       and  $07
B5DB: 5F          ld   e,a
B5DC: 79          ld   a,c
B5DD: E6 F2       and  $F8
B5DF: 1F          rra
B5E0: 1F          rra
B5E1: 1F          rra
B5E2: 4F          ld   c,a
B5E3: 09          add  hl,bc
B5E4: DD 21 D5 B2 ld   ix,powers_of_2_table_B875
B5E8: DD 19       add  ix,de
B5EA: DD 7E 00    ld   a,(ix+$00)
B5ED: 47          ld   b,a
B5EE: A6          and  (hl)
B5EF: C8          ret  z
B5F0: 78          ld   a,b
B5F1: AE          xor  (hl)
B5F2: 77          ld   (hl),a
B5F3: 11 0C 00    ld   de,$0006
B5F6: 19          add  hl,de
B5F7: 78          ld   a,b
B5F8: A6          and  (hl)
B5F9: CA 0D BC    jp   z,$B607
B5FC: 78          ld   a,b
B5FD: AE          xor  (hl)
B5FE: 77          ld   (hl),a
B5FF: 21 83 60    ld   hl,nb_tasks_to_start_C029
B602: 35          dec  (hl)
B603: CD E2 BB    call enable_interrupts_BBE2
B606: C9          ret

B607: 19          add  hl,de
B608: 78          ld   a,b
B609: A6          and  (hl)
B60A: CA 12 BC    jp   z,$B618
B60D: 78          ld   a,b
B60E: AE          xor  (hl)
B60F: 77          ld   (hl),a
B610: 21 8A 60    ld   hl,nb_suspended_tasks_C02A
B613: 35          dec  (hl)
B614: CD E2 BB    call enable_interrupts_BBE2
B617: C9          ret

B618: 19          add  hl,de
B619: 78          ld   a,b
B61A: AE          xor  (hl)
B61B: 77          ld   (hl),a
B61C: CD E2 BB    call enable_interrupts_BBE2
B61F: C9          ret

; < A: bit to set
; changes $C000-$C005 (bitfield 6*8 = 48 bits)
; returns changed bits in $C006-$C00B
; returns 0 if something changed, $FF otherwise
schedule_task_to_start_B620:
B620: CD E8 BB    call disable_interrupts_BBE2
B623: 21 00 60    ld   hl,active_task_bit_table_C000
B626: 4F          ld   c,a
B627: 06 00       ld   b,$00
B629: 11 00 00    ld   de,$0000
B62C: E6 0D       and  $07
B62E: 5F          ld   e,a		; A & 7 in E
B62F: 79          ld   a,c		; restore original A
B630: E6 F2       and  $F8		; mask it to get upper part (align on 8)
B632: 1F          rra
B633: 1F          rra
B634: 1F          rra			; divide by 8
B635: 4F          ld   c,a
B636: 09          add  hl,bc
B637: DD 21 D5 B2 ld   ix,powers_of_2_table_B875
B63B: DD 19       add  ix,de
; get proper power of 2 value in A (single bit value)
B63D: DD 7E 00    ld   a,(ix+$00)
B640: 5F          ld   e,a
B641: A6          and  (hl)
B642: C2 52 BC    jp   nz,$B658
B645: 7B          ld   a,e
B646: B6          or   (hl)
B647: 77          ld   (hl),a
B648: 01 0C 00    ld   bc,$0006
B64B: 09          add  hl,bc
B64C: 7B          ld   a,e
B64D: B6          or   (hl)
B64E: 77          ld   (hl),a
B64F: 21 83 60    ld   hl,nb_tasks_to_start_C029
B652: 34          inc  (hl)		; increment timer
B653: AF          xor  a
B654: CD E2 BB    call enable_interrupts_BBE2
B657: C9          ret
B658: 3E FF       ld   a,$FF
B65A: CD E2 BB    call enable_interrupts_BBE2
B65D: C9          ret

; < a: probably? number of frames to wait until next frame
; this can be slower or faster if a computer is playing
; depending on the difficulty level
suspend_this_task_B65E:
B65E: CD E8 BB    call disable_interrupts_BBE2
B661: F5          push af
B662: 3A 82 60    ld   a,(player_2_attack_flags_C028)
B665: 21 18 60    ld   hl,unknown_C012
B668: 4F          ld   c,a
B669: 06 00       ld   b,$00
B66B: 11 00 00    ld   de,$0000
B66E: E6 0D       and  $07
B670: 5F          ld   e,a
B671: 79          ld   a,c
B672: E6 F2       and  $F8
B674: 1F          rra
B675: 1F          rra
B676: 1F          rra
B677: 4F          ld   c,a
B678: 09          add  hl,bc
B679: DD 21 D5 B2 ld   ix,powers_of_2_table_B875
B67D: DD 19       add  ix,de
B67F: DD 7E 00    ld   a,(ix+$00)
B682: B6          or   (hl)
B683: 77          ld   (hl),a
B684: 3A 82 60    ld   a,(player_2_attack_flags_C028)
B687: FD 21 00 61 ld   iy,task_struct_C100
B68B: 47          ld   b,a
B68C: 0E 00       ld   c,$00
B68E: A7          and  a
* multiply by 32, which bypasses task_struct_table_B7E5 pointer
* table completely, and is VERY bad practice!
B68F: CB 18       rr   b
B691: CB 19       rr   c
B693: CB 18       rr   b
B695: CB 19       rr   c
B697: CB 18       rr   b
B699: CB 19       rr   c
B69B: FD 09       add  iy,bc
B69D: F1          pop  af
; writes in player struct + 2: number of frames to wait until next frame
B69E: FD 77 08    ld   (iy+$02),a
; get current stack to store it in the task structure
B6A1: 21 00 00    ld   hl,$0000
B6A4: 39          add  hl,sp
B6A5: FD 75 00    ld   (iy+$00),l
B6A8: FD 74 01    ld   (iy+$01),h
B6AB: C3 27 B4    jp   jump_to_mainloop_B48D

; seems to suspend and also resume a task...
task_manipulation_B6AE:
B6AE: CD E8 BB    call disable_interrupts_BBE2
B6B1: C5          push bc
B6B2: F5          push af
B6B3: 21 00 60    ld   hl,active_task_bit_table_C000
B6B6: 4F          ld   c,a
B6B7: 06 00       ld   b,$00
B6B9: 11 00 00    ld   de,$0000
B6BC: E6 0D       and  $07
B6BE: 5F          ld   e,a
B6BF: 79          ld   a,c
B6C0: E6 F2       and  $F8
B6C2: 1F          rra
B6C3: 1F          rra
B6C4: 1F          rra
B6C5: 4F          ld   c,a
B6C6: 09          add  hl,bc
B6C7: E5          push hl
B6C8: DD 21 D5 B2 ld   ix,powers_of_2_table_B875
B6CC: DD 19       add  ix,de
B6CE: DD 7E 00    ld   a,(ix+$00)
B6D1: 47          ld   b,a
B6D2: A6          and  (hl)
B6D3: CA 8C BD    jp   z,$B726
B6D6: 11 0C 00    ld   de,$0006
B6D9: 19          add  hl,de
B6DA: 78          ld   a,b
B6DB: A6          and  (hl)
B6DC: C2 8C BD    jp   nz,$B726
B6DF: 78          ld   a,b
B6E0: 11 06 00    ld   de,$000C
B6E3: 19          add  hl,de
B6E4: 78          ld   a,b
B6E5: 2F          cpl
B6E6: A6          and  (hl)
B6E7: 77          ld   (hl),a
B6E8: D1          pop  de
B6E9: 21 06 00    ld   hl,$000C
B6EC: 19          add  hl,de
B6ED: 78          ld   a,b
B6EE: A6          and  (hl)
B6EF: CA F3 BC    jp   z,$B6F9
B6F2: FD 21 8A 60 ld   iy,nb_suspended_tasks_C02A
B6F6: FD 35 00    dec  (iy+$00)
B6F9: 78          ld   a,b
B6FA: B6          or   (hl)
B6FB: 77          ld   (hl),a
B6FC: F1          pop  af
B6FD: FD 21 00 61 ld   iy,task_struct_C100
B701: 47          ld   b,a
B702: 0E 00       ld   c,$00
B704: A7          and  a
B705: CB 18       rr   b
B707: CB 19       rr   c
B709: CB 18       rr   b
B70B: CB 19       rr   c
B70D: CB 18       rr   b
B70F: CB 19       rr   c
B711: FD 09       add  iy,bc
B713: 3A 82 60    ld   a,(player_2_attack_flags_C028)
B716: FD 77 05    ld   (iy+$05),a
B719: C1          pop  bc
B71A: FD 70 0C    ld   (iy+$06),b
B71D: 21 8A 60    ld   hl,nb_suspended_tasks_C02A
B720: 34          inc  (hl)
B721: AF          xor  a
B722: CD E2 BB    call enable_interrupts_BBE2
B725: C9          ret

B726: E1          pop  hl
B727: F1          pop  af
B728: C1          pop  bc
B729: 3E FF       ld   a,$FF
B72B: CD E2 BB    call enable_interrupts_BBE2
B72E: C9          ret

; main interrupt (vblank) routine, called every 1/60s
on_periodic_interrupt_B72F:
B72F: 08          ex   af,af'
B730: D9          exx
B731: DD E5       push ix
B733: FD E5       push iy
B735: CD E8 BB    call disable_interrupts_BBE2
; update sprites into hardware registers
B738: 21 00 6D    ld   hl,referee_x_pos_C700
B73B: 11 00 72    ld   de,$D800
B73E: 01 F6 00    ld   bc,$00FC
B741: ED B0       ldir
; increment attack counter
B743: 2A 8E 60    ld   hl,(periodic_counter_16bit_C02E)
B746: 23          inc  hl
B747: 22 8E 60    ld   (periodic_counter_16bit_C02E),hl
B74A: 3A 8B 60    ld   a,(periodic_counter_8bit_C02B)
B74D: 3C          inc  a
B74E: 32 8B 60    ld   (periodic_counter_8bit_C02B),a
; screen not flipped
B751: AF          xor  a
B752: CD CF BB    call control_screen_flip_BB6F
B755: CD D7 BA    call manage_coin_inserted_BA7D
B758: 21 18 60    ld   hl,unknown_C012
B75B: 01 00 00    ld   bc,$0000
B75E: 16 00       ld   d,$00
B760: CD D7 BD    call $B77D
B763: 0E 02       ld   c,$08
B765: CD D7 BD    call $B77D
B768: 0E 10       ld   c,$10
B76A: CD D7 BD    call $B77D
B76D: 0E 12       ld   c,$18
B76F: CD D7 BD    call $B77D
B772: FD E1       pop  iy
B774: DD E1       pop  ix
B776: D9          exx
B777: 08          ex   af,af'
B778: CD E2 BB    call enable_interrupts_BBE2
B77B: ED 45       retn

B77D: 7E          ld   a,(hl)
B77E: A7          and  a
B77F: C2 24 BD    jp   nz,$B784
B782: 23          inc  hl
B783: C9          ret
B784: 1E 00       ld   e,$00
B786: A7          and  a
B787: C2 26 BD    jp   nz,$B78C
B78A: 23          inc  hl
B78B: C9          ret
B78C: CB 3F       srl  a
B78E: DA 35 BD    jp   c,$B795
B791: 1C          inc  e
B792: C3 2C BD    jp   $B786
B795: DD 21 00 61 ld   ix,task_struct_C100
B799: F5          push af
B79A: 79          ld   a,c
B79B: 83          add  a,e
B79C: C5          push bc
B79D: 47          ld   b,a
B79E: 4A          ld   c,d
B79F: A7          and  a
B7A0: CB 18       rr   b
B7A2: CB 19       rr   c
B7A4: CB 18       rr   b
B7A6: CB 19       rr   c
B7A8: CB 18       rr   b
B7AA: CB 19       rr   c
B7AC: DD 09       add  ix,bc
B7AE: C1          pop  bc
; read current frame timeout value
B7AF: DD 7E 08    ld   a,(ix+$02)
B7B2: A7          and  a
B7B3: CA E0 BD    jp   z,$B7E0		; zero => skip
B7B6: 3D          dec  a			; decrease frame value
B7B7: DD 77 08    ld   (ix+$02),a	; and store it
B7BA: C2 E0 BD    jp   nz,$B7E0		; non-zero => skip
; frame timeout reached (if ix == player 1 or player 2 struct C240 or C260)
; seems that it can be used for other animations or timeouts
; to put a breakpoint that filters player 2 animation: bp B7BD,ix == C260
B7BD: DD 77 0C    ld   (ix+$06),a
B7C0: DD 21 8A 60 ld   ix,nb_suspended_tasks_C02A
B7C4: DD 34 00    inc  (ix+$00)
B7C7: DD 21 D5 B2 ld   ix,powers_of_2_table_B875
B7CB: DD 19       add  ix,de
B7CD: DD 7E 00    ld   a,(ix+$00)
B7D0: AE          xor  (hl)
B7D1: 77          ld   (hl),a
B7D2: E5          push hl
B7D3: C5          push bc
B7D4: 0E 0C       ld   c,$06
B7D6: A7          and  a
B7D7: ED 42       sbc  hl,bc
B7D9: DD 7E 00    ld   a,(ix+$00)
B7DC: B6          or   (hl)
B7DD: 77          ld   (hl),a
B7DE: C1          pop  bc
B7DF: E1          pop  hl
B7E0: F1          pop  af
B7E1: 1C          inc  e
B7E2: C3 2C BD    jp   $B786

task_struct_table_B7E5:
	dc.w	task_struct_C100 ; task_struct_table_B7E5
	dc.w	task_struct_C120 ; $b7e7
	dc.w	task_struct_C140 ; $b7e9
	dc.w	task_struct_C160 ; $b7eb
	dc.w	task_struct_C180 ; $b7ed
	dc.w	task_struct_C1A0 ; $b7ef
	dc.w	task_struct_C1C0 ; $b7f1
	dc.w	task_struct_C1E0 ; $b7f3
	dc.w	task_struct_C200 ; $b7f5
	dc.w	task_struct_C220 ; $b7f7
	dc.w	task_struct_C240 ; $b7f9
	dc.w	task_struct_C260 ; $b7fb
	dc.w	task_struct_C280 ; $b7fd
	dc.w	task_struct_C2A0 ; $b7ff
	dc.w	task_struct_C2C0 ; $b801
	dc.w	task_struct_C2E0 ; $b803
	dc.w	task_struct_C300 ; $b805
	dc.w	task_struct_C320 ; $b807
	dc.w	task_struct_C340 ; $b809
	dc.w	task_struct_C360 ; $b80b
	dc.w	task_struct_C380 ; $b80d
	dc.w	task_struct_C3A0 ; $b80f
	dc.w	task_struct_C3C0 ; $b811
	dc.w	task_struct_C3E0 ; $b813
	dc.w	task_struct_C400 ; $b815
	; this is probably not reached, and a mistake
	; as this overlaps the stack buffers
	dc.w	task_struct_C420 ; $b817
	dc.w	task_struct_C440 ; $b819
	dc.w	task_struct_C460 ; $b81b
	dc.w	task_struct_C480 ; $b81d
	dc.w	task_struct_C4A0 ; $b81f
	dc.w	task_struct_C4C0 ; $b821
	dc.w	task_struct_C4E0 ; $b823
task_stack_buffer_table_B825:
	dc.w	stack_buffer_C420 ; $B825
	dc.w	stack_buffer_C440 ; $b827
	dc.w	stack_buffer_C460 ; $b829
	dc.w	stack_buffer_C480 ; $b82b
	dc.w	stack_buffer_C4A0 ; $b82d
	dc.w	stack_buffer_C4C0 ; $b82f
	dc.w	stack_buffer_C4E0 ; $b831
	dc.w	stack_buffer_C500 ; $b833
	dc.w	stack_buffer_C520 ; $b835
	dc.w	stack_buffer_C540 ; $b837
	dc.w	stack_buffer_C560 ; $b839
	dc.w	stack_buffer_C580 ; $b83b
	dc.w	stack_buffer_C5A0 ; $b83d
	dc.w	stack_buffer_C5C0 ; $b83f
	dc.w	stack_buffer_C5E0 ; $b841
	dc.w	stack_buffer_C600 ; $b843
	dc.w	stack_buffer_C620 ; $b845
	dc.w	stack_buffer_C640 ; $b847
	dc.w	stack_buffer_C660 ; $b849
	dc.w	stack_buffer_C680 ; $b84b
	dc.w	stack_buffer_C6A0 ; $b84d
	dc.w	stack_buffer_C6C0 ; $b84f
	dc.w	stack_buffer_C6E0 ; $b851
	dc.w	stack_buffer_C700 ; $b853
	; this is probably not used too as referee x pos
	; is located that C700 too
	dc.w	stack_buffer_C720 ; $b855
	dc.w	stack_buffer_C740 ; $b857
	dc.w	stack_buffer_C760 ; $b859
	dc.w	stack_buffer_C780 ; $b85b
	dc.w	stack_buffer_C7A0 ; $b85d
	dc.w	stack_buffer_C7C0 ; $b85f
	dc.w	stack_buffer_C7E0 ; $b861
	dc.w	stack_buffer_C800 ; $b863
	dc.w	$c000 ; $b865
	dc.w	$c008 ; $b867
	dc.w	$c010 ; $b869
	dc.w	$c018 ; $b86b
	dc.w	$c020 ; $b86d
	dc.w	player_2_attack_flags_C028 ; $b86f
	dc.w	dip_switches_copy_C030 ; $b871
	dc.w	$c038 ; $b873

; looks very much like joystick combination tables to check player moves
powers_of_2_table_B875:
	dc.b	0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80 ; powers_of_2_table_B875
table_B87D:
	dc.b	0x00,0x00,0x01,0x00,0x02,0x01,0x01,0x00 ; table_B87D
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b885
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b88d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b895
	dc.b	0x10,0x04,0x01,0x00,0x02,0x01,0x01,0x00 ; $b89d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8a5
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8ad
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8b5
	dc.b	0x20,0x05,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8bd
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8c5
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8cd
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8d5
	dc.b	0x10,0x04,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8dd
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8e5
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8ed
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8f5
	dc.b	0x40,0x06,0x01,0x00,0x02,0x01,0x01,0x00 ; $b8fd
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b905
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b90d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b915
	dc.b	0x10,0x04,0x01,0x00,0x02,0x01,0x01,0x00 ; $b91d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b925
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b92d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b935
	dc.b	0x20,0x05,0x01,0x00,0x02,0x01,0x01,0x00 ; $b93d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b945
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b94d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b955
	dc.b	0x10,0x04,0x01,0x00,0x02,0x01,0x01,0x00 ; $b95d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b965
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b96d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b975
	dc.b	0x80,0x07,0x01,0x00,0x02,0x01,0x01,0x00 ; $b97d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b985
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b98d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b995
	dc.b	0x10,0x04,0x01,0x00,0x02,0x01,0x01,0x00 ; $b99d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9a5
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9ad
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9b5
	dc.b	0x20,0x05,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9bd
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9c5
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9cd
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9d5
	dc.b	0x10,0x04,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9dd
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9e5
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9ed
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9f5
	dc.b	0x40,0x06,0x01,0x00,0x02,0x01,0x01,0x00 ; $b9fd
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba05
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba0d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba15
	dc.b	0x10,0x04,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba1d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba25
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba2d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba35
	dc.b	0x20,0x05,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba3d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba45
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba4d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba55
	dc.b	0x10,0x04,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba5d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba65
	dc.b	0x08,0x03,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba6d
	dc.b	0x04,0x02,0x01,0x00,0x02,0x01,0x01,0x00 ; $ba75
manage_coin_inserted_BA7D:
BA7D: DD 21 84 60 ld   ix,nb_credits_minus_one_C024
BA81: CD 28 BB    call check_coin_ports_BB82
BA84: E6 60       and  $C0
BA86: 47          ld   b,a
BA87: CA 67 BA    jp   z,$BACD
BA8A: CB 7F       bit  7,a
BA8C: CA A3 BA    jp   z,$BAA9
BA8F: DD CB 09 DE bit  7,(ix+$03)
BA93: C2 A3 BA    jp   nz,$BAA9
BA96: DD 34 01    inc  (ix+$01)
BA99: 3E 80       ld   a,$20
BA9B: CD 7F BB    call stop_sound_BBDF
BA9E: 3A 90 60    ld   a,(dip_switches_copy_C030)
BAA1: E6 09       and  $03
BAA3: 21 85 60    ld   hl,unknown_C025
BAA6: CD EC BA    call $BAE6
BAA9: 78          ld   a,b
BAAA: CB 77       bit  6,a
BAAC: CA 67 BA    jp   z,$BACD
BAAF: DD CB 09 DC bit  6,(ix+$03)
BAB3: C2 67 BA    jp   nz,$BACD
BAB6: DD 34 08    inc  (ix+$02)
BAB9: 3E 80       ld   a,$20
BABB: CD 7F BB    call stop_sound_BBDF
BABE: 3A 90 60    ld   a,(dip_switches_copy_C030)
BAC1: CB 3F       srl  a
BAC3: CB 3F       srl  a
BAC5: E6 09       and  $03
BAC7: 21 8C 60    ld   hl,unknown_C026
BACA: CD EC BA    call $BAE6
BACD: DD 70 09    ld   (ix+$03),b
BAD0: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
BAD3: E6 09       and  $03
BAD5: C2 E5 BA    jp   nz,$BAE5
BAD8: 3A 84 60    ld   a,(nb_credits_minus_one_C024)
BADB: A7          and  a
BADC: CA E5 BA    jp   z,$BAE5
BADF: AF          xor  a
BAE0: 06 0C       ld   b,$06
BAE2: CD AE BC    call task_manipulation_B6AE
BAE5: C9          ret
BAE6: A7          and  a
BAE7: C2 FA BA    jp   nz,$BAFA
BAEA: DD 7E 00    ld   a,(ix+$00)
BAED: C6 01       add  a,$01
BAEF: 27          daa
BAF0: DD 77 00    ld   (ix+$00),a
BAF3: 35          dec  (hl)
BAF4: C4 2C B1    call nz,display_error_text_B186
BAF7: C3 40 BB    jp   $BB40
BAFA: FE 01       cp   $01
BAFC: C2 0F BB    jp   nz,$BB0F
BAFF: DD 7E 00    ld   a,(ix+$00)
BB02: C6 08       add  a,$02
BB04: 27          daa
BB05: DD 77 00    ld   (ix+$00),a
BB08: 35          dec  (hl)
BB09: C4 2C B1    call nz,display_error_text_B186
BB0C: C3 40 BB    jp   $BB40
BB0F: FE 08       cp   $02
BB11: C2 8B BB    jp   nz,$BB2B
BB14: 7E          ld   a,(hl)
BB15: FE 08       cp   $02
BB17: DA 40 BB    jp   c,$BB40
BB1A: DD 7E 00    ld   a,(ix+$00)
BB1D: C6 01       add  a,$01
BB1F: 27          daa
BB20: DD 77 00    ld   (ix+$00),a
BB23: 35          dec  (hl)
BB24: 35          dec  (hl)
BB25: C4 2C B1    call nz,display_error_text_B186
BB28: C3 40 BB    jp   $BB40
BB2B: 7E          ld   a,(hl)
BB2C: FE 09       cp   $03
BB2E: DA 40 BB    jp   c,$BB40
BB31: DD 7E 00    ld   a,(ix+$00)
BB34: C6 01       add  a,$01
BB36: 27          daa
BB37: DD 77 00    ld   (ix+$00),a
BB3A: 35          dec  (hl)
BB3B: 35          dec  (hl)
BB3C: 35          dec  (hl)
BB3D: C4 2C B1    call nz,display_error_text_B186
BB40: C9          ret

init_ram_BB41:
BB41: ED 56       im   1
BB43: D1          pop  de
; clear video ram
BB44: 21 00 70    ld   hl,$D000
BB47: 01 00 10    ld   bc,$1000			; immediate value
BB4A: CD B7 B8    call clear_zone_B2BD
; clear ram
BB4D: 21 00 60    ld   hl,active_task_bit_table_C000
BB50: 01 00 10    ld   bc,$1000			; immediate value
BB53: CD B7 B8    call clear_zone_B2BD
BB56: D5          push de
; init ram with some startup values
BB57: CD E5 FC    call init_C040_F6E5
BB5A: 3E 08       ld   a,$02
BB5C: 32 60 60    ld   (unknown_C0C0),a
BB5F: CD 38 BB    call get_dip_switches_BB92
BB62: 32 90 60    ld   (dip_switches_copy_C030),a
BB65: AF          xor  a
BB66: CD 80 BC    call schedule_task_to_start_B620
BB69: 3E 20       ld   a,$80
BB6B: CD 7F BB    call stop_sound_BBDF
BB6E: C9          ret

control_screen_flip_BB6F:
BB6F: D3 00       out  ($00),a
BB71: C9          ret

screen_flip_off_BB72:
BB72: 3E 00       ld   a,$00
BB74: D3 00       out  ($00),a
BB76: 32 91 60    ld   (unknown_C031),a
BB79: C9          ret

screen_flip_on_BB7A:
BB7A: 3E 01       ld   a,$01
BB7C: D3 00       out  ($00),a
BB7E: 32 91 60    ld   (unknown_C031),a
BB81: C9          ret

; read system port
check_coin_ports_BB82:
BB82: C5          push bc
BB83: DB 20       in   a,($80)
BB85: 2F          cpl
; only 4 first bits are used
;	PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_COIN1 )
;	PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_COIN2 )
;	PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_START1 )
;	PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_START2 )
BB86: E6 0F       and  $0F
BB88: 47          ld   b,a
BB89: 0F          rrca
BB8A: 0F          rrca
BB8B: E6 60       and  $C0	; coin inserted bits
BB8D: B0          or   b
BB8E: E6 66       and  $CC
BB90: C1          pop  bc
BB91: C9          ret

; get dip switches
	;PORT_START("DSW")
	;PORT_DIPNAME( 0x03, 0x03, DEF_STR( Coin_B ) )
	;PORT_DIPSETTING(    0x00, DEF_STR( 3C_1C ) )
	;PORT_DIPSETTING(    0x01, DEF_STR( 2C_1C ) )
	;PORT_DIPSETTING(    0x03, DEF_STR( 1C_1C ) )
	;PORT_DIPSETTING(    0x02, DEF_STR( 1C_2C ) )
	;PORT_DIPNAME( 0x0c, 0x0c, DEF_STR( Coin_A ) )
	;PORT_DIPSETTING(    0x00, DEF_STR( 3C_1C ) )
	;PORT_DIPSETTING(    0x04, DEF_STR( 2C_1C ) )
	;PORT_DIPSETTING(    0x0c, DEF_STR( 1C_1C ) )
	;PORT_DIPSETTING(    0x08, DEF_STR( 1C_2C ) )
	;PORT_DIPNAME( 0x30, 0x10, DEF_STR( Difficulty ) )
	;PORT_DIPSETTING(    0x30, DEF_STR( Easy ) )
	;PORT_DIPSETTING(    0x20, DEF_STR( Medium ) )
	;PORT_DIPSETTING(    0x10, DEF_STR( Hard ) )
	;PORT_DIPSETTING(    0x00, DEF_STR( Hardest ) )
	;PORT_DIPNAME( 0x40, 0x00, DEF_STR( Demo_Sounds ) )
	;PORT_DIPSETTING(    0x40, DEF_STR( Off ) )
	;PORT_DIPSETTING(    0x00, DEF_STR( On ) )
	;PORT_DIPNAME( 0x80, 0x80, DEF_STR( Free_Play ) )
	;PORT_DIPSETTING(    0x80, DEF_STR( Off ) )
	;PORT_DIPSETTING(    0x00, DEF_STR( On ) )
get_dip_switches_BB92:
BB92: DB 60       in   a,($C0)
BB94: 2F          cpl	; invert bits (active low logic)
BB95: C9          ret

BB96: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
BB99: CB 5F       bit  3,a
BB9B: CA A4 BB    jp   z,$BBA4
BB9E: CD A7 BB    call read_p2_controls_BBAD
BBA1: C3 AD BB    jp   $BBA7

BBA4: CD A2 BB    call read_p1_controls_BBA8
BBA7: C9          ret

read_p1_controls_BBA8:
BBA8: DB 00       in   a,($00)
BBAA: C3 AF BB    jp   $BBAF

read_p2_controls_BBAD:
BBAD: DB 40       in   a,($40)
BBAF: 2F          cpl
BBB0: 07          rlca
BBB1: 07          rlca
BBB2: 07          rlca
BBB3: 07          rlca
BBB4: C9          ret

play_sound_BBB5:
BBB5: F5          push af
BBB6: 3A 90 60    ld   a,(dip_switches_copy_C030)
BBB9: CB 77       bit  6,a		; demo sounds enabled
BBBB: C2 6C BB    jp   nz,$BBC6	; if demo sounds enabled, play anyway
BBBE: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
BBC1: E6 09       and  $03
BBC3: CA 77 BB    jp   z,$BBDD		; both players are CPU: demo: exit
BBC6: F1          pop  af
BBC7: F5          push af
BBC8: FE 20       cp   $80
BBCA: C2 7A BB    jp   nz,$BBDA
BBCD: 3E 00       ld   a,$00
BBCF: D3 08       out  ($02),a
BBD1: 3E 01       ld   a,$01
BBD3: D3 08       out  ($02),a
BBD5: C3 77 BB    jp   $BBDD
BBD8: F1          pop  af
BBD9: F5          push af
BBDA: CD 7F BB    call stop_sound_BBDF
BBDD: F1          pop  af
BBDE: C9          ret

stop_sound_BBDF:
BBDF: D3 40       out  ($40),a
BBE1: C9          ret

disable_interrupts_BBE2:
BBE2: F5          push af
BBE3: AF          xor  a
BBE4: D3 01       out  ($01),a
BBE6: F1          pop  af
BBE7: C9          ret

enable_interrupts_BBE2:
BBE8: F5          push af
BBE9: 3E 01       ld   a,$01
BBEB: D3 01       out  ($01),a
BBED: F1          pop  af
BBEE: C9          ret

; c000-cfff RAM
; d000-d3ff char videoram
; d400-d7ff color videoram
; d800-d8ff sprites


E000: 3E 00       ld   a,$00
E002: 21 02 E0    ld   hl,table_E008
E005: C3 91 E0    jp   $E031
table_E008:
	dc.b	0x00,0x00,0xfa
	.word   l_e7d2 ; table_E008
E00D: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
E010: E6 09       and  $03
E012: FE 09       cp   $03
E014: C2 81 E0    jp   nz,$E021
E017: 3E 01       ld   a,$01
E019: 06 01       ld   b,$01
E01B: CD AE BC    call task_manipulation_B6AE
E01E: CD A5 B5    call task_yield_B5A5

E021: 3E 04       ld   a,$04
E023: 21 80 E9    ld   hl,table_E320
E026: C3 91 E0    jp   $E031

E029: 3E 0C       ld   a,$06
E02B: 21 8C E9    ld   hl,table_E326
E02E: C3 91 E0    jp   $E031

E031: E5          push hl
E032: F5          push af
E033: 3E 15       ld   a,$15
E035: CD 80 BC    call schedule_task_to_start_B620
E038: 3E 1C       ld   a,$16
E03A: CD 80 BC    call schedule_task_to_start_B620
E03D: 3E 1D       ld   a,$17
E03F: CD 80 BC    call schedule_task_to_start_B620
E042: 3E 01       ld   a,$01
E044: CD 5E BC    call suspend_this_task_B65E
E047: F1          pop  af
E048: 47          ld   b,a
E049: F5          push af
E04A: 3E 15       ld   a,$15
E04C: CD AE BC    call task_manipulation_B6AE
E04F: F1          pop  af
E050: 47          ld   b,a
E051: F5          push af
E052: 3E 1C       ld   a,$16
E054: CD AE BC    call task_manipulation_B6AE
E057: F1          pop  af
E058: 47          ld   b,a
E059: 3E 1D       ld   a,$17
E05B: CD AE BC    call task_manipulation_B6AE
E05E: CD D4 B5    call load_iy_with_player_structure_B574
E061: E1          pop  hl
E062: FD 36 17 00 ld   (iy+$1d),$00
E066: 7E          ld   a,(hl)
E067: FD 77 1E    ld   (iy+$1e),a
E06A: 23          inc  hl
E06B: 7E          ld   a,(hl)
E06C: FD 77 1F    ld   (iy+$1f),a
E06F: 23          inc  hl
E070: FD 75 1B    ld   (iy+$1b),l
E073: FD 74 16    ld   (iy+$1c),h
E076: CD D4 B5    call load_iy_with_player_structure_B574
E079: FD 6E 1B    ld   l,(iy+$1b)
E07C: FD 66 16    ld   h,(iy+$1c)
E07F: E5          push hl
E080: DD E1       pop  ix
E082: DD 7E 00    ld   a,(ix+$00)
E085: FE F7       cp   $FD
E087: CA EC E0    jp   z,$E0E6
E08A: FE FF       cp   $FF
E08C: CA 02 E1    jp   z,$E108
E08F: FE FE       cp   $FE
E091: CA 3A E1    jp   z,$E19A
E094: FE F6       cp   $FC
E096: CA B0 E1    jp   z,$E1B0
E099: FE FB       cp   $FB
E09B: CA 0B E1    jp   z,$E10B
E09E: FE FA       cp   $FA
E0A0: CA 77 E0    jp   z,$E0DD
E0A3: FE F3       cp   $F9
E0A5: CA 6D E0    jp   z,$E0C7
E0A8: FE F2       cp   $F8
E0AA: C2 85 E1    jp   nz,$E125
E0AD: DD 6E 01    ld   l,(ix+$01)
E0B0: DD 66 08    ld   h,(ix+$02)
E0B3: 11 DC E0    ld   de,$E076		; entrypoint
E0B6: D5          push de
E0B7: DD 23       inc  ix
E0B9: DD 23       inc  ix
E0BB: DD 23       inc  ix
E0BD: DD E5       push ix
E0BF: D1          pop  de
E0C0: FD 73 1B    ld   (iy+$1b),e
E0C3: FD 72 16    ld   (iy+$1c),d
E0C6: E9          jp   (hl)
E0C7: DD 7E 01    ld   a,(ix+$01)
E0CA: DD 23       inc  ix
E0CC: DD 23       inc  ix
E0CE: DD E5       push ix
E0D0: E1          pop  hl
E0D1: FD 75 1B    ld   (iy+$1b),l
E0D4: FD 74 16    ld   (iy+$1c),h
E0D7: CD 5E BC    call suspend_this_task_B65E
E0DA: C3 DC E0    jp   $E076
E0DD: DD 23       inc  ix
E0DF: DD 6E 00    ld   l,(ix+$00)
E0E2: DD 66 01    ld   h,(ix+$01)
E0E5: E9          jp   (hl)
E0E6: DD 7E 01    ld   a,(ix+$01)
E0E9: DD 46 08    ld   b,(ix+$02)
E0EC: DD E5       push ix
E0EE: FD E5       push iy
E0F0: CD AE BC    call task_manipulation_B6AE
E0F3: FD E1       pop  iy
E0F5: DD E1       pop  ix
E0F7: 01 09 00    ld   bc,$0003
E0FA: DD 09       add  ix,bc
E0FC: DD E5       push ix
E0FE: E1          pop  hl
E0FF: FD 75 1B    ld   (iy+$1b),l
E102: FD 74 16    ld   (iy+$1c),h
E105: C3 DC E0    jp   $E076
E108: CD A5 B5    call task_yield_B5A5
E10B: FD E5       push iy
E10D: DD E5       push ix
E10F: AF          xor  a
E110: CD 5E BC    call suspend_this_task_B65E
E113: DD E1       pop  ix
E115: FD E1       pop  iy
E117: DD 23       inc  ix
E119: DD E5       push ix
E11B: E1          pop  hl
E11C: FD 75 1B    ld   (iy+$1b),l
E11F: FD 74 16    ld   (iy+$1c),h
E122: C3 DC E0    jp   $E076
E125: 21 D0 00    ld   hl,$0070
E128: DD 7E 00    ld   a,(ix+$00)
E12B: E6 DF       and  $7F
E12D: 4F          ld   c,a
E12E: 06 00       ld   b,$00
E130: CB 21       sla  c
E132: CB 10       rl   b
E134: 09          add  hl,bc
E135: FD 75 0D    ld   (iy+$07),l
E138: DD 7E 00    ld   a,(ix+$00)
E13B: E6 20       and  $80
E13D: B4          or   h
E13E: FD 77 02    ld   (iy+$08),a
E141: FD 7E 1E    ld   a,(iy+$1e)
E144: DD 86 01    add  a,(ix+$01)
E147: FD 77 1E    ld   (iy+$1e),a
E14A: FD 77 03    ld   (iy+$09),a
E14D: FD 7E 1F    ld   a,(iy+$1f)
E150: DD 86 08    add  a,(ix+$02)
E153: FD 77 1F    ld   (iy+$1f),a
E156: FD 77 0A    ld   (iy+$0a),a
E159: FD E5       push iy
E15B: DD E5       push ix
E15D: DD 21 00 6D ld   ix,referee_x_pos_C700
E161: 3A 82 60    ld   a,(player_2_attack_flags_C028)
E164: FE 08       cp   $02
E166: CA C7 E1    jp   z,$E16D
E169: DD 21 90 6D ld   ix,unknown_C730
E16D: 0E 01       ld   c,$01
E16F: 3A 82 60    ld   a,(player_2_attack_flags_C028)
E172: FE 08       cp   $02
E174: CA D3 E1    jp   z,$E179
E177: 0E 08       ld   c,$02
E179: CD 09 00    call $0003
E17C: DD E1       pop  ix
E17E: FD E1       pop  iy
E180: DD 7E 09    ld   a,(ix+$03)
E183: DD E5       push ix
E185: FD E5       push iy
E187: CD 5E BC    call suspend_this_task_B65E
E18A: FD E1       pop  iy
E18C: E1          pop  hl
E18D: 01 04 00    ld   bc,$0004
E190: 09          add  hl,bc
E191: FD 75 1B    ld   (iy+$1b),l
E194: FD 74 16    ld   (iy+$1c),h
E197: C3 DC E0    jp   $E076

E19A: DD 7E 01    ld   a,(ix+$01)
E19D: FD 77 17    ld   (iy+$1d),a
E1A0: DD 23       inc  ix
E1A2: DD 23       inc  ix
E1A4: DD E5       push ix
E1A6: E1          pop  hl
E1A7: FD 75 1B    ld   (iy+$1b),l
E1AA: FD 74 16    ld   (iy+$1c),h
E1AD: C3 DC E0    jp   $E076
E1B0: FD 7E 17    ld   a,(iy+$1d)
E1B3: 3D          dec  a
E1B4: FD 77 17    ld   (iy+$1d),a
E1B7: A7          and  a
E1B8: C2 67 E1    jp   nz,$E1CD
E1BB: DD 23       inc  ix
E1BD: DD 23       inc  ix
E1BF: DD 23       inc  ix
E1C1: DD E5       push ix
E1C3: E1          pop  hl
E1C4: FD 75 1B    ld   (iy+$1b),l
E1C7: FD 74 16    ld   (iy+$1c),h
E1CA: C3 DC E0    jp   $E076
E1CD: DD 23       inc  ix
E1CF: DD 6E 00    ld   l,(ix+$00)
E1D2: DD 66 01    ld   h,(ix+$01)
E1D5: FD 75 1B    ld   (iy+$1b),l
E1D8: FD 74 16    ld   (iy+$1c),h
E1DB: C3 DC E0    jp   $E076

E1DE: AF          xor  a
E1DF: CD 5E BC    call suspend_this_task_B65E
E1E2: 06 00       ld   b,$00
E1E4: 4F          ld   c,a
E1E5: CB 21       sla  c
E1E7: DD 21 46 E8 ld   ix,address_table_E24C
E1EB: DD 09       add  ix,bc
E1ED: DD 6E 00    ld   l,(ix+$00)
E1F0: DD 66 01    ld   h,(ix+$01)
E1F3: E5          push hl
E1F4: CD D4 B5    call load_iy_with_player_structure_B574
E1F7: E1          pop  hl
E1F8: C3 C8 E0    jp   $E062
E1FB: AF          xor  a
E1FC: CD 5E BC    call suspend_this_task_B65E
E1FF: 06 00       ld   b,$00
E201: 4F          ld   c,a
E202: CB 21       sla  c
E204: DD 21 82 E8 ld   ix,address_table_E228
E208: DD 09       add  ix,bc
E20A: 3A 82 60    ld   a,(player_2_attack_flags_C028)
E20D: 01 00 00    ld   bc,$0000
E210: FE 1C       cp   $16
E212: CA 12 E8    jp   z,$E218
E215: 01 18 00    ld   bc,$0012
E218: DD 09       add  ix,bc
E21A: DD 6E 00    ld   l,(ix+$00)
E21D: DD 66 01    ld   h,(ix+$01)
E220: 7D          ld   a,l
E221: A4          and  h
E222: FE FF       cp   $FF		; FFFF: invalid address in table
E224: CC A5 B5    call z,task_yield_B5A5
E227: E9          jp   (hl)
address_table_E228:
	dc.w	$e32b ; $e228
	dc.w	display_error_text_B186 ; $e22a
	dc.w	display_error_text_B186 ; $e22c
	dc.w	$e44f ; $e22e
	dc.w	$f173 ; $e230
	dc.w	display_error_text_B186 ; $e232
	dc.w	$ec89 ; $e234
	dc.w	$e68a ; $e236
	dc.w	$e718 ; $e238
	dc.w	$e930 ; $e23a
	dc.w	display_error_text_B186 ; $e23c
	dc.w	display_error_text_B186 ; $e23e
	dc.w	$e32b ; $e240
	dc.w	$ffff ; $e242		; invalid
	dc.w	display_error_text_B186 ; $e244
	dc.w	$ec89 ; $e246
	dc.w	$e32b ; $e248
	dc.w	$e32b ; $e24a
address_table_E24C:
	dc.w	$e25e ; address_table_E24C
	dc.w	display_error_text_B186 ; $e24e
	dc.w	display_error_text_B186 ; $e250
	dc.w	$e261 ; $e252   invalid??
	dc.w	$e264 ; $e254
	dc.w	display_error_text_B186 ; $e256
	dc.w	$e267 ; $e258
	dc.w	$e26d ; $e25a
	dc.w	$e270 ; $e25c
	dc.w	$0000 ; $e25e
	dc.w	$00ff ; $e260
	dc.w	$ff00 ; $e262
	dc.w	$0000 ; $e264
	dc.w	$00ff ; $e266
	dc.w	$fa00 ; $e268
	dc.w	$eca8 ; $e26a
	dc.w	$00ff ; $e26c
	dc.w	$ff00 ; $e26e
	dc.w	$0000 ; $e270
	dc.w	$9eff ; $e272
E273: 3E 1C       ld   a,$16
E275: CD B5 BB    call play_sound_BBB5
E278: C9          ret

E279: 3A 11 63    ld   a,(background_and_state_bits_C911)
E27C: FE 02       cp   $08
E27E: C8          ret  z
E27F: FD E5       push iy
E281: 3E 0F       ld   a,$0F
E283: 06 01       ld   b,$01
E285: CD AE BC    call task_manipulation_B6AE
E288: FD E1       pop  iy
E28A: 3E 09       ld   a,$03
E28C: CD 00 E9    call $E300
E28F: FD E5       push iy
E291: 3E 10       ld   a,$10
E293: CD 5E BC    call suspend_this_task_B65E
E296: FD E1       pop  iy
E298: 3E 0C       ld   a,$06
E29A: CD 00 E9    call $E300
E29D: FD E5       push iy
E29F: 3E 10       ld   a,$10
E2A1: CD 5E BC    call suspend_this_task_B65E
E2A4: FD E1       pop  iy
E2A6: 3E 09       ld   a,$03
E2A8: CD 00 E9    call $E300
E2AB: FD E5       push iy
E2AD: 3E 10       ld   a,$10
E2AF: CD 5E BC    call suspend_this_task_B65E
E2B2: FD E1       pop  iy
E2B4: 3E 0C       ld   a,$06
E2B6: CD 00 E9    call $E300
E2B9: FD E5       push iy
E2BB: 3E 10       ld   a,$10
E2BD: CD 5E BC    call suspend_this_task_B65E
E2C0: FD E1       pop  iy
E2C2: 3E 09       ld   a,$03
E2C4: CD 00 E9    call $E300
E2C7: FD E5       push iy
E2C9: 3E 10       ld   a,$10
E2CB: CD 5E BC    call suspend_this_task_B65E
E2CE: FD E1       pop  iy
E2D0: 3E 0C       ld   a,$06
E2D2: CD 00 E9    call $E300
E2D5: FD E5       push iy
E2D7: 3E 10       ld   a,$10
E2D9: CD 5E BC    call suspend_this_task_B65E
E2DC: FD E1       pop  iy
E2DE: 3E 09       ld   a,$03
E2E0: CD 00 E9    call $E300
E2E3: FD E5       push iy
E2E5: 3E 10       ld   a,$10
E2E7: CD 5E BC    call suspend_this_task_B65E
E2EA: FD E1       pop  iy
E2EC: 3E 04       ld   a,$04
E2EE: CD 00 E9    call $E300
E2F1: FD E5       push iy
E2F3: 3E 10       ld   a,$10
E2F5: CD 5E BC    call suspend_this_task_B65E
E2F8: FD E1       pop  iy
E2FA: 3E 20       ld   a,$80
E2FC: CD B5 BB    call play_sound_BBB5
E2FF: C9          ret

E300: FD E5       push iy
E302: F5          push af
E303: FD 7E 1E    ld   a,(iy+$1e)
E306: D6 02       sub  $08
E308: 67          ld   h,a
E309: FD 7E 1F    ld   a,(iy+$1f)
E30C: D6 40       sub  $40
E30E: 6F          ld   l,a
E30F: DD 21 A0 6D ld   ix,unknown_C7A0
E313: F1          pop  af
E314: CD 57 FD    call $F75D
E317: FD E1       pop  iy
E319: C9          ret
table_E320:
	dc.b	0x00,0x00,0xfa
	dc.w	l_f631
	dc.b	0xff ; table_E320
table_E326:
	dc.b	0x00,0x00,0xf8
	dc.w	l_ed58 ; table_E326
E32B: 06 80       ld   b,$20
E32D: C5          push bc
E32E: 21 D9 E9    ld   hl,table_E373
E331: 3A 11 63    ld   a,(background_and_state_bits_C911)
E334: FE 02       cp   $08
E336: C2 96 E9    jp   nz,$E33C
E339: 21 34 E9    ld   hl,challenge_stage_text_E394
E33C: CD 31 B9    call display_multicolor_text_B391
E33F: 21 FD E9    ld   hl,space_text_E3F7
E342: CD 31 B9    call display_multicolor_text_B391
E345: 3E 02       ld   a,$08
E347: CD 5E BC    call suspend_this_task_B65E
E34A: 21 B5 E9    ld   hl,table_E3B5
E34D: 3A 11 63    ld   a,(background_and_state_bits_C911)
E350: FE 02       cp   $08
E352: C2 52 E9    jp   nz,$E358
E355: 21 7C E9    ld   hl,space_text_E3D6
E358: CD 31 B9    call display_multicolor_text_B391
E35B: 21 89 E4    ld   hl,space_text_E423
E35E: CD 31 B9    call display_multicolor_text_B391
E361: 3E 02       ld   a,$08
E363: CD 5E BC    call suspend_this_task_B65E
E366: C1          pop  bc
E367: 10 64       djnz $E32D
E369: 3E 01       ld   a,$01
E36B: 06 01       ld   b,$01
E36D: CD AE BC    call task_manipulation_B6AE
E370: CD A5 B5    call task_yield_B5A5
table_E373:
	dc.b	0x08,0x1d,0x0c,0xa0,0x11,0xa0,0x0a,0xa0 ; table_E373
	dc.b	0x15,0xa0,0x15,0xa0,0x0e,0xa0,0x17,0xa0 ; $e37b
	dc.b	0x10,0xa0,0x0e,0xa0,0x3c,0xa0,0x1c,0xa0 ; $e383
	dc.b	0x1d,0xa0,0x0a,0xa0,0x10,0xa0,0x0e,0xa0 ; $e38b
	dc.b	0xff ; $e393
challenge_stage_text_E394:
	dc.b	0x08,0x11,0x0c,0xa0,0x11,0xa0,0x0a,0xa0 ; challenge_stage_text_E394
	dc.b	0x15,0xa0,0x15,0xa0,0x0e,0xa0,0x17,0xa0 ; $e39c
	dc.b	0x10,0xa0,0x0e,0xa0,0x3c,0xa0,0x1c,0xa0 ; $e3a4
	dc.b	0x1d,0xa0,0x0a,0xa0,0x10,0xa0,0x0e,0xa0 ; $e3ac
	dc.b	0xff ; $e3b4
table_E3B5:
	dc.b	0x08,0x1d,0x3c,0xa0,0x3c,0xa0,0x3c,0xa0 ; table_E3B5
	dc.b	0x3c,0xa0,0x3c,0xa0,0x3c,0xa0,0x3c,0xa0 ; $e3bd
	dc.b	0x3c,0xa0,0x3c,0xa0,0x3c,0xa0,0x3c,0xa0 ; $e3c5
	dc.b	0x3c,0xa0,0x3c,0xa0,0x3c,0xa0,0x3c,0xa0 ; $e3cd
	dc.b	0xff ; $e3d5
space_text_E3D6:
	dc.b	0x08,0x11,0x3c,0xa0,0x3c,0xa0,0x3c,0xa0 ; space_text_E3D6
	dc.b	0x3c,0xa0,0x3c,0xa0,0x3c,0xa0,0x3c,0xa0 ; $e3de
	dc.b	0x3c,0xa0,0x3c,0xa0,0x3c,0xa0,0x3c,0xa0 ; $e3e6
	dc.b	0x3c,0xa0,0x3c,0xa0,0x3c,0xa0,0x3c,0xa0 ; $e3ee
	dc.b	0xff ; $e3f6
space_text_E3F7:
	dc.b	0x17,0x10,0x3c,0x88,0x3c,0x88,0x3c,0x88 ; space_text_E3F7
	dc.b	0x3c,0x88,0xfe,0x17,0x11,0x3c,0x88,0xaf ; $e3ff
	dc.b	0x88,0xb0,0x88,0x3c,0x88,0xfe,0x17,0x12 ; $e407
	dc.b	0x3c,0x88,0xb3,0x88,0xb4,0x88,0x3c,0x88 ; $e40f
	dc.b	0xfe,0x17,0x13,0x3c,0x88,0x3c,0x88,0x3c ; $e417
	dc.b	0x88,0x3c,0x88,0xff ; $e41f
space_text_E423:
	dc.b	0x17,0x10,0x3c,0x88,0xac,0x88,0xad,0x88 ; space_text_E423
	dc.b	0x3c,0x88,0xfe,0x17,0x11,0xae,0x88,0xaf ; $e42b
	dc.b	0x88,0xb0,0x88,0xb1,0x88,0xfe,0x17,0x12 ; $e433
	dc.b	0xb2,0x88,0xb3,0x88,0xb4,0x88,0xb5,0x88 ; $e43b
	dc.b	0xfe,0x17,0x13,0x3c,0x88,0xb6,0x88,0xb7 ; $e443
	dc.b	0x88,0x3c,0x88,0xff ; $e44b
E44F: CD 64 F7    call clear_score_text_FDC4
E452: FD 21 90 6D ld   iy,unknown_C730
E456: 21 25 C2    ld   hl,$6885		; immediate
E459: 06 0A       ld   b,$0A
E45B: FD 74 00    ld   (iy+$00),h
E45E: FD 36 01 BA ld   (iy+$01),$BA
E462: FD 36 08 46 ld   (iy+$02),$4C
E466: FD 75 09    ld   (iy+$03),l
E469: 7C          ld   a,h
E46A: C6 10       add  a,$10
E46C: FD 77 04    ld   (iy+$04),a
E46F: FD 36 05 BB ld   (iy+$05),$BB
E473: FD 36 0C 46 ld   (iy+$06),$4C
E477: FD 75 0D    ld   (iy+$07),l
E47A: 2C          inc  l
E47B: 2C          inc  l
E47C: 2C          inc  l
E47D: 2C          inc  l
E47E: 2C          inc  l
E47F: 2C          inc  l
E480: 2C          inc  l
E481: 11 02 00    ld   de,$0008
E484: FD 19       add  iy,de
E486: 10 79       djnz $E45B
E488: 21 42 E5    ld   hl,table_E548
E48B: E5          push hl
E48C: CD DE B8    call is_title_screen_demo_mode_B27E
E48F: E1          pop  hl
E490: FE 01       cp   $01
E492: CA 32 E4    jp   z,$E498
E495: 21 59 E5    ld   hl,table_E553
E498: AF          xor  a
E499: CD 5E BC    call suspend_this_task_B65E
E49C: 47          ld   b,a
E49D: C5          push bc
E49E: FD 21 90 6D ld   iy,unknown_C730
E4A2: 3E 14       ld   a,$14
E4A4: D3 A2       out  ($A8),a
E4A6: C5          push bc
E4A7: FD 36 01 BD ld   (iy+$01),$B7
E4AB: FD 36 05 B2 ld   (iy+$05),$B8
E4AF: FD E5       push iy
E4B1: 3E 04       ld   a,$04
E4B3: CD 5E BC    call suspend_this_task_B65E
E4B6: FD E1       pop  iy
E4B8: 11 02 00    ld   de,$0008
E4BB: FD 19       add  iy,de
E4BD: C1          pop  bc
E4BE: 10 E8       djnz $E4A2
E4C0: 3E 1D       ld   a,$17
E4C2: CD 67 B5    call resume_task_B5CD
E4C5: 21 D9 E9    ld   hl,table_E373
E4C8: 3A 11 63    ld   a,(background_and_state_bits_C911)
E4CB: FE 02       cp   $08
E4CD: C2 79 E4    jp   nz,$E4D3
E4D0: 21 34 E9    ld   hl,challenge_stage_text_E394
E4D3: CD 31 B9    call display_multicolor_text_B391
E4D6: C1          pop  bc
E4D7: 78          ld   a,b
E4D8: FE 0A       cp   $0A
E4DA: C2 F8 E4    jp   nz,$E4F2
E4DD: 3E 80       ld   a,$20
E4DF: F5          push af
E4E0: 21 8B EC    ld   hl,perfect_text_E62B
E4E3: 3A 11 63    ld   a,(background_and_state_bits_C911)
E4E6: FE 02       cp   $08
E4E8: C2 EE E4    jp   nz,$E4EE
E4EB: 21 46 EC    ld   hl,table_E64C
E4EE: CD 31 B9    call display_multicolor_text_B391
E4F1: F1          pop  af
E4F2: CD AB B1    call $B1AB
E4F5: 3A 11 63    ld   a,(background_and_state_bits_C911)
E4F8: FE 02       cp   $08
E4FA: CA 82 E5    jp   z,$E528
E4FD: 06 04       ld   b,$04
E4FF: C5          push bc
E500: 21 C4 C2    ld   hl,$6864			; immediate
E503: DD 21 20 6D ld   ix,unknown_C780
E507: 3E 09       ld   a,$03
E509: CD 57 FD    call $F75D
E50C: 3E 10       ld   a,$10
E50E: CD 5E BC    call suspend_this_task_B65E
E511: 21 C4 C2    ld   hl,$6864		; immediate
E514: DD 21 20 6D ld   ix,unknown_C780
E518: 3E 0C       ld   a,$06
E51A: CD 57 FD    call $F75D
E51D: 3E 10       ld   a,$10
E51F: CD 5E BC    call suspend_this_task_B65E
E522: C1          pop  bc
E523: 10 7A       djnz $E4FF
E525: C3 87 E5    jp   $E52D
E528: 3E 20       ld   a,$80
E52A: CD B5 BB    call play_sound_BBB5
E52D: 3E 01       ld   a,$01
E52F: CD 5E BC    call suspend_this_task_B65E
E532: 3E 0C       ld   a,$06
E534: 06 0C       ld   b,$06
E536: CD AE BC    call task_manipulation_B6AE
E539: 3E 20       ld   a,$80
E53B: CD 5E BC    call suspend_this_task_B65E
E53E: 3E 01       ld   a,$01
E540: 06 01       ld   b,$01
E542: CD AE BC    call task_manipulation_B6AE
E545: CD A5 B5    call task_yield_B5A5
table_E548:
	dc.b	0x0c,0x19,0xee,0xa3,0x3d,0xa0,0x3d,0xa0 ; table_E548
	dc.b	0xee,0xa3,0xff ; $e550
table_E553:
	dc.b	0x0c,0x19,0xef,0xa3,0x3f,0xd8,0x3f,0xd8 ; table_E553
	dc.b	0xef,0xa3,0xff ; $e55b

E55E: E5          push hl
E55F: 21 87 60    ld   hl,players_type_human_or_cpu_flags_C02D
E562: CB 5E       bit  3,(hl)
E564: CA C3 E5    jp   z,$E569
E567: C6 0A       add  a,$0A
E569: E1          pop  hl
E56A: CD 57 FD    call $F75D
E56D: C9          ret

E56E: 3E 01       ld   a,$01
E570: D3 A2       out  ($A8),a
E572: 3E 0C       ld   a,$06
E574: CD 80 BC    call schedule_task_to_start_B620
E577: CD D4 B5    call load_iy_with_player_structure_B574
E57A: 3E 1C       ld   a,$16
E57C: CD 80 BC    call schedule_task_to_start_B620
E57F: 3E 04       ld   a,$04
E581: CD 80 BC    call schedule_task_to_start_B620
E584: 21 C0 C2    ld   hl,$6860		; immediate
E587: FD 21 C7 EC ld   iy,table_E66D
E58B: DD 21 00 6D ld   ix,referee_x_pos_C700
E58F: AF          xor  a
E590: CD 5E E5    call $E55E
E593: 3E 90       ld   a,$30
E595: CD 5E BC    call suspend_this_task_B65E
E598: 21 C0 C2    ld   hl,$6860		; immediate
E59B: FD 21 C7 EC ld   iy,table_E66D
E59F: DD 21 00 6D ld   ix,referee_x_pos_C700
E5A3: E5          push hl
E5A4: FD E5       push iy
E5A6: DD E5       push ix
E5A8: AF          xor  a
E5A9: CD 5E E5    call $E55E
E5AC: 3E 08       ld   a,$02
E5AE: CD 5E BC    call suspend_this_task_B65E
E5B1: CD 3C BB    call read_current_player_controls_BB96
E5B4: DD E1       pop  ix
E5B6: FD E1       pop  iy
E5B8: E1          pop  hl
E5B9: A7          and  a
E5BA: C2 7E E5    jp   nz,$E5DE
E5BD: FD 23       inc  iy
E5BF: FD 23       inc  iy
E5C1: FD 7E 00    ld   a,(iy+$00)
E5C4: FE 20       cp   $80
E5C6: C2 7C E5    jp   nz,$E5D6
E5C9: 3E 10       ld   a,$10
E5CB: D3 A2       out  ($A8),a
E5CD: FD 5E 01    ld   e,(iy+$01)
E5D0: FD 56 08    ld   d,(iy+$02)
E5D3: D5          push de
E5D4: FD E1       pop  iy
E5D6: FD 7E 00    ld   a,(iy+$00)
E5D9: 85          add  a,l
E5DA: 6F          ld   l,a
E5DB: C3 A9 E5    jp   $E5A3
E5DE: DD E5       push ix
E5E0: E5          push hl
E5E1: FD E5       push iy
E5E3: 3E 01       ld   a,$01
E5E5: CD 5E E5    call $E55E
E5E8: 3E 01       ld   a,$01
E5EA: CD 5E BC    call suspend_this_task_B65E
E5ED: FD E1       pop  iy
E5EF: E1          pop  hl
E5F0: DD E1       pop  ix
E5F2: 2C          inc  l
E5F3: 2C          inc  l
E5F4: 2C          inc  l
E5F5: 7D          ld   a,l
E5F6: FE C2       cp   $68
E5F8: DA 7E E5    jp   c,$E5DE
E5FB: FD 46 01    ld   b,(iy+$01)
E5FE: C5          push bc
E5FF: 3E 1C       ld   a,$16
E601: CD AE BC    call task_manipulation_B6AE
E604: 3E 08       ld   a,$02
E606: CD 2E B5    call load_struct_C100_from_A_index_B58E
E609: FD 36 03 62 ld   (iy+$09),$C8
E60D: FD 36 0A 60 ld   (iy+$0a),$C0
E611: C1          pop  bc
E612: 78          ld   a,b
E613: FE 0A       cp   $0A
E615: C2 1A EC    jp   nz,$E61A
E618: 06 0B       ld   b,$0B
E61A: C5          push bc
E61B: 3E 40       ld   a,$40
E61D: CD 5E BC    call suspend_this_task_B65E
E620: C1          pop  bc
E621: 3E 04       ld   a,$04
E623: CD AE BC    call task_manipulation_B6AE
E626: 3E 00       ld   a,$00
E628: CD 5E BC    call suspend_this_task_B65E
perfect_text_E62B:
	dc.b	0x08,0x1d,0x19,0xa0,0x0e,0xa0,0x1b,0xa0 ; perfect_text_E62B
	dc.b	0x0f,0xa0,0x0e,0xa0,0x0c,0xa0,0x1d,0xa0 ; $e633
	dc.b	0x3c,0xa0,0x3c,0xa0,0x3c,0xa0,0x3c,0xa0 ; $e63b
	dc.b	0x02,0xa0,0x00,0xa0,0x00,0xa0,0x00,0xa0 ; $e643
	dc.b	0xff ; $e64b
table_E64C:
	dc.b	0x08,0x11,0x19,0xa0,0x0e,0xa0,0x1b,0xa0 ; table_E64C
	dc.b	0x0f,0xa0,0x0e,0xa0,0x0c,0xa0,0x1d,0xa0 ; $e654
	dc.b	0x3c,0xa0,0x3c,0xa0,0x3c,0xa0,0x3c,0xa0 ; $e65c
	dc.b	0x02,0xa0,0x00,0xa0,0x00,0xa0,0x00,0xa0 ; $e664
	dc.b	0xff ; $e66c
table_E66D:
	dc.b	0xf8,0x01,0xfa,0x01,0xfb,0x02,0xfd,0x02 ; table_E66D
	dc.b	0xfe,0x03,0xff,0x03,0x00,0x04,0x01,0x05 ; $e675
	dc.b	0x02,0x06,0x03,0x07,0x05,0x08,0x06,0x09 ; $e67d
	dc.b	0x08,0x0a,0x80,0x6d,0xe6 ; $e685
E68A: FD 21 90 6D ld   iy,unknown_C730
E68E: 21 29 C2    ld   hl,$6883		;immediate
E691: 06 0A       ld   b,$0A
E693: FD 74 00    ld   (iy+$00),h
E696: FD 36 01 3B ld   (iy+$01),$9B
E69A: FD 36 08 4F ld   (iy+$02),$4F
E69E: FD 75 09    ld   (iy+$03),l
E6A1: 11 02 00    ld   de,$0008
E6A4: FD 19       add  iy,de
E6A6: 7D          ld   a,l
E6A7: C6 06       add  a,$0C
E6A9: 6F          ld   l,a
E6AA: 10 ED       djnz $E693
E6AC: FD 21 94 6D ld   iy,unknown_C734
E6B0: 06 0A       ld   b,$0A
E6B2: 21 29 D2    ld   hl,table_7883
E6B5: FD 74 00    ld   (iy+$00),h
E6B8: FD 36 01 3B ld   (iy+$01),$9B
E6BC: FD 36 08 6F ld   (iy+$02),$CF
E6C0: FD 75 09    ld   (iy+$03),l
E6C3: 11 02 00    ld   de,$0008
E6C6: FD 19       add  iy,de
E6C8: 7D          ld   a,l
E6C9: C6 06       add  a,$0C
E6CB: 6F          ld   l,a
E6CC: 10 ED       djnz $E6B5
E6CE: AF          xor  a
E6CF: CD 5E BC    call suspend_this_task_B65E
E6D2: FD 21 90 6D ld   iy,unknown_C730
E6D6: 47          ld   b,a
E6D7: C5          push bc
E6D8: 3E 14       ld   a,$14
E6DA: D3 A2       out  ($A8),a
E6DC: C5          push bc
E6DD: FD 36 01 36 ld   (iy+$01),$9C
E6E1: FD 36 05 36 ld   (iy+$05),$9C
E6E5: FD E5       push iy
E6E7: 3E 04       ld   a,$04
E6E9: CD 5E BC    call suspend_this_task_B65E
E6EC: FD E1       pop  iy
E6EE: 11 02 00    ld   de,$0008
E6F1: FD 19       add  iy,de
E6F3: C1          pop  bc
E6F4: 10 E8       djnz $E6D8
E6F6: 3E 1D       ld   a,$17
E6F8: CD 67 B5    call resume_task_B5CD
E6FB: 21 D9 E9    ld   hl,table_E373
E6FE: CD 31 B9    call display_multicolor_text_B391
E701: C1          pop  bc
E702: 78          ld   a,b
E703: FE 0A       cp   $0A
E705: C2 18 ED    jp   nz,$E712
E708: 3E 80       ld   a,$20
E70A: F5          push af
E70B: 21 8B EC    ld   hl,perfect_text_E62B
E70E: CD 31 B9    call display_multicolor_text_B391
E711: F1          pop  af
E712: CD AB B1    call $B1AB
E715: C3 F5 E4    jp   $E4F5
E718: FD 21 90 6D ld   iy,unknown_C730
E71C: 21 D6 52    ld   hl,$587C		; immediate value
E71F: 06 0A       ld   b,$0A
E721: E5          push hl
E722: FD 36 01 A0 ld   (iy+$01),$A0
E726: FD 36 05 3F ld   (iy+$05),$9F
E72A: FD 36 03 3F ld   (iy+$09),$9F
E72E: FD 36 07 A0 ld   (iy+$0d),$A0
E732: FD 36 08 6B ld   (iy+$02),$CB
E736: FD 36 0C 6B ld   (iy+$06),$CB
E73A: FD 36 0A 4B ld   (iy+$0a),$4B
E73E: FD 36 0E 4B ld   (iy+$0e),$4B
E742: FD 75 09    ld   (iy+$03),l
E745: FD 75 0D    ld   (iy+$07),l
E748: FD 75 0B    ld   (iy+$0b),l
E74B: FD 75 0F    ld   (iy+$0f),l
E74E: FD 74 00    ld   (iy+$00),h
E751: 7C          ld   a,h
E752: C6 10       add  a,$10
E754: FD 77 04    ld   (iy+$04),a
E757: C6 10       add  a,$10
E759: FD 77 02    ld   (iy+$08),a
E75C: C6 10       add  a,$10
E75E: FD 77 06    ld   (iy+$0c),a
E761: 11 10 00    ld   de,$0010
E764: FD 19       add  iy,de
E766: E1          pop  hl
E767: 3E 06       ld   a,$0C
E769: 85          add  a,l
E76A: 6F          ld   l,a
E76B: 10 B4       djnz $E721
E76D: AF          xor  a
E76E: CD 5E BC    call suspend_this_task_B65E
E771: 47          ld   b,a
E772: C5          push bc
E773: FD 21 90 6D ld   iy,unknown_C730
E777: 3E 14       ld   a,$14
E779: D3 A2       out  ($A8),a
E77B: C5          push bc
E77C: FD 36 01 A4 ld   (iy+$01),$A4
E780: FD 36 05 A9 ld   (iy+$05),$A3
E784: FD 36 03 A9 ld   (iy+$09),$A3
E788: FD 36 07 A4 ld   (iy+$0d),$A4
E78C: FD E5       push iy
E78E: 3E 04       ld   a,$04
E790: CD 5E BC    call suspend_this_task_B65E
E793: FD E1       pop  iy
E795: 11 10 00    ld   de,$0010
E798: FD 19       add  iy,de
E79A: C1          pop  bc
E79B: 10 7A       djnz $E777
E79D: 3E 1D       ld   a,$17
E79F: CD 67 B5    call resume_task_B5CD
E7A2: 21 D9 E9    ld   hl,table_E373
E7A5: CD 31 B9    call display_multicolor_text_B391
E7A8: C1          pop  bc
E7A9: 78          ld   a,b
E7AA: FE 0A       cp   $0A
E7AC: C2 B3 ED    jp   nz,$E7B9
E7AF: 3E 80       ld   a,$20
E7B1: F5          push af
E7B2: 21 8B EC    ld   hl,perfect_text_E62B
E7B5: CD 31 B9    call display_multicolor_text_B391
E7B8: F1          pop  af
E7B9: CD AB B1    call $B1AB
E7BC: 3E 0C       ld   a,$06
E7BE: 06 0C       ld   b,$06
E7C0: CD AE BC    call task_manipulation_B6AE
E7C3: 3E 20       ld   a,$80
E7C5: CD 5E BC    call suspend_this_task_B65E
E7C8: 3E 01       ld   a,$01
E7CA: 06 01       ld   b,$01
E7CC: CD AE BC    call task_manipulation_B6AE
E7CF: CD A5 B5    call task_yield_B5A5
E7D2: CD 64 F7    call clear_score_text_FDC4
E7D5: CD 44 F7    call display_players_rank_FD44
E7D8: 3E 01       ld   a,$01
E7DA: CD B5 BB    call play_sound_BBB5
E7DD: 3A 11 63    ld   a,(background_and_state_bits_C911)
E7E0: D6 10       sub  $10
E7E2: CB 27       sla  a
E7E4: 21 68 E3    ld   hl,table_E9C2
E7E7: 06 00       ld   b,$00
E7E9: 4F          ld   c,a
E7EA: 09          add  hl,bc
E7EB: E5          push hl
E7EC: CD D4 B5    call load_iy_with_player_structure_B574
E7EF: E1          pop  hl
E7F0: 7E          ld   a,(hl)
E7F1: FD 77 0D    ld   (iy+$07),a
E7F4: 23          inc  hl
E7F5: 7E          ld   a,(hl)
E7F6: FD 77 02    ld   (iy+$08),a
E7F9: 3E 00       ld   a,$00
E7FB: FD 66 0D    ld   h,(iy+$07)
E7FE: FD 6E 02    ld   l,(iy+$08)
E801: DD 21 40 6D ld   ix,unknown_C740
E805: CD FF EB    call $EBFF
E808: CD D4 B5    call load_iy_with_player_structure_B574
E80B: FD 7E 0D    ld   a,(iy+$07)
E80E: C6 D0       add  a,$70
E810: 67          ld   h,a
E811: FD 7E 02    ld   a,(iy+$08)
E814: C6 10       add  a,$10
E816: 6F          ld   l,a
E817: E5          push hl
E818: 7C          ld   a,h
E819: D6 10       sub  $10
E81B: 7D          ld   a,l
E81C: C6 10       add  a,$10
E81E: 6F          ld   l,a
E81F: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
E822: E6 02       and  $08
E824: CA 87 E2    jp   z,$E82D
E827: 7C          ld   a,h
E828: C6 42       add  a,$48
E82A: ED 44       neg
E82C: 67          ld   h,a
E82D: CB 3C       srl  h
E82F: CB 3C       srl  h
E831: CB 3C       srl  h
E833: CB 3D       srl  l
E835: CB 3D       srl  l
E837: CB 3D       srl  l
E839: 3A 11 63    ld   a,(background_and_state_bits_C911)
E83C: CD E4 F3    call $F9E4
E83F: E1          pop  hl
E840: 06 0A       ld   b,$0A
E842: 3E 0C       ld   a,$06
E844: DD 21 C2 6D ld   ix,unknown_C768
E848: E5          push hl
E849: DD E5       push ix
E84B: F5          push af
E84C: C5          push bc
E84D: CD FF EB    call $EBFF
E850: C1          pop  bc
E851: F1          pop  af
E852: DD E1       pop  ix
E854: E1          pop  hl
E855: DD 23       inc  ix
E857: DD 23       inc  ix
E859: DD 23       inc  ix
E85B: DD 23       inc  ix
E85D: 24          inc  h
E85E: 24          inc  h
E85F: 24          inc  h
E860: 24          inc  h
E861: 10 E5       djnz $E848
E863: CD D4 B5    call load_iy_with_player_structure_B574
E866: FD 66 0D    ld   h,(iy+$07)
E869: FD 6E 02    ld   l,(iy+$08)
E86C: FD 21 0C EA ld   iy,table_EA06
E870: 3E 04       ld   a,$04
E872: DD 21 40 6D ld   ix,unknown_C740
E876: E5          push hl
E877: FD E5       push iy
E879: DD E5       push ix
E87B: F5          push af
E87C: CD FF EB    call $EBFF
E87F: 3E 01       ld   a,$01
E881: CD 5E BC    call suspend_this_task_B65E
E884: CD 3C BB    call read_current_player_controls_BB96
E887: A7          and  a
E888: C2 BE E2    jp   nz,$E8BE
E88B: F1          pop  af
E88C: 47          ld   b,a
E88D: DD E1       pop  ix
E88F: FD E1       pop  iy
E891: E1          pop  hl
E892: FD 23       inc  iy
E894: FD 23       inc  iy
E896: FD 23       inc  iy
E898: FD 7E 00    ld   a,(iy+$00)
E89B: FE F7       cp   $FD
E89D: C2 A4 E2    jp   nz,$E8A4
E8A0: FD 21 0C EA ld   iy,table_EA06
E8A4: FD 7E 01    ld   a,(iy+$01)
E8A7: 84          add  a,h
E8A8: 67          ld   h,a
E8A9: FD 7E 00    ld   a,(iy+$00)
E8AC: 85          add  a,l
E8AD: 6F          ld   l,a
E8AE: 06 04       ld   b,$04
E8B0: FD 7E 01    ld   a,(iy+$01)
E8B3: FE 08       cp   $02
E8B5: C2 BA E2    jp   nz,$E8BA
E8B8: 06 05       ld   b,$05
E8BA: 78          ld   a,b
E8BB: C3 DC E2    jp   $E876
E8BE: 3E 20       ld   a,$80
E8C0: CD B5 BB    call play_sound_BBB5
E8C3: 3E 01       ld   a,$01
E8C5: CD 5E BC    call suspend_this_task_B65E
E8C8: F1          pop  af
E8C9: DD E1       pop  ix
E8CB: FD E1       pop  iy
E8CD: E1          pop  hl
E8CE: FD E5       push iy
E8D0: E5          push hl
E8D1: CD D4 B5    call load_iy_with_player_structure_B574
E8D4: FD 7E 02    ld   a,(iy+$08)
E8D7: E1          pop  hl
E8D8: FD E1       pop  iy
E8DA: 6F          ld   l,a
E8DB: 3E 88       ld   a,$22
E8DD: CD B5 BB    call play_sound_BBB5
E8E0: FD E5       push iy
E8E2: E5          push hl
E8E3: 3E 00       ld   a,$00
E8E5: DD 21 40 6D ld   ix,unknown_C740
E8E9: CD FF EB    call $EBFF
E8EC: 3E 08       ld   a,$02
E8EE: CD 5E BC    call suspend_this_task_B65E
E8F1: E1          pop  hl
E8F2: 3E 02       ld   a,$08
E8F4: 84          add  a,h
E8F5: 67          ld   h,a
E8F6: DD 21 40 6D ld   ix,unknown_C740
E8FA: 3E 01       ld   a,$01
E8FC: E5          push hl
E8FD: CD FF EB    call $EBFF
E900: 3E 08       ld   a,$02
E902: CD 5E BC    call suspend_this_task_B65E
E905: E1          pop  hl
E906: 3E 02       ld   a,$08
E908: 84          add  a,h
E909: 67          ld   h,a
E90A: DD 21 40 6D ld   ix,unknown_C740
E90E: 3E 08       ld   a,$02
E910: E5          push hl
E911: CD FF EB    call $EBFF
E914: 3E 08       ld   a,$02
E916: CD 5E BC    call suspend_this_task_B65E
E919: E1          pop  hl
E91A: DD 21 40 6D ld   ix,unknown_C740
E91E: 3E 09       ld   a,$03
E920: CD FF EB    call $EBFF
E923: FD E1       pop  iy
E925: FD 46 08    ld   b,(iy+$02)
E928: 3E 1D       ld   a,$17
E92A: CD AE BC    call task_manipulation_B6AE
E92D: CD A5 B5    call task_yield_B5A5
table_E92E:
	dc.b	0xa5,0xb5 ; $e92e
E930: 3E 04       ld   a,$04
E932: CD 80 BC    call schedule_task_to_start_B620
E935: AF          xor  a
E936: CD 5E BC    call suspend_this_task_B65E
E939: 47          ld   b,a
E93A: C5          push bc
E93B: FD 21 C2 6D ld   iy,unknown_C768
E93F: A7          and  a
E940: CA C7 E3    jp   z,$E96D
E943: 3E 14       ld   a,$14
E945: CD B5 BB    call play_sound_BBB5
E948: C5          push bc
E949: FD 36 01 73 ld   (iy+$01),$D9
E94D: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
E950: CB 57       bit  2,a
E952: C2 53 E3    jp   nz,$E959
E955: FD CB 08 FE set  7,(iy+$02)
E959: FD E5       push iy
E95B: 3E 04       ld   a,$04
E95D: CD 5E BC    call suspend_this_task_B65E
E960: FD E1       pop  iy
E962: FD 23       inc  iy
E964: FD 23       inc  iy
E966: FD 23       inc  iy
E968: FD 23       inc  iy
E96A: C1          pop  bc
E96B: 10 7C       djnz $E943
E96D: 3E 1C       ld   a,$16
E96F: CD 67 B5    call resume_task_B5CD
E972: 21 D9 E9    ld   hl,table_E373
E975: CD 31 B9    call display_multicolor_text_B391
E978: C1          pop  bc
E979: 78          ld   a,b
E97A: FE 0A       cp   $0A
E97C: C2 38 E3    jp   nz,$E992
E97F: 21 8B EC    ld   hl,perfect_text_E62B
E982: CD 31 B9    call display_multicolor_text_B391
E985: 3E 0F       ld   a,$0F
E987: 06 80       ld   b,$20
E989: CD AE BC    call task_manipulation_B6AE
E98C: A7          and  a
E98D: C4 2C B1    call nz,display_error_text_B186
E990: 06 0B       ld   b,$0B
E992: C5          push bc
E993: 3E 08       ld   a,$02
E995: CD 2E B5    call load_struct_C100_from_A_index_B58E
E998: C1          pop  bc
E999: FD 36 03 62 ld   (iy+$09),$C8
E99D: FD 36 0A 60 ld   (iy+$0a),$C0
E9A1: 3E 04       ld   a,$04
E9A3: C5          push bc
E9A4: CD AE BC    call task_manipulation_B6AE
E9A7: C1          pop  bc
E9A8: 78          ld   a,b
E9A9: FE 0B       cp   $0B
E9AB: C2 B0 E3    jp   nz,$E9B0
table_E9C2:
	dc.b	0x18,0x80,0x28,0x9c,0x18,0x80,0x18,0x80 ; table_E9C2
	dc.b	0x28,0x9c,0x18,0x80,0x18,0x80,0x18,0x80 ; $e9ca
	dc.b	0x18,0x80,0x28,0x9c,0x28,0x9c,0x18,0x80 ; $e9d2
	dc.b	0x18,0x80,0x18,0x80,0x18,0x80,0x18,0x80 ; $e9da
table_E9E2:
	dc.w	table_eadf ; $e9e2
	dc.w	table_eaf3 ; $e9e4
	dc.w	table_eb07 ; $e9e6
	dc.w	table_eb1b ; $e9e8
	dc.w	table_eb38 ; $e9ea
	dc.w	table_eb4c ; $e9ec
	dc.w	table_eb60 ; $e9ee
	dc.w	table_eb65 ; $e9f0
	dc.w	table_eb6a ; $e9f2
	dc.w	table_eb6f ; $e9f4
	dc.w	table_eb83 ; $e9f6
	dc.w	table_eb97 ; $e9f8
	dc.w	table_ebab ; $e9fa
	dc.w	table_ebc8 ; $e9fc
	dc.w	table_ebdc ; $e9fe
	dc.w	table_ebf0 ; $ea00
	dc.w	table_ebf5 ; $ea02
	dc.w	table_ebfa ; $ea04
table_EA06:
	dc.b	0xff,0x02,0x00,0xff,0x02,0x00,0xff,0x02 ; $ea06
	dc.b	0x00,0xff,0x02,0x00,0x00,0x02,0x00,0xff ; $ea0e
	dc.b	0x02,0x00,0xff,0x02,0x00,0x00,0x02,0x00 ; $ea16
	dc.b	0x00,0x02,0x00,0xff,0x02,0x00,0x00,0x02 ; $ea1e
	dc.b	0x00,0x00,0x02,0x00,0x00,0x02,0x00,0x00 ; $ea26
	dc.b	0x02,0x00,0x00,0x02,0x00,0x00,0x02,0x00 ; $ea2e
	dc.b	0x00,0x02,0x00,0x00,0x02,0x00,0x00,0x02 ; $ea36
	dc.b	0x00,0x00,0x02,0x01,0x00,0x02,0x01,0x00 ; $ea3e
	dc.b	0x02,0x01,0x00,0x02,0x01,0x00,0x02,0x01 ; $ea46
	dc.b	0x00,0x02,0x01,0x00,0x02,0x01,0x01,0x02 ; $ea4e
	dc.b	0x01,0x00,0x02,0x02,0x01,0x02,0x03,0x00 ; $ea56
	dc.b	0x02,0x04,0x01,0x02,0x05,0x00,0x02,0x06 ; $ea5e
	dc.b	0x01,0x02,0x07,0x01,0x02,0x08,0x01,0x02 ; $ea66
	dc.b	0x09,0x01,0x02,0x0a,0xff,0xfe,0x05,0xff ; $ea6e
	dc.b	0xfe,0x04,0xff,0xfe,0x03,0xff,0xfe,0x02 ; $ea76
	dc.b	0x00,0xfe,0x01,0xff,0xfe,0x00,0x00,0xfe ; $ea7e
	dc.b	0x00,0xff,0xfe,0x00,0x00,0xfe,0x00,0xff ; $ea86
	dc.b	0xfe,0x00,0x00,0xfe,0x00,0x00,0xfe,0x00 ; $ea8e
	dc.b	0x00,0xfe,0x00,0x00,0xfe,0x00,0x00,0xfe ; $ea96
	dc.b	0x00,0x00,0xfe,0x00,0x00,0xfe,0x00,0x00 ; $ea9e
	dc.b	0xfe,0x00,0x00,0xfe,0x00,0x00,0xfe,0x00 ; $eaa6
	dc.b	0x00,0xfe,0x00,0x00,0xfe,0x00,0x00,0xfe ; $eaae
	dc.b	0x00,0x00,0xfe,0x00,0x00,0xfe,0x00,0x00 ; $eab6
	dc.b	0xfe,0x00,0x01,0xfe,0x00,0x00,0xfe,0x00 ; $eabe
	dc.b	0x00,0xfe,0x00,0x01,0xfe,0x00,0x01,0xfe ; $eac6
	dc.b	0x00,0x00,0xfe,0x00,0x01,0xfe,0x00,0x01 ; $eace
	dc.b	0xfe,0x00,0x01,0xfe,0x00,0x01,0xfe,0x00 ; $ead6
	dc.b	0xfd ; $eade
table_eadf:
	dc.b	0x02,0x03,0xe7,0x05,0x01,0xe8,0x05,0x01 ; $eadf
	dc.b	0xe9,0x05,0x01,0xea,0x05,0x01,0xeb,0x05 ; $eae7
	dc.b	0x01,0xec,0x05,0x01 ; $eaef
table_eaf3:
	dc.b	0x02,0x03,0xed,0x05,0x01,0xee,0x05,0x01 ; $eaf3
	dc.b	0xef,0x05,0x01,0xf0,0x05,0x01,0xf1,0x05 ; $eafb
	dc.b	0x01,0xf2,0x05,0x01 ; $eb03
table_eb07:
	dc.b	0x02,0x03,0xf3,0x05,0x01,0xf4,0x05,0x01 ; $eb07
	dc.b	0xf5,0x05,0x01,0xf6,0x05,0x01,0xf7,0x05 ; $eb0f
	dc.b	0x01,0xf8,0x05,0x01 ; $eb17
table_eb1b:
	dc.b	0x03,0x03,0xf9,0x05,0x01,0xfa,0x05,0x01 ; $eb1b
	dc.b	0x00,0x00,0x01,0xfb,0x05,0x01,0xfc,0x05 ; $eb23
	dc.b	0x01,0xff,0x05,0x01,0xfd,0x05,0x01,0xfe ; $eb2b
	dc.b	0x05,0x01,0x00,0x00,0x01 ; $eb33
table_eb38:
	dc.b	0x02,0x03,0xdb,0x05,0x01,0xdc,0x05,0x01 ; $eb38
	dc.b	0xdd,0x05,0x01,0xde,0x05,0x01,0xdf,0x05 ; $eb40
	dc.b	0x01,0xe0,0x05,0x01 ; $eb48
table_eb4c:
	dc.b	0x02,0x03,0xe1,0x05,0x01,0xe2,0x05,0x01 ; $eb4c
	dc.b	0xe3,0x05,0x01,0xe4,0x05,0x01,0xe5,0x05 ; $eb54
	dc.b	0x01,0xe6,0x05,0x01 ; $eb5c
table_eb60:
	dc.b	0x01,0x01,0xd8,0x05,0x0d ; $eb60
table_eb65:
	dc.b	0x01,0x01,0xd9,0x05,0x0d ; $eb65
table_eb6a:
	dc.b	0x01,0x01,0xda,0x05,0x0d ; $eb6a
table_eb6f:
	dc.b	0x02,0x03,0xe8,0x05,0x82,0xe7,0x05,0x82 ; $eb6f
	dc.b	0xea,0x05,0x82,0xe9,0x05,0x82,0xec,0x05 ; $eb77
	dc.b	0x82,0xeb,0x05,0x82 ; $eb7f
table_eb83:
	dc.b	0x02,0x03,0xee,0x05,0x82,0xed,0x05,0x82 ; $eb83
	dc.b	0xf0,0x05,0x82,0xef,0x05,0x82,0xf2,0x05 ; $eb8b
	dc.b	0x82,0xf1,0x05,0x82 ; $eb93
table_eb97:
	dc.b	0x02,0x03,0xf4,0x05,0x82,0xf3,0x05,0x82 ; $eb97
	dc.b	0xf6,0x05,0x82,0xf5,0x05,0x82,0xf8,0x05 ; $eb9f
	dc.b	0x82,0xf7,0x05,0x82 ; $eba7
table_ebab:
	dc.b	0x03,0x03,0x00,0x00,0x82,0xfa,0x05,0x82 ; $ebab
	dc.b	0xf9,0x05,0x82,0xff,0x05,0x82,0xfc,0x05 ; $ebb3
	dc.b	0x82,0xfb,0x05,0x82,0x00,0x00,0x82,0xfe ; $ebbb
	dc.b	0x05,0x82,0xfd,0x05,0x82 ; $ebc3
table_ebc8:
	dc.b	0x02,0x03,0xdc,0x05,0x82,0xdb,0x05,0x82 ; $ebc8
	dc.b	0xde,0x05,0x82,0xdd,0x05,0x82,0xe0,0x05 ; $ebd0
	dc.b	0x82,0xdf,0x05,0x82 ; $ebd8
table_ebdc:
	dc.b	0x02,0x03,0xe2,0x05,0x82,0xe1,0x05,0x82 ; $ebdc
	dc.b	0xe4,0x05,0x82,0xe3,0x05,0x82,0xe6,0x05 ; $ebe4
	dc.b	0x82,0xe5,0x05,0x82 ; $ebec
table_ebf0:
	dc.b	0x01,0x01,0xd8,0x05,0x0d ; $ebf0
table_ebf5:
	dc.b	0x01,0x01,0xd9,0x05,0x8d ; $ebf5
table_ebfa:
	dc.b	0x01,0x01,0xda,0x05,0x0d ; $ebfa
EBFF: FD 21 E8 E3 ld   iy,table_E9E2
EC03: 11 00 00    ld   de,$0000
EC06: 47          ld   b,a
EC07: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
EC0A: E6 02       and  $08
EC0C: CA 19 E6    jp   z,$EC13
EC0F: 78          ld   a,b
EC10: C6 03       add  a,$09
EC12: 47          ld   b,a
EC13: 78          ld   a,b
EC14: 5F          ld   e,a
EC15: CB 23       sla  e
EC17: CB 12       rl   d
EC19: FD 19       add  iy,de
EC1B: FD 5E 00    ld   e,(iy+$00)
EC1E: FD 56 01    ld   d,(iy+$01)
EC21: D5          push de
EC22: FD E1       pop  iy
EC24: 01 08 00    ld   bc,$0002
EC27: FD 09       add  iy,bc
EC29: FD 46 FF    ld   b,(iy-$01)
EC2C: FD 4E FE    ld   c,(iy-$02)
EC2F: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
EC32: E6 02       and  $08
EC34: CA 44 E6    jp   z,$EC44
EC37: 79          ld   a,c
EC38: CB 27       sla  a
EC3A: CB 27       sla  a
EC3C: CB 27       sla  a
EC3E: CB 27       sla  a
EC40: 84          add  a,h
EC41: ED 44       neg
EC43: 67          ld   h,a
EC44: C5          push bc
EC45: 41          ld   b,c
EC46: E5          push hl
EC47: 7C          ld   a,h
EC48: DD 77 00    ld   (ix+$00),a
EC4B: FD 7E 00    ld   a,(iy+$00)
EC4E: DD 77 01    ld   (ix+$01),a
EC51: FD 7E 08    ld   a,(iy+$02)
EC54: DD 77 08    ld   (ix+$02),a
EC57: 7D          ld   a,l
EC58: DD 77 09    ld   (ix+$03),a
EC5B: FD 7E 01    ld   a,(iy+$01)
EC5E: CB 27       sla  a
EC60: CB 27       sla  a
EC62: CB 27       sla  a
EC64: CB 27       sla  a
EC66: DD B6 08    or   (ix+$02)
EC69: DD 77 08    ld   (ix+$02),a
EC6C: 3E 10       ld   a,$10
EC6E: 84          add  a,h
EC6F: 67          ld   h,a
EC70: FD 23       inc  iy
EC72: FD 23       inc  iy
EC74: FD 23       inc  iy
EC76: DD 23       inc  ix
EC78: DD 23       inc  ix
EC7A: DD 23       inc  ix
EC7C: DD 23       inc  ix
EC7E: 10 6D       djnz $EC47
EC80: E1          pop  hl
EC81: 3E 10       ld   a,$10
EC83: 85          add  a,l
EC84: 6F          ld   l,a
EC85: C1          pop  bc
EC86: 10 B6       djnz $EC44
EC88: C9          ret
EC89: 06 12       ld   b,$18
EC8B: DD 21 C0 6D ld   ix,unknown_C760
EC8F: 3A 82 60    ld   a,(player_2_attack_flags_C028)
EC92: FE 1D       cp   $17
EC94: C2 37 E6    jp   nz,$EC9D
EC97: 06 90       ld   b,$30
EC99: DD 21 30 6D ld   ix,unknown_C790
EC9D: DD E5       push ix
EC9F: 78          ld   a,b
ECA0: CD 5E BC    call suspend_this_task_B65E
ECA3: DD E1       pop  ix
ECA5: C3 71 E6    jp   $ECD1
ECA8: 3E 01       ld   a,$01
ECAA: CD B5 BB    call play_sound_BBB5
ECAD: 01 96 D0    ld   bc,$703C
ECB0: CD 1C B9    call fill_video_and_attribute_memory_B316
ECB3: CD AE F1    call display_hiscores_F1AE
ECB6: 21 DC FE    ld   hl,copyright_data_east_text_FE76
ECB9: 16 30       ld   d,$90
ECBB: CD 5D B9    call display_text_B357
ECBE: 06 0B       ld   b,$0B
ECC0: 21 00 00    ld   hl,$0000
ECC3: E5          push hl
ECC4: C5          push bc
ECC5: CD 28 E7    call $ED82
ECC8: C1          pop  bc
ECC9: E1          pop  hl
ECCA: 2C          inc  l
ECCB: 10 FC       djnz $ECC3
ECCD: DD 21 90 6D ld   ix,unknown_C730
ECD1: 21 90 F5    ld   hl,$F530		; entrypoint
ECD4: 3A 82 60    ld   a,(player_2_attack_flags_C028)
ECD7: FE 1D       cp   $17
ECD9: C2 7F E6    jp   nz,$ECDF
ECDC: 21 84 F4    ld   hl,$F424
ECDF: FD 21 A7 E7 ld   iy,name_registration_time_str_EDAD
ECE3: 06 FF       ld   b,$FF
ECE5: DD E5       push ix
ECE7: E5          push hl
ECE8: FD E5       push iy
ECEA: C5          push bc
ECEB: DD E5       push ix
ECED: 3A 82 60    ld   a,(player_2_attack_flags_C028)
ECF0: FE 1D       cp   $17
ECF2: C2 0C E7    jp   nz,$ED06
ECF5: 3A 8B 60    ld   a,(periodic_counter_8bit_C02B)
ECF8: E6 0F       and  $0F
ECFA: CB 3F       srl  a
ECFC: CB 3F       srl  a
ECFE: CB 3F       srl  a
ED00: C6 10       add  a,$10
ED02: 57          ld   d,a
ED03: C3 02 E7    jp   $ED08
ED06: 16 08       ld   d,$02
ED08: 7A          ld   a,d
ED09: CD 57 FD    call $F75D
ED0C: 3E 01       ld   a,$01
ED0E: CD 5E BC    call suspend_this_task_B65E
ED11: 06 06       ld   b,$0C
ED13: DD E1       pop  ix
ED15: 11 04 00    ld   de,$0004
ED18: DD 36 00 00 ld   (ix+$00),$00
ED1C: DD 19       add  ix,de
ED1E: 10 F2       djnz $ED18
ED20: C1          pop  bc
ED21: FD E1       pop  iy
ED23: E1          pop  hl
ED24: DD E1       pop  ix
ED26: FD 23       inc  iy
ED28: FD 7E 00    ld   a,(iy+$00)
ED2B: FE 20       cp   $80
ED2D: C2 A9 E7    jp   nz,$EDA3
ED30: FD 23       inc  iy
ED32: FD 5E 00    ld   e,(iy+$00)
ED35: FD 56 01    ld   d,(iy+$01)
ED38: D5          push de
ED39: FD E1       pop  iy
ED3B: 05          dec  b
ED3C: C2 A9 E7    jp   nz,$EDA3
ED3F: 3A 82 60    ld   a,(player_2_attack_flags_C028)
ED42: FE 1D       cp   $17
ED44: C2 DF E7    jp   nz,$ED7F
ED47: DD 21 90 6D ld   ix,unknown_C730
ED4B: 06 84       ld   b,$24
ED4D: 11 04 00    ld   de,$0004
ED50: DD 36 00 00 ld   (ix+$00),$00
ED54: DD 19       add  ix,de
ED56: 10 F2       djnz $ED50
ED58: 06 09       ld   b,$03
ED5A: C5          push bc
ED5B: 21 05 0A    ld   hl,$0A05		; immediate
ED5E: 3E 04       ld   a,$04
ED60: CD E4 F3    call $F9E4
ED63: 3E 40       ld   a,$40
ED65: CD 5E BC    call suspend_this_task_B65E
ED68: 21 05 0A    ld   hl,$0A05		; immediate
ED6B: 3E 05       ld   a,$05
ED6D: CD E4 F3    call $F9E4
ED70: 3E 40       ld   a,$40
ED72: CD 5E BC    call suspend_this_task_B65E
ED75: C1          pop  bc
ED76: 10 E8       djnz $ED5A
ED78: 3E 01       ld   a,$01
ED7A: 06 01       ld   b,$01
ED7C: CD AE BC    call task_manipulation_B6AE
ED7F: CD A5 B5    call task_yield_B5A5

ED82: CD FC B8    call compute_screen_address_from_XY_B2F6
ED85: E5          push hl
ED86: FD E1       pop  iy
ED88: 11 00 04    ld   de,$0400
ED8B: 19          add  hl,de
ED8C: E5          push hl
ED8D: DD E1       pop  ix
ED8F: 11 E0 FF    ld   de,$FFE0		; offset
ED92: 06 80       ld   b,$20
ED94: FD 36 00 96 ld   (iy+$00),$3C
ED98: DD 36 00 22 ld   (ix+$00),$88
ED9C: DD 19       add  ix,de
ED9E: FD 19       add  iy,de
EDA0: 10 F8       djnz $ED94
EDA2: C9          ret
EDA3: 25          dec  h
EDA4: 25          dec  h
EDA5: FD 7E 00    ld   a,(iy+$00)
EDA8: 85          add  a,l
EDA9: 6F          ld   l,a
EDAA: C3 E5 E6    jp   $ECE5
name_registration_time_str_EDAD:
	dc.b	0x69,0xe5,0xec,0xf9,0xfc,0xfe,0xfe,0xfe ; $edaa
	dc.b	0xff,0xff,0xff,0xff,0xff,0x00,0xff,0x00 ; $edb2
	dc.b	0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00 ; $edba
	dc.b	0x01,0x00,0x01,0x01,0x01,0x01,0x02,0x02 ; $edc2
	dc.b	0x02,0x03,0x05,0x03,0x80,0xad,0xed ; $edca
table_EDD1:
	dc.b	0x04,0x01,0x17,0x70,0x0a,0x70,0x16,0x70 ; table_EDD1
	dc.b	0x0e,0x70,0x3c,0x70,0x1b,0x70,0x0e,0x70 ; $edd9
	dc.b	0x10,0x70,0x12,0x70,0x1c,0x70,0x1d,0x70 ; $ede1
	dc.b	0x1b,0x70,0x0a,0x70,0x1d,0x70,0x12,0x70 ; $ede9
	dc.b	0x18,0x70,0x17,0x70,0xfe,0x17,0x02,0x1d ; $edf1
	dc.b	0x88,0x12,0x88,0x16,0x88,0x0e,0x88,0xfe ; $edf9
	dc.b	0x05,0x03,0xdb,0xb2,0xdc,0xb2,0xdc,0xb2 ; $ee01
	dc.b	0xdc,0xb2,0xdc,0xb2,0xdd,0xb2,0x3c,0x70 ; $ee09
	dc.b	0x3c,0x70,0xdb,0xb2,0xdc,0xb2,0xdc,0xb2 ; $ee11
	dc.b	0xdc,0xb2,0xdc,0xb2,0xdd,0xb2,0x3c,0x70 ; $ee19
	dc.b	0x3c,0x70,0x3c,0x70,0x3c,0x70,0x3c,0x88 ; $ee21
	dc.b	0x3c,0x98,0x3c,0x98,0x3c,0x88,0xfe,0x05 ; $ee29
	dc.b	0x04,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0,0x3c ; $ee31
	dc.b	0xb0,0x3c,0xb0,0xde,0xb2,0x3c,0x70,0x3c ; $ee39
	dc.b	0x70,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0,0x3c ; $ee41
	dc.b	0xb0,0x3c,0xb0,0xde,0xb2,0x3c,0x70,0x3c ; $ee49
	dc.b	0x70,0x3c,0x70,0x3c,0x70,0x24,0x88,0x24 ; $ee51
	dc.b	0x88,0x24,0x88,0x24,0x88,0xfe,0x05,0x06 ; $ee59
	dc.b	0xdb,0xb2,0xdd,0xb2,0xdb,0xb2,0xdd,0xb2 ; $ee61
	dc.b	0xdb,0xb2,0xdd,0xb2,0xdb,0xb2,0xdd,0xb2 ; $ee69
	dc.b	0xdb,0xb2,0xdd,0xb2,0xdb,0xb2,0xdd,0xb2 ; $ee71
	dc.b	0xdb,0xb2,0xdd,0xb2,0xdb,0xb2,0xdd,0xb2 ; $ee79
	dc.b	0xdb,0xb2,0xdd,0xb2,0xdb,0xb2,0xdd,0xb2 ; $ee81
	dc.b	0xdb,0xb2,0xdd,0xb2,0xfe,0x05,0x07,0x0a ; $ee89
	dc.b	0xb0,0xde,0xb2,0x0b,0xb0,0xde,0xb2,0x0c ; $ee91
	dc.b	0xb0,0xde,0xb2,0x0d,0xb0,0xde,0xb2,0x0e ; $ee99
	dc.b	0xb0,0xde,0xb2,0x0f,0xb0,0xde,0xb2,0x10 ; $eea1
	dc.b	0xb0,0xde,0xb2,0x11,0xb0,0xde,0xb2,0x12 ; $eea9
	dc.b	0xb0,0xde,0xb2,0x13,0xb0,0xde,0xb2,0x14 ; $eeb1
	dc.b	0xb0,0xde,0xb2,0xfe,0x05,0x08,0xdb,0xb2 ; $eeb9
	dc.b	0xdd,0xb2,0xdb,0xb2,0xdd,0xb2,0xdb,0xb2 ; $eec1
	dc.b	0xdd,0xb2,0xdb,0xb2,0xdd,0xb2,0xdb,0xb2 ; $eec9
	dc.b	0xdd,0xb2,0xdb,0xb2,0xdd,0xb2,0xdb,0xb2 ; $eed1
	dc.b	0xdd,0xb2,0xdb,0xb2,0xdd,0xb2,0xdb,0xb2 ; $eed9
	dc.b	0xdd,0xb2,0xdb,0xb2,0xdd,0xb2,0xdb,0xb2 ; $eee1
	dc.b	0xdd,0xb2,0xfe,0x05,0x09,0x15,0xb0,0xde ; $eee9
	dc.b	0xb2,0x16,0xb0,0xde,0xb2,0x17,0xb0,0xde ; $eef1
	dc.b	0xb2,0x18,0xb0,0xde,0xb2,0x19,0xb0,0xde ; $eef9
	dc.b	0xb2,0x1a,0xb0,0xde,0xb2,0x1b,0xb0,0xde ; $ef01
	dc.b	0xb2,0x1c,0xb0,0xde,0xb2,0x1d,0xb0,0xde ; $ef09
	dc.b	0xb2,0x1e,0xb0,0xde,0xb2,0x1f,0xb0,0xde ; $ef11
	dc.b	0xb2,0xfe,0x05,0x0a,0xdb,0xb2,0xdd,0xb2 ; $ef19
	dc.b	0xdb,0xb2,0xdd,0xb2,0xdb,0xb2,0xdd,0xb2 ; $ef21
	dc.b	0xdb,0xb2,0xdd,0xb2,0xdb,0xb2,0xdd,0xb2 ; $ef29
	dc.b	0xdb,0xb2,0xdd,0xb2,0xdb,0xb2,0xdd,0xb2 ; $ef31
	dc.b	0xdb,0xb2,0xdd,0xb2,0xdb,0xb2,0xdd,0xb2 ; $ef39
	dc.b	0xdb,0xb2,0xdc,0xb2,0xdc,0xb2,0xdc,0xb2 ; $ef41
	dc.b	0xdd,0xb2,0xfe,0x05,0x0b,0x20,0xb0,0xde ; $ef49
	dc.b	0xb2,0x21,0xb0,0xde,0xb2,0x22,0xb0,0xde ; $ef51
	dc.b	0xb2,0x23,0xb0,0xde,0xb2,0x25,0xb0,0xde ; $ef59
	dc.b	0xb2,0x26,0xb0,0xde,0xb2,0x27,0xb0,0xde ; $ef61
	dc.b	0xb2,0x2d,0xb0,0xde,0xb2,0x2f,0xb0,0xde ; $ef69
	dc.b	0xb2,0x29,0xb0,0x2a,0xb0,0x2b,0xb0,0x2c ; $ef71
	dc.b	0xb0,0xde,0xb2,0xff ; $ef79
point_rank_name_text_EF7D:
	dc.b	0x08,0x0d,0x19,0x98,0x18,0x98,0x12,0x98 ; point_rank_name_text_EF7D
	dc.b	0x17,0x98,0x1d,0x98,0x3c,0x70,0x3c,0x70 ; $ef85
	dc.b	0x3c,0x70,0x1b,0x98,0x0a,0x98,0x17,0x98 ; $ef8d
	dc.b	0x14,0x98,0x3c,0x70,0x3c,0x70,0x3c,0x70 ; $ef95
	dc.b	0x17,0x98,0x0a,0x98,0x16,0x98,0x0e,0x98 ; $ef9d
	dc.b	0xfe,0x0f,0x0e,0xdb,0xb2,0xdc,0xb2,0xdc ; $efa5
	dc.b	0xb2,0xdc,0xb2,0xdc,0xb2,0xdd,0xb2,0x3c ; $efad
	dc.b	0x70,0xdb,0xb2,0xdc,0xb2,0xdc,0xb2,0xdc ; $efb5
	dc.b	0xb2,0xdc,0xb2,0xdd,0xb2,0xfe,0x04,0x0f ; $efbd
	dc.b	0x01,0x98,0x25,0x98,0xfe,0x0f,0x0f,0x3c ; $efc5
	dc.b	0xb0,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0,0x3c ; $efcd
	dc.b	0xb0,0xde,0xb2,0x3c,0x70,0x3c,0xb0,0x3c ; $efd5
	dc.b	0xb0,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0,0xde ; $efdd
	dc.b	0xb2,0xfe,0x0f,0x10,0xdb,0xb2,0xdc,0xb2 ; $efe5
	dc.b	0xdc,0xb2,0xdc,0xb2,0xdc,0xb2,0xdd,0xb2 ; $efed
	dc.b	0x3c,0x70,0xdb,0xb2,0xdc,0xb2,0xdc,0xb2 ; $eff5
	dc.b	0xdc,0xb2,0xdc,0xb2,0xdd,0xb2,0xfe,0x04 ; $effd
	dc.b	0x11,0x02,0x98,0x25,0x98,0xfe,0x0f,0x11 ; $f005
	dc.b	0x3c,0xb0,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0 ; $f00d
	dc.b	0x3c,0xb0,0xde,0xb2,0x3c,0x70,0x3c,0xb0 ; $f015
	dc.b	0x3c,0xb0,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0 ; $f01d
	dc.b	0xde,0xb2,0xfe,0x0f,0x12,0xdb,0xb2,0xdc ; $f025
	dc.b	0xb2,0xdc,0xb2,0xdc,0xb2,0xdc,0xb2,0xdd ; $f02d
	dc.b	0xb2,0x3c,0x70,0xdb,0xb2,0xdc,0xb2,0xdc ; $f035
	dc.b	0xb2,0xdc,0xb2,0xdc,0xb2,0xdd,0xb2,0xfe ; $f03d
	dc.b	0x04,0x13,0x03,0x98,0x25,0x98,0xfe,0x0f ; $f045
	dc.b	0x13,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0,0x3c ; $f04d
	dc.b	0xb0,0x3c,0xb0,0xde,0xb2,0x3c,0x70,0x3c ; $f055
	dc.b	0xb0,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0,0x3c ; $f05d
	dc.b	0xb0,0xde,0xb2,0xfe,0x0f,0x14,0xdb,0xb2 ; $f065
	dc.b	0xdc,0xb2,0xdc,0xb2,0xdc,0xb2,0xdc,0xb2 ; $f06d
	dc.b	0xdd,0xb2,0x3c,0x70,0xdb,0xb2,0xdc,0xb2 ; $f075
	dc.b	0xdc,0xb2,0xdc,0xb2,0xdc,0xb2,0xdd,0xb2 ; $f07d
	dc.b	0xfe,0x04,0x15,0x04,0x98,0x25,0x98,0xfe ; $f085
	dc.b	0x0f,0x15,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0 ; $f08d
	dc.b	0x3c,0xb0,0x3c,0xb0,0xde,0xb2,0x3c,0x70 ; $f095
	dc.b	0x3c,0xb0,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0 ; $f09d
	dc.b	0x3c,0xb0,0xde,0xb2,0xfe,0x0f,0x16,0xdb ; $f0a5
	dc.b	0xb2,0xdc,0xb2,0xdc,0xb2,0xdc,0xb2,0xdc ; $f0ad
	dc.b	0xb2,0xdd,0xb2,0x3c,0x70,0xdb,0xb2,0xdc ; $f0b5
	dc.b	0xb2,0xdc,0xb2,0xdc,0xb2,0xdc,0xb2,0xdd ; $f0bd
	dc.b	0xb2,0xfe,0x04,0x17,0x05,0x98,0x25,0x98 ; $f0c5
	dc.b	0xfe,0x0f,0x17,0x3c,0xb0,0x3c,0xb0,0x3c ; $f0cd
	dc.b	0xb0,0x3c,0xb0,0x3c,0xb0,0xde,0xb2,0x3c ; $f0d5
	dc.b	0x70,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0,0x3c ; $f0dd
	dc.b	0xb0,0x3c,0xb0,0xde,0xb2,0xfe,0x0f,0x18 ; $f0e5
	dc.b	0xdb,0xb2,0xdc,0xb2,0xdc,0xb2,0xdc,0xb2 ; $f0ed
	dc.b	0xdc,0xb2,0xdd,0xb2,0x3c,0x70,0xdb,0xb2 ; $f0f5
	dc.b	0xdc,0xb2,0xdc,0xb2,0xdc,0xb2,0xdc,0xb2 ; $f0fd
	dc.b	0xdd,0xb2,0xfe,0x04,0x19,0x06,0x98,0x25 ; $f105
	dc.b	0x98,0xfe,0x0f,0x19,0x3c,0xb0,0x3c,0xb0 ; $f10d
	dc.b	0x3c,0xb0,0x3c,0xb0,0x3c,0xb0,0xde,0xb2 ; $f115
	dc.b	0x3c,0x70,0x3c,0xb0,0x3c,0xb0,0x3c,0xb0 ; $f11d
	dc.b	0x3c,0xb0,0x3c,0xb0,0xde,0xb2,0xfe,0x13 ; $f125
	dc.b	0x1f,0x3c,0x98,0xff ; $f12d
table_F131:
	dc.b	0x0a,0xb0,0x0b,0xb0,0x0c,0xb0,0x0d,0xb0 ; table_F131
	dc.b	0x0e,0xb0,0x0f,0xb0,0x10,0xb0,0x11,0xb0 ; $f139
	dc.b	0x12,0xb0,0x13,0xb0,0x14,0xb0,0x15,0xb0 ; $f141
	dc.b	0x16,0xb0,0x17,0xb0,0x18,0xb0,0x19,0xb0 ; $f149
	dc.b	0x1a,0xb0,0x1b,0xb0,0x1c,0xb0,0x1d,0xb0 ; $f151
	dc.b	0x1e,0xb0,0x1f,0xb0,0x20,0xb0,0x21,0xb0 ; $f159
	dc.b	0x22,0xb0,0x23,0xb0,0x25,0xb0,0x26,0xb0 ; $f161
	dc.b	0x27,0xb0,0x2d,0xb0,0x2f,0xb0,0x29,0xb0 ; $f169
	dc.b	0x2f,0xb0,0xaf ; $f171
F173: AF          xor	a
F174: CD 5E BC    call suspend_this_task_B65E
F177: CB 27       sla  a
F179: C6 0F       add  a,$0F
F17B: 6F          ld   l,a
F17C: 26 04       ld   h,$04
F17E: CD FC B8    call compute_screen_address_from_XY_B2F6
F181: 01 00 04    ld   bc,$0400
F184: 09          add  hl,bc
F185: E5          push hl
F186: 06 0A       ld   b,$0A
F188: 11 80 00    ld   de,task_address_table_0020
F18B: 36 30       ld   (hl),$90
F18D: A7          and  a
F18E: ED 52       sbc  hl,de
F190: 10 F3       djnz $F18B
F192: 3E 80       ld   a,$20
F194: CD 5E BC    call suspend_this_task_B65E
F197: E1          pop  hl
F198: E5          push hl
F199: 06 0A       ld   b,$0A
F19B: 11 80 00    ld   de,task_address_table_0020
F19E: 36 00       ld   (hl),$00
F1A0: A7          and  a
F1A1: ED 52       sbc  hl,de
F1A3: 10 F3       djnz $F19E
F1A5: 3E 80       ld   a,$20
F1A7: CD 5E BC    call suspend_this_task_B65E
F1AA: E1          pop  hl
F1AB: C3 25 F1    jp   $F185

display_hiscores_F1AE:
F1AE: 21 D7 EF    ld   hl,point_rank_name_text_EF7D
F1B1: CD 31 B9    call display_multicolor_text_B391
F1B4: 06 0C       ld   b,$06
F1B6: FD 21 40 60 ld   iy,unknown_C040
F1BA: DD 21 02 6F ld   ix,unknown_CF08
F1BE: DD 36 00 0D ld   (ix+$00),$07
F1C2: DD 36 01 0F ld   (ix+$01),$0F
F1C6: DD 36 0E FF ld   (ix+$0e),$FF
F1CA: C5          push bc
F1CB: 06 09       ld   b,$03
F1CD: FD 7E 00    ld   a,(iy+$00)
F1D0: CB 3F       srl  a
F1D2: CB 3F       srl  a
F1D4: CB 3F       srl  a
F1D6: CB 3F       srl  a
F1D8: DD 77 08    ld   (ix+$02),a
F1DB: DD 36 09 32 ld   (ix+$03),$98
F1DF: FD 7E 00    ld   a,(iy+$00)
F1E2: E6 0F       and  $0F
F1E4: DD 77 04    ld   (ix+$04),a
F1E7: DD 36 05 32 ld   (ix+$05),$98
F1EB: FD 23       inc  iy
F1ED: DD 23       inc  ix
F1EF: DD 23       inc  ix
F1F1: DD 23       inc  ix
F1F3: DD 23       inc  ix
F1F5: 10 7C       djnz $F1CD
F1F7: FD E5       push iy
F1F9: DD 21 0A 6F ld   ix,unknown_CF0A
F1FD: 06 05       ld   b,$05
F1FF: DD 7E 00    ld   a,(ix+$00)
F202: A7          and  a
F203: C2 10 F8    jp   nz,$F210
F206: DD 36 00 96 ld   (ix+$00),$3C
F20A: DD 23       inc  ix
F20C: DD 23       inc  ix
F20E: 10 EF       djnz $F1FF
F210: 21 02 6F    ld   hl,unknown_CF08
F213: CD 31 B9    call display_multicolor_text_B391
F216: FD E1       pop  iy
F218: DD 21 02 6F ld   ix,unknown_CF08
F21C: DD 34 01    inc  (ix+$01)
F21F: DD 34 01    inc  (ix+$01)
F222: 11 0F 00    ld   de,$000F
F225: FD 19       add  iy,de
F227: C1          pop  bc
F228: 10 A0       djnz $F1CA
F22A: 06 0C       ld   b,$06
F22C: FD 21 40 60 ld   iy,unknown_C040
F230: DD 21 02 6F ld   ix,unknown_CF08
F234: DD 36 00 0F ld   (ix+$00),$0F
F238: DD 36 01 0F ld   (ix+$01),$0F
F23C: DD 36 08 96 ld   (ix+$02),$3C
F240: DD 36 04 07 ld   (ix+$04),$0D
F244: DD 36 05 0A ld   (ix+$05),$0A
F248: DD 36 0C 1D ld   (ix+$06),$17
F24C: DD 36 0D FF ld   (ix+$07),$FF
F250: FD 7E 11    ld   a,(iy+$11)
F253: 3C          inc  a
F254: DD 77 09    ld   (ix+$03),a
F257: FE 0A       cp   $0A
F259: DA DB F8    jp   c,$F27B
F25C: DD 36 08 01 ld   (ix+$02),$01
F260: DD 36 09 00 ld   (ix+$03),$00
F264: CA DB F8    jp   z,$F27B
F267: DD 36 08 06 ld   (ix+$02),$0C
F26B: DD 36 09 11 ld   (ix+$03),$11
F26F: DD 36 04 0A ld   (ix+$04),$0A
F273: DD 36 05 1C ld   (ix+$05),$16
F277: DD 36 0C 13 ld   (ix+$06),$19
F27B: 21 02 6F    ld   hl,unknown_CF08
F27E: 16 B0       ld   d,$B0
F280: C5          push bc
F281: CD 5D B9    call display_text_B357
F284: 11 18 00    ld   de,$0012
F287: FD 19       add  iy,de
F289: DD 21 02 6F ld   ix,unknown_CF08
F28D: DD 34 01    inc  (ix+$01)
F290: DD 34 01    inc  (ix+$01)
F293: C1          pop  bc
F294: 10 AC       djnz $F23C
F296: 06 0C       ld   b,$06
F298: FD 21 40 60 ld   iy,unknown_C040
F29C: DD 21 02 6F ld   ix,unknown_CF08
F2A0: DD 36 00 1D ld   (ix+$00),$17
F2A4: DD 36 01 0F ld   (ix+$01),$0F
F2A8: DD 36 02 FF ld   (ix+$08),$FF
F2AC: 06 0C       ld   b,$06
F2AE: C5          push bc
F2AF: FD 7E 0C    ld   a,(iy+$06)
F2B2: DD 77 08    ld   (ix+$02),a
F2B5: FD 7E 0D    ld   a,(iy+$07)
F2B8: DD 77 09    ld   (ix+$03),a
F2BB: FD 7E 02    ld   a,(iy+$08)
F2BE: DD 77 04    ld   (ix+$04),a
F2C1: FD 7E 03    ld   a,(iy+$09)
F2C4: DD 77 05    ld   (ix+$05),a
F2C7: FD 7E 0A    ld   a,(iy+$0a)
F2CA: DD 77 0C    ld   (ix+$06),a
F2CD: FD 7E 0B    ld   a,(iy+$0b)
F2D0: DD 77 0D    ld   (ix+$07),a
F2D3: FD E5       push iy
F2D5: 21 02 6F    ld   hl,unknown_CF08
F2D8: CD 31 B9    call display_multicolor_text_B391
F2DB: FD E1       pop  iy
F2DD: C1          pop  bc
F2DE: DD 21 02 6F ld   ix,unknown_CF08
F2E2: DD 34 01    inc  (ix+$01)
F2E5: DD 34 01    inc  (ix+$01)
F2E8: 11 18 00    ld   de,$0012
F2EB: FD 19       add  iy,de
F2ED: 10 BF       djnz $F2AE
F2EF: C9          ret
F2F0: 06 0C       ld   b,$06
F2F2: DD 21 40 60 ld   ix,unknown_C040
F2F6: 11 18 00    ld   de,$0012
F2F9: FD 21 62 60 ld   iy,unknown_C0C8
F2FD: 3A 87 60    ld   a,(players_type_human_or_cpu_flags_C02D)
F300: CB 57       bit  2,a
F302: C2 03 F9    jp   nz,$F309
F305: FD 21 70 60 ld   iy,unknown_C0D0
F309: FD 7E 08    ld   a,(iy+$02)
F30C: DD 96 08    sub  (ix+$02)
F30F: FD 7E 01    ld   a,(iy+$01)
F312: DD 9E 01    sbc  a,(ix+$01)
F315: FD 7E 00    ld   a,(iy+$00)
F318: DD 9E 00    sbc  a,(ix+$00)
F31B: D2 87 F9    jp   nc,$F32D
F31E: DD 19       add  ix,de
F320: 10 ED       djnz $F309
F322: E1          pop  hl
F323: 3E 01       ld   a,$01
F325: 06 01       ld   b,$01
F327: CD AE BC    call task_manipulation_B6AE
F32A: CD A5 B5    call task_yield_B5A5
F32D: 3E 0C       ld   a,$06
F32F: 90          sub  b
F330: C5          push bc
F331: FD E5       push iy
F333: DD E5       push ix
F335: 47          ld   b,a
F336: 3E 1C       ld   a,$16
F338: CD AE BC    call task_manipulation_B6AE
F33B: DD E1       pop  ix
F33D: FD E1       pop  iy
F33F: C1          pop  bc
F340: 05          dec  b
F341: CA 55 F9    jp   z,$F355
F344: 3E 00       ld   a,$00
F346: C6 18       add  a,$12
F348: 10 F6       djnz $F346
F34A: 06 00       ld   b,$00
F34C: 4F          ld   c,a
F34D: 21 33 60    ld   hl,unknown_C099
F350: 11 AB 60    ld   de,unknown_C0AB
F353: ED B8       lddr
F355: FD 7E 00    ld   a,(iy+$00)
F358: DD 77 00    ld   (ix+$00),a
F35B: FD 7E 01    ld   a,(iy+$01)
F35E: DD 77 01    ld   (ix+$01),a
F361: FD 7E 08    ld   a,(iy+$02)
F364: DD 77 08    ld   (ix+$02),a
F367: 3A 10 63    ld   a,(computer_skill_C910)
F36A: DD 77 11    ld   (ix+$11),a
F36D: DD 22 0C 6F ld   (unknown_CF06),ix
F371: 01 0C 00    ld   bc,$0006
F374: DD 09       add  ix,bc
F376: DD 36 00 96 ld   (ix+$00),$3C
F37A: DD 36 01 B0 ld   (ix+$01),$B0
F37E: DD 36 08 96 ld   (ix+$02),$3C
F382: DD 36 09 B0 ld   (ix+$03),$B0
F386: DD 36 04 96 ld   (ix+$04),$3C
F38A: DD 36 05 B0 ld   (ix+$05),$B0
F38E: DD 36 0C 96 ld   (ix+$06),$3C
F392: DD 36 0D B0 ld   (ix+$07),$B0
F396: DD 36 02 96 ld   (ix+$08),$3C
F39A: DD 36 03 B0 ld   (ix+$09),$B0
F39E: C9          ret

F39F: F5          push af
F3A0: 3A 01 6F    ld   a,(unknown_CF01)
F3A3: D6 0D       sub  $07
F3A5: 57          ld   d,a
F3A6: 1E 0B       ld   e,$0B
F3A8: CD 69 B0    call multiply_de_B0C3
F3AB: DD 21 91 F1 ld   ix,table_F131
F3AF: DD 19       add  ix,de
F3B1: 3A 00 6F    ld   a,(temp_numeric_buffer_CF00)
F3B4: D6 05       sub  $05
F3B6: 06 00       ld   b,$00
F3B8: 4F          ld   c,a
F3B9: DD 09       add  ix,bc
F3BB: F1          pop  af
F3BC: 0E B0       ld   c,$B0
F3BE: A7          and  a
F3BF: CA 64 F9    jp   z,$F3C4
F3C2: 0E A2       ld   c,$A8
F3C4: 79          ld   a,c
F3C5: F5          push af
F3C6: 3A 00 6F    ld   a,(temp_numeric_buffer_CF00)
F3C9: 67          ld   h,a
F3CA: 3A 01 6F    ld   a,(unknown_CF01)
F3CD: 6F          ld   l,a
F3CE: CD FC B8    call compute_screen_address_from_XY_B2F6
F3D1: 11 00 04    ld   de,$0400
F3D4: 19          add  hl,de
F3D5: F1          pop  af
F3D6: 77          ld   (hl),a
F3D7: 47          ld   b,a
F3D8: 3A 00 6F    ld   a,(temp_numeric_buffer_CF00)
F3DB: FE 1D       cp   $17
F3DD: CA EC F9    jp   z,$F3E6
F3E0: FE 13       cp   $19
F3E2: CA EC F9    jp   z,$F3E6
F3E5: C9          ret
F3E6: 3A 01 6F    ld   a,(unknown_CF01)
F3E9: FE 0B       cp   $0B
F3EB: C0          ret  nz
F3EC: 11 E0 FF    ld   de,$FFE0		; immediate -32
F3EF: 19          add  hl,de
F3F0: 70          ld   (hl),b
F3F1: C9          ret
F3F2: C9          ret
F3F3: 3E 01       ld   a,$01
F3F5: CD 5E BC    call suspend_this_task_B65E
F3F8: 3A 09 6F    ld   a,(unknown_CF03)
F3FB: D6 01       sub  $01
F3FD: 27          daa
F3FE: 32 09 6F    ld   (unknown_CF03),a
F401: 3A 08 6F    ld   a,(unknown_CF02)
F404: DE 00       sbc  a,$00
F406: 27          daa
F407: 32 08 6F    ld   (unknown_CF02),a
F40A: 26 12       ld   h,$18
F40C: 2E 09       ld   l,$03
F40E: CD FC B8    call compute_screen_address_from_XY_B2F6
F411: E5          push hl
F412: DD E1       pop  ix
F414: 01 00 04    ld   bc,$0400
F417: 3A 08 6F    ld   a,(unknown_CF02)
F41A: CB 3F       srl  a
F41C: CB 3F       srl  a
F41E: CB 3F       srl  a
F420: CB 3F       srl  a
F422: DD 77 00    ld   (ix+$00),a
F425: 3A 08 6F    ld   a,(unknown_CF02)
F428: E6 0F       and  $0F
F42A: DD 77 E0    ld   (ix-$20),a
F42D: DD 09       add  ix,bc
F42F: DD 36 00 32 ld   (ix+$00),$98
F433: DD 36 E0 32 ld   (ix-$20),$98
F437: 21 08 6F    ld   hl,unknown_CF02
F43A: 7E          ld   a,(hl)
F43B: 23          inc  hl
F43C: B6          or   (hl)
F43D: FE 00       cp   $00
F43F: C2 44 F4    jp   nz,$F444
F442: 3D          dec  a
F443: C9          ret
F444: CD 3C BB    call read_current_player_controls_BB96
F447: A7          and  a
F448: CA F9 F9    jp   z,$F3F3
F44B: F5          push af
F44C: 3E 00       ld   a,$00
F44E: CD 3F F9    call $F39F
F451: F1          pop  af
F452: F5          push af
F453: E6 F0       and  $F0
F455: FE 20       cp   $80
F457: CA 30 F4    jp   z,$F490
F45A: FE 40       cp   $40
F45C: CA A8 F4    jp   z,$F4A2
F45F: FE 80       cp   $20
F461: CA B4 F4    jp   z,$F4B4
F464: FE 10       cp   $10
F466: C2 E9 F4    jp   nz,$F4E3
F469: 3A 00 6F    ld   a,(temp_numeric_buffer_CF00)
F46C: 3C          inc  a
F46D: 3C          inc  a
F46E: 32 00 6F    ld   (temp_numeric_buffer_CF00),a
F471: FE 1B       cp   $1B
F473: DA 27 F4    jp   c,$F48D
F476: 3E 05       ld   a,$05
F478: 32 00 6F    ld   (temp_numeric_buffer_CF00),a
F47B: 3A 01 6F    ld   a,(unknown_CF01)
F47E: 3C          inc  a
F47F: 3C          inc  a
F480: FE 07       cp   $0D
F482: DA 2D F4    jp   c,$F487
F485: 3E 0D       ld   a,$07
F487: 32 01 6F    ld   (unknown_CF01),a
F48A: C3 E9 F4    jp   $F4E3
F48D: C3 E9 F4    jp   $F4E3
F490: 3A 01 6F    ld   a,(unknown_CF01)
F493: 3C          inc  a
F494: 3C          inc  a
F495: FE 07       cp   $0D
F497: DA 36 F4    jp   c,$F49C
F49A: 3E 0D       ld   a,$07
F49C: 32 01 6F    ld   (unknown_CF01),a
F49F: C3 E9 F4    jp   $F4E3
F4A2: 3A 01 6F    ld   a,(unknown_CF01)
F4A5: 3D          dec  a
F4A6: 3D          dec  a
F4A7: FE 05       cp   $05
F4A9: C2 AE F4    jp   nz,$F4AE
F4AC: 3E 0B       ld   a,$0B
F4AE: 32 01 6F    ld   (unknown_CF01),a
F4B1: C3 E9 F4    jp   $F4E3
F4B4: 3A 00 6F    ld   a,(temp_numeric_buffer_CF00)
F4B7: 3D          dec  a
F4B8: 3D          dec  a
F4B9: FE 09       cp   $03
F4BB: CA 64 F4    jp   z,$F4C4
F4BE: 32 00 6F    ld   (temp_numeric_buffer_CF00),a
F4C1: C3 E9 F4    jp   $F4E3
F4C4: 3A 01 6F    ld   a,(unknown_CF01)
F4C7: FE 0D       cp   $07
F4C9: C2 73 F4    jp   nz,$F4D9
F4CC: 3E 13       ld   a,$19
F4CE: 32 00 6F    ld   (temp_numeric_buffer_CF00),a
F4D1: 3E 0B       ld   a,$0B
F4D3: 32 01 6F    ld   (unknown_CF01),a
F4D6: C3 E9 F4    jp   $F4E3
F4D9: 3E 13       ld   a,$19
F4DB: 32 00 6F    ld   (temp_numeric_buffer_CF00),a
F4DE: 21 01 6F    ld   hl,unknown_CF01
F4E1: 35          dec  (hl)
F4E2: 35          dec  (hl)
F4E3: 3E 01       ld   a,$01
F4E5: CD 3F F9    call $F39F
F4E8: F1          pop  af
F4E9: E6 0F       and  $0F
F4EB: CA 70 F5    jp   z,$F5D0
F4EE: 3A 01 6F    ld   a,(unknown_CF01)
F4F1: FE 0B       cp   $0B
F4F3: C2 01 F5    jp   nz,$F501
F4F6: 3A 00 6F    ld   a,(temp_numeric_buffer_CF00)
F4F9: FE 13       cp   $19
F4FB: C2 01 F5    jp   nz,$F501
F4FE: 3E FF       ld   a,$FF
F500: C9          ret
F501: 3A 01 6F    ld   a,(unknown_CF01)
F504: FE 0B       cp   $0B
F506: C2 55 F5    jp   nz,$F555
F509: 3A 00 6F    ld   a,(temp_numeric_buffer_CF00)
F50C: FE 1D       cp   $17
F50E: C2 55 F5    jp   nz,$F555
F511: 3E 1C       ld   a,$16
F513: CD B5 BB    call play_sound_BBB5
F516: 3A 05 6F    ld   a,(unknown_CF05)
F519: 3D          dec  a
F51A: FE FF       cp   $FF
F51C: CA 70 F5    jp   z,$F5D0
F51F: 32 05 6F    ld   (unknown_CF05),a
F522: 26 0E       ld   h,$0E
F524: 2E 04       ld   l,$04
F526: CD FC B8    call compute_screen_address_from_XY_B2F6
F529: E5          push hl
F52A: 3A 05 6F    ld   a,(unknown_CF05)
F52D: 5F          ld   e,a
F52E: 16 80       ld   d,$20
F530: CD 69 B0    call multiply_de_B0C3
F533: E1          pop  hl
F534: A7          and  a
F535: ED 52       sbc  hl,de
F537: 36 96       ld   (hl),$3C
F539: 11 00 04    ld   de,$0400
F53C: 19          add  hl,de
F53D: 36 B0       ld   (hl),$B0
F53F: 2A 0C 6F    ld   hl,(unknown_CF06)
F542: 3A 05 6F    ld   a,(unknown_CF05)
F545: CB 27       sla  a
F547: C6 0C       add  a,$06
F549: 06 00       ld   b,$00
F54B: 4F          ld   c,a
F54C: 09          add  hl,bc
F54D: 36 84       ld   (hl),$24
F54F: 23          inc  hl
F550: 36 B0       ld   (hl),$B0
F552: C3 70 F5    jp   $F5D0
F555: 3E 1C       ld   a,$16
F557: CD B5 BB    call play_sound_BBB5
F55A: 3A 01 6F    ld   a,(unknown_CF01)
F55D: D6 0D       sub  $07
F55F: 57          ld   d,a
F560: 1E 0B       ld   e,$0B
F562: CD 69 B0    call multiply_de_B0C3
F565: 26 00       ld   h,$00
F567: 3A 00 6F    ld   a,(temp_numeric_buffer_CF00)
F56A: D6 05       sub  $05
F56C: 6F          ld   l,a
F56D: 19          add  hl,de
F56E: 11 91 F1    ld   de,table_F131
F571: 19          add  hl,de
F572: E5          push hl
F573: 26 0E       ld   h,$0E
F575: 2E 04       ld   l,$04
F577: CD FC B8    call compute_screen_address_from_XY_B2F6
F57A: E5          push hl
F57B: 3A 05 6F    ld   a,(unknown_CF05)
F57E: FE 09       cp   $03
F580: C2 24 F5    jp   nz,$F584
F583: 3D          dec  a
F584: 57          ld   d,a
F585: 1E 80       ld   e,$20
F587: CD 69 B0    call multiply_de_B0C3
F58A: E1          pop  hl
F58B: A7          and  a
F58C: ED 52       sbc  hl,de
F58E: E5          push hl
F58F: FD E1       pop  iy
F591: DD E1       pop  ix
F593: DD 7E 00    ld   a,(ix+$00)
F596: FD 77 00    ld   (iy+$00),a
F599: 01 00 04    ld   bc,$0400
F59C: FD 09       add  iy,bc
F59E: FD 36 00 A2 ld   (iy+$00),$A8
F5A2: FD 2A 0C 6F ld   iy,(unknown_CF06)
F5A6: 3A 05 6F    ld   a,(unknown_CF05)
F5A9: FE 09       cp   $03
F5AB: C2 AF F5    jp   nz,$F5AF
F5AE: 3D          dec  a
F5AF: CB 27       sla  a
F5B1: C6 0C       add  a,$06
F5B3: 06 00       ld   b,$00
F5B5: 4F          ld   c,a
F5B6: FD 09       add  iy,bc
F5B8: DD 7E 00    ld   a,(ix+$00)
F5BB: FD 77 00    ld   (iy+$00),a
F5BE: DD 7E 01    ld   a,(ix+$01)
F5C1: FD 77 01    ld   (iy+$01),a
F5C4: 3A 05 6F    ld   a,(unknown_CF05)
F5C7: FE 09       cp   $03
F5C9: CA 67 F5    jp   z,$F5CD
F5CC: 3C          inc  a
F5CD: 32 05 6F    ld   (unknown_CF05),a
F5D0: 06 02       ld   b,$08
F5D2: 3E 01       ld   a,$01
F5D4: C5          push bc
F5D5: CD 5E BC    call suspend_this_task_B65E
F5D8: 3A 09 6F    ld   a,(unknown_CF03)
F5DB: D6 01       sub  $01
F5DD: 27          daa
F5DE: 32 09 6F    ld   (unknown_CF03),a
F5E1: 3A 08 6F    ld   a,(unknown_CF02)
F5E4: DE 00       sbc  a,$00
F5E6: 27          daa
F5E7: 32 08 6F    ld   (unknown_CF02),a
F5EA: 26 12       ld   h,$18
F5EC: 2E 09       ld   l,$03
F5EE: CD FC B8    call compute_screen_address_from_XY_B2F6
F5F1: 3A 08 6F    ld   a,(unknown_CF02)
F5F4: CB 3F       srl  a
F5F6: CB 3F       srl  a
F5F8: CB 3F       srl  a
F5FA: CB 3F       srl  a
F5FC: 77          ld   (hl),a
F5FD: E5          push hl
F5FE: FD E1       pop  iy
F600: 3A 08 6F    ld   a,(unknown_CF02)
F603: E6 0F       and  $0F
F605: FD 77 E0    ld   (iy-$20),a
F608: 01 00 04    ld   bc,$0400
F60B: FD 09       add  iy,bc
F60D: FD 36 00 32 ld   (iy+$00),$98
F611: FD 36 E0 32 ld   (iy-$20),$98
F615: CD 3C BB    call read_current_player_controls_BB96
F618: C1          pop  bc
F619: E6 0F       and  $0F
F61B: CA 80 FC    jp   z,$F620
F61E: 06 02       ld   b,$08
F620: 21 08 6F    ld   hl,unknown_CF02
F623: 7E          ld   a,(hl)
F624: 23          inc  hl
F625: B6          or   (hl)
F626: C2 86 FC    jp   nz,$F62C
F629: 3E FF       ld   a,$FF
F62B: C9          ret
F62C: 10 A4       djnz $F5D2
F62E: C3 F9 F9    jp   $F3F3
F631: 3E 01       ld   a,$01
F633: CD B5 BB    call play_sound_BBB5
F636: 3E 01       ld   a,$01
F638: CD 5E BC    call suspend_this_task_B65E
F63B: CD F0 F8    call $F2F0
F63E: 01 96 D0    ld   bc,$703C
F641: CD 1C B9    call fill_video_and_attribute_memory_B316
F644: DD 21 00 6D ld   ix,referee_x_pos_C700
F648: 06 40       ld   b,$40
F64A: DD 36 00 00 ld   (ix+$00),$00
F64E: DD 23       inc  ix
F650: DD 23       inc  ix
F652: DD 23       inc  ix
F654: DD 23       inc  ix
F656: 10 F8       djnz $F64A
F658: 21 71 E7    ld   hl,table_EDD1
F65B: CD 31 B9    call display_multicolor_text_B391
F65E: CD AE F1    call display_hiscores_F1AE
F661: DD 21 02 6F ld   ix,unknown_CF08
F665: DD 36 00 05 ld   (ix+$00),$05
F669: DD 36 01 04 ld   (ix+$01),$04
F66D: DD 36 08 96 ld   (ix+$02),$3C
F671: DD 36 04 07 ld   (ix+$04),$0D
F675: DD 36 05 0A ld   (ix+$05),$0A
F679: DD 36 0C 1D ld   (ix+$06),$17
F67D: DD 36 0D FF ld   (ix+$07),$FF
F681: 3A 10 63    ld   a,(computer_skill_C910)
F684: 3C          inc  a
F685: DD 77 09    ld   (ix+$03),a
F688: FE 0A       cp   $0A
F68A: DA A6 FC    jp   c,$F6AC
F68D: DD 36 08 01 ld   (ix+$02),$01
F691: DD 36 09 00 ld   (ix+$03),$00
F695: CA A6 FC    jp   z,$F6AC
F698: DD 36 08 06 ld   (ix+$02),$0C
F69C: DD 36 09 11 ld   (ix+$03),$11
F6A0: DD 36 04 0A ld   (ix+$04),$0A
F6A4: DD 36 05 1C ld   (ix+$05),$16
F6A8: DD 36 0C 13 ld   (ix+$06),$19
F6AC: 21 02 6F    ld   hl,unknown_CF08
F6AF: 16 A2       ld   d,$A8
F6B1: CD 5D B9    call display_text_B357
F6B4: AF          xor  a
F6B5: 32 09 6F    ld   (unknown_CF03),a
F6B8: 3E 90       ld   a,$30
F6BA: 32 08 6F    ld   (unknown_CF02),a
F6BD: AF          xor  a
F6BE: 32 05 6F    ld   (unknown_CF05),a
F6C1: 3E 05       ld   a,$05
F6C3: 32 00 6F    ld   (temp_numeric_buffer_CF00),a
F6C6: 3E 0D       ld   a,$07
F6C8: 32 01 6F    ld   (unknown_CF01),a
F6CB: 3E 01       ld   a,$01
F6CD: CD 3F F9    call $F39F
F6D0: CD F9 F9    call $F3F3
F6D3: CD AE F1    call display_hiscores_F1AE
F6D6: 3E 90       ld   a,$30
F6D8: CD 5E BC    call suspend_this_task_B65E
F6DB: 3E 01       ld   a,$01
F6DD: 06 01       ld   b,$01
F6DF: CD AE BC    call task_manipulation_B6AE
F6E2: CD A5 B5    call task_yield_B5A5
; copy contents of ROM in $C040
init_C040_F6E5:
F6E5: 01 C6 00    ld   bc,$006C
F6E8: 21 F1 FC    ld   hl,table_F6F1
F6EB: 11 40 60    ld   de,unknown_C040
F6EE: ED B0       ldir
F6F0: C9          ret
table_F6F1:
	dc.b	0x02,0x00,0x00,0x00,0x00,0x00,0x13,0xb0 ; table_F6F1
	dc.b	0x1e,0xb0,0x0c,0xb0,0x14,0xb0,0x22,0xb0 ; $f6f9
	dc.b	0x00,0x03,0x01,0x80,0x00,0x00,0x00,0x00 ; $f701
	dc.b	0x16,0xb0,0x0a,0xb0,0x1b,0xb0,0x22,0xb0 ; $f709
	dc.b	0x3c,0xb0,0x00,0x02,0x01,0x60,0x00,0x00 ; $f711
	dc.b	0x00,0x00,0x14,0xb0,0x1e,0xb0,0x17,0xb0 ; $f719
	dc.b	0x1d,0xb0,0x0a,0xb0,0x00,0x02,0x01,0x40 ; $f721
	dc.b	0x00,0x00,0x00,0x00,0x1b,0xb0,0x0e,0xb0 ; $f729
	dc.b	0x12,0xb0,0x14,0xb0,0x18,0xb0,0x00,0x01 ; $f731
	dc.b	0x01,0x20,0x00,0x00,0x00,0x00,0x13,0xb0 ; $f739
	dc.b	0x18,0xb0,0x17,0xb0,0x22,0xb0,0x3c,0xb0 ; $f741
	dc.b	0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00 ; $f749
	dc.b	0x2f,0xb0,0x2f,0xb0,0x2f,0xb0,0x2f,0xb0 ; $f751
	dc.b	0x2f,0xb0,0x00,0x01 ; $f759

; < ix
; < a
F75D: FD 21 64 FD ld   iy,table_F7C4
F761: 11 00 00    ld   de,$0000
F764: 5F          ld   e,a
F765: CB 23       sla  e
F767: CB 12       rl   d
F769: FD 19       add  iy,de
F76B: FD 5E 00    ld   e,(iy+$00)
F76E: FD 56 01    ld   d,(iy+$01)
F771: D5          push de
F772: FD E1       pop  iy
F774: 01 08 00    ld   bc,$0002
F777: FD 09       add  iy,bc
F779: FD 46 FF    ld   b,(iy-$01)
F77C: FD 4E FE    ld   c,(iy-$02)
F77F: C5          push bc
F780: 41          ld   b,c
F781: E5          push hl
F782: 7C          ld   a,h
F783: DD 77 00    ld   (ix+$00),a
F786: FD 7E 00    ld   a,(iy+$00)
F789: DD 77 01    ld   (ix+$01),a
F78C: FD 7E 08    ld   a,(iy+$02)
F78F: DD 77 08    ld   (ix+$02),a
F792: 7D          ld   a,l
F793: DD 77 09    ld   (ix+$03),a
F796: FD 7E 01    ld   a,(iy+$01)
F799: CB 27       sla  a
F79B: CB 27       sla  a
F79D: CB 27       sla  a
F79F: CB 27       sla  a
F7A1: DD B6 08    or   (ix+$02)
F7A4: DD 77 08    ld   (ix+$02),a
F7A7: 3E 10       ld   a,$10
F7A9: 84          add  a,h
F7AA: 67          ld   h,a
F7AB: FD 23       inc  iy
F7AD: FD 23       inc  iy
F7AF: FD 23       inc  iy
F7B1: DD 23       inc  ix
F7B3: DD 23       inc  ix
F7B5: DD 23       inc  ix
F7B7: DD 23       inc  ix
F7B9: 10 6D       djnz $F782
F7BB: E1          pop  hl
F7BC: 3E 10       ld   a,$10
F7BE: 85          add  a,l
F7BF: 6F          ld   l,a
F7C0: C1          pop  bc
F7C1: 10 B6       djnz $F77F
F7C3: C9          ret
table_F7C4:
	dc.b	0x63,0x22,0xf8,0x3c,0xf8,0x8c,0xf8,0x9a ; $f7c3
	dc.b	0xf8,0xb6,0xf8,0xc4,0xf8,0xa8,0xf8,0xf8 ; $f7cb
	dc.b	0xf7,0x06,0xf8,0x14,0xf8,0x57,0xf8,0x71 ; $f7d3
	dc.b	0xf8,0xff,0xff,0xff,0xff,0xff,0xff,0xff ; $f7db
	dc.b	0xff,0xd8,0xf8,0xfe,0xf8,0x24,0xf9,0x50 ; $f7e3
	dc.b	0xf9,0x24,0xf9,0x50,0xf9,0x7c,0xf9,0x96 ; $f7eb
	dc.b	0xf9,0xb0,0xf9,0xca,0xf9,0x02,0x02,0x89 ; $f7f3
	dc.b	0x03,0x0c,0x8a,0x03,0x0c,0x8b,0x03,0x0c ; $f7fb
	dc.b	0x8c,0x03,0x0c,0x02,0x02,0x8d,0x03,0x0c ; $f803
	dc.b	0x8e,0x03,0x0c,0x8f,0x03,0x0c,0x90,0x03 ; $f80b
	dc.b	0x0c,0x02,0x02,0x91,0x03,0x0c,0x92,0x03 ; $f813
	dc.b	0x0c,0x93,0x03,0x0c,0x94,0x03,0x0c,0x02 ; $f81b
	dc.b	0x04,0x42,0x04,0x01,0x43,0x04,0x01,0x44 ; $f823
	dc.b	0x04,0x01,0x45,0x04,0x01,0x46,0x04,0x01 ; $f82b
	dc.b	0x47,0x04,0x01,0x48,0x04,0x01,0x49,0x04 ; $f833
	dc.b	0x01,0x02,0x04,0x4a,0x04,0x01,0x4b,0x04 ; $f83b
	dc.b	0x01,0x4c,0x04,0x01,0x4d,0x04,0x01,0x4e ; $f843
	dc.b	0x04,0x01,0x4f,0x04,0x01,0x50,0x04,0x01 ; $f84b
	dc.b	0x00,0x00,0x01,0x00,0x02,0x04,0x42,0x04 ; $f853
	dc.b	0x02,0x43,0x04,0x02,0x44,0x04,0x02,0x45 ; $f85b
	dc.b	0x04,0x02,0x46,0x04,0x02,0x47,0x04,0x02 ; $f863
	dc.b	0x48,0x04,0x02,0x49,0x04,0x02,0x02,0x04 ; $f86b
	dc.b	0x4a,0x04,0x02,0x4b,0x04,0x02,0x4c,0x04 ; $f873
	dc.b	0x02,0x4d,0x04,0x02,0x4e,0x04,0x02,0x4f ; $f87b
	dc.b	0x04,0x02,0x50,0x04,0x02,0x00,0x00,0x02 ; $f883
	dc.b	0x00,0x02,0x02,0x61,0x04,0x01,0x62,0x04 ; $f88b
	dc.b	0x01,0x63,0x04,0x01,0x64,0x04,0x01,0x02 ; $f893
	dc.b	0x02,0x67,0x04,0x01,0x67,0x04,0x81,0x68 ; $f89b
	dc.b	0x04,0x05,0x68,0x04,0x85,0x02,0x02,0x65 ; $f8a3
	dc.b	0x04,0x01,0x65,0x04,0x81,0x66,0x04,0x05 ; $f8ab
	dc.b	0x66,0x04,0x85,0x02,0x02,0x00,0x00,0x01 ; $f8b3
	dc.b	0x00,0x00,0x01,0x00,0x00,0x01,0x00,0x00 ; $f8bb
	dc.b	0x01,0x02,0x03,0x67,0x04,0x01,0x67,0x04 ; $f8c3
	dc.b	0x81,0x68,0x04,0x05,0x68,0x04,0x85,0x63 ; $f8cb
	dc.b	0x04,0x05,0x64,0x04,0x05,0x04,0x03,0x69 ; $f8d3
	dc.b	0x04,0x02,0x6a,0x04,0x03,0x6b,0x04,0x03 ; $f8db
	dc.b	0x6c,0x04,0x03,0x6d,0x04,0x03,0x6e,0x04 ; $f8e3
	dc.b	0x03,0xff,0x03,0x03,0x6f,0x04,0x03,0x70 ; $f8eb
	dc.b	0x04,0x03,0x71,0x04,0x03,0x72,0x04,0x03 ; $f8f3
	dc.b	0x73,0x04,0x03,0x04,0x03,0x69,0x04,0x03 ; $f8fb
	dc.b	0x6a,0x04,0x03,0x6b,0x04,0x03,0xc4,0x04 ; $f903
	dc.b	0x03,0x6d,0x04,0x03,0x6e,0x04,0x03,0xff ; $f90b
	dc.b	0x03,0x03,0x79,0x04,0x03,0x75,0x04,0x03 ; $f913
	dc.b	0x76,0x04,0x03,0x77,0x04,0x03,0x78,0x04 ; $f91b
	dc.b	0x03,0x0e,0x01,0x7c,0x04,0x8a,0x7d,0x04 ; $f923
	dc.b	0x8a,0x7e,0x04,0x8a,0x7f,0x04,0x8a,0x7c ; $f92b
	dc.b	0x04,0x8a,0x7d,0x04,0x8a,0x7e,0x04,0x8a ; $f933
	dc.b	0x7f,0x04,0x8a,0x7c,0x04,0x8a,0x7d,0x04 ; $f93b
	dc.b	0x8a,0x7e,0x04,0x8a,0x7f,0x04,0x8a,0x7c ; $f943
	dc.b	0x04,0x8a,0x7d,0x04,0x8a,0x0e,0x01,0x7e ; $f94b
	dc.b	0x04,0x8a,0x7f,0x04,0x8a,0x7c,0x04,0x8a ; $f953
	dc.b	0x7d,0x04,0x8a,0x7e,0x04,0x8a,0x7f,0x04 ; $f95b
	dc.b	0x8a,0x7c,0x04,0x8a,0x7d,0x04,0x8a,0x7e ; $f963
	dc.b	0x04,0x8a,0x7f,0x04,0x8a,0x7c,0x04,0x8a ; $f96b
	dc.b	0x7d,0x04,0x8a,0x7e,0x04,0x8a,0x7f,0x04 ; $f973
	dc.b	0x8a,0x02,0x04,0x51,0x04,0x01,0x52,0x04 ; $f97b
	dc.b	0x01,0x53,0x04,0x01,0x54,0x04,0x01,0x55 ; $f983
	dc.b	0x04,0x01,0x56,0x04,0x01,0x57,0x04,0x01 ; $f98b
	dc.b	0x58,0x04,0x01,0x02,0x04,0x59,0x04,0x01 ; $f993
	dc.b	0x5a,0x04,0x01,0x5b,0x04,0x01,0x5c,0x04 ; $f99b
	dc.b	0x01,0x5d,0x04,0x01,0x5e,0x04,0x01,0x5f ; $f9a3
	dc.b	0x04,0x01,0x60,0x04,0x01,0x02,0x04,0x51 ; $f9ab
	dc.b	0x04,0x02,0x52,0x04,0x02,0x53,0x04,0x02 ; $f9b3
	dc.b	0x54,0x04,0x02,0x55,0x04,0x02,0x56,0x04 ; $f9bb
	dc.b	0x02,0x57,0x04,0x02,0x58,0x04,0x02,0x02 ; $f9c3
	dc.b	0x04,0x59,0x04,0x02,0x5a,0x04,0x02,0x5b ; $f9cb
	dc.b	0x04,0x02,0x5c,0x04,0x02,0x5d,0x04,0x02 ; $f9d3
	dc.b	0x5e,0x04,0x02,0x5f,0x04,0x02,0x60,0x04 ; $f9db
	dc.b	0x02 ; $f9e3
F9E4: FD 21 82 FA ld   iy,table_FA28
F9E8: 16 00       ld   d,$00
F9EA: 5F          ld   e,a
F9EB: CB 23       sla  e
F9ED: CB 12       rl   d
F9EF: FD 19       add  iy,de
F9F1: FD 5E 00    ld   e,(iy+$00)
F9F4: FD 56 01    ld   d,(iy+$01)
F9F7: D5          push de
F9F8: FD E1       pop  iy
F9FA: FD 46 01    ld   b,(iy+$01)
F9FD: FD 4E 00    ld   c,(iy+$00)
FA00: FD 23       inc  iy
FA02: FD 23       inc  iy
FA04: C5          push bc
FA05: 41          ld   b,c
FA06: C5          push bc
FA07: E5          push hl
FA08: CD FC B8    call compute_screen_address_from_XY_B2F6
FA0B: FD 7E 00    ld   a,(iy+$00)
FA0E: 77          ld   (hl),a
FA0F: 11 00 04    ld   de,$0400
FA12: 19          add  hl,de
FA13: FD 7E 01    ld   a,(iy+$01)
FA16: 77          ld   (hl),a
FA17: E1          pop  hl
FA18: C1          pop  bc
FA19: 24          inc  h
FA1A: FD 23       inc  iy
FA1C: FD 23       inc  iy
FA1E: 10 EC       djnz $FA06
FA20: 7C          ld   a,h
FA21: 91          sub  c
FA22: 67          ld   h,a
FA23: 2C          inc  l
FA24: C1          pop  bc
FA25: 10 77       djnz $FA04
FA27: C9          ret
table_FA28:
	dc.w	0xfab2 ; $fa28
	dc.w	0xfac6 ; $fa2a
	dc.w	0xfb0a ; $fa2c
	dc.w	0xfbec ; $fa2e
	dc.w	0xfada ; $fa30 INSERT COIN text
	dc.w	0xfaf2 ; $fa32
	dc.w	0xfc2e ; $fa34
	dc.w	0xfc42 ; $fa36
	dc.w	0xfc56 ; $fa38
	dc.w	0xfc6a ; $fa3a
	dc.w	0xffff ; $fa3c
	dc.w	0xffff ; $fa3e
	dc.w	0xffff ; $fa40
	dc.w	0xffff ; $fa42
	dc.w	0xffff ; $fa44
	dc.w	0xffff ; $fa46
	dc.w	0xfa68 ; $fa48
	dc.w	0xfa68 ; $fa4a
	dc.w	0xfa68 ; $fa4c
	dc.w	0xfa68 ; $fa4e
	dc.w	0xfa68 ; $fa50
	dc.w	0xfa68 ; $fa52
	dc.w	0xfa68 ; $fa54
	dc.w	0xfa68 ; $fa56
	dc.w	0xfa68 ; $fa58
	dc.w	0xfa68 ; $fa5a
	dc.w	0xfa68 ; $fa5c
	dc.w	0xfa68 ; $fa5e
	dc.w	0xfa68 ; $fa60
	dc.w	0xfa68 ; $fa62
	dc.w	0xfa68 ; $fa64
	dc.w	0xfa68 ; $fa66
table_FA68:
	dc.b	0x09,0x04,0xa1,0x3a,0xa2,0x3a,0xa2,0x3a ; $fa68
	dc.b	0xa2,0x3a,0xa2,0x3a,0xa2,0x3a,0xa2,0x3a ; $fa70
	dc.b	0xa2,0x3a,0xa4,0x3a,0x3f,0x38,0x3f,0x38 ; $fa78
	dc.b	0x3f,0x38,0x3f,0x38,0x3f,0x38,0x3f,0x38 ; $fa80
	dc.b	0x3f,0x38,0x3f,0x38,0xa3,0x3a,0x3f,0x38 ; $fa88
	dc.b	0x3f,0x38,0x3f,0x38,0x3f,0x38,0x3f,0x38 ; $fa90
	dc.b	0x3f,0x38,0x3f,0x38,0x3f,0x38,0xa3,0x3a ; $fa98
	dc.b	0x3f,0x38,0x3f,0x38,0x3f,0x38,0x3f,0x38 ; $faa0
	dc.b	0x3f,0x38,0x3f,0x38,0x3f,0x38,0x3f,0x38 ; $faa8
	dc.b	0xa5,0x3a,0x03,0x03,0x5c,0x42,0x5e,0x5a ; $fab0
	dc.b	0x60,0x62,0x5d,0x42,0x5f,0x5a,0x61,0x62 ; $fab8
	dc.b	0x60,0x62,0x5c,0x42,0x62,0x5a,0x03,0x03 ; $fac0
	dc.b	0x5e,0x5a,0x62,0x5a,0x60,0x62,0x5f,0x5a ; $fac8
	dc.b	0x62,0x5a,0x61,0x62,0x60,0x62,0x5e,0x5a ; $fad0
	dc.b	0x5c,0x42,0x0b,0x01,0x12,0x88,0x17,0x88 ; $fad8
	dc.b	0x1c,0x88,0x0e,0x88,0x1b,0x88,0x1d,0x88 ; $fae0
	dc.b	0x3c,0x88,0x0c,0x88,0x18,0x88,0x12,0x88 ; $fae8
	dc.b	0x17,0x88,0x0b,0x01,0x3c,0x88,0x3c,0x88 ; $faf0
	dc.b	0x3c,0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88 ; $faf8
	dc.b	0x3c,0x88,0x3c,0x88,0x3c,0x88,0x3c,0x88 ; $fb00
	dc.b	0x3c,0x88,0x1c,0x04,0x5c,0x42,0x5e,0x5a ; $fb08
	dc.b	0x60,0x62,0x62,0x42,0x5d,0x62,0x5f,0xb2 ; $fb10
	dc.b	0x61,0x42,0x61,0x62,0x5c,0x62,0x5f,0x62 ; $fb18
	dc.b	0x5e,0x42,0x61,0x42,0x5f,0x42,0x63,0x42 ; $fb20
	dc.b	0x62,0x5a,0x5d,0x62,0x63,0xb2,0x60,0x42 ; $fb28
	dc.b	0x63,0x62,0x5d,0x62,0x5f,0xb2,0x5c,0x5a ; $fb30
	dc.b	0x60,0x42,0x60,0x42,0x5e,0x62,0x60,0x42 ; $fb38
	dc.b	0x5f,0x62,0x5e,0x62,0x5c,0x62,0x63,0x42 ; $fb40
	dc.b	0x61,0x5a,0x5d,0xb2,0x5e,0xb2,0x5e,0x62 ; $fb48
	dc.b	0x5e,0xb2,0x5e,0x62,0x5e,0x42,0x5e,0x62 ; $fb50
	dc.b	0x5e,0x5a,0x5e,0x42,0x60,0x42,0x60,0x5a ; $fb58
	dc.b	0x62,0x62,0x5d,0x42,0x62,0x62,0x62,0xb2 ; $fb60
	dc.b	0x5d,0x62,0x5f,0x62,0x5d,0xb2,0x5d,0x62 ; $fb68
	dc.b	0x5d,0x42,0x5d,0x62,0x5d,0x5a,0x5f,0x42 ; $fb70
	dc.b	0x5d,0x62,0x5d,0x62,0x5c,0x42,0x5e,0x62 ; $fb78
	dc.b	0x5e,0x42,0x5c,0x62,0x5e,0x62,0x60,0x62 ; $fb80
	dc.b	0x5e,0x42,0x5c,0xb2,0x60,0x5a,0x62,0x42 ; $fb88
	dc.b	0x62,0x42,0x5c,0x62,0x5c,0x42,0x5c,0x42 ; $fb90
	dc.b	0x5c,0x5a,0x60,0x42,0x62,0xb2,0x62,0x62 ; $fb98
	dc.b	0x62,0x42,0x5e,0x42,0x60,0x42,0x60,0x62 ; $fba0
	dc.b	0x60,0x42,0x5c,0xb2,0x63,0xb2,0x61,0x62 ; $fba8
	dc.b	0x5f,0x42,0x5f,0x62,0x5c,0x42,0x5e,0x5a ; $fbb0
	dc.b	0x60,0x62,0x62,0x42,0x5d,0x62,0x5f,0xb2 ; $fbb8
	dc.b	0x61,0x42,0x61,0x62,0x5c,0x62,0x5f,0x62 ; $fbc0
	dc.b	0x5e,0x42,0x61,0x42,0x5f,0x42,0x63,0x42 ; $fbc8
	dc.b	0x62,0x5a,0x5d,0x62,0x63,0xb2,0x60,0x42 ; $fbd0
	dc.b	0x63,0x62,0x5d,0x62,0x5f,0xb2,0x5c,0x5a ; $fbd8
	dc.b	0x60,0x42,0x60,0x42,0x5e,0x62,0x60,0x42 ; $fbe0
	dc.b	0x5f,0x62,0x5e,0x62,0x20,0x01,0x3c,0x48 ; $fbe8
	dc.b	0x3c,0x48,0x3c,0x48,0x3c,0x48,0x3c,0x48 ; $fbf0
	dc.b	0x3c,0x48,0x3c,0x48,0x3c,0x48,0x3c,0x48 ; $fbf8
	dc.b	0x3c,0x48,0x3c,0x48,0x3c,0x48,0x3c,0x48 ; $fc00
	dc.b	0x3c,0x48,0x3c,0x48,0x3c,0x48,0x3c,0x48 ; $fc08
	dc.b	0x3c,0x48,0x3c,0x48,0x3c,0x48,0x3c,0x48 ; $fc10
	dc.b	0x3c,0x48,0x3c,0x48,0x3c,0x48,0x3c,0x48 ; $fc18
	dc.b	0x3c,0x48,0x3c,0x48,0x3c,0x48,0x3c,0x48 ; $fc20
	dc.b	0x3c,0x48,0x3c,0x48,0x3c,0x48,0x03,0x03 ; $fc28
	dc.b	0x5c,0x42,0x5e,0x5a,0x60,0x42,0x5d,0x62 ; $fc30
	dc.b	0x5f,0xb2,0x61,0x42,0x5c,0x62,0x5f,0x62 ; $fc38
	dc.b	0x5e,0x42,0x03,0x03,0x5f,0x42,0x60,0x5a ; $fc40
	dc.b	0x62,0x42,0x63,0x62,0x60,0xb2,0x5e,0x42 ; $fc48
	dc.b	0x62,0x62,0x62,0x62,0x5d,0x42,0x03,0x03 ; $fc50
	dc.b	0x63,0x42,0x62,0x5a,0x5f,0x42,0x60,0x62 ; $fc58
	dc.b	0x60,0xb2,0x60,0x42,0x5d,0x62,0x62,0x62 ; $fc60
	dc.b	0x5d,0x42,0x03,0x03,0x5e,0x42,0x5e,0x5a ; $fc68
	dc.b	0x5f,0x42,0x62,0x62,0x60,0xb2,0x5d,0x42 ; $fc70
	dc.b	0x60,0x62,0x5d,0x62,0x60,0x42 ; $fc78

FC7E: FD 21 E0 F6 ld   iy,table_FCE0
FC82: 01 00 00    ld   bc,$0000
FC85: 4F          ld   c,a
FC86: CB 21       sla  c
FC88: CB 10       rl   b
FC8A: FD 09       add  iy,bc
FC8C: FD 4E 00    ld   c,(iy+$00)
FC8F: FD 46 01    ld   b,(iy+$01)
FC92: C5          push bc
FC93: FD E1       pop  iy
FC95: 01 08 00    ld   bc,$0002
FC98: FD 09       add  iy,bc
FC9A: FD 46 FF    ld   b,(iy-$01)
FC9D: FD 4E FE    ld   c,(iy-$02)
FCA0: C5          push bc
FCA1: 41          ld   b,c
FCA2: E5          push hl
FCA3: 7C          ld   a,h
FCA4: DD 77 00    ld   (ix+$00),a
FCA7: FD 7E 00    ld   a,(iy+$00)
FCAA: DD 77 01    ld   (ix+$01),a
FCAD: DD 72 08    ld   (ix+$02),d
FCB0: 7D          ld   a,l
FCB1: DD 77 09    ld   (ix+$03),a
FCB4: FD 7E 01    ld   a,(iy+$01)
FCB7: CB 27       sla  a
FCB9: CB 27       sla  a
FCBB: CB 27       sla  a
FCBD: CB 27       sla  a
FCBF: DD B6 08    or   (ix+$02)
FCC2: DD 77 08    ld   (ix+$02),a
FCC5: 3E 10       ld   a,$10
FCC7: 84          add  a,h
FCC8: 67          ld   h,a
FCC9: FD 23       inc  iy
FCCB: FD 23       inc  iy
FCCD: DD 23       inc  ix
FCCF: DD 23       inc  ix
FCD1: DD 23       inc  ix
FCD3: DD 23       inc  ix
FCD5: 10 66       djnz $FCA3
FCD7: E1          pop  hl
FCD8: 3E 10       ld   a,$10
FCDA: 85          add  a,l
FCDB: 6F          ld   l,a
FCDC: C1          pop  bc
FCDD: 10 61       djnz $FCA0
FCDF: C9          ret
table_FCE0:
	dc.b	0xe2,0xfc,0x04,0x0c,0xa5,0x04,0xa6,0x04 ; table_FCE0
	dc.b	0xa6,0x04,0xa7,0x04,0xa8,0x04,0xa9,0x04 ; $fce8
	dc.b	0xa9,0x04,0xaa,0x04,0xa8,0x04,0xa9,0x04 ; $fcf0
	dc.b	0xa9,0x04,0xaa,0x04,0xa8,0x04,0xa9,0x04 ; $fcf8
	dc.b	0xa9,0x04,0xaa,0x04,0xa8,0x04,0xa9,0x04 ; $fd00
	dc.b	0xa9,0x04,0xaa,0x04,0xa8,0x04,0xa9,0x04 ; $fd08
	dc.b	0xa9,0x04,0xaa,0x04,0xa8,0x04,0xa9,0x04 ; $fd10
	dc.b	0xa9,0x04,0xaa,0x04,0xa8,0x04,0xa9,0x04 ; $fd18
	dc.b	0xa9,0x04,0xaa,0x04,0xa8,0x04,0xa9,0x04 ; $fd20
	dc.b	0xa9,0x04,0xaa,0x04,0xa8,0x04,0xa9,0x04 ; $fd28
	dc.b	0xa9,0x04,0xaa,0x04,0xa8,0x04,0xa9,0x04 ; $fd30
	dc.b	0xa9,0x04,0xaa,0x04,0xa8,0x04,0xa9,0x04 ; $fd38
	dc.b	0xa9,0x04,0xaa,0x04 ; $fd40

display_players_rank_FD44:
FD44: 1E 04       ld   e,$04
FD46: 16 30       ld   d,$90
FD48: 21 10 63    ld   hl,computer_skill_C910
FD4B: 3A 98 60    ld   a,(unknown_C032)
FD4E: E6 09       and  $03
FD50: FE 09       cp   $03
FD52: C2 CC F7    jp   nz,$FD66
FD55: 1E 08       ld   e,$02
FD57: 16 32       ld   d,$98
FD59: 21 00 63    ld   hl,map_index_C900
FD5C: CD CA F7    call display_player_rank_FD6A
FD5F: 1E 0C       ld   e,$06
FD61: 16 30       ld   d,$90
FD63: 21 02 63    ld   hl,unknown_C908
FD66: CD CA F7    call display_player_rank_FD6A
FD69: C9          ret

display_player_rank_FD6A:
FD6A: D5          push de
FD6B: E5          push hl
FD6C: 1C          inc  e
FD6D: 1C          inc  e
FD6E: 1C          inc  e
FD6F: 1C          inc  e
FD70: DD 21 02 6F ld   ix,unknown_CF08
FD74: DD 73 00    ld   (ix+$00),e
FD77: DD 36 01 01 ld   (ix+$01),$01
FD7B: E1          pop  hl
; check level number, to display 1ST => 10G => CMP
; only called at start of a round
FD7C: 7E          ld   a,(hl)
FD7D: FE 0A       cp   $0A
FD7F: DA 24 F7    jp   c,$FD84  ; < 10 ? skip
; max to 10
FD82: 3E 0A       ld   a,$0A
FD84: 4F          ld   c,a
FD85: 87          add  a,a
FD86: 81          add  a,c
FD87: 4F          ld   c,a
FD88: 06 00       ld   b,$00
FD8A: 21 A9 F7    ld   hl,position_table_FDA3
FD8D: 09          add  hl,bc
FD8E: 11 0A 6F    ld   de,unknown_CF0A
FD91: ED A0       ldi
FD93: ED A0       ldi
FD95: ED A0       ldi
FD97: DD 36 05 FF ld   (ix+$05),$FF
FD9B: 21 02 6F    ld   hl,unknown_CF08
FD9E: D1          pop  de
FD9F: CD 5D B9    call display_text_B357
FDA2: C9          ret
; 1ST, 2ND ...
position_table_FDA3:
	dc.b	0x01,0x1c,0x1d,0x02,0x17,0x0d,0x03,0x1b ; position_table_FDA3
	dc.b	0x0d,0x04,0x1d,0x11,0x05,0x1d,0x11,0x06 ; $fdab
	dc.b	0x1d,0x11,0x07,0x1d,0x11,0x08,0x1d,0x11 ; $fdb3
	dc.b	0x09,0x1d,0x11,0x01,0x00,0x10,0x0c,0x16 ; $fdbb
	dc.b	0x19 ; $fdc3

clear_score_text_FDC4:
FDC4: 21 E1 F7    ld   hl,space_text_FDE1
FDC7: C3 77 F7    jp   $FDDD

FDCA: 3A 11 63    ld   a,(background_and_state_bits_C911)
FDCD: CB 7F       bit  7,a
FDCF: C2 77 F7    jp   nz,$FDDD
FDD2: 21 14 FE    ld   hl,score_00_text_FE14
FDD5: FE 02       cp   $08
FDD7: CA 77 F7    jp   z,$FDDD
FDDA: 21 45 FE    ld   hl,score_00_text_FE45
FDDD: CD 31 B9    call display_multicolor_text_B391
FDE0: C9          ret
space_text_FDE1:
	dc.b	0x06,0x05,0x9e,0x92,0x9f,0x92,0xbb,0x92 ; space_text_FDE1
	dc.b	0xbc,0x92,0xbd,0x92,0xbe,0x92,0xbf,0x92 ; $fde9
	dc.b	0xfe,0x06,0x06,0xc0,0x92,0x8d,0x92,0x8e ; $fdf1
	dc.b	0x92,0x8f,0x92,0x90,0x92,0x91,0x92,0x92 ; $fdf9
	dc.b	0x92,0xfe,0x06,0x07,0x93,0x92,0x94,0x92 ; $fe01
	dc.b	0x95,0x92,0x96,0x92,0x97,0x92,0x98,0x92 ; $fe09
	dc.b	0x99,0x92,0xff ; $fe11
score_00_text_FE14:
	dc.b	0x02,0x05,0x7a,0xba,0x7b,0xba,0x7c,0xba ; score_00_text_FE14
	dc.b	0x7d,0xba,0x00,0x00,0x7e,0xba,0x7f,0xba ; $fe1c
	dc.b	0xfe,0x02,0x06,0x80,0xb2,0x81,0xb2,0x82 ; $fe24
	dc.b	0xb2,0x83,0xb2,0x84,0xb2,0x85,0xb2,0x86 ; $fe2c
	dc.b	0xb2,0xfe,0x02,0x07,0x87,0xb2,0x88,0xb2 ; $fe34
	dc.b	0x89,0xb2,0x8a,0xb2,0x8b,0xb2,0x8c,0xb2 ; $fe3c
	dc.b	0xff ; $fe44
score_00_text_FE45:
	dc.b	0x06,0x05,0x7a,0xba,0x7b,0xba,0x7c,0xba ; score_00_text_FE45
	dc.b	0x7d,0xba,0x00,0x00,0x7e,0xba,0x7f,0xba ; $fe4d
	dc.b	0xfe,0x06,0x06,0x80,0xb2,0x81,0xb2,0x82 ; $fe55
	dc.b	0xb2,0x83,0xb2,0x84,0xb2,0x85,0xb2,0x86 ; $fe5d
	dc.b	0xb2,0xfe,0x06,0x07,0x87,0xb2,0x88,0xb2 ; $fe65
	dc.b	0x89,0xb2,0x8a,0xb2,0x8b,0xb2,0x8c,0xb2 ; $fe6d
	dc.b	0xff ; $fe75
copyright_data_east_text_FE76:
	dc.b	0x07,0x1d,0x30,0x3c,0x0c,0x18,0x19,0x22 ; copyright_data_east_text_FE76
	dc.b	0x1b,0x12,0x10,0x11,0x1d,0x3c,0x01,0x09 ; $fe7e
	dc.b	0x08,0x04,0xfe,0x07,0x1f,0x0d,0x0a,0x1d ; $fe86
	dc.b	0x0a,0x3c,0x0e,0x0a,0x1c,0x1d,0x3c,0x1e ; $fe8e
	dc.b	0x1c,0x0a,0x31,0x12,0x17,0x0c,0x25,0xff ; $fe96
	dc.b	0x00 ; $fe9e
FE9F: C9          ret
; copy of code from $5E9F probably not useful or called, removing it

