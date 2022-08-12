This is a 1:1 attempt of a remake of Karate Champ VS on the Amiga 500

if crouch when end of foot sweep (back or front) 
then connect to crouch
crouch connects to reverse punch: implemented? check

jump special case just for jumping side kick (connect from jump)
jumping side kick y looks wrong: fix later (from video)
jump not correct
foot sweep on left displays on the right too  
				
rip girls side/end
rip evade obstacles (stone, breaking it, breaking plank)
rip evade sound
rip bull separate specific sprite sheet (left/right)

forward close walk animation is broken
optimization: do not check hits if player distance is too high


player 2 joypad controls


play & rip stage 2 2players stomach blow

check_if_facing_each_other not working

if py<(py_start-32) (not jumping)
if going left and 0<px-px_other<threshold, don't move left
if going right and 0<px_other-px<threshold
(group with test against xmax/xmin or compute xmin/xmax
at each update)

girl animation (easy) interruptible with fire!

- check back blow facing/not facing
- draw priority to the player which has an active hit to deliver (if possible)

cheatkey to allow being hit without falling, keep fighting

bugs

- against CPU player performs blocks without reason
- some blows don't connect (both players same direction): check debug pic
- when hit, player falls too fast
- weak reverse when distance is small: not working
- final timer countdown broken
- animation for win sequence to fix
- 2 player mode - 1ST - => 1ST   1ST non-cpu player with
  highest level leads the current stage: level_number refactoring by player
- win a round: timer not reset, points not reset
- 2p mode: missing score 1 - 0 ... etc.

evade sequence: 

plant high, bottle high, apple low, rock low, plank mid-back (+ mirror)
plant mid,bottle mid,apple high back,rock high back,book low back (+ probably mirror)

