class FluidGrid extends StaggeredGrid implements Field {
  public FluidGrid(int gridSize, int numGridX, int numGridY, int numGridZ) {
    super(gridSize, numGridX, numGridY, numGridZ);
  }

  public void willUpdateParticle(Particle particle) {
    PVector gridIndexF = convertGridIndexFFromPosition(particle.position().copy());
    PVector velocity = calculateLerpPrevVelocity(gridIndexF);
    particle.velocity(velocity.mult(5));
  }

  public void didUpdateParticle(Particle particle) {}
}
