This is a 1:1 attempt of a remake of Karate Champ VS on the Amiga 500

if crouch when end of foot sweep (back or front) 
then connect to crouch
crouch connects to reverse punch: implemented? check

				
rip evade obstacles (stone, breaking it, breaking plank)
rip evade sound



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

optimize "minus 48 to center character" 3 times!!!
bull
evade

rip evade level 4 rock
sequence: low rear mid front high rear mid front high rear

bugs

- game start: doesn't see previous joy button, then check - player2 start not working
- break planks sometimes breaks planks while away
- jumping side kick y looks wrong: fix later (from video)
- jump not correct
- copper: detect state change and reset state_timer
- bull add restore bg on right
- optimization: do not check hits if player distance is too high
- some blows don't connect (both players same direction): check debug pic
- when hit, player falls too fast
- win a round: timer not reset
- count how many rounds have been won... next level...
- win a round by KO: countdown doesn't work, points not reset
- clarify what to set to 0: start of round, start of fight, start of level
- check/fix consistency in options
- refactoring: create first_draw functions too/move first draws inside
- center display -16 left ddf if clipping is satisfactory


