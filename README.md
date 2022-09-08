This is a 1:1 attempt of a remake of Karate Champ VS on the Amiga 500

todo:

if crouch when end of foot sweep (back or front) 
then connect to crouch
crouch connects to reverse punch: implemented? check


if py<(py_start-32) (not jumping)
if going left and 0<px-px_other<threshold, don't move left
if going right and 0<px_other-px<threshold
(group with test against xmax/xmin or compute xmin/xmax
at each update)

- jump special case just for jumping side kick (connect from jump)
- check back blow facing/not facing (check_if_facing_each_other not working)
- draw priority to the player which has an active hit to deliver (if possible)
- demo add "player vs player" flashing
- 2p make rounds won flash (draw_score_box/erase_score_box) at start
- when lost, show girls + score (green background)
- A.I.
- evade: faster object frequency according to the level
  0: 78 4: 6E 8: 64 12: 5A 16: 55
bull

evade sequences:
sequence: low rear mid front high rear mid front high rear
sequence: 3x mid front, 2x high rear!!!

multiple evade objects: can be displayed at the same time

a.i investigate

end naming & commenting tables jump_table_A54F
what is C147, C148, C149, looks zeroed?
breakpoint at ACFE see if it's reached

try to reach A980? 
bpset A90C same direction try ommersault back
analyse condition of turn around in cpu_move_forward_towards_enemy_far_away_A6D4


memory watch on frames (16 bit) at start of A.I. mainloop
for instance 13C8 13D1 forward sommersault... vs C22B/C22C
bpset A849
; get more info about player_2_attack_flags_C028 what does the values mean (09,0A...)
; * figure out how select_cpu_attack_AB2E sequences are chosen
; (with other variable: address_of_cpu_move_byte_CF04)
; * check & understand ai jump tables of react_to_opponent_attack_A53B
; understand what 3DB7 does
; understand what A34D does
; * undestand A53B jump tables (react to opponent attack), confirm
; how exactly are computed values of C22F (player logical distance) to select jump tables
; break in A75D  A73F: when does it jump to A75D?? understand bit  7,(iy+$0f) aka C22F: facing each other if cleared
* recode A.I. from fight_mainloop_A390 entrypoint

bugs:

- adjust player x $20 (min x) and $DF (max x) so A.I. x/distance values can be used
- back round kick other direction than opponent: can't be done in normal mode (ok in evade): back kick instead
- jumping side kick one frame too high
- evade collisions: front ok, back move ko
- evade: player moves: trashes object update
- evade: sometimes random end to practice with start music... then crash...
- 2P game over player message: doesn't stay long enough
- test fight against cpu: win & lose
- when hit, player falls too fast
- demo/plank level scoring is complete bogus
- intro karateka wrong move (sometimes stuck x=0 on left) + pb erase
- break planks sometimes breaks planks while away
- bull add restore bg on right
- sometimes some blows don't connect: check debug pic
- check/fix consistency in options
- jump not correct
- optimization: do not check hits if player distance is too high
- reduce memory: collision maps as bits: would gain 50kb
- timeout win: no win animation
- practice: jumping back kick asked 2 times in the end (2 player)p



