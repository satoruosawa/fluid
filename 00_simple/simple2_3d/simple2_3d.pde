StaggeredGrid STAGGERED_GRID;
int GRID_SIZE = 54;
float CAMERA_Z = 0.0;
boolean IS_ROTATE_MODE = false;

void setup() {
  size(1080, 1080, P3D);
  frameRate(60);
  STAGGERED_GRID = new StaggeredGrid(
    GRID_SIZE, width / GRID_SIZE, height / GRID_SIZE, width / GRID_SIZE);
  CAMERA_Z = width * -1.5;
}

void update() {
  STAGGERED_GRID.update();
}

void draw() {
  update();
  background(255);
  pushMatrix(); {
    cameraControl();
    drawAxis();
    STAGGERED_GRID.draw();
  } popMatrix();
  // saveFrame("frames/######.tif");
}

void drawAxis() {
  stroke(255, 0, 0);
  line(0, 0, 0, 100, 0, 0);
  stroke(0, 255, 0);
  line(0, 0, 0, 0, 100, 0);
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 0, 100);
}

void cameraControl() {
  beginCamera(); {
    camera();
    translate(0, 0, CAMERA_Z);
  } endCamera();
  if (IS_ROTATE_MODE) {
    translate(width / 2, height / 2, width / 2);
    float mappedMouseX = map(mouseX, 0, width, -1.0, 1.0);
    float mappedMouseY = map(mouseY, 0, width, -1.0, 1.0);
    rotateX(-mappedMouseY * PI);
    rotateY(mappedMouseX * PI);
    translate(-width / 2, -height / 2, -width / 2);
  }
}

void mouseWheel(MouseEvent event) {
  float fov = PI / 3.0;
  float e = event.getCount();
  CAMERA_Z -= e / 10.0;
}

void mouseMoved() {
  if (!IS_ROTATE_MODE) {
    PVector diffMouse = new PVector(mouseX - pmouseX, mouseY - pmouseY, 0.0).mult(100);
    PVector position = new PVector(mouseX, mouseY, width / 2.0);
    STAGGERED_GRID.addLerpPrevVelocity(position, diffMouse);
  }
}

void keyPressed() {
	if (key == CODED) {
		if (keyCode == SHIFT) {
      IS_ROTATE_MODE = true;
		}
	}
}

void keyReleased() {
	if (key == CODED) {
		if (keyCode == SHIFT) {
      IS_ROTATE_MODE = false;
		}
	}
}
