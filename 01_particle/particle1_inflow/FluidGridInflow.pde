class FluidGridInflow extends StaggeredGrid implements Field {
  public FluidGridInflow(int gridSize, int numGridX, int numGridY) {
    super(gridSize, numGridX, numGridY);
  }

  public void willUpdateParticle(Particle particle) {
    PVector gridIndexF = convertGridIndexFFromPosition(particle.position().copy());
    PVector velocity = calculateLerpPrevVelocity(gridIndexF);
    particle.velocity(velocity.mult(5));
  }

  public void didUpdateParticle(Particle particle) {}

  protected float getPrevVelocityX(float gridIndexXH, int gridIndexY) {
    // gridIndexXH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = int(gridIndexXH + 1.0);
    int indexY = gridIndexY;
    if (indexX < 0 || indexX >= numGridX + 1 ||
      indexY < 0 || indexY >= numGridY) {
      println("No index in prevVelocitiesX. @getPrevVelocityX");
      return 0.0;
    }
    if (indexX == 1 && indexY == width / 2 / gridWidth) {
      return 20.0;
    }
    if (indexX == 1 || indexX == numGridX - 1) {
      // On the wall
      return 0.0;
    } else if (indexX == 0) {
      // In the wall
      return -prevVelocitiesX[2][indexY];
    } else if (indexX == numGridX) {
      // In the wall
      return -prevVelocitiesX[numGridX - 2][indexY];
    }
    if (indexY == 0) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesX[indexX][1];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesX[indexX][1];
    } else if (indexY == numGridY - 1) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesX[indexX][numGridY - 2];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesX[indexX][numGridY - 2];
    }
    return prevVelocitiesX[indexX][indexY];
  }
}
