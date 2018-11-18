import java.util.Iterator;

FluidGrid FLUID_GRID;
ParticleSystem PARTICLE_SYSTEM = new ParticleSystem();
int GRID_SIZE = 20;
float CAMERA_Z = 0.0;
boolean IS_ROTATE_MODE = false;
boolean IS_DRAW_GRID = false;
boolean IS_DRAW_PARTICLES = true;
int DEPTH;

void setup() {
  size(1080, 1080, P3D);
  frameRate(60);
  DEPTH = width / 9;
  FLUID_GRID = new FluidGrid(
    GRID_SIZE, width / GRID_SIZE, height / GRID_SIZE, DEPTH / GRID_SIZE);
  for (int i = 0; i < 100; i++) {
    addParticle();
  }
  CAMERA_Z = -DEPTH + GRID_SIZE * 2.6;
}

void update() {
  for (int i = 0; i < 200; i++) {
    addParticle();
  }
  FLUID_GRID.update();
  PARTICLE_SYSTEM.update();
}

void draw() {
  update();
  background(255);
  pushMatrix(); {
    cameraControl();
    drawAxis();
    if (IS_DRAW_GRID) {
      FLUID_GRID.draw();
    }
    if (IS_DRAW_PARTICLES) {
      PARTICLE_SYSTEM.draw();
    }
  } popMatrix();
  // saveFrame("frames/######.tif");
}

void addParticle() {
  Particle p = new Particle();
  p.position(new PVector(
    random(GRID_SIZE, width - GRID_SIZE),
    random(GRID_SIZE, height - GRID_SIZE),
    random(GRID_SIZE, DEPTH - GRID_SIZE)
  ));
  p.addField(FLUID_GRID);
  p.life(511);
  PARTICLE_SYSTEM.addParticle(p);
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
    translate(width / 2, height / 2, DEPTH / 2);
    float mappedMouseX = map(mouseX, 0, width, -1.0, 1.0);
    float mappedMouseY = map(mouseY, 0, width, -1.0, 1.0);
    rotateX(-mappedMouseY * PI);
    rotateY(mappedMouseX * PI);
    translate(-width / 2, -height / 2, -DEPTH / 2);
  }
}

void mouseWheel(MouseEvent event) {
  float fov = PI / 3.0;
  float e = event.getCount();
  CAMERA_Z -= e / 10.0;
}

void mouseMoved() {
  if (!IS_ROTATE_MODE) {
    PVector diffMouse = new PVector(mouseX - pmouseX, mouseY - pmouseY, 0.0).mult(50);
    PVector position = new PVector(mouseX, mouseY, DEPTH / 2.0);
    FLUID_GRID.addLerpPrevVelocity(position, diffMouse);
  }
}

void keyPressed() {
  switch (key) {
    case 'g':
      IS_DRAW_GRID = !IS_DRAW_GRID;
      break;
    case 'p':
      IS_DRAW_PARTICLES = !IS_DRAW_PARTICLES;
      break;
    case CODED:
  		if (keyCode == SHIFT) {
        IS_ROTATE_MODE = true;
  		}
      break;
    default:
      break;
  }
}

void keyReleased() {
	if (key == CODED) {
		if (keyCode == SHIFT) {
      IS_ROTATE_MODE = false;
		}
	}
}
