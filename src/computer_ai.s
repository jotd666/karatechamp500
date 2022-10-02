

DECIDE_MOVE:MACRO
	move.l	#MOVE_\1,d7
	ENDM


; < A4: computer player structure

handle_cpu_opponent:
	; is the computer letting opponent attack before attacking itself?
	move.w	computer_next_attack_timer(a4),d0
	beq.b	.main_ai
	; yes, decrease timer
	subq.w	#1,d0
	move.w	d0,computer_next_attack_timer(a4)
	; timer is 0 => perform the attack that has been decided earlier
	beq		.attack
	bra		out_without_moving
.attack
	move.w	computer_next_attack(a4),d7
	bra		cpu_move_done_A410
	
	; first, check if player reaction timer has been loaded, if so, return immediately
	; without any move
	;move.w	frozen_controls_timer(a4),d0
	;bne.b	.no_wait
	; useful when cpu just made a ground attack, remains stuck for a while
	; will cause issues with jump attacks/sommersaults, that will be a
	; special case
	;;move.l	frozen_joystick_state(a4),d0		; keep doing what it was doing


	
; 1 player mode: handle computer
;A39D: DD 21 9B AA ld   ix,walk_frames_list_AA3B
;A3A1: FD 6E 0D    ld   l,(iy+$07)
;A3A4: FD 66 02    ld   h,(iy+$08)	; <= what the computer frame is
;A3A7: E5          push hl
;; the computer tries to find its own displayed frame in the various lists
;; is the computer walking?
;A3A8: CD 03 B0    call check_hl_in_ix_list_B009
;A3AB: E1          pop  hl
;A3AC: A7          and  a
;; if walking/stands guard, computer can attack the player
;A3AD: C2 9B A5    jp   nz,maybe_attack_opponent_A53B
.main_ai

	move.l	a4,a0
	bsr		is_walking_move
	tst		d0
	bne.b	maybe_attack_opponent_A53B

	; not walking, check if currently jumping to avoid a blow
	; not necessary since controls are frozen during a jump
	; or maybe it is???
	
;A3B0: DD 21 47 AA ld   ix,jump_frames_list_AA4D
;A3B4: E5          push hl
;A3B5: CD 03 B0    call check_hl_in_ix_list_B009
;A3B8: E1          pop  hl
;A3B9: A7          and  a
;A3BA: C2 66 AB    jp   nz,handle_cpu_land_from_jump_ABCC

	; check if frame just changed TODO (implement previous_frame, check it)

	; if frame just changed
	; check if staying_frames is negative (infinite time for frame, for human cpu)
	tst.w	current_frame_countdown(a4)
	bmi		full_blown_hit_ABE3
	; other cases: check both jump frames (left and right)
	move.l	frame_set(a4),a1
	add.w	frame(a4),a1
	move.l	bob_data(a1),a1
	cmp.l	#jumping_back_kick_6_right,a1
	beq.b	full_blown_hit_ABE3
	cmp.l	#jumping_back_kick_6_left,a1
	beq.b	full_blown_hit_ABE3
	cmp.l	#jumping_side_kick_7_right,a1
	beq.b	full_blown_hit_ABE3
	cmp.l	#jumping_side_kick_7_left,a1
	beq.b	full_blown_hit_ABE3
	
	; we have tested all attacking points where we should (maybe)
	; make a pause
	; we also have tested walk frames
	; the rest of the case is: in-move & sommersault & block
	; we have to sustain the move else it's likely to be aborted
	move.w	computer_next_attack(a4),d7
	
;A3BD: DD 21 C7 AA ld   ix,hitting_frame_list_AA6D
;A3C1: E5          push hl
;A3C2: CD 03 B0    call check_hl_in_ix_list_B009
;A3C5: E1          pop  hl
;A3C6: A7          and  a
;A3C7: C2 E9 AB    jp   nz,full_blown_hit_ABE3	; missed cpu hit: let player react
; the rest of the routine is used to maintain block as long as needed
; (as long as opponent is performing the same menacing move or another
; move of the same attack height)
;A3CA: DD 21 27 AA ld   ix,blocking_frame_list_AA8D
;A3CE: E5          push hl
;A3CF: CD 03 B0    call check_hl_in_ix_list_B009
;A3D2: E1          pop  hl
;A3D3: A7          and  a
;A3D4: C2 FF AB    jp   nz,$computer_completed_a_blocking_move_ABFF	; computer has completed a blocking move
;A3D7: E5          push hl
;A3D8: DD E1       pop  ix
;A3DA: DD 7E 02    ld   a,(ix+$08)
;A3DD: A7          and  a
;A3DE: C2 62 A6    jp   nz,$ACC8		; move done
;A3E1: C3 6B A6    jp   $ACCB		; move done
	; TOCODE
	bra.b	cpu_move_done_A410
	
cpu_move_decided_opponent_can_react_A3E4:
; special cases in demo mode
;A3E4: 3A 11 63    ld   a,($background_and_state_bits_C911)
;A3E7: CB BF       res  7,a	; clears bit 7
;; this is during demo mode (blue "karate champ" background), 2 cpu players
;; during cpu vs cpu demo (bridge), it's not $50
;A3E9: FE 50       cp   $50
;A3EB: CA 10 A4    jp   z,cpu_move_done_A410
;A3EE: FD CB 10 4C bit  0,(iy+$10)
;A3F2: C2 10 A4    jp   nz,cpu_move_done_A410

;; we enter here when computer is about to attack, but (in lower difficulty levels < 16)
;; it lets the opponent a chance to counter attack just before the attack
;; the time for the opponent to react is smaller and smaller with increasing skill level
;; attack has been already decided by functions that end up
;; calling A3E4
;A3F5: 21 CD A7    ld   hl,counter_attack_time_table_AD67
;A3F8: CD 6E A6    call let_opponent_react_depending_on_skill_level_ACCE
;; something animation related must have been set up to handle the special (why?)
;; case of counter attack with jump. Otherwise return code doesn't matter much
;A3FB: FE 03       cp   $09
;A3FD: CA DB A9    jp   z,$fight_mainloop_A37B		; jump attack: loop back (without attacking)
;A400: A7          and  a
;A401: CA 03 A4    jp   z,$A409		; 0
;A404: FE FF       cp   $FF
;A406: C4 D5 B0    call nz,display_error_text_B075
;; a = $FF: non jump counter attack has been launched by opponent
;; iy is C220
;; the attack move is already loaded in cpu C26B
;A409: FD CB 10 6C set  0,(iy+$10)
;A40D: C3 30 A9    jp   fight_mainloop_A390
;
;; called after a non-attacking move (walk, sommersault, turn back...)
;; but can also be called after deciding an attack...
;; this version doesn't give the chance to react (because most of the time
;; the computer is performing a non-attacking move)

	lea	counter_attack_time_table_AD67(pc),a0
	bsr	let_opponent_react_depending_on_skill_level_ACCE
	tst		d0
	beq.b	cpu_move_done_A410		; attack immediately
	
	; time attack for later
	move.w	d0,computer_next_attack_timer(a4)
	move.w	d7,computer_next_attack(a4)
	bra.b	out_without_moving
	
	
cpu_move_done_A410:
	cmp.l	#MOVE_TURN_AROUND,d7
	beq.b	.turn_around
	; convert enum(d7) to bits(d0)
	move.w	direction(a4),d1
	move.w	d7,d0
	bsr		convert_move_enum_to_joy_controls
	; how many frames will the technique remain ?
	lea		remain_frames_table(pc),a0
	add.w	d7,d7
	move.w	(a0,d7.w),frozen_controls_timer(a4)
	move.l	d0,frozen_joystick_state(a4)
	rts

; this move isn't possible with a human player
; perform it here, and declare "no move"
.turn_around
	move.w	direction(a4),d0
	cmp.w	#RIGHT,d0
	beq.b	.left
	move.w	#RIGHT,d0
	bra.b	.setd
.left
	move.w	#LEFT,d0
.setd
	move.w	d0,direction(a4)
out_without_moving:
	moveq.l	#0,d0	; no move bits
	move.l	d0,frozen_joystick_state(a4)
	rts
	
	
; min value is 1: move is frozen at least 1 frame
; 1 second!! this is not final, it's just to see if the moves work
remain_frames_table
	dc.w	1		; no move
	dc.w	6		; back/block TODO
	dc.w	1		; move fwd
	dc.w	60		; jump
	dc.w	60		; crouch (computer never does that)
	dc.w	60		; back kick
	dc.w	60		; MOVE_BACK_KICK_2 = 6
	dc.w	60		; MOVE_TURN_AROUND = 7
	dc.w	60		; MOVE_JUMPING_BACK_KICK = 8
	dc.w	60		; MOVE_FOOT_SWEEP_BACK = 9
	dc.w	60		; MOVE_FRONT_KICK_OR_REVERSE_PUNCH = 10
	dc.w	60		; MOVE_BACK_ROUND_KICK = 11
	dc.w	60		; MOVE_LUNGE_PUNCH_400 = 12
	dc.w	60		; MOVE_JUMPING_SIDE_KICK = 13
	dc.w	60		; MOVE_FOOT_SWEEP_FRONT_1 = 14
	dc.w	60		; MOVE_ROUND_KICK = 15
	dc.w	60		; MOVE_LUNGE_PUNCH_600 = 16
	dc.w	60		; MOVE_LUNGE_PUNCH_1000 = 17
	dc.w	60		; MOVE_REAR_SOMMERSAULT = 18
	dc.w	60		; MOVE_REVERSE_PUNCH_800 = 19
	dc.w	60		; MOVE_LOW_KICK = 20
	dc.w	60		; MOVE_LOW_KICK_2 = 21
	dc.w	60		; MOVE_LOW_KICK_3 = 22
	dc.w	60		; MOVE_FRONT_SOMMERSAULT = 23
	dc.w	60		; MOVE_FOOT_SWEEP_FRONT_2 = 24
	
; < A0: attack time master table (with 4 levels of difficulty)
; > D0: number of frames to wait

; trashes D1,A1
let_opponent_react_depending_on_skill_level_ACCE:
	move.l	opponent(a4),a1
	move.w	rank(a1),d1
	cmp.w	#16,d1
	bcc.b	.immediately	; no wait, attack immediately
	
	move.w	skill_level_option,d0
	move.l	(a0,d1.w),a0		; proper time table depending on skill level
	add.w	d1,d1		; values come in couples, TODO figure out the handicap
	moveq	#0,d0
	move.b	(a0,d1.w),d0	; number of frames to wait to opponent attack
	bmi.b	.immediately	; negative => 0
	rts
.immediately
	moveq	#0,d0
	rts
;
;; jump table depending on the value of iy+0xF
;; this jumps to another jump table selector (which is not very performant
;; as all the routines jumped to just load ix to a different value, a double
;; jump could probably have been avoided. But who am I to criticize Z80 code ?
;;
;; note: block moves are probably triggered when cpu decides to move back and
;; the player attacks at the same time (code $01)
;;
maybe_attack_opponent_A53B
;A53B: DD 21 4F A5 ld   ix,opponent_distance_jump_table_A54F
;A53F: 06 00       ld   b,$00
;A541: FD 4E 0F    ld   c,(iy+$0f); iy = C220: algebraic distance index (0-8 + facing direction bit 7)
;A544: CB 21       sla  c		; times 2 (and gets rid of the direction bit)
;A546: DD 09       add  ix,bc
;A548: DD 6E 00    ld   l,(ix+$00)
;A54B: DD 66 01    ld   h,(ix+$01)
;A54E: E9          jp   (hl)
;
	lea		opponent_distance_jump_table_A54F(pc),a0
	move.w	fine_distance(a4),d0
	bclr	#7,d0
	
	move.w	d0,$110		; TEMP
	
	add.w	d0,d0
	add.w	d0,d0
	move.l	(a0,d0.w),a2


	bsr		classify_opponent_move_start_A665
	move.w	d0,$112		; TEMP
	add.w	d0,d0
	add.w	d0,d0
	move.l	(a2,d0.w),a0
	jmp		(a0)
	
; there's a jump that loads a table and jumps to it. Better load the table using a table
; than code that does the same for each case

;jump_to_routine_from_table_A59D
;A59D: DD E5       push ix
;A59F: CD C5 AC    call classify_opponent_move_start_A665	; retrieve value 1 -> 9
;A5A2: DD E1       pop  ix
;; a is the index of the routine in selected computer_ai_jump_table
;; it cannot be 0
;A5A4: 87          add  a,a
;A5A5: 06 00       ld   b,$00
;A5A7: 4F          ld   c,a
;A5A8: DD 09       add  ix,bc
;A5AA: DD 6E 00    ld   l,(ix+$00)
;A5AD: DD 66 01    ld   h,(ix+$01)
;; jump to the routine
;A5B0: E9          jp   (hl)

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
opponent_distance_jump_table_A54F: 
	dc.l	ai_jump_table_all_move_towards_opponent_A651	; 0
	dc.l	ai_jump_table_opp_faces_far_A5C5		; 1
	dc.l	ai_jump_table_opp_faces_close_A5D9		; 2
	dc.l	ai_jump_table_opp_faces_closer_A5ED	; 3
	dc.l	ai_jump_table_opp_faces_closest_A601	; 4 
	dc.l	ai_jump_table_opp_turns_back_far_A615 		; 5
	dc.l	ai_jump_table_opp_turns_back_close_A629 	; 6
	dc.l	ai_jump_table_opp_turns_back_closer_A63D	; 7 
	dc.l	ai_jump_table_all_turn_back_A651 	; 8
;


	; now a0 is the table matching the fine distance
	; we have to classify opponent current move in 9 categories 1-9
	; 0: error (can't happen)
	; 1: no particular stuff (guard)
	; 2: frontal attack
	; 3: rear attack
	; 4: crouch
	; 5: in-jump
	; 6: sommersault forward
	; 7: sommersault backwards
	; 8: starting a jump
	; 9: move not in list


;; makes sense: players are far away, CPU just tries to get closer to player
;; but can also change direction
ai_jump_table_all_move_towards_opponent_A651:
	dc.l	display_error_text_B075                        ; what opponent does:
	dc.l	cpu_move_forward_towards_enemy_far_away_A6D4   ; 1: no particular stuff
	dc.l	cpu_move_forward_towards_enemy_far_away_A6D4   ; 2: frontal attack
	dc.l	cpu_move_forward_towards_enemy_far_away_A6D4   ; 3: rear attack
	dc.l	cpu_move_forward_towards_enemy_far_away_A6D4   ; 4: crouch
	dc.l	cpu_move_forward_towards_enemy_far_away_A6D4   ; 5 in-jump
	dc.l	cpu_move_forward_towards_enemy_far_away_A6D4   ; 6: sommersault forward
	dc.l	cpu_move_forward_towards_enemy_far_away_A6D4   ; 7: sommersault backwards
	dc.l	cpu_move_forward_towards_enemy_far_away_A6D4   ; 8: starting a jump
	dc.l	cpu_move_forward_towards_enemy_far_away_A6D4   ; 9: move not in list
	
ai_jump_table_opp_faces_far_A5C5
	dc.l	display_error_text_B075                             ; what opponent does:
	dc.l	cpu_move_forward_towards_enemy_A6E7	                ; 1: no particular stuff
	dc.l	cpu_forward_or_stop_if_facing_A6EF					; 2: frontal attack
	dc.l	cpu_forward_or_stop_if_not_facing_A700				; 3: rear attack
	dc.l	cpu_move_forward_towards_enemy_A6E7                 ; 4: crouch ($A711 jumps there)
	dc.l	cpu_move_forward_towards_enemy_A6E7                 ; 5 in-jump ($A714 jumps there)
	dc.l	cpu_forward_or_backward_depending_on_facing_A7D5	; 6: sommersault forward $A717	jumps there
	dc.l	cpu_backward_or_forward_depending_on_facing_A7E6	; 7: sommersault backwards $A71A	jumps there 
	dc.l	cpu_move_forward_towards_enemy_A71D	                ; 8: starting a jump
	dc.l	cpu_move_forward_towards_enemy_A71D	                ; 9: move not in list
;	
ai_jump_table_opp_faces_close_A5D9:
	dc.l	display_error_text_B075                             ; what opponent does:
	dc.l	attack_once_out_of_16_frames_else_walk_A725         ; 1: no particular stuff
	dc.l	cpu_avoids_low_attack_if_facing_else_maybe_attacks_A73F   ; 2: frontal attack
	dc.l	cpu_maybe_attacks_if_facing_else_avoids_low_attack_A786   ; 3: rear attack
	dc.l	just_walk_A7C5                                      ; 4: crouch
	dc.l	just_walk_A7CD                                      ; 5 in-jump
	dc.l	cpu_forward_or_backward_depending_on_facing_A7D5    ; 6: sommersault forward
	dc.l	cpu_backward_or_forward_depending_on_facing_A7E6    ; 7: sommersault backwards
	dc.l	attack_once_out_of_16_frames_else_walk_A725	        ; 8: starting a jump  $A7F7	jumps there
	dc.l	cpu_move_forward_towards_enemy_A7FA                 ; 9: move not in list
;	
ai_jump_table_opp_faces_closer_A5ED	
	dc.l	display_error_text_B075                             ; what opponent does:
	dc.l	pick_cpu_attack_A802                                ; 1: no particular stuff
	dc.l	cpu_reacts_to_low_attack_if_facing_else_attacks_A80C; 2: frontal attack
	dc.l	cpu_react_to_low_attack_or_perform_attack_A85B      ; 3: rear attack
	dc.l	cpu_small_chance_of_low_kick_else_walk_A893         ; 4: crouch
	dc.l	pick_cpu_attack_A802 ; was $A8A8                    ; 5 in-jump
	dc.l	pick_cpu_attack_A802 ; was $A8A8                    ; 6: sommersault forward
	dc.l	move_fwd_or_bwd_checking_sommersault_and_dir_A8E8   ; 7: sommersault backwards
	dc.l	pick_cpu_attack_A802  ; $A911 calls it              ; 8: starting a jump
	dc.l	pick_cpu_attack_A802  ; $A914 calls it              ; 9: move not in list
	
ai_jump_table_opp_faces_closest_A601
	dc.l	display_error_text_B075                             ; what opponent does:
	dc.l	get_out_of_edge_or_low_kick_A917                    ; 1: no particular stuff
	dc.l	cpu_reacts_to_low_attack_if_facing_else_attacks_A80C; 2: frontal attack $A92F
	dc.l	front_kick_or_fwd_sommersault_to_recenter_A94E      ; 3: rear attack                                    ; $A932 jumps there
	dc.l	perform_low_kick_A935	    						; 4: crouch                                      ; $A93D jumps there
	dc.l	front_kick_or_fwd_sommersault_to_recenter_A94E	    ; 5 in-jump                                      ; $A93D jumps there
	dc.l	high_attack_if_forward_sommersault_or_walk_A8AB	    ; 6: sommersault forward                        ; $A940 jumps there
	dc.l	move_fwd_or_bwd_checking_sommersault_and_dir_A8E8	; 7: sommersault backwards                     ; $A943 jumps there
	dc.l	perform_walk_back_A946                             ; 8: starting a jump
	dc.l	front_kick_or_fwd_sommersault_to_recenter_A94E      ; 9: move not in list
	                                                            
ai_jump_table_opp_turns_back_far_A615
	dc.l	display_error_text_B075
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
ai_jump_table_opp_turns_back_close_A629
	dc.l	display_error_text_B075
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
	dc.l	cpu_move_turn_around_A966
ai_jump_table_opp_turns_back_closer_A63D
	dc.l	display_error_text_B075       ; what opponent does:
	dc.l	pick_cpu_attack_A96E        ; 1: no particular stuff
	dc.l	cpu_complex_reaction_to_front_attack_A980     ; 2: frontal high attack
	dc.l	cpu_complex_reaction_to_rear_attack_A9D6                         ; 3: rear attack               
	dc.l	foot_sweep_back_AA10  		; 4: crouch                               
	dc.l	pick_cpu_attack_A96E        ; 5 in-jump    $AA22                
	dc.l	cpu_turn_back_AA25            ; 6: sommersault forward       
	dc.l	cpu_turn_back_AA25            ; 7: sommersault backwards     
	dc.l	pick_cpu_attack_A96E		  ; 8: starting a jump
	dc.l	pick_cpu_attack_A96E		  ; 9: move not in list
; opponent right closest: just landed it cpu back (not possible otherwise)
; turn back (no need to test)
ai_jump_table_all_turn_back_A651:
	dc.l	display_error_text_B075
	dc.l	cpu_turn_back_AA33
	dc.l	cpu_turn_back_AA33
	dc.l	cpu_turn_back_AA33
	dc.l	cpu_turn_back_AA33
	dc.l	cpu_turn_back_AA33
	
	dc.l	cpu_turn_back_AA33
	dc.l	cpu_turn_back_AA33
	dc.l	cpu_turn_back_AA33
	dc.l	cpu_turn_back_AA33


;
;; given opponent moves (not distance), return a value between 1 and 9
;; to be used in a per-distance/facing configuration jump table
;; iy: points on C220 (the A.I. structure)
;; 1: no particular stuff
;; 2: frontal high attack
;; 3: rear attack
;; 4: crouch
;; 5: in-jump
;; 6: sommersault forward
;; 7: sommersault backwards
;; 8: starting a jump
;; 9: move not in list
;A665: FD 6E 0B    ld   l,(iy+$0b)
;A668: FD 66 06    ld   h,(iy+$0c)		; hl <= opponent frame
;A66B: CB BC       res  7,h		; remove last bit (facing direction)
;A66D: DD 21 9B AA ld   ix,walk_frames_list_AA3B
;A671: E5          push hl
;A672: CD 03 B0    call check_hl_in_ix_list_B009
;A675: E1          pop  hl
;A676: A7          and  a
;A677: 3E 01       ld   a,$01
;A679: C2 79 AC    jp   nz,move_found_A6D3
;A67C: DD 21 B9 AA ld   ix,crouch_frame_list_AAB3	; load a table, there are 7 tables like this
;A680: E5          push hl
;A681: CD 03 B0    call check_hl_in_ix_list_B009
;A684: E1          pop  hl
;A685: A7          and  a
;A686: 3E 04       ld   a,$04
;A688: C2 79 AC    jp   nz,move_found_A6D3
;A68B: DD 21 47 AA ld   ix,jump_frames_list_AA4D
;A68F: E5          push hl
;A690: CD 03 B0    call check_hl_in_ix_list_B009
;A693: E1          pop  hl
;A694: A7          and  a
;A695: 3E 05       ld   a,$05
;A697: C2 79 AC    jp   nz,move_found_A6D3
;A69A: DD 21 35 AA ld   ix,forward_sommersault_frame_list_AA95
;A69E: E5          push hl
;A69F: CD 03 B0    call check_hl_in_ix_list_B009
;A6A2: E1          pop  hl
;A6A3: A7          and  a
;A6A4: 3E 0C       ld   a,$06		; forward sommersault
;A6A6: C2 79 AC    jp   nz,move_found_A6D3
;A6A9: DD 21 A5 AA ld   ix,backwards_sommersault_frame_list_AAA5
;A6AD: CD 03 B0    call check_hl_in_ix_list_B009
;A6B0: A7          and  a
;A6B1: 3E 0D       ld   a,$07		; backwards sommersault
;A6B3: C2 79 AC    jp   nz,move_found_A6D3
;A6B6: CD 76 AA    call opponent_starting_frontal_attack_AADC
;A6B9: A7          and  a
;A6BA: 3E 08       ld   a,$02		; frontal attack (very large move list!)
;A6BC: C2 79 AC    jp   nz,move_found_A6D3
;A6BF: CD ED AA    call opponent_starting_rear_attack_AAE7
;A6C2: A7          and  a
;A6C3: 3E 09       ld   a,$03
;A6C5: C2 79 AC    jp   nz,move_found_A6D3
;A6C8: CD 18 AB    call opponent_starting_a_sommersault_AB12
;A6CB: A7          and  a
;A6CC: 3E 02       ld   a,$08
;A6CE: C2 79 AC    jp   nz,move_found_A6D3
;A6D1: 3E 03       ld   a,$09
;move_found_A6D3:
;	C9          ret

; > D0: 1-9
classify_opponent_move_start_A665:
	moveq.l	#1,d1
	move.l	opponent(a4),a3
	move.l	a3,a0
	bsr.b	is_walking_move
	tst		d0
	bne.b	.out

	moveq.l	#4,d1
	move.l	current_move_header(a3),a0
	move.l	right_frame_set(a0),a0		; current frame
	cmp.l	#crouch_right_frames,a0
	beq.b	.out
	moveq.l	#5,d1
	cmp.l	#jump_right_frames,a0
	beq.b	.out
	
	; sommersaults
	; this is coded slightly differently than the original routine
	; I hope it's faithful
	;
	; 
	moveq.l	#8,d1	; starting it
	bsr.b	opponent_starting_a_sommersault_AB12
	tst		D0
	beq.b	.no_sommersault
	; once a sommersault is detected, if sommersault just started, return
	; value is 8 regardless of front/back sault type
	; first check if sommersault is clearly engaged

	move.w	frame(a3),d0
	cmp.w	#3*PlayerFrame_SIZEOF,d0	; check against 3 first frames
	bcs.b	.out		; starting the sommersault
	; engaged, check which sommersault
	moveq.l	#6,d1
	move.w	attack_id(a0),d0
	cmp.w	#ATTACK_SOMMERSAULT,d0
	beq.b	.out
	moveq.l	#7,d1
	bra.b	.out

.no_sommersault	
	moveq.l	#2,d1
	bsr		opponent_starting_frontal_attack_AADC
	tst		d0
	bne.b	.out
	
	moveq.l	#3,d1
	bsr		opponent_starting_rear_attack_AAE7
	tst		d0
	bne.b	.out
	
	moveq.l	#9,d1
.out
	move.l	d1,d0
	rts


;
;; move forward with a special case
;cpu_move_forward_towards_enemy_far_away_A6D4:
;A6D4: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;; here writes to C26B (if player 2 CPU) to tell CPU to walk forward
;; hl = C26B
;A6D7: 36 08       ld   (hl),$02		; move forward
;; iy=$C220
;; C22D is roughly minus opponent x (CPL which inverts bits, performed at A47C)
;; it actually is done to get 256-opponent x
;A6D9: FD 7E 07    ld   a,(iy+$0d)
;A6DC: FD BE 03    cp   (iy+$09)		; opponent x
;A6DF: D2 E4 AC    jp   nc,$A6E4
;; turn back if player is on the right (almost) half of the screen (difficult
;; to achieve when both players are far away. Possible with well
;; timed sommersaults)
;A6E2: 36 0D       ld   (hl),$07
;A6E4: C3 10 A4    jp   cpu_move_done_A410
;
cpu_move_forward_towards_enemy_far_away_A6D4:
	DECIDE_MOVE	FORWARD
	move.l	opponent(a4),a0
	move.w	#$100,d0
	move.w	xpos(a0),d1
	add.w	#$20,d1	; x offset of original game
	; bizarre opponent position test
	sub.w	d1,d0
	cmp.w	d1,d0
	bcc.b	cpu_move_done_A410
	DECIDE_MOVE	TURN_AROUND
	bra.b	cpu_move_done_A410


;; simplest & dumbest move forward
;cpu_move_forward_towards_enemy_A6E7:
;A6E7: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A6EA: 36 08       ld   (hl),$02
;A6EC: C3 10 A4    jp   cpu_move_done_A410
cpu_move_forward_towards_enemy_A7FA:
cpu_move_forward_towards_enemy_A6E7:
cpu_move_forward_towards_enemy_A71D:
	DECIDE_MOVE	FORWARD
	rts
	
;; move if not facing, stop if facing
;cpu_forward_or_stop_if_facing_A6EF:
;A6EF: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A6F2: 36 00       ld   (hl),$00		; stop
;A6F4: DD CB 0F DE bit  7,(ix+$0f)	; are players facing or back to back
;A6F8: CA F7 AC    jp   z,$A6FD		; facing
;; back to back: move
;A6FB: 36 08       ld   (hl),$02
;A6FD: C3 10 A4    jp   cpu_move_done_A410
;
cpu_forward_or_stop_if_facing_A6EF:
	DECIDE_MOVE	GUARD
	move.w	fine_distance(a4),d0
	btst	#7,d0
	beq.b	cpu_move_done_A410
	DECIDE_MOVE	FORWARD
	bra.b	cpu_move_done_A410

;; move if facing, stop if not facing
;cpu_forward_or_stop_if_not_facing_A700:
;A700: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A703: 36 00       ld   (hl),$00
;A705: FD CB 0F DE bit  7,(iy+$0f)
;A709: C2 0E AD    jp   nz,$A70E
;A70C: 36 08       ld   (hl),$02
;A70E: C3 10 A4    jp   cpu_move_done_A410
;
cpu_forward_or_stop_if_not_facing_A700:
	DECIDE_MOVE	GUARD
	move.w	fine_distance(a4),d0
	btst	#7,d0
	bne.b	cpu_move_done_A410
	DECIDE_MOVE	FORWARD
	bra.b	cpu_move_done_A410


;A717: C3 75 AD    jp   cpu_forward_or_backward_depending_on_facing_A7D5
;A71A: C3 EC AD    jp   cpu_backward_or_forward_depending_on_facing_A7E6
;; send "walk forward", exactly the same as A6E7
;cpu_move_forward_towards_enemy_A71D:
;A71D: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A720: 36 08       ld   (hl),$02
;A722: C3 10 A4    jp   cpu_move_done_A410
;
;; called by a jp (hl) when distance between players is "medium" (C26C 0 -> 1)
;attack_once_out_of_16_frames_else_walk_A725
;A725: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
;A728: E6 0F       and  $0F
;; periodic counter: decide an attack each 1/4s roughly
;; (actually if reaches that point with the counter aligned on 16, not
;; sure if it's each 1/4s)
;A72A: C2 94 AD    jp   nz,$A734
;A72D: CD 8E AB    call select_cpu_attack_AB2E
;A730: A7          and  a
;A731: C2 96 AD    jp   nz,$A73C	; a != 0 => attacked: always true
;; returns 0: just walk, don't attack. Only reaches here because periodic
;; counter is not a multiple of 16 (0x10)
;A734: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;; just send walk forward order to CPU
;A737: 36 08       ld   (hl),$02
;A739: C3 10 A4    jp   cpu_move_done_A410
;
;A73C: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4
;
attack_once_out_of_16_frames_else_walk_A725:
	move.b	randomness_timer,d0
	and.b	#$F,d0
	bne.b	just_walk_A7C5
	; 1/16 probability to attack
	bsr.b		select_cpu_attack_AB2E
	bra.b	cpu_move_decided_opponent_can_react_A3E4
	
;; if not facing, either attack or walk forward (50% chance each)
;; if facing, react to low attack by walking forward/backwards or jump
;cpu_avoids_low_attack_if_facing_else_maybe_attacks_A73F:
;A73F: FD CB 0F DE bit  7,(iy+$0f)
;A743: CA 57 AD    jp   z,$A75D
;; not facing opponent
;A746: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
;A749: E6 01       and  $01
;; 50% chance attack
;A74B: CA 55 AD    jp   z,$A755
;A74E: CD 8E AB    call select_cpu_attack_AB2E
;A751: A7          and  a
;A752: C2 29 AD    jp   nz,$A783		; always true
;; just walk, don't attack, one time out of 2
;A755: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A758: 36 08       ld   (hl),$02
;A75A: C3 20 AD    jp   $A780		; cpu_move_done_A410
;
cpu_avoids_low_attack_if_facing_else_maybe_attacks_A73F
	move.w	fine_distance(a4),d0
	btst	#7,d0
	beq.b	.facing
	; not facing: can attack
	btst	#0,randomness_timer
	beq.b	just_walk_A7C5
	bsr.b	select_cpu_attack_AB2E
	bra.b	cpu_move_decided_opponent_can_react_A3E4
.facing
;; facing opponent
;A75D: CD 02 AB    call opponent_starting_low_kick_AB08
;A760: A7          and  a
;A761: CA C6 AD    jp   z,$A76C
;; low kick: just walk
;A764: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A767: 36 08       ld   (hl),$02
;A769: C3 20 AD    jp   $A780
;; react to foot sweep
;A76C: CD F7 AA    call opponent_starting_low_attack_AAFD
;A76F: A7          and  a
;A770: CA DB AD    jp   z,$A77B
;A773: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;; evasive jump up
;A776: 36 09       ld   (hl),$03
;A778: C3 20 AD    jp   $A780
;; move back / block possible attack
;A77B: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A77E: 36 01       ld   (hl),$01
;
;A780: C3 10 A4    jp   cpu_move_done_A410
;A783: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4
;
	bsr		opponent_starting_low_kick_AB08
	tst		d0
	bne.b	just_walk_A7C5
	bsr		opponent_starting_low_attack_AAFD
	tst		d0
	bne.b	.not_low_attack
	DECIDE_MOVE	JUMP
	bra.b	cpu_move_done_A410
.not_low_attack
	DECIDE_MOVE	BACK
	bra.b	cpu_move_done_A410
	
;cpu_maybe_attacks_if_facing_else_avoids_low_attack_A786:
;A786: FD CB 0F DE bit  7,(iy+$0f)
;A78A: C2 A4 AD    jp   nz,$A7A4
;; facing each other
;A78D: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
;; 50% chance, (but by checking bit 1, so not the same value as below)
;A790: CB 4F       bit  1,a
;A792: CA 36 AD    jp   z,$A79C
;A795: CD 8E AB    call select_cpu_attack_AB2E
;A798: A7          and  a
;A799: C2 68 AD    jp   nz,$A7C2		; always true
;; just walk, don't attack
;A79C: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A79F: 36 08       ld   (hl),$02
;A7A1: C3 BF AD    jp   $A7BF

cpu_maybe_attacks_if_facing_else_avoids_low_attack_A786
	move.w	fine_distance(a4),d0
	btst	#7,d0
	bne.b	.not_facing
	move.b	randomness_timer,d0
	btst	#1,d0
	beq.b	just_walk_A7C5
	bra.b	pick_cpu_attack_A802
;; not facing each other: if low attack, 50% chance of jump,
;; 50% ; move back / block possible attack
;
;A7A4: CD F7 AA    call opponent_starting_low_attack_AAFD
;A7A7: CA BA AD    jp   z,$A7BA
;A7AA: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
;A7AD: CB 47       bit  0,a		; 50% chance
;A7AF: C2 BA AD    jp   nz,$A7BA
;A7B2: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;; 50% chance evasive jump
;A7B5: 36 09       ld   (hl),$03
;A7B7: C3 BF AD    jp   $A7BF
;; move back / block possible attack
;A7BA: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A7BD: 36 01       ld   (hl),$01
;A7BF: C3 10 A4    jp   cpu_move_done_A410
;A7C2: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4
;
.not_facing
	bsr.b	opponent_starting_low_attack_AAFD
	tst		d0
	beq.b	perform_walk_back_A946
	move.b	randomness_timer,d0
	btst	#0,d0
	bne.b	perform_walk_back_A946
	DECIDE_MOVE	JUMP
	bra.b	cpu_move_done_A410
	
;just_walk_A7C5: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A7C8: 36 08       ld   (hl),$02
;A7CA: C3 10 A4    jp   cpu_move_done_A410
;
;just_walk_A7CD: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A7D0: 36 08       ld   (hl),$02
;A7D2: C3 10 A4    jp   cpu_move_done_A410
;
just_walk_A7C5:
just_walk_A7CD:
	DECIDE_MOVE	FORWARD
	bra.b	cpu_move_done_A410
	
;; move forward, except if back to back in which case
;; move back / block possible attack
;cpu_forward_or_backward_depending_on_facing_A7D5:
;A7D5: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A7D8: 36 08       ld   (hl),$02
;A7DA: FD CB 0F DE bit  7,(iy+$0f)
;A7DE: C2 E9 AD    jp   nz,$A7E3
;A7E1: 36 01       ld   (hl),$01
;A7E3: C3 10 A4    jp   cpu_move_done_A410
cpu_forward_or_backward_depending_on_facing_A7D5:
	DECIDE_MOVE	FORWARD
	move.w	fine_distance(a4),d0
	btst	#7,d0
	bne.b	cpu_move_done_A410
	DECIDE_MOVE	BACK
	bra.b	cpu_move_done_A410
;; move backwards/block, except if back to back in which case move forwards
;cpu_backward_or_forward_depending_on_facing_A7E6:
;A7E6: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A7E9: 36 08       ld   (hl),$02
;A7EB: FD CB 0F DE bit  7,(iy+$0f)
;A7EF: CA F4 AD    jp   z,$A7F4
;A7F2: 36 01       ld   (hl),$01
;A7F4: C3 10 A4    jp   cpu_move_done_A410
;
cpu_backward_or_forward_depending_on_facing_A7E6
	DECIDE_MOVE	FORWARD
	move.w	fine_distance(a4),d0
	btst	#7,d0
	beq.b	cpu_move_done_A410
	DECIDE_MOVE	BACK
	bra.b	cpu_move_done_A410


	
;cpu_reacts_to_low_attack_if_facing_else_attacks_A80C:
;A80C: FD CB 0F DE bit  7,(iy+$0f)  ; => C20F
;A810: C2 4E A2    jp   nz,$A84E		; jumps if not facing each other
;; players facing each other
;A813: CD 02 AB    call opponent_starting_low_kick_AB08
;A816: A7          and  a
;A817: CA 81 A2    jp   z,$A821
;; opponent starting low kick: react with jumping side kick
;A81A: CD 22 AB    call perform_jumping_side_kick_if_level_2_AB88
;A81D: A7          and  a
;A81E: C2 55 A2    jp   nz,$A855
;; low difficulty level or no low kick, check if starting low kick or foot sweep
;A821: CD F7 AA    call opponent_starting_low_attack_AAFD
;A824: A7          and  a
;A825: CA 92 A2    jp   z,$A838
;; react to foot sweep/low kick
;A828: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A82B: 36 09       ld   (hl),$03		; evasive jump
;A82D: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
;A830: E6 09       and  $03
;A832: CA 52 A2    jp   z,$A858
;A835: C3 4C A2    jp   $A846
;A838: CD F8 AA    call opponent_starting_high_attack_AAF2
;A83B: A7          and  a
;A83C: CA 4C A2    jp   z,$A846
;A83F: CD 33 AB    call perform_foot_sweep_if_level_3_AB99
;A842: A7          and  a
;A843: C2 55 A2    jp   nz,$A855
;A846: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;; move back / block possible attack
;A849: 36 01       ld   (hl),$01
;A84B: C3 55 A2    jp   $A855		; and opponent has some time to react...
;
cpu_reacts_to_low_attack_if_facing_else_attacks_A80C:
	move.w	fine_distance(a4),d0
	btst	#7,d0
	bne.b	pick_cpu_attack_A802
	bsr		opponent_starting_low_kick_AB08
	tst		d0
	beq.b	.not_low_kick
	; react to low kick, but not at first level
	bsr.b	perform_jumping_side_kick_if_level_2_AB88
	tst		d0
	bne.b	cpu_move_decided_opponent_can_react_A3E4	; attack triggered
.not_low_kick
	bsr.b	opponent_starting_low_attack_AAFD
	tst		d0
	beq.b	.not_low_attack
	;; react to foot sweep/low kick
	DECIDE_MOVE	JUMP
	move.b	randomness_timer,d0
	and.b	#3,d0
	beq.b	cpu_move_done_A410		; jumps to avoid 1 time out of 4
.move_back
	DECIDE_MOVE	BACK		; else moves back
	bra.b	cpu_move_decided_opponent_can_react_A3E4
.not_low_attack
	bsr.b	opponent_starting_high_attack_AAF2
	tst		d0
	beq.b	.move_back
	bsr.b	perform_foot_sweep_if_level_3_AB99
	tst		d0
	beq.b	.move_back
	bra.b	cpu_move_decided_opponent_can_react_A3E4
	
;; routine duplicated a lot... pick an attack fails if 0 (which never happens)
;A84E: CD 8E AB    call select_cpu_attack_AB2E
;A851: A7          and  a
;A852: CC D5 B0    call z,display_error_text_B075
;A855: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4
;
;A858: C3 10 A4    jp   cpu_move_done_A410
;
;; if not facing, check if low attack: if low attack jump or move back/block (50%)
;;                 if not low attack, then perform foot sweep if level >=3 else back
;; if facing, select an attack
;cpu_react_to_low_attack_or_perform_attack_A85B:
;A85B: FD CB 0F DE bit  7,(iy+$0f)
;A85F: CA 2C A2    jp   z,$A886
;; not facing each other
;A862: CD F7 AA    call opponent_starting_low_attack_AAFD
;A865: A7          and  a
;A866: CA DB A2    jp   z,$A87B
;A869: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;; avoid low attack by jump 50% of the time
;A86C: 36 09       ld   (hl),$03
;A86E: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
;A871: CB 47       bit  0,a
;A873: C2 30 A2    jp   nz,$A890
;; else move back/block if player attacks
;A876: 36 01       ld   (hl),$01
;A878: C3 27 A2    jp   $A88D
;; not starting low attack: 
;; move back/block unless skill level >= 3 in which case attacks with foot sweep
;A87B: CD 33 AB    call perform_foot_sweep_if_level_3_AB99
;A87E: C2 27 A2    jp   nz,$A88D
;; move back/block
;A881: 36 01       ld   (hl),$01
;A883: C3 27 A2    jp   $A88D
;
cpu_react_to_low_attack_or_perform_attack_A85B
	move.w	fine_distance(a4),d0
	btst	#7,d0
	beq.b	pick_cpu_attack_A802
	; not facing
	bsr.b		opponent_starting_low_attack_AAFD
	tst		d0
	beq.b	.counter_low_attack


.counter_low_attack
	bsr		perform_foot_sweep_if_level_3_AB99
	tst		d0
	bne.b	cpu_move_decided_opponent_can_react_A3E4
	; low skill level, just parry
	DECIDE_MOVE	JUMP
	btst	#0,randomness_timer
	bne.b	cpu_move_done_A410
	bra.b	perform_walk_back_A946
	
;; facing each other... pick an attack
;A886: CD 8E AB    call select_cpu_attack_AB2E
;;;A889: A7          and  a
;;;A88A: CC D5 B0    call z,display_error_text_B075	; can't happen
;A88D: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4
;
;A890: C3 10 A4    jp   cpu_move_done_A410
;

	

;cpu_small_chance_of_low_kick_else_walk_A893:
;A893: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;; decide a low kick once out of 8 ticks (12% chance of low kick)
;A896: 36 14       ld   (hl),$14
;A898: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
;A89B: E6 0D       and  $07
;A89D: CA A5 A2    jp   z,$A8A5
;; just walk
;A8A0: 36 08       ld   (hl),$02
;A8A2: C3 10 A4    jp   cpu_move_done_A410
;
;A8A5: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4
;
cpu_small_chance_of_low_kick_else_walk_A893:
	DECIDE_MOVE	LOW_KICK
	move.b	randomness_timer,d0
	and.b	#7,d0
	beq.b	cpu_move_decided_opponent_can_react_A3E4
	DECIDE_MOVE	FORWARD
	bra.b	cpu_move_decided_opponent_can_react_A3E4

;
;high_attack_if_forward_sommersault_or_walk_A8AB: 
;A8AB: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A8AE: FD CB 0F DE bit  7,(iy+$0f)
;A8B2: C2 6F A2    jp   nz,$A8CF
;; not turning backs to each other
;A8B5: E5          push hl
;A8B6: DD 21 3B AA ld   ix,forward_sommersault_frame_list_end_AA9B
;A8BA: FD 6E 0B    ld   l,(iy+$0b)
;A8BD: FD 66 06    ld   h,(iy+$0c)
;A8C0: CB BC       res  7,h
;A8C2: CD 03 B0    call check_hl_in_ix_list_B009
;A8C5: A7          and  a
;A8C6: E1          pop  hl
;A8C7: C2 6F A2    jp   nz,$A8CF		; end of forward sommersault: attack
;; just walk forward
;A8CA: 36 08       ld   (hl),$02
;A8CC: C3 E5 A2    jp   $A8E5	; cpu_move_done_A410
;
high_attack_if_forward_sommersault_or_walk_A8AB
	move.w	fine_distance(a4),d0
	btst	#7,d0
	bne.b	.attack
	; check if opponent is performing forward sommersault and what is
	; the frame counter
	bsr		identify_opponent_current_move_AB1D
	cmp.w	#ATTACK_SOMMERSAULT,d0
	bne.b	just_walk_A7C5
	; sommersault, but which frame
	move.l	opponent(a4),a3
	move.w	frame(a3),d0
	cmp.w	#7*PlayerFrame_SIZEOF,d0		; 3 last frames
	bcs.b	just_walk_A7C5
.attack
;; odds: lunge (0 - 25%), jumping kick (2,3 - 50%), round kick (1 - 25%)
;A8CF: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
;A8D2: 36 10       ld   (hl),$10		; rear+up lunge punch
;A8D4: E6 09       and  $03
;A8D6: CA E8 A2    jp   z,$A8E2
;A8D9: 36 07       ld   (hl),$0D		; rather a jumping side kick
;A8DB: FE 01       cp   $01
;A8DD: CA E8 A2    jp   z,$A8E2
;A8E0: 36 0F       ld   (hl),$0F		; rather a round kick
;A8E2: C3 10 A4    jp   cpu_move_done_A410
;
	move.b	randomness_timer,d0
	DECIDE_MOVE	LUNGE_PUNCH_600
	and.b	#3,d0
	beq.b	cpu_move_done_A410
	DECIDE_MOVE	JUMPING_SIDE_KICK
	cmp.b	#1,d0
	beq.b	cpu_move_done_A410
	DECIDE_MOVE	ROUND_KICK
	bra.b	cpu_move_done_A410

;move_fwd_or_bwd_checking_sommersault_and_dir_A8E8: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A8EB: FD CB 0F DE bit  7,(iy+$0f)
;A8EF: CA 06 A3    jp   z,$A90C		; not turning back to each other: goto "move back/block"
;A8F2: E5          push hl
;; check if opponent is performing sommersault (back) while
;; turning backs to each other
;A8F3: DD 21 A3 AA ld   ix,backwards_sommersault_frame_list_end_AAA9
;A8F7: FD 6E 0B    ld   l,(iy+$0b)
;A8FA: FD 66 06    ld   h,(iy+$0c)
;A8FD: CB BC       res  7,h
;A8FF: CD 03 B0    call check_hl_in_ix_list_B009
;A902: A7          and  a
;A903: E1          pop  hl
;A904: C2 06 A3    jp   nz,$A90C
;; not performing sommersault: move forward
;A907: 36 08       ld   (hl),$02		; move forward
;A909: C3 0E A3    jp   $A90E
;; opponent is performing back sommersault when same facing
;; direction: move back to avoid being a target to rear attack when opponent lands
;A90C: 36 01       ld   (hl),$01		; move back
;A90E: C3 10 A4    jp   cpu_move_done_A410
;
move_fwd_or_bwd_checking_sommersault_and_dir_A8E8:
	move.w	fine_distance(a4),d0
	btst	#7,d0
	beq.b	perform_walk_back_A946

	; the frame counter
	bsr		identify_opponent_current_move_AB1D
	cmp.w	#ATTACK_SOMMERSAULT_BACK,d0
	bne.b	perform_walk_back_A946
	; sommersault, but which frame
	move.l	opponent(a4),a3
	move.w	frame(a3),d0
	cmp.w	#7*PlayerFrame_SIZEOF,d0		; 4 last frames (there are 11 frames)
	bcs.b	perform_walk_back_A946
	bra.b	just_walk_A7C5
	
;get_out_of_edge_or_low_kick_A917: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A91A: 36 14       ld   (hl),$14	; low kick
;A91C: FD 7E 03    ld   a,(iy+$09)	; opponent x
;A91F: FE 90       cp   $30		; if opponent almost completely on the left, don't attack, perform sommersault
;A921: D2 83 A3    jp   nc,$A929
;A924: 36 1D       ld   (hl),$17	; sommersault
;A926: C3 10 A4    jp   cpu_move_done_A410	; immediate (it's not an attack)
;A929: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4	; opponent can react to low kick
;
get_out_of_edge_or_low_kick_A917:
	DECIDE_MOVE	LOW_KICK
	move.l	opponent(a4),a3
	move.w	xpos(a3),d0
	cmp.w	#$30-$20,d0		; there's a $20 offset in the arcade game that we don't have here
	bcs.b	cpu_move_decided_opponent_can_react_A3E4
	DECIDE_MOVE	FRONT_SOMMERSAULT
	bra.b	cpu_move_done_A410
;
;perform_low_kick_A935: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A938: 36 14       ld   (hl),$14
;A93A: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4
;
perform_low_kick_A935:
	DECIDE_MOVE	LOW_KICK
	bra.b	cpu_move_decided_opponent_can_react_A3E4
	
;
;perform_walk_back_A946:
;A946: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A949: 36 01       ld   (hl),$01
;A94B: C3 10 A4    jp   cpu_move_done_A410
;
perform_walk_back_A946:
	DECIDE_MOVE	BACK
	bra.b	cpu_move_done_A410
	
;front_kick_or_fwd_sommersault_to_recenter_A94E: 
; 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;; front kick
;A951: 36 0A       ld   (hl),$0A
;A953: FD 7E 03    ld   a,(iy+$09)		; C209: white player x coordinate
;A956: FE 90       cp   $30		; far left?
;A958: D2 C0 A3    jp   nc,$A960
;; front sommersault if player x < $30 to get outside the border
;A95B: 36 1D       ld   (hl),$17
;A95D: C3 10 A4    jp   cpu_move_done_A410
;A960: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4

front_kick_or_fwd_sommersault_to_recenter_A94E:
	DECIDE_MOVE	FRONT_KICK_OR_REVERSE_PUNCH
	move.l	opponent(a4),a3
	move.w	xpos(a3),d0
	cmp.w	#$30-$20,d0
	bcc.b	cpu_move_decided_opponent_can_react_A3E4
	DECIDE_MOVE		FRONT_SOMMERSAULT
	bra.b	cpu_move_done_A410

;
;
;cpu_complex_reaction_to_front_attack_A980:
;A980: FD CB 0F DE bit  7,(iy+$0f)
;A984: C2 BB A3    jp   nz,$A9BB
;; facing each other
;A987: CD 02 AB    call opponent_starting_low_kick_AB08
;A98A: A7          and  a
;A98B: CA 35 A3    jp   z,$A995
;; react to low kick by jumping back kick if not facing
;A98E: CD AA AB    call perform_jumping_back_kick_ABAA
;A991: A7          and  a
;A992: C2 79 A3    jp   nz,$A9D3	; always true
;A995: CD F7 AA    call opponent_starting_low_attack_AAFD
;A998: A7          and  a
;A999: CA A6 A3    jp   z,$A9AC
;; opponent is starting low attack
;A99C: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A99F: 36 09       ld   (hl),$03	; jump to avoid low attack
;A9A1: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
;A9A4: E6 09       and  $03
;A9A6: CA 70 A3    jp   z,$A9D0	; 25% chance: jump to avoid low attack
;A9A9: C3 61 A3    jp   $A9C1	; 75% chance: turn back
;A9AC: CD F8 AA    call opponent_starting_high_attack_AAF2
;A9AF: CA 61 A3    jp   z,$A9C1
;; react to high attack by foot sweep
;A9B2: CD BB AB    call perform_foot_sweep_back_ABBB
;A9B5: C2 79 A3    jp   nz,$A9D3		; always true: end move
;A9B8: C3 61 A3    jp   $A9C1
;; not facing each other
;A9BB: CD 8E AB    call select_cpu_attack_AB2E
;A9BE: C2 79 A3    jp   nz,$A9D3
;A9C1: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A9C4: 36 0D       ld   (hl),$07
;A9C6: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
;A9C9: CB 47       bit  0,a
;A9CB: CA 70 A3    jp   z,$A9D0
;; turn back or walk forward (50% chance)
;A9CE: 36 08       ld   (hl),$02
;A9D0: C3 10 A4    jp   cpu_move_done_A410
;A9D3: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4

cpu_complex_reaction_to_front_attack_A980:
	move.w	fine_distance(a4),d0
	btst	#7,d0
	bne.b	.not_facing
	; facing each other with a reaction to a front attack at this distance
	; seems impossible to reach on MAME
	bsr		opponent_starting_low_kick_AB08
	
.not_facing
	; happens when opponent attacks in the opposite
	; direction mostly..., but what's the use??

;; not facing each other	
.facing
	bsr	select_cpu_attack_AB2E
	tst	d0
	bne.b	cpu_move_decided_opponent_can_react_A3E4
	DECIDE_MOVE	TURN_AROUND
	btst	#0,randomness_timer		; 50% chance
	beq.b	cpu_move_done_A410
	DECIDE_MOVE	FORWARD
	bra.b	cpu_move_done_A410
;
;cpu_complex_reaction_to_rear_attack_A9D6: FD CB 0F DE
;A9D6: bit  7,(iy+$0f)
;A9DA: CA FE A3    jp   z,pick_cpu_attack_A9FE
;A9DD: CD F7 AA    call opponent_starting_low_attack_AAFD
;A9E0: A7          and  a
;A9E1: CA F4 A3    jp   z,$A9F4
;; starting low attack: jump to avoid it (75% chance)
;; or turn back (25% chance)
;A9E4: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;A9E7: 36 09       ld   (hl),$03
;A9E9: 3A 8E 60    ld   a,(periodic_counter_16bit_C02E)
;A9EC: E6 09       and  $03
;A9EE: CA 0A AA    jp   z,$AA0A
;A9F1: C3 05 AA    jp   $AA05
;; not starting low attack: perform foot sweep
;A9F4: CD BB AB    call perform_foot_sweep_back_ABBB
;A9F7: A7          and  a
;A9F8: C2 07 AA    jp   nz,$AA0D		; always true
;A9FB: C3 05 AA    jp   $AA05	; never reached
cpu_complex_reaction_to_rear_attack_A9D6:
	move.w	fine_distance(a4),d0
	btst	#7,d0
	beq.b	pick_cpu_attack_A802	;; facing each other: pick an attack
	bsr.b	opponent_starting_low_attack_AAFD
	tst		d0
	beq.b	foot_sweep_back_AA10
	DECIDE_MOVE	JUMP
	move.b	randomness_timer,d0
	and.b	#3,d0
	beq.b	cpu_move_done_A410
	DECIDE_MOVE	TURN_AROUND
	bra.b	cpu_move_done_A410
	
;; turn back
;AA05: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;AA08: 36 0D       ld   (hl),$07
;AA0A: C3 10 A4    jp   cpu_move_done_A410
;AA0D: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4
;


;AA10: CD BB AB    call perform_foot_sweep_back_ABBB
;;;AA13: A7          and  a
;;;AA14: C2 1F AA    jp   nz,$AA1F	; always true
;;;AA17: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;;;AA1A: 36 0D       ld   (hl),$07
;;;AA1C: C3 10 A4    jp   cpu_move_done_A410
;AA1F: C3 E4 A9    jp   cpu_move_decided_opponent_can_react_A3E4
;AA22: C3 CE A3    jp   pick_cpu_attack_A96E
;
foot_sweep_back_AA10
	DECIDE_MOVE	FOOT_SWEEP_BACK
	bra.b	cpu_move_decided_opponent_can_react_A3E4

cpu_move_turn_around_A966:
cpu_turn_back_AA25:
cpu_turn_back_AA33:
;AA33: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;AA36: 36 0D       ld   (hl),$07
;AA38: C3 10 A4    jp   cpu_move_done_A410
	DECIDE_MOVE	TURN_AROUND
	bra		cpu_move_done_A410
;
;; collection of tables exploited by B009 at various points of the A.I. code
;; probably specific animation frames of techniques so the computer
;; can counter attack / react on them
;; 
;; for example 890A (0A89 first item of the first list) is: stand guard facing left
;; facing right this would be 8A89
;; 8B22 would be the value in C22B if player starts a jump (joy up) facing right
;
;walk_frames_list_AA3B:
;	dc.b	89 0A 92 0A 9B 0A A4 0A AD 0A B6 0A BF 0A C8 0A FF FF
;jump_frames_list_AA4D:
;	dc.b	$22 0B 8E 0B 97 0B A0 0B A9 0B B2 0B BB 0B C4 0B CD 0B D6 0B DF 0B E8 0B F1 0B FA 0B 73 0B FF FF
;	; frames where the blow reaches its end/is full blown
;hitting_frame_list_AA6D:
;	dc.b	$C0 0C D2 0C 47 0D D7 0D 4C 0E AF 0E 1B 0F 90 0F 0E 10 9E 10 0A 11 6D 11 E2 11 D5 12 4A 13 FF FF
;block_frame_list_AA8D:
;	dc.b	$88 1A D0 1A 18 1B FF FF
;forward_sommersault_frame_list_AA95:
;	dc.b	$AD 13 B6 13 BF 13
;forward_sommersault_frame_list_end_AA9B
;	dc.b	C8 13 D1 13 DA 13 E3 13 FF FF
;backwards_sommersault_frame_list_AAA5:
;	dc.b	$45 12 4E 12	; includes the follwing frames
;backwards_sommersault_frame_list_end_AAA9:
;	dc.b	57 12 60 12 72 12 7B 12 FF FF
;; player gets down, including foot sweep
;crouch_frame_list_AAB3:
;	dc.b	27 0C E0 0D A7 10 DE 12 FF FF
;
;; some other tables loaded by the code below (accessed by a table too)
;; one byte per attack, match ATTACK_* defines above

table_AABD:
	dc.b	$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$FF
table_AAC9
	dc.b	$01,$02,$03,$FF
table_high_attacks_AACD
	dc.b	$02,$06,$08,$0A,$0B,$0C,$FF
table_low_attacks_AAD4
	dc.b	$03,$09,$0E,$FF
table_sommersaults_AAD8
	dc.b	$10,$11,$12,$FF
	even
;
;
;opponent_starting_frontal_attack_AADC
;AADC: CD 17 AB    call identify_opponent_current_move_AB1D
;AADF: DD 21 B7 AA ld   ix,table_AABD
;AAE3: CD 0F B0    call table_linear_search_B00F
;AAE6: C9          ret
;
opponent_starting_frontal_attack_AADC:
	bsr		identify_opponent_current_move_AB1D
	lea		table_AABD(pc),a0
	bra.b	table_linear_search_B00F
	
;; rear attack but not low attack. Just back kick jumping back kick
;opponent_starting_rear_attack_AAE7
;AAE7: CD 17 AB    call identify_opponent_current_move_AB1D
;AAEA: DD 21 63 AA ld   ix,table_AAC9
;AAEE: CD 0F B0    call table_linear_search_B00F
;AAF1: C9          ret
;
opponent_starting_rear_attack_AAE7:
	bsr		identify_opponent_current_move_AB1D
	lea		table_AAC9(pc),a0
	bra.b	table_linear_search_B00F

;opponent_starting_high_attack_AAF2
;AAF2: CD 17 AB    call identify_opponent_current_move_AB1D
;AAF5: DD 21 67 AA ld   ix,table_high_attacks_AACD
;AAF9: CD 0F B0    call table_linear_search_B00F
;AAFC: C9          ret
;
opponent_starting_high_attack_AAF2:
	bsr		identify_opponent_current_move_AB1D
	lea		table_high_attacks_AACD(pc),a0
	bra.b	table_linear_search_B00F

;opponent_starting_low_attack_AAFD:
;AAFD: CD 17 AB    call identify_opponent_current_move_AB1D
;AB00: DD 21 74 AA ld   ix,table_low_attacks_AAD4
;AB04: CD 0F B0    call table_linear_search_B00F
;AB07: C9          ret
;
opponent_starting_low_attack_AAFD:
	bsr.b		identify_opponent_current_move_AB1D
	lea		table_low_attacks_AAD4(pc),a0
	bra.b	table_linear_search_B00F

;; return a != 0 if current frame is $0E (low kick)
;opponent_starting_low_kick_AB08
;AB08: CD 17 AB    call identify_opponent_current_move_AB1D
;AB0B: FE 0E       cp   $0E
;AB0D: CA 11 AB    jp   z,$AB11
;AB10: AF          xor  a
;AB11: C9          ret
;
opponent_starting_low_kick_AB08:
	bsr.b		identify_opponent_current_move_AB1D
	cmp.b	#ATTACK_LOW_KICK,d0
	beq.b	.out
	moveq	#0,d0
.out
	rts
	
;opponent_starting_a_jump_AB12
;AB12: CD 17 AB    call identify_opponent_current_move_AB1D
;AB15: DD 21 72 AA ld   ix,table_sommersaults_AAD8
;AB19: CD 0F B0    call table_linear_search_B00F
;AB1C: C9          ret
;
opponent_starting_a_sommersault_AB12
	bsr.b		identify_opponent_current_move_AB1D
	lea		table_sommersaults_AAD8(pc),a0
	bra.b	table_linear_search_B00F

;; iy=C220, loads ix with current frame pointer of opponent, then
;; identifies opponent exact frame/move (starting move probably)
;identify_opponent_current_move_AB1D:
;; load current frame pointer
;AB1D: FD 4E 0B    ld   c,(iy+$0b)
;AB20: FD 46 06    ld   b,(iy+$0c)
;; remove direction bit
;AB23: CB B8       res  7,b
;AB25: C5          push bc
;AB26: DD E1       pop  ix
;; load at offset 8 to get move id. Ex 4 = front kick
;AB28: DD 7E 02    ld   a,(ix+$08)
;AB2B: CB BF       res  7,a
;AB2D: C9          ret

; > D0.W: ATTACK_* enumerate
identify_opponent_current_move_AB1D:
	move.l	opponent(a4),a3
	move.l	current_move_header(a3),a3
	move.w	attack_id(a3),d0
	rts
	

;
; > D0: nonzero if attacking, else zero
pick_cpu_attack_A802
pick_cpu_attack_A96E
	bsr.b	select_cpu_attack_AB2E
	bra.b	cpu_move_decided_opponent_can_react_A3E4
	
;
;
;
;perform_jumping_side_kick_if_level_2_AB88:
;AB88: 3A 10 63    ld   a,(computer_skill_C910)
;AB8B: FE 01       cp   $01
;AB8D: 3E 00       ld   a,$00
;AB8F: DA 32 AB    jp   c,$AB98
;; if level >= 1, perform jumping side kick, else do nothing
;AB92: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;AB95: 3E 07       ld   a,$0D
;AB97: 77          ld   (hl),a
;AB98: C9          ret
;
perform_jumping_side_kick_if_level_2_AB88:
	move.l	opponent(a4),a3
	move.w	rank(a3),d0
	cmp.w	#1,d0
	bcs.b	.do_nothing
	DECIDE_MOVE	JUMPING_SIDE_KICK
	st		d0
.do_nothing
	moveq.l	#0,d0
	rts
	
;; reacting to jumping side kick at close distance
;perform_foot_sweep_if_level_3_AB99: 
;AB99: 3A 10 63    ld   a,(computer_skill_C910)
;AB9C: FE 08       cp   $02
;AB9E: 3E 00       ld   a,$00
;ABA0: DA A3 AB    jp   c,$ABA9
;; if level >= 2 perform a foot sweep
;ABA3: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;ABA6: 3E 0E       ld   a,$0E
;ABA8: 77          ld   (hl),a
;ABA9: C9          ret
;
; > A4 player structure
; <>: D7: change to foot sweep if rank 2 (level 3)
; > D0: 0 if d7 has not changed
perform_foot_sweep_if_level_3_AB99
	move.l	opponent(a4),a3
	move.w	rank(a3),d0
	cmp.w	#2,d0
	bcs.b	.do_nothing
	DECIDE_MOVE	FOOT_SWEEP_FRONT_1
	st		d0
.do_nothing
	moveq.l	#0,d0
	rts
	
;perform_jumping_back_kick_ABAA:  
;; useless, skill level is always >= 0
;; maybe difficulty was pumped up since kchamp
;; asm used defines for a level threshold
;;;ABAA: 3A 10 63   ld   a,(computer_skill_C910)
;;;ABAD: FE 00       cp   $00
;;;ABAF: 3E 00       ld   a,$00
;;;ABB1: DA BA AB    jp   c,$ABBA		
;ABB4: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;ABB7: 3E 02       ld   a,$08
;ABB9: 77          ld   (hl),a
;ABBA: C9          ret
;
perform_jumping_back_kick_ABAA:
	DECIDE_MOVE	JUMPING_BACK_KICK
	rts

;perform_foot_sweep_back_ABBB
;; useless, skill level is always >= 0
;;;ABBB: 3A 10 63    ld   a,(computer_skill_C910)
;;;ABBE: FE 00       cp   $00
;;;ABC0: 3E 00       ld   a,$00
;;;ABC2: DA 6B AB    jp   c,$ABCB
;ABC5: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;ABC8: 3E 03       ld   a,$09
;ABCA: 77          ld   (hl),a
;ABCB: C9          ret
;
perform_foot_sweep_back_ABBB:
	DECIDE_MOVE	FOOT_SWEEP_BACK
	rts
	
;; computer is jumping
;handle_cpu_land_from_jump_ABCC: FD 6E 0D    ld   l,(iy+$07)
;ABCF: FD 66 02    ld   h,(iy+$08)
;ABD2: 11 D9 0B    ld   de,$0B73
;ABD5: A7          and  a
;ABD6: ED 52       sbc  hl,de
;ABD8: C2 E0 AB    jp   nz,$ABE0
;ABDB: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;; land if reaches a given point
;ABDE: 36 00       ld   (hl),$00
;ABE0: C3 10 A4    jp   cpu_move_done_A410
;
;; computer just tried to hit player but failed
;; now wait for player response (or not, if skill level is high enough)
full_blown_hit_ABE3:
	; hack current frame countdown: either it's infinite (negative)
	; for human player, or it's short (attack jumps) when in low
	; skill levels, the game freezes cpu attack even on jumps
	; to give a chance to the player to counter attack
	lea		counter_attack_time_table_ADEF(pc),a0
	bsr	let_opponent_react_depending_on_skill_level_ACCE
	
	; lousy check to see if the value has already been set in
	; the previous call
	; it can happen in jump attacks when full blown hit doesn't
	; have -1 as frame countdown value
	cmp.w	current_frame_countdown(a4),d0
	beq.b	.no_reload	
	addq.w	#1,d0		; add 1 as 0 would be a problem
	move.w	d0,current_frame_countdown(a4)
.no_reload
	move.w	computer_next_attack(a4),d7
	bra		cpu_move_done_A410
	
;ABE3: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;; tell CPU to stop moving / stand guard
;ABE6: 36 00       ld   (hl),$00
;ABE8: 21 EF A7    ld   hl,counter_attack_time_table_ADEF
;ABEB: CD 6E A6    call let_opponent_react_depending_on_skill_level_ACCE
;ABEE: FE 03       cp   $09
;ABF0: CA DB A9    jp   z,fight_mainloop_A37B
;ABF3: A7          and  a
;ABF4: CA F6 AB    jp   z,$ABFC
;ABF7: FE FF       cp   $FF
;ABF9: C4 D5 B0    call nz,display_error_text_B075
;ABFC: C3 10 A4    jp   cpu_move_done_A410
;

;
;; blocks a given number of frames (depending on table and level) during which
;; the opponent has time to pre-react before the computed already decided 
;; attack is launched
;; < hl pointer on a 4 pointer table containing each $20 values of data; each
;; table corresponds to a difficulty setting (4 total)
;; if upper-hard championship level >= 16: no time for player to react just before
;; an attack
;; > a: $00: attacks
;; > a: $09: doesn't attack
;let_opponent_react_depending_on_skill_level_ACCE:
;ACCE: 3A 10 63    ld   a,(computer_skill_C910)
;ACD1: FE 10       cp   $10
;ACD3: 3E 00       ld   a,$00
;ACD5: D2 1C A7    jp   nc,$AD16		; if level >= $10, skip the routine altogether
;
;; this is called when skill level is < 16 (under high level of champ)
;; game checks difficulty level at that point
;; (in CMP high mode it doesn't matter)
;ACD8: 3A 90 60    ld   a,(dip_switches_copy_C030)
;ACDB: CB 3F       srl  a
;ACDD: CB 3F       srl  a
;ACDF: CB 3F       srl  a
;ACE1: E6 0C       and  $06
;; a = 0: difficulty: easy
;; a = 2: difficulty: medium
;; a = 4: difficulty: hard
;; a = 6: difficulty: hardest
;ACE3: 06 00       ld   b,$00
;ACE5: 4F          ld   c,a
;ACE6: 09          add  hl,bc
;ACE7: 5E          ld   e,(hl)
;ACE8: 23          inc  hl
;ACE9: 56          ld   d,(hl)
;; proper table (matching skill level) is loaded in de
;; one of the table addresses is $AD8F for instance
;; check skill level again
;ACEA: 3A 10 63    ld   a,(computer_skill_C910)
;ACED: CB 27       sla  a	; times 2
;ACEF: 6F          ld   l,a
;ACF0: 26 00       ld   h,$00
;; offset for the byte value in the table
;ACF2: 19          add  hl,de
;; check those mysterious C148, C149 values that look = 0
;; everywhere in the code it seems that the only thing that is done with
;; them is that they're set to 0 so the code below is useless
;; (a!=b!=0 would tone the difficulty down slightly, letting the program
;; pick the delay value before the current one
;ACF3: 3A 42 61    ld   a,($C148)
;ACF6: 47          ld   b,a
;ACF7: 3A 4D 61    ld   a,($C147)
;ACFA: B0          or   b
;ACFB: CA FF A6    jp   z,$ACFF	; a=b=0: don't increase hl (harder)
;ACFE: 23          inc  hl
;ACFF: 7E          ld   a,(hl)
;AD00: 47          ld   b,a
;AD01: A7          and  a
;AD02: 3E 00       ld   a,$00	; return value if a<=0
;AD04: CA 1C A7    jp   z,$AD16	; if a=0, exit, attack immediately
;AD07: FA 1C A7    jp   m,$AD16	; if a<0 exit, attack immediately
;; a was strictly positive
;AD0A: 78          ld   a,b	; restore read value of a (number of waiting frames)
;AD0B: A7          and  a
;AD0C: CC D5 B0    call z,display_error_text_B075	; can't happen! we just testedf it
;AD0F: FD E5       push iy
;; this can block cpu moves up to 1/2 second at low skill level
;AD11: CD 13 A7    call let_opponent_react_AD19
;AD14: FD E1       pop  iy
;AD16: C9          ret
;
;
;; never called in CMP hardest mode (level >= 16)
;; < b # of frames to wait for opponent reaction. 30 frames = 1/2 second (easiest setting)
;; > a:00 no opponent reaction
;;    :09 opponent reacted with a jump (front/back) (from observation)
;;    :ff opponent reacted with some other attack(exits before timeout)
;;
;; to clock that, I've used MAME breakpoint commands
;; bpset AD19,1,{printf "enter: "; time; g}
;; bpset AD64,1,{printf "exit: %02x ",a; time; g}
;

; this is used for computer reaction, but also in a different way
; for animation speedup depending on the difficulty level
;
; for animation, only negative values are considered. Positive values
; are seen as 0 (no frame count decrease = no speed increase)
;
; for reaction time, negative values count as 0 (no time to react
; after a CPU attack)
;
counter_attack_time_table_AD67:
	dc.l	counter_attack_timers_AD6F		; easy
	dc.l	counter_attack_timers_AD8F		; medium
	dc.l	counter_attack_timers_ADAF		; hard
	dc.l	counter_attack_timers_ADCF		; hardest
	
; $20 values per entry, number of frames to wait for opponent response
; just before cpu attacks (when an attack has been decided)
; first value matches skill 0, and so on. There are 24 levels, plus a 1 or 2
; handicap

counter_attack_timers_AD6F:
	dc.b	$30,$2D,$2A,$26,$23,$20,$1D,$1A
	dc.b	$17,$14,$10,$0D,$0A,$07,$04,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF
	dc.b	$FF,$FE,$FE,$FE,$FE,$FE,$FE,$FE
counter_attack_timers_AD8F:
	dc.b	$30,$26,$20,$1B,$17,$13,$10,$0D
	dc.b	$0B,$08,$06,$05,$03,$02,$01,$00,$00,$00,$00,$FF,$FF,$FF,$FE,$FE
	dc.b	$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
counter_attack_timers_ADAF:
	dc.b	$30,$20,$10,$0E,$0B,$09,$07,$06
	dc.b	$05,$04,$03,$02,$02,$01,$00,$00,$00,$00,$FF,$FF,$FE,$FE,$FE,$FE
	dc.b	$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
counter_attack_timers_ADCF:
	dc.b	$30,$14,$08,$07,$06,$05,$04,$03
	dc.b	$02,$02,$01,$01,$00,$00,$00,$00,$FF,$FF,$FF,$FE,$FE,$FE,$FE,$FE
	dc.b	$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
	 
counter_attack_time_table_ADEF:
	dc.l	counter_attack_timers_ADF7
	dc.l	counter_attack_timers_ADF7
	dc.l	counter_attack_timers_ADF7
	dc.l	counter_attack_timers_ADF7


; 16x2 values
counter_attack_timers_ADF7:
	dc.b	$20,$20,$18,$18,$18,$18,$10,$10,$08,$08,$07,$07,$06,$06,$04,$03
	dc.b	$02,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	
counter_attack_time_table_AE17:
	dc.l	counter_attack_timers_AE1F 
	dc.l	counter_attack_timers_AE1F 
	dc.l	counter_attack_timers_AE1F 
	dc.l	counter_attack_timers_AE1F 
	 
counter_attack_timers_AE1F:
	dc.b	$20,$20,$20,$20,$18,$18,$10,$10
	dc.b	$08,$08,$07,$07,$06,$06,$05,$05,$04,$04,$03,$03,$02,$02,$01,$01
	dc.b	$01,$01,$01,$01,$01,$01,$01,$01
	; below probably not reached
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00

	even

; < A0: table of byte values, end with $FF
; < D0: value to search for
; > D0: 0 if not found, 1 if found
; trashes: D6, A0
table_linear_search_B00F
	move.b	(a0)+,d6
	bmi.b	.not_found
	cmp.b	d0,d6
	bne.b	table_linear_search_B00F
	; found
	moveq.l	#1,d0
	rts
	
.not_found
	moveq.l	#0,d0
	rts
	
;; > a: attack id (cf table at start of the source file)
;; but this routine cannot return 0 because tables it points to don't contain 0
;; furthermore, this routine is sometimes followed by a sanity check crashing with
;; an error message if a is 0 on exit. Since it's random, how could the sanity check NOT fail?
;;
;; injecting values performs the move... or the move is discarded by caller
;
;select_cpu_attack_AB2E:
;AB2E: DD 21 52 AB ld   ix,master_cpu_move_table_AB58		; table of pointers of move tables
;; choose the proper move list depending on facing & distance
;AB32: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)	; <= C26B
;AB35: 23          inc  hl
;AB36: 7E          ld   a,(hl)	; get value in C26C: facing configuration
;AB37: 87          add  a,a
;AB38: 4F          ld   c,a
;AB39: 06 00       ld   b,$00
;AB3B: DD 09       add  ix,bc
;AB3D: DD 6E 00    ld   l,(ix+$00)
;AB40: DD 66 01    ld   h,(ix+$01)
;; get msb of 16 bit counter for randomness
;AB43: ED 5B 8E 60 ld   de,(periodic_counter_16bit_C02E)
;AB47: 5E          ld   e,(hl)	; pick a number 0-value of hl (not included)
;AB48: 23          inc  hl	; skip number of values
;AB49: E5          push hl
;AB4A: CD 0C B0    call random_B006
;AB4D: E1          pop  hl
;AB4E: 06 00       ld   b,$00
;AB50: 4F          ld   c,a
;AB51: 09          add  hl,bc
;; gets CPU move to make
;AB52: 7E          ld   a,(hl)
;AB53: 2A 04 6F    ld   hl,(address_of_current_player_move_byte_CF04)
;; gives attack order to the CPU
;; only attack moves (not walk moves) are given here
;AB56: 77          ld   (hl),a
;AB57: C9          ret

select_cpu_attack_AB2E:
	move.w	rough_distance(a4),d0
	add.w	d0,d0
	add.w	d0,d0
	lea		master_cpu_move_table_AB58(pc),a0
	move.l	(a0,d0.w),a0		; selected attack table
	moveq.l	#0,d0
	move.b	(a0)+,d0
	bsr		randrange
	moveq	#0,d7
	move.b	(a0,d0.w),d7	; cpu attack move
	rts

; < A0: player_structure
; > D0: 1 if walking, 0 if not walking
is_walking_move:
	moveq.l	#0,d0
	move.l	current_move_header(a0),a0	
	move.l	right_frame_set(a0),a0		; current frame
	cmp.l	#walk_forward_right_frames,a0
	beq.b	.walking
	cmp.l	#forward_right_frames,a0
	beq.b	.walking
	cmp.l	#walk_backwards_right_frames,a0
	beq.b	.walking
	cmp.l	#backwards_right_frames,a0
	beq.b	.walking
	rts
.walking
	moveq	#1,d0
	rts
	
;; some moves are done or not depending on how the players are
;; located and if current player can reach opponent with a blow
;; (the CPU isn't going to perform a back move in the void)
;; the direction of opponent isn't considered here
;; (the 5 values relate to player struct + $0C)
;

master_cpu_move_table_AB58:
	dc.l  move_list_far_away_AB62	; far away (we don't care much about facing)
	dc.l  move_list_facing_mid_range_AB70		; mid-range, cpu faces opponent (who can face cpu or not...)
	dc.l  move_list_facing_close_range_AB7B		; close-range, cpu faces opponent
	dc.l  move_list_turning_back_AB84		; mid-range, cpu has its back turned on opponent
	dc.l  move_list_turning_back_AB84		; close-range, cpu has its back turned on opponent (same as above)
;
;; move list starts by number of moves (for random pick)
;; not the same move indexes as above, move indexes are listed at start of
;; document
move_list_far_away_AB62:
;	; 13 moves: back, jbk, footsweep, front kick/punch, back round, lunge, jsk, round, lunge, lunge, revpunch, lowk
;	; the move doesn't really matter as it cannot connect (too far)
	dc.b	$0D,MOVE_BACK_KICK,MOVE_JUMPING_BACK_KICK,MOVE_FOOT_SWEEP_BACK,MOVE_FRONT_KICK_OR_REVERSE_PUNCH
	dc.b	MOVE_BACK_ROUND_KICK,MOVE_LUNGE_PUNCH_400,MOVE_JUMPING_SIDE_KICK,MOVE_FOOT_SWEEP_FRONT_1,MOVE_ROUND_KICK
	dc.b	MOVE_LUNGE_PUNCH_600,MOVE_LUNGE_PUNCH_1000,MOVE_REVERSE_PUNCH_800,MOVE_LOW_KICK
;	; lunge backroundkick lungemedium jsk 0E(???) round lunge, lunge, revpunch, lowkick
move_list_facing_mid_range_AB70:
	dc.b	10,$0A,$0B,$0C,$0D,$0E,$0F,$10,$11,$13,$14
;	; front kick, back round, lungemedium, jsk, round, lunge, revpunch, lowkick
move_list_facing_close_range_AB7B
	; small reverse, back round, lungemediumj sk,...
	dc.b	 8,$0A,$0B,$0C,$0D,$0F,$10,$13,$14 
	; list of only reverse attacks (mostly defensive, cpu turns its back on the opponent)
	; back kick jbk foot sweep back
move_list_turning_back_AB84
	dc.b	3,$05,$08,$09
	
display_error_text_B075
	lea		.error_text(pc),a0
	move.w	#SCREEN_WIDTH/2-16,d0
	move.w	#NB_LINES/2-4,d1
	move.w	#$FFF,D2
	bsr		write_blanked_color_string
	illegal

.error_text
	dc.b	"ERROR",0
	even

	