class NormalGrid {
  private int gridSize;
  private int numColumn;
  private int numRow;
  private float[] pressures;
  private PVector[] prevVelocities;
  private PVector[] velocities;

  public NormalGrid(int gridSize, int numColumn, int numRow) {
    this.gridSize = gridSize;
    this.numColumn = numColumn;
    this.numRow = numRow;
    pressures = new float[numColumn * numRow];
    prevVelocities = new PVector[numColumn * numRow];
    velocities = new PVector[numColumn * numRow];
    for (int i = 0; i < numColumn * numRow; i++) {
      prevVelocities[i] = new PVector(0, 0);
      velocities[i] = new PVector(0, 0);
      pressures[i] = 0.0;
    }
  }

  public void update() {
    // Navier Stokes equations
    updteConvection();
    updateDiffusion();
    // updatePressure();
    // updateLossVelocities();
  }

  private void updteConvection() {
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        // semi-Lagrangian
        PVector velocityPosition = new PVector(i, j).mult(gridSize);
        PVector prevVelocityPosition = velocityPosition.sub(prevVelocities[getIndex(i, j)]);
        PVector prevVelocityRef = PVector.div(prevVelocityPosition, gridSize);
        velocities[getIndex(i, j)] = calculateLerpPrevVelocity(prevVelocityRef.x, prevVelocityRef.y);
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
        float centerRatio = 1.0 - 4 * surroundRatio;
        // or you can define this way
        // float centerRatio = 0.2; // 0 - 1
        // float surroundRatio = (1.0 - antiDiffusionRatio) / 4;
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
    // TODO: Check algorithm
    // Incompressible
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        float coef = 0.2;
        float leftPressure = getPressure(i - 1, j);
        float rightPressure = getPressure(i + 1, j);
        float topPressure = getPressure(i, j - 1);
        float bottomPressure = getPressure(i, j + 1);
        velocities[getIndex(i, j)] = PVector
          .add(prevVelocities[getIndex(i, j)], new PVector(
            leftPressure - rightPressure,
            topPressure - bottomPressure
          ).mult(coef));
      }
    }
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        prevVelocities[getIndex(i, j)] = velocities[getIndex(i, j)].copy();
      }
    }
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        PVector leftVelocity = getPrevVelocity(i - 1, j);
        PVector rightVelocity = getPrevVelocity(i + 1, j);
        PVector topVelocity = getPrevVelocity(i, j - 1);
        PVector bottomVelocity = getPrevVelocity(i, j + 1);
        pressures[getIndex(i, j)] +=
          leftVelocity.x - rightVelocity.x +
          topVelocity.y - bottomVelocity.y;
      }
    }
  }

  private void updateLossVelocities() {
    for (int i = 0; i < numColumn; i++) {
      for (int j = 0; j < numRow; j++) {
        float coef = 0.9;
        getPrevVelocity(i, j).mult(coef);
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

  private float getPressure(int column, int row) {
    if (column < 0 || column >= numColumn || row < 0 || row >= numRow) {
      return 0.0;
    }
    return pressures[getIndex(column, row)];
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
      getPrevVelocity(left, bottom), getPrevVelocity(right, bottom), column - left
    );
    return PVector.lerp(topLerp, bottomLerp, row - top);
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
        float pressure = pressures[getIndex(i, j)];
        ellipse(position.x, position.y, pressure, pressure);
        stroke(0);
        noFill();
        PVector velocity = prevVelocities[getIndex(i, j)];
        line(
          position.x,
          position.y,
          position.x + velocity.x * 4,
          position.y + velocity.y * 4
        );
      }
    }
  }
}
