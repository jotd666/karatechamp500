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

optimize "minus 48 to center character" 3 times!!!
bull

evade sequences:
sequence: low rear mid front high rear mid front high rear
sequence: 3x mid front, 2x high rear!!!

bugs:

- 2P red wins fight: score position wrong (x=0)
- evade collisions: front ok, back move ko (completely broken),
  doesn't award 200 points
  blocks player even in next level!!!
- evade: player moves: trashes object update
- 2 player mode controls mixup???
- game over player message: doesn't stay long enough
- cpu player wins: doesn't end, no game over... jumps and jumps: re-test
- try timeout win: win infini: re-test
- test fight against cpu: win & lose
- when hit, player falls too fast
- demo/plank level scoring is complete bogus
- human player red: never restarts fight/round when wins it

- intro karateka wrong move (stuck x=0 on left) + pb erase
- break planks sometimes breaks planks while away
- bull add restore bg on right
- optimization: do not check hits if player distance is too high
- some blows don't connect (both players same direction): check debug pic
- check/fix consistency in options
- jump not correct
- reduce memory: collision maps as bits: would gain 50kb



