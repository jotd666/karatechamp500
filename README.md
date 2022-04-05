This is a 1:1 attempt of a remake of Karate Champ VS on the Amiga 500

try to add more colors (stage 1 gray)

last frame should always be first frame
rollback only at start, add flags  dc.w	0,0,6,0,0,0 => dc.w	0,0,6,*1*,0,0


address error on 68000
crouch special case to perform foot sweeps (connect from crouch)
jump special case just for jumping side kick (connect from jump)
-> <- back round kick to the left (regardless of character direction)
<- -> to the right
if direction is not the proper one, turn before move
jumps are bogus (wrong y on land), same for sommersaults
jumping back: turn after complete move
center display
reverse punch (800) erase square too small
