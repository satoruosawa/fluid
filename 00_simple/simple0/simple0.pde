Grid grid;
int rectSize = 10;

void setup() {
  size(1080, 1080);
  grid = new Grid(rectSize, width / rectSize, height / rectSize);
}

void update() {
  grid.update();
}

void draw() {
  update();
  background(255);
  grid.draw();
  // saveFrame("frames/######.tif");
}

void mouseMoved() {
  PVector diffMouse = new PVector(mouseX - pmouseX, mouseY - pmouseY).mult(10);
  PVector position = new PVector(mouseX, mouseY);
  grid.addLerpVelocity(position, diffMouse);
}
