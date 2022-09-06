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

bpset A896 (low kick)
bpset A8D2
bpset A849
bpset A90C rear sommersault (end of sommersault)
; * figure out how select_cpu_attack_AB2E sequences are chosen
; (with other variable: address_of_cpu_move_byte_CF04)
; * check & understand ai jump tables of react_to_opponent_attack_A53B
; * understand when cpu performs a back sommersault (it happens!! when both players
; aren't facing and all located on the left side... very rare)
; understand what 3DB7 does
; understand what A34D does
; * undestand A53B jump tables (react to opponent attack), confirm
  values of C22F (player logical distance) to select jump tables
; understand A3E4 (most routines end there)
; figure out what C911 contains/means (tested in A3E4)
; break in A75D  A73F: when does it jump to A75D?? understand bit  7,(iy+$0f) aka C22F: facing each other if cleared
* recode A.I. from fight_mainloop_A390 entrypoint

bugs:

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



