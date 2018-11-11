NormalGrid NORMAL_GRID;
int GRID_WIDTH = 10;

void setup() {
  size(1080, 1080);
  NORMAL_GRID = new NormalGrid(
    GRID_WIDTH, width / GRID_WIDTH, height / GRID_WIDTH);
}

void update() {
  NORMAL_GRID.update();
}

void draw() {
  update();
  background(255);
  NORMAL_GRID.draw();
  // saveFrame("frames/######.tif");
}

void mouseMoved() {
  PVector diffMouse = new PVector(mouseX - pmouseX, mouseY - pmouseY).mult(10);
  PVector position = new PVector(mouseX, mouseY);
  NORMAL_GRID.addLerpPrevVelocity(position, diffMouse);
}
