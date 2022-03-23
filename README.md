This is a 1:1 attempt of a remake of Karate Champ VS on the Amiga 500

try to add more colors (stage 1 gray)
-1 infinite position lock (round kick)
last frame should always be first frame
rollback only at start, add flags  dc.w	0,0,6,0,0,0 => dc.w	0,0,6,*1*,0,0
even if rollback requested, keep going forward if flag is 0: walk should have full rollback all the time
and never allow rollback if move stops

address error on 68000
crouch special case ex reverse punch animation is faster, low attacks like foot sweeps are
faster too, no rollback
jump special case just for jumping side kick