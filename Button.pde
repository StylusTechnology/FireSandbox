class Button
{
  float x, y, w, h;
  String text = "";
  Button(float nx, float ny, float nw, float nh, String ntext)
  {
    x = nx;
    y = ny;
    w = nw;
    h = nh;
    text = ntext;
  }
  void paint()
  {
    fill(0, 0, 255);
    rect(x, y, w, h);
    fill(255);
    text(text, x + h/3, y + h*3/4);
  }
  boolean isClicked()
  {
    if (mouseX > x && mouseY > y && mouseX < x + w && mouseY < y + h && mousePressed)
    {
      return true;
    }
    return false;
  }
}
