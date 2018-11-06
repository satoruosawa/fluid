class NormalGrid {
  private int gridSize;
  private int numColumn;
  private int numRow;
  private PVector[] prevVelocities;
  private PVector[] velocities;
  private float[] prevPressures;
  private float[] pressures;

  public NormalGrid(int gridSize, int numColumn, int numRow) {
    this.gridSize = gridSize;
    this.numColumn = numColumn;
    this.numRow = numRow;
    prevVelocities = new PVector[numColumn * numRow];
    velocities = new PVector[numColumn * numRow];
    prevPressures = new float[numColumn * numRow];
    pressures = new float[numColumn * numRow];
    for (int i = 0; i < numColumn * numRow; i++) {
      prevVelocities[i] = new PVector(0, 0);
      velocities[i] = new PVector(0, 0);
      prevPressures[i] = 0.0;
      pressures[i] = 0.0;
    }
  }

  public void update() {
    // Navier Stokes equations
    updteConvection();
    updateDiffusion();
    updatePressure();
  }

  private void updteConvection() {
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        // semi-Lagrangian
        PVector velocityPosition = new PVector(i, j).mult(gridSize);
        PVector prevVelocityPosition = velocityPosition
          .sub(prevVelocities[getIndex(i, j)]);
        PVector prevVelocityRef = PVector.div(prevVelocityPosition, gridSize);
        velocities[getIndex(i, j)] = calculateLerpPrevVelocity(
          prevVelocityRef.x, prevVelocityRef.y);
      }
    }
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        prevVelocities[getIndex(i, j)] = velocities[getIndex(i, j)].copy();
      }
    }
  }

  private void updateDiffusion() {
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        // Explicit way
        // h = dx = dy = rectSize
        // Dynamic and kinematic viscosity [nu]
        // surroundRatio = nu * dt / (h * h)
        float surroundRatio = 0.2; // 0 - 0.25
        float centerRatio = 1 - 4 * surroundRatio;
        // or you can define this way
        // float centerRatio = 0.2; // 0 - 1
        // float surroundRatio = (1 - centerRatio) / 4.0;
        PVector leftVelocity = getPrevVelocity(i - 1, j);
        PVector rightVelocity = getPrevVelocity(i + 1, j);
        PVector topVelocity = getPrevVelocity(i, j - 1);
        PVector bottomVelocity = getPrevVelocity(i, j + 1);
        PVector total = PVector
          .add(leftVelocity, rightVelocity)
          .add(topVelocity).add(bottomVelocity);
        velocities[getIndex(i, j)] = PVector
          .mult(prevVelocities[getIndex(i, j)], centerRatio)
          .add(total.mult(surroundRatio));
      }
    }
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        prevVelocities[getIndex(i, j)] = velocities[getIndex(i, j)].copy();
      }
    }
  }

  private void updatePressure() {
    // Incompressible
    // TODO: case of boundary
    // SOR (Successive over-relaxation)
    int numSorRepeat = 3;
    float sorRelaxationFactor = 1.01; // should more than 1
    // h = dx = dy = rectSize
    // Density [rho]
    // poissonCoef = h * rho / dt
    float poissonCoef = 0.1;
    for (int k = 0; k < numSorRepeat; k++) {
      for (int i = 0; i < numColumn; i++) {
        for (int j = 0; j < numRow; j++) {
          pressures[getIndex(i, j)] =
            (1 - sorRelaxationFactor) * getPrevPressure(i, j) +
            sorRelaxationFactor * calculatePoissonsEquation(i, j, poissonCoef);
        }
      }
      for (int i = 0; i < numColumn; i++) {
        for (int j = 0; j < numRow; j++) {
          prevPressures[getIndex(i, j)] = pressures[getIndex(i, j)];
        }
      }
    }
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        float leftPressure = getPrevPressure(i - 1, j);
        float rightPressure = getPrevPressure(i + 1, j);
        float topPressure = getPrevPressure(i, j - 1);
        float bottomPressure = getPrevPressure(i, j + 1);
        velocities[getIndex(i, j)] = PVector
          .add(prevVelocities[getIndex(i, j)], new PVector(
            leftPressure - rightPressure,
            topPressure - bottomPressure
          ).div(poissonCoef));
      }
    }
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        prevVelocities[getIndex(i, j)] = velocities[getIndex(i, j)].copy();
      }
    }
  }

  private int getIndex(int column, int row) {
    return row * numColumn + column;
  }

  private PVector generateVelocityPosition(int column, int row) {
    return (new PVector(column, row).add(0.5, 0.5)).mult(gridSize);
  }

  private PVector getPrevVelocity(int column, int row) {
    if (column < 0 || column >= numColumn || row < 0 || row >= numRow) {
      return new PVector(0, 0);
    }
    return prevVelocities[getIndex(column, row)];
  }

  private float getPrevPressure(int column, int row) {
    if (column < 0 || column >= numColumn || row < 0 || row >= numRow) {
      return 0.0;
    }
    return prevPressures[getIndex(column, row)];
  }

  private PVector calculateLerpPrevVelocity(float column, float row) {
    int left = floor(column);
    int top = floor(row);
    int right = left + 1;
    int bottom = top + 1;
    PVector topLerp = PVector.lerp(
      getPrevVelocity(left, top), getPrevVelocity(right, top), column - left
    );
    PVector bottomLerp = PVector.lerp(
      getPrevVelocity(left, bottom),
      getPrevVelocity(right, bottom),
      column - left
    );
    return PVector.lerp(topLerp, bottomLerp, row - top);
  }

  private float calculatePoissonsEquation(
    int column, int row, float poissonCoef) {
    // PVector centerVelocity = getPrevVelocity(i, j);
    PVector leftVelocity = getPrevVelocity(column - 1, row);
    PVector rightVelocity = getPrevVelocity(column + 1, row);
    PVector topVelocity = getPrevVelocity(column, row - 1);
    PVector bottomVelocity = getPrevVelocity(column, row + 1);
    float divVelocity = poissonCoef *
      (rightVelocity.x - leftVelocity.x + bottomVelocity.y - topVelocity.y);
    float leftPressure = getPrevPressure(column - 1, row);
    float rightPressure = getPrevPressure(column + 1, row);
    float topPressure = getPrevPressure(column, row - 1);
    float bottomPressure = getPrevPressure(column, row + 1);
    return (leftPressure + rightPressure + topPressure + bottomPressure -
      divVelocity) / 4.0;
  }

  public void addLerpVelocity(PVector position, PVector velocity) {
    PVector velocityRef = PVector.div(position, gridSize).sub(0.5, 0.5);
    int left = floor(velocityRef.x);
    int top = floor(velocityRef.y);
    float alpha = (velocityRef.x) - left;
    float beta = (velocityRef.y) - top;
    addVelocity(left, top, PVector.mult(velocity, (1 - alpha) * (1 - beta)));
    addVelocity(left + 1, top, PVector.mult(velocity, alpha * (1 - beta)));
    addVelocity(left, top + 1, PVector.mult(velocity, (1 - alpha) * beta));
    addVelocity(left + 1, top + 1, PVector.mult(velocity, alpha * beta));
  }

  private void addVelocity(int column, int row, PVector velocity) {
    if (column < 0 || column >= numColumn || row < 0 || row >= numRow) {
      return;
    }
    prevVelocities[getIndex(column, row)].add(velocity);
  }

  void draw() {
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        noStroke();
        fill(0);
        PVector position = generateVelocityPosition(i, j);
        float pressure = prevPressures[getIndex(i, j)];
        ellipse(position.x, position.y, pressure * 20, pressure * 20);
        stroke(0);
        noFill();
        PVector velocity = prevVelocities[getIndex(i, j)];
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
