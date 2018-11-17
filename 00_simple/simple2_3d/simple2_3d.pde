StaggeredGrid STAGGERED_GRID;
int GRID_SIZE = 54;

void setup() {
  size(1080, 1080, P3D);
  frameRate(60);
  STAGGERED_GRID = new StaggeredGrid(
    GRID_SIZE, width / GRID_SIZE, height / GRID_SIZE, width / GRID_SIZE);
}

void update() {
  addFlow();
  // STAGGERED_GRID.update();
}

void draw() {
  update();
  background(255);
  // STAGGERED_GRID.draw();
  // saveFrame("frames/######.tif");
}

void addFlow() {
  PVector diffMouse = new PVector(1, 1, 1).mult(10);
  PVector position = new PVector(width / 2, height / 2, width / 2);
  STAGGERED_GRID.addLerpPrevVelocity(position, diffMouse);
}

void mouseMoved() {
// rotate
}
