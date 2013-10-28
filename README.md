FireSandbox
===========

A sandbox for the simulation and display of Eulerian Incompressible Fluids in real time

FEEL FREE TO TAKE THIS STUFF AND USE IT!
NONE OF THE TECHNIQUES I USE ARE NEW, 
ALL ARE IN THE PUBLIC DOMAIN, AND I HAD 
SO MUCH TROUBLE FINDING THIS STUFF, THAT 
NO ONE ELSE SHOULD HAVE TO DO THE SAME.

  Stylus Technologies
Okay, so this is a little bit messy, so sue me.
This is what I call a bag of tricks simulation, 
I use the semi-lagrangian advection algorythm, 
standard linear-solve function, and some stuff 
for the pressure solve that I don't understand
because I'm stupid. I use a del-cross algorythm
for vorticity confinement (which I found on the
website of Berkely or Stanford or something like
that). I buoy the velocity field based on the
density field (of dye in the water). The density
field can be assumed to be synonymous with temp-
erature. Boundary conditions are handled with 
another trick, that of zeroing the velocity field
at walls, and adapting the linear solve function
to account for regions not filled by fluid.
After all that, the rest is just for visualization:
I color and blur the density field to look like
fire, and add some sparky particles. Particles 
are prevented from collecting to a single point
(as a result of rounding errors) with a spring-
based, area-density regularization. Particles 
are advected by fluid flow, and the rest is 
just getting it to look nice, which I like to
think that it does, enjoy!.
By the way, this entire idea is stolen from 
peter blascovic at escapemotions.com, I didn't 
use any of his code (it's not open source, so
I wouldn't be able to if I wanted to), but he
has a fire simulation sandbox similar to this
one, so go see his stuff, it's much better 
than mine.
