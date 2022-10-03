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


- table at A529 dump it

- how much cpu holds block 
- fake fight in title screen
- demo in level 4 cpu vs cpu
- check cpu move speed from videos with varying skill level: no need: frame speed up
  has been reversed, now have to code it
- define debug variable so CPU only performs jump attacks
- define debug variable so CPU always jumps to avoid low kicks
- define debug variable where cpu blocks

bugs:

- computer should not move past player either (implement player x boundary
  when not jumping): should be able to perform weak reverse punch and hit:
  leave the computer come close without moving to test
- computer score doesn't show all the time
- when hit, player falls too fast: freeze frames
- tests jumps as it seems to fail... cpu tries to jump (?) several times
  before performing a ground attack
- jumping side kick cpu stays stuck (jumping back seems ok)
- hardest difficulty level seems to bug less...
- when hit in the air, player should fall down
- movement lock of player when opponent is hit doesn't seem to work
- jump: too short, maybe duplicate frame sequence
- evade collisions: front ok, back move ko (and trashes game)
- evade: player moves: trashes object update
- evade: sometimes random end to practice with start music... then crash...
- 2P game over player message: doesn't stay long enough
- demo/plank level scoring is complete bogus
- intro karateka wrong move (sometimes stuck x=0 on left) + pb erase
- break planks sometimes breaks planks while away
- bull add restore bg on right
- check/fix consistency in options
- optimization: do not check hits if player distance is too high
- reduce memory: collision maps as bits: would gain 50kb
- reduce memory: try to split frames into 3-4 strips of height 16
- timeout win: no win animation




