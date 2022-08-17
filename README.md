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

forward close walk animation is broken
optimization: do not check hits if player distance is too high


player 2 joypad controls


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
- final timer countdown: should wait a bit after countdown
- animation for win sequence to fix
- 2 player mode - 1ST - => 1ST   1ST non-cpu player with
  number of rounds won+1
- win a round: timer not reset
- count how many rounds have been won... next level...
- 2p mode: missing score 1 - 0 ... etc.
- win a round by KO: countdown doesn't work, points not reset
- clarify what to set to 0: start of round, start of fight, start of level
- player2 start not working


break planks:

all planks = 2000 + very good

snapshot just before planks
video planks frappe dans le vide: rip frames
check min/max x planks pour score min/max
easy dev:

bull
evade
girls
