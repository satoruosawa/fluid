class NormalGrid {
  private int gridWidth;
  private int numGridX;
  private int numGridY;
  private PVector[][] prevVelocities;
  private PVector[][] velocities;
  private float[][] prevPressures;
  private float[][] pressures;

  public NormalGrid(int gridWidth, int numGridX, int numGridY) {
    this.gridWidth = gridWidth;
    this.numGridX = numGridX;
    this.numGridY = numGridY;
    prevVelocities = new PVector[numGridX][numGridY];
    velocities = new PVector[numGridX][numGridY];
    prevPressures = new float[numGridX][numGridY];
    pressures = new float[numGridX][numGridY];
    for (int j = 0; j < numGridY; j++) {
      for (int i = 0; i < numGridX; i++) {
        prevVelocities[i][j] = new PVector(0, 0);
        velocities[i][j] = new PVector(0, 0);
        prevPressures[i][j] = 0.0;
        pressures[i][j] = 0.0;
      }
    }
  }

  public void update() {
    // Navier Stokes equations
    updteConvection();
    updateDiffusion();
    updatePressure();
  }

  private void updteConvection() {
    for (int i = 0; i < numGridX; i++) {
      for (int j = 0; j < numGridY; j++) {
        // semi-Lagrangian
        PVector position = convertPositionFromGridIndexF(new PVector(i, j));
        PVector backTracedPosition = position.sub(prevVelocities[i][j]);
        PVector backTracedGridIndexF =
          convertGridIndexFFromPosition(backTracedPosition);
        velocities[i][j] = calculateLerpPrevVelocity(backTracedGridIndexF);
      }
    }
    copyVelocitiesToPrevVelocities();
  }

  private void updateDiffusion() {
    // TODO: case of boundary
    // Explicit way
    // h = dx = dy = rectSize
    // Dynamic and kinematic viscosity [nu]
    // surroundRatio = nu * dt / (h * h)
    float surroundRatio = 0.2; // 0 - 0.25
    float centerRatio = 1 - 4 * surroundRatio;
    // or you can define this way
    // float centerRatio = 0.2; // 0 - 1
    // float surroundRatio = (1 - centerRatio) / 4.0;
    for (int j = 0; j < numGridY; j++) {
      for (int i = 0; i < numGridX; i++) {
        PVector left = getPrevVelocity(i - 1, j);
        PVector right = getPrevVelocity(i + 1, j);
        PVector top = getPrevVelocity(i, j - 1);
        PVector bottom = getPrevVelocity(i, j + 1);
        PVector total = PVector.add(left, right).add(top).add(bottom);
        velocities[i][j] = PVector
          .mult(prevVelocities[i][j], centerRatio)
          .add(total.mult(surroundRatio));
      }
    }
    copyVelocitiesToPrevVelocities();
  }

  private void updatePressure() {
    // TODO: case of boundary
    // Incompressible
    // SOR (Successive over-relaxation)
    int numSorRepeat = 3;
    float sorRelaxationFactor = 1.0; // should more than 1
    // h = dx = dy = rectSize
    // Density [rho]
    // poissonCoef = h * rho / dt
    float poissonCoef = 0.1;
    for (int k = 0; k < numSorRepeat; k++) {
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX; i++) {
          pressures[i][j] =
            (1 - sorRelaxationFactor) * getPrevPressure(i, j) +
            sorRelaxationFactor * calculatePoissonsEquation(i, j, poissonCoef);
        }
      }
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX; i++) {
          prevPressures[i][j] = pressures[i][j];
        }
      }
    }
    for (int j = 0; j < numGridY; j++) {
      for (int i = 0; i < numGridX; i++) {
        float leftPressure = getPrevPressure(i - 1, j);
        float rightPressure = getPrevPressure(i + 1, j);
        float topPressure = getPrevPressure(i, j - 1);
        float bottomPressure = getPrevPressure(i, j + 1);
        velocities[i][j] = PVector
          .add(prevVelocities[i][j], new PVector(
            leftPressure - rightPressure,
            topPressure - bottomPressure
          ).div(poissonCoef));
      }
    }
    copyVelocitiesToPrevVelocities();
  }

  private float calculatePoissonsEquation(
    int gridIndexX, int gridIndexY, float poissonCoef) {
    // XXX: Should calculate gridIndexX - 0.5 and gridIndexX + 0.5 and
    // gridIndexY - 0.5 and gridIndexY + 0.5?
    PVector leftVelocity = getPrevVelocity(gridIndexX - 1, gridIndexY);
    PVector rightVelocity = getPrevVelocity(gridIndexX + 1, gridIndexY);
    PVector topVelocity = getPrevVelocity(gridIndexX, gridIndexY - 1);
    PVector bottomVelocity = getPrevVelocity(gridIndexX, gridIndexY + 1);
    float divVelocity = poissonCoef *
      (rightVelocity.x - leftVelocity.x + bottomVelocity.y - topVelocity.y);
    float leftPressure = getPrevPressure(gridIndexX - 1, gridIndexY);
    float rightPressure = getPrevPressure(gridIndexX + 1, gridIndexY);
    float topPressure = getPrevPressure(gridIndexX, gridIndexY - 1);
    float bottomPressure = getPrevPressure(gridIndexX, gridIndexY + 1);
    return (leftPressure + rightPressure + topPressure + bottomPressure -
      divVelocity) / 4.0;
  }

  private void copyVelocitiesToPrevVelocities() {
    for (int j = 0; j < numGridY; j++) {
      for (int i = 0; i < numGridX; i++) {
        prevVelocities[i][j] = velocities[i][j].copy();
      }
    }
  }

  private float getPrevPressure(int gridIndexX, int gridIndexY) {
    if (gridIndexX < 0 || gridIndexX >= numGridX ||
      gridIndexY < 0 || gridIndexY >= numGridY) {
      return 0.0;
    }
    return prevPressures[gridIndexX][gridIndexY];
  }

  public void addLerpPrevVelocity(PVector position, PVector velocity) {
    PVector gridIndexF = convertGridIndexFFromPosition(position.copy());
    int left = floor(gridIndexF.x);
    int top = floor(gridIndexF.y);
    float coefX = gridIndexF.x - left;
    float coefY = gridIndexF.y - top;
    addPrevVelocity(
      left, top,
      PVector.mult(velocity, (1 - coefX) * (1 - coefY))
    );
    addPrevVelocity(
      left + 1, top,
      PVector.mult(velocity, coefX * (1 - coefY))
    );
    addPrevVelocity(
      left, top + 1,
      PVector.mult(velocity, (1 - coefX) * coefY)
    );
    addPrevVelocity(
      left + 1, top + 1,
      PVector.mult(velocity, coefX * coefY)
    );
  }

  private void addPrevVelocity(
    int gridIndexX, int gridIndexY, PVector velocity) {
    if (gridIndexX < 0 || gridIndexX >= numGridX ||
      gridIndexY < 0 || gridIndexY >= numGridY) {
      // Out of Field.
      return;
    }
    prevVelocities[gridIndexX][gridIndexY].add(velocity);
  }

  private PVector convertPositionFromGridIndexF(PVector gridIndexF) {
    return gridIndexF.add(0.5, 0.5).mult(gridWidth);
  }

  private PVector convertGridIndexFFromPosition(PVector position) {
    return position.div(gridWidth).sub(0.5, 0.5);
  }

  private PVector calculateLerpPrevVelocity(PVector gridIndexF) {
    int left = floor(gridIndexF.x);
    int top = floor(gridIndexF.y);
    float coefX = gridIndexF.x - left;
    float coefY = gridIndexF.y - top;
    PVector topLerp = PVector.lerp(
      getPrevVelocity(left, top),
      getPrevVelocity(left + 1, top),
      coefX
    );
    PVector bottomLerp = PVector.lerp(
      getPrevVelocity(left, top + 1),
      getPrevVelocity(left + 1, top + 1),
      coefX
    );
    return PVector.lerp(topLerp, bottomLerp, coefY);
  }

  private PVector getPrevVelocity(int gridIndexX, int gridIndexY) {
    if (gridIndexX < 0 || gridIndexX >= numGridX ||
      gridIndexY < 0 || gridIndexY >= numGridY) {
      // Out of Field.
      return new PVector(0, 0);
    }
    return prevVelocities[gridIndexX][gridIndexY];
  }

  void draw() {
    for (int i = 0; i < numGridX; i++) {
      for (int j = 0; j < numGridY; j++) {
        noStroke();
        fill(0);
        PVector position = convertPositionFromGridIndexF(new PVector(i, j));
        float pressure = prevPressures[i][j];
        ellipse(position.x, position.y, pressure * 20, pressure * 20);
        stroke(0);
        noFill();
        PVector velocity = prevVelocities[i][j];
        line(
          position.x,
          position.y,
          position.x + velocity.x * 5,
          position.y + velocity.y * 5
        );
      }
    }
  }
}
