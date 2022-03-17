This is a 1:1 attempt of a remake of Karate Champ VS on the Amiga 500

try to add more colors (stage 1 gray)
3 frame widths: 32, 48 and 64 to save memory
rip blocks (moves 4?)
re-rip sommersault fwd without referee
-1 infinite position lock (round kick)
number of frames should be # of frames of NEXT frame
last frame should always be first frame
rollback only at start, add flags  dc.w	0,0,6,0,0,0 => dc.w	0,0,6,*1*,0,0
even if rollback requested, keep going forward if flag is 0: walk should have full rollback all the time
and never allow rollback if move stops
remove nb frames, rollback doesn't need it
have walk/guardmove back different move than front (redo a vid?) so moves are simpler
and no need to loop backwards (when start is reached)

false position blit ex 4 round kicks
crash on complex moves