class P
{
  float x, y, u, v;
  int life;
  boolean isFireParticle = false;
  P(float nx, float ny, float nu, float nv)
  {
    x = nx;
    y = ny;
    u = nu;
    v = nv;
  }
  void keepOnStage()
  {
    float radius = 5;
    float s1 = radius + 1;
    float sheight = height - radius;
    float swidth = width - radius;
    if (y < s1) y = 2 * (s1) - y;
    if (y > sheight-1) 
    {
      y = 2 * (sheight - 1) - y;
    }
    if (x > swidth-1) x = 2 * (swidth - 1) - x;
    if (x < s1) x = 2 * (s1) - x;
    life ++;
  }
}
