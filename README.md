This is a 1:1 attempt of a remake of Karate Champ VS on the Amiga 500

try to add more colors (stage 1 gray)
-1 infinite position lock (round kick)
last frame should always be first frame
rollback only at start, add flags  dc.w	0,0,6,0,0,0 => dc.w	0,0,6,*1*,0,0
even if rollback requested, keep going forward if flag is 0: walk should have full rollback all the time
and never allow rollback if move stops

crash on complex moves
forward guard move 2 moves second move doesn't last long enough even with 20 frames