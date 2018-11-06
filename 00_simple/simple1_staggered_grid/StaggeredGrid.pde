class StaggeredGrid {
  private int gridSize;
  private int numGridX;
  private int numGridY;
  private float[][] prevVelocitiesX;
  private float[][] velocitiesX;
  private float[][] prevVelocitiesY;
  private float[][] velocitiesY;
  private float[][] prevPressures;
  private float[][] pressures;

  public StaggeredGrid(int gridSize, int numGridX, int numGridY) {
    // TODO: Change to Staggered grid
    this.gridSize = gridSize;
    this.numGridX = numGridX;
    this.numGridY = numGridY;
    prevVelocitiesX = new float[numGridX + 1][numGridY];
    velocitiesX = new float[numGridX + 1][numGridY];
    for (int j = 0; j < numGridY; j++) {
      for (int i = 0; i < numGridX + 1; i++) {
        prevVelocitiesX[i][j] = 0.0;
        velocitiesX[i][j] = 0.0;
      }
    }
    prevVelocitiesY = new float[numGridX][numGridY + 1];
    velocitiesY = new float[numGridX][numGridY + 1];
    for (int j = 0; j < numGridY + 1; j++) {
      for (int i = 0; i < numGridX; i++) {
        prevVelocitiesY[i][j] = 0.0;
        velocitiesY[i][j] = 0.0;
      }
    }
    prevPressures = new float[numGridX][numGridY];
    pressures = new float[numGridX][numGridY];
    for (int j = 0; j < numGridY; j++) {
      for (int i = 0; i < numGridX; i++) {
        prevPressures[i][j] = 0.0;
        pressures[i][j] = 0.0;
      }
    }
  }

  public void update() {
    // TODO: Change to Staggered grid
    // Navier Stokes equations
    updteConvection();
    // updateDiffusion();
    // updatePressure();
  }

  private void updteConvection() {
    for (int i = 0; i < numGridX; i++) {
      for (int j = 0; j < numGridY; j++) {
        // semi-Lagrangian
        PVector backTracedPosition = calculateBackTracedPosition(i, j);
        PVector backTracedGridIndexF = PVector.div(backTracedPosition, gridSize);
        velocitiesX[i][j] = calculateLerpPrevVelocityX(backTracedGridIndexF);
        velocitiesY[i][j] = calculateLerpPrevVelocityY(backTracedGridIndexF);
      }
    }
    copyVelocitiesToPrevVelocities();
  }

  private PVector calculateBackTracedPosition(int gridIndexX, int gridIndexY) {
    PVector position = generatePosition(gridIndexX, gridIndexY);
    float prevVelocityX = (prevVelocitiesX[gridIndexX][gridIndexY] +
      prevVelocitiesX[gridIndexX + 1][gridIndexY]) / 2.0;
    float prevVelocityY = (prevVelocitiesY[gridIndexX][gridIndexY] +
      prevVelocitiesY[gridIndexX][gridIndexY + 1]) / 2.0;
    // BUG: 
    // return position.sub(prevVelocityX, prevVelocityY);
    return position;
  }

  private float calculateLerpPrevVelocityX(PVector gridIndexF) {
    int xIndexX = floor(gridIndexF.x);
    int xIndexY = floor(gridIndexF.y - 0.5);
    float topLerp = lerp(
      getPrevVelocityX(xIndexX, xIndexY),
      getPrevVelocityX(xIndexX + 1, xIndexY),
      gridIndexF.x - 0.5 - xIndexX
    );
    float bottomLerp = lerp(
      getPrevVelocityX(xIndexX, xIndexY + 1),
      getPrevVelocityX(xIndexX + 1, xIndexY + 1),
      gridIndexF.x - 0.5 - xIndexX
    );
    return lerp(topLerp, bottomLerp, gridIndexF.y - 0.5 - xIndexY);
  }

  private float calculateLerpPrevVelocityY(PVector gridIndexF) {
    int yIndexX = floor(gridIndexF.x - 0.5);
    int yIndexY = floor(gridIndexF.y);
    float topLerp = lerp(
      getPrevVelocityY(yIndexX, yIndexY),
      getPrevVelocityY(yIndexY + 1, yIndexY),
      gridIndexF.x - 0.5 - yIndexX
    );
    float bottomLerp = lerp(
      getPrevVelocityY(yIndexX, yIndexY + 1),
      getPrevVelocityY(yIndexY + 1, yIndexY + 1),
      gridIndexF.x - 0.5 - yIndexX
    );
    return lerp(topLerp, bottomLerp, gridIndexF.y - 0.5 - yIndexY);
  }
  //
  // private void updateDiffusion() {
  //   for (int j = 0; j < numGridY; j++) {
  //     for (int i = 0; i < numGridX; i++) {
  //       // Explicit way
  //       // h = dx = dy = rectSize
  //       // Dynamic and kinematic viscosity [nu]
  //       // surroundRatio = nu * dt / (h * h)
  //       float surroundRatio = 0.2; // 0 - 0.25
  //       float centerRatio = 1 - 4 * surroundRatio;
  //       // or you can define this way
  //       // float centerRatio = 0.2; // 0 - 1
  //       // float surroundRatio = (1 - centerRatio) / 4.0;
  //       PVector leftVelocity = getPrevVelocity(i - 1, j);
  //       PVector rightVelocity = getPrevVelocity(i + 1, j);
  //       PVector topVelocity = getPrevVelocity(i, j - 1);
  //       PVector bottomVelocity = getPrevVelocity(i, j + 1);
  //       PVector total = PVector
  //         .add(leftVelocity, rightVelocity)
  //         .add(topVelocity)
  //         .add(bottomVelocity);
  //       velocities[i][j] = PVector
  //         .mult(prevVelocities[i][j], centerRatio)
  //         .add(total.mult(surroundRatio));
  //     }
  //   }
  //   copyVelocitiesToPrevVelocities();
  // }
  //
  // private void updatePressure() {
  //   // Incompressible
  //   // TODO: case of boundary
  //   // SOR (Successive over-relaxation)
  //   int numSorRepeat = 3;
  //   float sorRelaxationFactor = 1.0; // should more than 1
  //   // h = dx = dy = rectSize
  //   // Density [rho]
  //   // poissonCoef = h * rho / dt
  //   float poissonCoef = 0.1;
  //   for (int k = 0; k < numSorRepeat; k++) {
  //     for (int j = 0; j < numGridY; j++) {
  //       for (int i = 0; i < numGridX; i++) {
  //         pressures[i][j] =
  //           (1 - sorRelaxationFactor) * getPrevPressure(i, j) +
  //           sorRelaxationFactor * calculatePoissonsEquation(i, j, poissonCoef);
  //       }
  //     }
  //     for (int j = 0; j < numGridY; j++) {
  //       for (int i = 0; i < numGridX; i++) {
  //         prevPressures[i][j] = pressures[i][j];
  //       }
  //     }
  //   }
  //   for (int j = 0; j < numGridY; j++) {
  //     for (int i = 0; i < numGridX; i++) {
  //       float leftPressure = getPrevPressure(i - 1, j);
  //       float rightPressure = getPrevPressure(i + 1, j);
  //       float topPressure = getPrevPressure(i, j - 1);
  //       float bottomPressure = getPrevPressure(i, j + 1);
  //       velocities[i][j] = PVector
  //         .add(prevVelocities[i][j], new PVector(
  //           leftPressure - rightPressure,
  //           topPressure - bottomPressure
  //         ).div(poissonCoef));
  //     }
  //   }
  //   copyVelocitiesToPrevVelocities();
  // }
  //
  // private float calculatePoissonsEquation(
  //   int gridIndexX, int gridIndexY, float poissonCoef) {
  //   // PVector centerVelocity = getPrevVelocity(i, j);
  //   PVector leftVelocity = getPrevVelocity(gridIndexX - 1, gridIndexY);
  //   PVector rightVelocity = getPrevVelocity(gridIndexX + 1, gridIndexY);
  //   PVector topVelocity = getPrevVelocity(gridIndexX, gridIndexY - 1);
  //   PVector bottomVelocity = getPrevVelocity(gridIndexX, gridIndexY + 1);
  //   float divVelocity = poissonCoef *
  //     (rightVelocity.x - leftVelocity.x + bottomVelocity.y - topVelocity.y);
  //   float leftPressure = getPrevPressure(gridIndexX - 1, gridIndexY);
  //   float rightPressure = getPrevPressure(gridIndexX + 1, gridIndexY);
  //   float topPressure = getPrevPressure(gridIndexX, gridIndexY - 1);
  //   float bottomPressure = getPrevPressure(gridIndexX, gridIndexY + 1);
  //   return (leftPressure + rightPressure + topPressure + bottomPressure -
  //     divVelocity) / 4.0;
  // }
  //
  private void copyVelocitiesToPrevVelocities() {
    for (int j = 0; j < numGridY; j++) {
      for (int i = 0; i < numGridX + 1; i++) {
        prevVelocitiesX[i][j] = velocitiesX[i][j];
      }
    }
    for (int j = 0; j < numGridY + 1; j++) {
      for (int i = 0; i < numGridX; i++) {
        prevVelocitiesY[i][j] = velocitiesY[i][j];
      }
    }
  }

  private float getPrevVelocityX(int xIndexX, int xIndexY) {
    if (xIndexX < 0 || xIndexX >= numGridX + 1 ||
      xIndexY < 0 || xIndexY >= numGridY) {
      return 0.0;
    }
    return prevVelocitiesX[xIndexX][xIndexY];
  }

  private float getPrevVelocityY(int yIndexX, int yIndexY) {
    if (yIndexX < 0 || yIndexX >= numGridX ||
      yIndexY < 0 || yIndexY >= numGridY + 1) {
      return 0.0;
    }
    return prevVelocitiesY[yIndexX][yIndexY];
  }
  //
  // private float getPrevPressure(int gridIndexX, int gridIndexY) {
  //   if (gridIndexX < 0 || gridIndexX >= numGridX ||
  //     gridIndexY < 0 || gridIndexY >= numGridY) {
  //     return 0.0;
  //   }
  //   return prevPressures[gridIndexX][gridIndexY];
  // }
  //
  public void addLerpVelocity(PVector position, PVector velocity) {
    // For X
    PVector xIndexF = PVector.div(position, gridSize).sub(0.0, 0.5);
    int xIndexX = floor(xIndexF.x);
    int xIndexY = floor(xIndexF.y);
    PVector coefX = new PVector(xIndexF.x - xIndexX, xIndexF.y - xIndexY);
    addVelocityX(xIndexX, xIndexY, velocity.x * (1 - coefX.x) * (1 - coefX.y));
    addVelocityX(xIndexX + 1, xIndexY, velocity.x * coefX.x * (1 - coefX.y));
    addVelocityX(xIndexX, xIndexY + 1, velocity.x * (1 - coefX.x) * coefX.y);
    addVelocityX(xIndexX + 1, xIndexY + 1, velocity.x * coefX.x * coefX.y);
    // For Y
    PVector yIndexF = PVector.div(position, gridSize).sub(0.5, 0.0);
    int yIndexX = floor(yIndexF.x);
    int yIndexY = floor(yIndexF.y);
    PVector coefY = new PVector(yIndexF.x - yIndexX, yIndexF.y - yIndexY);
    addVelocityY(yIndexX, yIndexY, velocity.y * (1 - coefY.x) * (1 - coefY.y));
    addVelocityY(yIndexX + 1, yIndexY, velocity.y * coefY.x * (1 - coefY.y));
    addVelocityY(yIndexX, yIndexY + 1, velocity.y * (1 - coefY.x) * coefY.y);
    addVelocityY(yIndexX + 1, yIndexY + 1, velocity.y * coefY.x * coefY.y);
  }

  private void addVelocityX(int gridIndexX, int gridIndexY, float velocityX) {
    if (gridIndexX < 0 || gridIndexX >= numGridX ||
      gridIndexY < 0 || gridIndexY >= numGridY) {
      return;
    }
    prevVelocitiesX[gridIndexX][gridIndexY] += velocityX;
  }

  private void addVelocityY(int gridIndexX, int gridIndexY, float velocityY) {
    if (gridIndexX < 0 || gridIndexX >= numGridX ||
      gridIndexY < 0 || gridIndexY >= numGridY) {
      return;
    }
    prevVelocitiesY[gridIndexX][gridIndexY] += velocityY;
  }

  private PVector generatePosition(int gridIndexX, int gridIndexY) {
    return new PVector(gridIndexX, gridIndexY).add(0.5, 0.5).mult(gridSize);
  }

  void draw() {
    for (int i = 0; i < numGridX; i++) {
      for (int j = 0; j < numGridY; j++) {
        noStroke();
        fill(0);
        PVector position = generatePosition(i, j);
        float pressure = prevPressures[i][j];
        ellipse(position.x, position.y, pressure * 20, pressure * 20);
        stroke(0);
        noFill();
        float velocityX = (prevVelocitiesX[i][j] + prevVelocitiesX[i + 1][j]) / 2.0;
        float velocityY = (prevVelocitiesY[i][j] + prevVelocitiesY[i][j + 1]) / 2.0;
        line(
          position.x,
          position.y,
          position.x + velocityX * 5,
          position.y + velocityY * 5
        );
      }
    }
  }
}
