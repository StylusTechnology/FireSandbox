 /*Stylus Technologies
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
*/
Solver s = new Solver();
ArrayList ps = new ArrayList();
float x, y, oldX, oldY;
String mode = "fire";
Button fireButton = new Button(10, 10, 40, 20, "Fire");
Button windButton = new Button(60, 10, 40, 20, "Wind");
Button particlesButton = new Button(110, 10, 60, 20, "Particles");
Button removeParticlesButton = new Button(180, 10, 110, 20, "Remove Particles");
Button wallsButton = new Button(300, 10, 40, 20, "Walls");
Button eraseWallsButton = new Button(10, 40, 90, 20, "Erase Walls");
void setup()
{
  size(400, 400);
  noStroke();
  frameRate(999);
}
void draw()
{
  background(0);
  doFire();
  doParticles();
  doButtons();
  if (mousePressed && mode == "walls" && mouseY > 30)
  {
    int i = (int) ((mouseX / (float) width) * s.n + 1);
    int j = (int) ((mouseY / (float) height) * s.n + 1);
    s.walls[I(i, j)] = true;
    s.walls[I(i + 1, j)] = true;
    s.walls[I(i + 1, j + 1)] = true;
    s.walls[I(i, j + 1)] = true;
  }
  if (mousePressed && mode == "eraseWalls")
  {
    int i = (int) ((mouseX / (float) width) * s.n + 1);
    int j = (int) ((mouseY / (float) height) * s.n + 1);
    s.walls[I(i, j)] = false;
    s.walls[I(i + 1, j)] = false;
    s.walls[I(i + 1, j + 1)] = false;
    s.walls[I(i, j + 1)] = false;
  }
  oldX = mouseX;
  oldY = mouseY;
  println(frameRate);
}
void doParticles()
{
  for (int i = 0; i < ps.size(); i ++)
  {
    P p = (P) ps.get(i);
    p.x += p.u;
    p.y += p.v;
    p.v += 0.02;
    float friction = 0.9;
    p.u *= friction;
    p.v *= friction;
    p.keepOnStage();
    for (int j = 0; j < i; j ++)
    {
      P p2 = (P) ps.get(j);
      float dx = p.x - p2.x;
      float dy = p.y - p2.y;
      if (dx * dx + dy * dy < 9)
      {
        dx *= -0.01;
        dy *= -0.01; 
        p.u -= dx;
        p.v -= dy;
        p2.u += dx;
        p2.v += dy;
      }
    }
    if (p.isFireParticle)
    {
      if (p.life >= 40)if (i < ps.size() - 1)ps.remove(i);
    }
    else
    {
      if (p.life >= 10000)if (i < ps.size() - 1)ps.remove(i);
    }
    if (p.isFireParticle && p.life < 40) set(int(p.x), int(p.y), color(255, 200, 0));
    else if (p.life < 10000) set(int(p.x), int(p.y), color(200, 200, 255));
  }
  if (mousePressed && mode == "particles" && mouseY > 30)
  {
    for (int i = 0; i < 20; i ++)
    {
      if (ps.size() < 3000) ps.add(new P(mouseX + random(3), mouseY + random(3), 0, 0));
      float vx = (mouseX - oldX) * 0.1;
      float vy = (mouseY - oldY) * 0.1;
      addVel(mouseX, mouseY, vx, vy);
    }
  }
}
void doButtons()
{
  fireButton.paint();
  windButton.paint();
  particlesButton.paint();
  removeParticlesButton.paint();
  wallsButton.paint();
  eraseWallsButton.paint();
  if (fireButton.isClicked()) mode = "fire";
  if (windButton.isClicked()) mode = "wind";
  if (particlesButton.isClicked()) mode = "particles";
  if (wallsButton.isClicked()) mode = "walls";
  if (eraseWallsButton.isClicked()) mode = "eraseWalls";
  if (removeParticlesButton.isClicked())
  {
    for (int i = 0; i < 15; i ++)
    {
      if (ps.size() > 1) ps.remove(ps.size() - 1);
    }
  }
}
void doFire()
{
  s.velocitySolver();
  s.densitySolver();
  s.decayDens(0.9);
  if (mousePressed && mouseY > 30)
  {
    if (mode == "fire")
    {
      addBoxDens(mouseX, mouseY, 2, 2, 50);
      addVel(mouseX, mouseY, (mouseX - oldX) + random(-1, 1), (mouseY - oldY) + random(-1, 1));
      ps.add(new P(mouseX + random(3), mouseY + random(3), 0, 0));
      P p = (P) ps.get(ps.size() - 1);
      p.isFireParticle = true;
    }
    if (mode == "wind")
    {
      float vx = (mouseX - oldX) * 0.1;
      float vy = (mouseY - oldY) * 0.1;
      addVel(mouseX, mouseY, vx, vy);
    }
  }
  for (int i = 0; i < s.n; i ++)
  {
    for (int j = 0; j < s.n; j ++)
    {
      float c = (s.d[I(i, j)]);
      if (s.walls[I(i, j)])
      {
        fill(100);
        rect(float(i - 1) * width / s.n, float(j - 1) * height / s.n, width / s.n, height / s.n);
      }
      else
      {
        fill(c * 100, c * 20, 0);
        rect(float(i - 1) * width / s.n, float(j - 1) * height / s.n, width / s.n, height / s.n);
      }
    }
  }
  for (int k = 0; k < ps.size(); k ++)
  {
    P p = (P) ps.get(k);
    int i = (int) ((p.x / (float) width) * s.n + 1);
    int j = (int) ((p.y / (float) height) * s.n + 1);
    p.u += s.u[I(i, j)] * 6;
    p.v += s.v[I(i, j)] * 6;
    if (s.walls[I(i, j)])
    {
      
    }
  }
  doBlur();
}
void doBlur()
{
  fastBlur();
  fastBlur();
  fastBlur();
}
void fastBlur()
{
  loadPixels();
  int pa[]=pixels;
  int pb[]=pixels;
  int h=height;
  int w=width;
  final int mask=(0xFF&(0xFF<<2))*0x01010101;
  for(int y=1;y<h-1;y++){ //edge pixels ignored
    int rowStart=y*w  +1;
    int rowEnd  =y*w+w-1;
    for(int i=rowStart;i<rowEnd;i++){
      pb[i]=(
        ( (pa[i-w]&mask) // sum of neighbours only, center pixel ignored
         +(pa[i+w]&mask)
         +(pa[i-1]&mask)
         +(pa[i+1]&mask)
        )>>2)
        |0xFF000000 //alpha -> opaque
        ;
    }
  }
  updatePixels();
}
void addDens(float x, float y, float amount)
{
  float i = (int) ((x / (float) width) * s.n + 1);
  float j = (int) ((y / (float) height) * s.n + 1);
  if (i > s.n) i = s.n;
  if (i < 1) i = 1;
  if (j > s.n) j = s.n;
  if (j < 1) j = 1;
  s.dOld[s.I(int(i), int(j))] = amount;
}
void addBoxDens(float x, float y, int cw, int ch, float amount)
{
  int ix = (int) ((x / width) * s.n + 1);
  int iy = (int) ((y / height) * s.n + 1);
  for (int i = 0; i < cw; i ++)
  {
    for (int j = 0; j < ch; j ++)
    {
      int ni = i + ix;
      int nj = j + iy;
      if (ni > s.n) ni = s.n;
      if (ni < 1) ni = 1;
      if (nj > s.n) nj = s.n;
      if (nj < 1) nj = 1;
      s.dOld[s.I(ni, nj)] = amount;
    }
  }
}
void addVel(float x, float y, float u, float v)
{
  float i = (int) ((x / (float) width) * s.n + 1);
  float j = (int) ((y / (float) height) * s.n + 1);
  if (i > s.n) i = s.n;
  if (i < 1) i = 1;
  if (j > s.n) j = s.n;
  if (j < 1) j = 1;
  s.uOld[s.I(int(i), int(j))] = u;
  s.vOld[s.I(int(i), int(j))] = v;
  
  s.uOld[s.I(int(i + 1), int(j))] = u;
  s.vOld[s.I(int(i + 1), int(j))] = v;
  
  s.uOld[s.I(int(i + 1), int(j + 1))] = u;
  s.vOld[s.I(int(i + 1), int(j + 1))] = v;
  
  s.uOld[s.I(int(i), int(j + 1))] = u;
  s.vOld[s.I(int(i), int(j + 1))] = v;
}
int I(int i, int j)
{
  return i + (s.n + 2) * j; 
}
