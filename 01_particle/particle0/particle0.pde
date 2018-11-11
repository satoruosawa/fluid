import java.util.Iterator;

FluidGrid FLUID_GRID;
ParticleSystem PARTICLE_SYSTEM = new ParticleSystem();
int GRID_WIDTH = 10;

void setup() {
  size(1080, 1080);
  FLUID_GRID = new FluidGrid(
    GRID_WIDTH, width / GRID_WIDTH, height / GRID_WIDTH);
  for (int i = 0; i < 100; i++) {
    addParticle();
  }
}

void update() {
  for (int i = 0; i < 20; i++) {
    addParticle();
  }
  FLUID_GRID.update();
  PARTICLE_SYSTEM.update();
}

void draw() {
  update();
  background(255);
  rectMode(CORNERS);
  noFill();
  stroke(220);
  strokeWeight(GRID_WIDTH * 2);
  rect(0, 0, width, height);
  // FLUID_GRID.draw();
  PARTICLE_SYSTEM.draw();
  // saveFrame("frames/######.tif");
}

void mouseMoved() {
  PVector diffMouse = new PVector(mouseX - pmouseX, mouseY - pmouseY).mult(10);
  PVector position = new PVector(mouseX, mouseY);
  FLUID_GRID.addLerpPrevVelocity(position, diffMouse);
}

void addParticle() {
  Particle p = new Particle();
  p.position(new PVector(
    random(GRID_WIDTH, width - GRID_WIDTH),
    random(GRID_WIDTH, height - GRID_WIDTH)
  ));
  p.addField(FLUID_GRID);
  p.life(511);
  p.size(3);
  PARTICLE_SYSTEM.addParticle(p);
}
