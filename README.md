This is a 1:1 attempt of a remake of Karate Champ VS on the Amiga 500

if crouch when end of foot sweep (back or front) 
then connect to crouch
crouch connects to reverse punch: implemented? check

jump special case just for jumping side kick (connect from jump)
jumping side kick y looks wrong: fix later (from video)
jump not correct
foot sweep on left displays on the right too  
				
rip girls side/end
rip evade obstacles
rip breaking wood
rip bull separate specific sprite sheet (left/right)

forward close walk animation is broken
optimization do not check hits if player distance is too high

half/full point: either add one row of half points at the rightmost pos or replace rightmost hitpos
generate table with coords /2 + half/full point type

player 2 joypad controls


start screen with 1P/2P

play & rip stage 2 2players coup ventre

check_if_facing_each_other not working

controls blocked = time blocked (including before BEGIN) to check begin.
basically stage starts with control/time blocked

- check back blow facing/not facing
- controls blocked but keep the infinite technique a few frames
- draw priority to the player which has an active hit to deliver (if possible)

cheatkey to set time at 1
cheatkey to allow being hit without falling, keep fighting


evade sequence: plant high, bottle high, apple low, rock low, plank mid-back (+ mirror)

plant mid
bottle mid
apple high back
rock high back
book low back