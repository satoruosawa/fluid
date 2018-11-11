StaggeredGrid STAGGERED_GRID;
int GRID_WIDTH = 10;

void setup() {
  size(1080, 1080);
  STAGGERED_GRID = new StaggeredGrid(
    GRID_WIDTH, width / GRID_WIDTH, height / GRID_WIDTH);
}

void update() {
  STAGGERED_GRID.update();
}

void draw() {
  update();
  background(255);
  STAGGERED_GRID.draw();
  // saveFrame("frames/######.tif");
}

void mouseMoved() {
  PVector diffMouse = new PVector(mouseX - pmouseX, mouseY - pmouseY).mult(10);
  PVector position = new PVector(mouseX, mouseY);
  STAGGERED_GRID.addLerpPrevVelocity(position, diffMouse);
}
