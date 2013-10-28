class Solver
{
  int n = 100;
  int size = n * n + 16 * n; // sq(n + 2), just for fun
  float dt = 0.2;
  float visc = 0;
  float diff = 0;
  float[] tmp;
  float buoyancy = 0.0001;
  float b = sqrt(buoyancy);
  float[] d, dOld;
  float[] u, uOld;
  float[] v, vOld;
  float[] curl;
  boolean[] walls;
  boolean confineVorticies = true;
  boolean buoyDensities = true;
  Solver()
  {
    init();
  }
  void init()
  {
    d    = new float[size];
    dOld = new float[size];
    u    = new float[size];
    uOld = new float[size];
    v    = new float[size];
    vOld = new float[size];
    curl = new float[size];
    walls = new boolean[size];
    
    for (int i = 0; i < size; i++)
    {
      u[i] = uOld[i] = v[i] = vOld[i] = 0.0f;
      d[i] = dOld[i] = curl[i] = 0.0f;
      walls[i] = false;
    }
  }
  void buoyancy(float [] Fbuoy)
  {
    float Tamb = 0;

    for (int i = 1; i <= n; i++)
    {
      for (int j = 1; j <= n; j++)
      {
        Tamb += d[I(i, j)];
      }
    }
    Tamb /= (n * n);
    for (int i = 1; i <= n; i++)
    {
      for (int j = 1; j <= n; j++)
      {
        Fbuoy[I(i, j)] = buoyancy * d[I(i, j)] -b * (d[I(i, j)] - Tamb);
      }
    }
  }
  float curl(int i, int j)
  {
    float dudy = (u[I(i, j + 1)] - u[I(i, j - 1)]) * 0.5;
    float dvdx = (v[I(i + 1, j)] - v[I(i - 1, j)]) * 0.5;
    return dudy - dvdx;
  }
  void vorticityConfinement(float [] Fvc_x, float[] Fvc_y)
  {
    float dw_dx, dw_dy;
    float length;
    float v;

    for (int i = 1; i <= n; i++)
    {
      for (int j = 1; j <= n; j++)
      {
        //faster than abs(x)
        float c = curl(i, j);
        if (c > 0) curl[I(i, j)] = c;
        else curl[I(i, j)] = -c;
      }
    }
    for (int i = 2; i < n; i++)
    {
      for (int j = 2; j < n; j++)
      {
        dw_dx = (curl[I(i + 1, j)] - curl[I(i - 1, j)]) * 0.5;
        dw_dy = (curl[I(i, j + 1)] - curl[I(i, j - 1)]) * 0.5;
        length = sqrt(dw_dx * dw_dx + dw_dy * dw_dy) + 0.000001;

        dw_dx /= length;
        dw_dy /= length;

        v = curl(i, j);

        Fvc_x[I(i, j)] = dw_dy * -v;
        Fvc_y[I(i, j)] = dw_dx *  v;
      }
    }
  }
  void velocitySolver()
  {
    addSource(u, uOld);
    addSource(v, vOld);
    if (confineVorticies) 
    {
      vorticityConfinement(uOld, vOld);
      addSource(u, uOld);
      addSource(v, vOld);
    }
    if (buoyDensities)
    {
      buoyancy(vOld);
      addSource(v, vOld);
    }
    for (int i = 0; i < n; i ++)
    {
      for (int j = 0; j < n; j ++)
      {
        if (walls[I(i, j)])
        {
          zeroVel(i, j);
          zeroVel(i + 1, j);
          zeroVel(i + 1, j + 1);
          zeroVel(i, j + 1);
          zeroVel(i - 1, j + 1);
          zeroVel(i - 1, j);
          zeroVel(i - 1, j - 1);
          zeroVel(i, j - 1);
          zeroVel(i + 1, j - 1);
        }
      }
    }
    swapU();
    diffuse(0, u, uOld, visc);

    swapV();
    diffuse(0, v, vOld, visc);
    project(u, v, uOld, vOld);

    swapU(); 
    swapV();
    
    advect(1, u, uOld, uOld, vOld);
    advect(2, v, vOld, uOld, vOld);
    
    project(u, v, uOld, vOld);
    
    for (int i = 0; i < size; i++)
    {
      uOld[i] = 0; vOld[i] = 0;
    }
  }
  void zeroVel(int i, int j)
  {
    u[I(i, j)] = v[I(i, j)] = 0;
  }
  void densitySolver()
  {
      addSource(d, dOld);
      swapD();

      diffuse(0, d, dOld, diff);
      swapD();

      advect(0, d, dOld, u, v);

      // clear input density array for next frame
      for (int i = 0; i < size; i++) dOld[i] = 0;
  }
  void addSource(float[] x, float[] x0)
  {
    for (int i = 0; i < size; i++)
    {
      x[i] += dt * x0[i];
    }
  }
  void advect(int b, float d[], float[] d0, float[] du, float[] dv)
  {
    int i0, j0, i1, j1;
    float x, y, s0, t0, s1, t1, dt0;

    dt0 = dt * n;

    for (int i = 1; i <= n; i++)
    {
      for (int j = 1; j <= n; j++)
      {
        // go backwards through velocity field
        x = i - dt0 * du[I(i, j)];
        y = j - dt0 * dv[I(i, j)];

        // interpolate results
        if (x > n + 0.5) x = n + 0.5f;
        if (x < 0.5)     x = 0.5f;

        i0 = (int) x;
        i1 = i0 + 1;

        if (y > n + 0.5) y = n + 0.5f;
        if (y < 0.5)     y = 0.5f;

        j0 = (int) y;
        j1 = j0 + 1;

        s1 = x - i0;
        s0 = 1 - s1;
        t1 = y - j0;
        t0 = 1 - t1;

        d[I(i, j)] = s0 * (t0 * d0[I(i0, j0)] + t1 * d0[I(i0, j1)]) + s1 * (t0 * d0[I(i1, j0)] + t1 * d0[I(i1, j1)]);
      }
    }
    setBoundry(b, d);
  }
  private void diffuse(int b, float[] c, float[] c0, float diff)
  {
    float a = dt * diff * n * n;
    linearSolver(b, c, c0, a, 1 + 4 * a);
  }
  void project(float[] x, float[] y, float[] p, float[] div)
  {
    for (int i = 1; i <= n; i++)
    {
      for (int j = 1; j <= n; j++)
      {
        div[I(i, j)] = (x[I(i+1, j)] - x[I(i-1, j)]
                      + y[I(i, j+1)] - y[I(i, j-1)])
                      * - 0.5 / n;
        p[I(i, j)] = 0;
      }
    }

    setBoundry(0, div);
    setBoundry(0, p);

    linearSolver(0, p, div, 1, 4);

    for (int i = 1; i <= n; i++)
    {
      for (int j = 1; j <= n; j++)
      {
        x[I(i, j)] -= 0.5f * n * (p[I(i+1, j)] - p[I(i-1, j)]);
        y[I(i, j)] -= 0.5f * n * (p[I(i, j+1)] - p[I(i, j-1)]);
      }
    }

    setBoundry(1, x);
    setBoundry(2, y);
  }
  void linearSolver(int b, float[] x, float[] x0, float a, float c)
  {
      for (int k = 0; k < 10; k++)
      {
        for (int i = 1; i <= n; i++)
        {
          for (int j = 1; j <= n; j++)
          {
            float sum = 0;
            if (!checkWalls(i - 1, j)) sum += x[I(i - 1, j)];
            if (!checkWalls(i + 1, j)) sum += x[I(i + 1, j)];
            if (!checkWalls(i, j - 1)) sum += x[I(i, j - 1)];
            if (!checkWalls(i, j + 1)) sum += x[I(i, j + 1)];
            x[I(i, j)] = (a * (sum) +
                                x0[I(i, j)]) / c;
          }
        }
        setBoundry(b, x);
      }
  }
  private boolean checkWalls(int i, int j)
  {
    if (walls[I(i, j)])return true;
    return false;
  }
  // specifies simple boundry conditions.
  private void setBoundry(int b, float[] x)
  {
    for (int i = 1; i <= n; i++)
    {
      x[I(  0, i  )] = b == 1 ? -x[I(1, i)] : x[I(1, i)];
      x[I(n+1, i  )] = b == 1 ? -x[I(n, i)] : x[I(n, i)];
      x[I(  i, 0  )] = b == 2 ? -x[I(i, 1)] : x[I(i, 1)];
      x[I(  i, n+1)] = b == 2 ? -x[I(i, n)] : x[I(i, n)];
    }
    x[I(  0,   0)] = 0.5f * (x[I(1, 0  )] + x[I(  0, 1)]);
    x[I(  0, n+1)] = 0.5f * (x[I(1, n+1)] + x[I(  0, n)]);
    x[I(n+1,   0)] = 0.5f * (x[I(n, 0  )] + x[I(n+1, 1)]);
    x[I(n+1, n+1)] = 0.5f * (x[I(n, n+1)] + x[I(n+1, n)]);
  }
  void decayDens(float coeff)
  {
    for (int i = 1; i <= n; i++)
    {
      for (int j = 1; j <= n; j++)
      {
        d[I(i, j)] *= coeff;
      }
    }
  }
  public void swapU(){ tmp = u; u = uOld; uOld = tmp; }
  public void swapV(){ tmp = v; v = vOld; vOld = tmp; }
  public void swapD(){ tmp = d; d = dOld; dOld = tmp; }

  private int I(int i, int j){ return i + (n + 2) * j; }
}
