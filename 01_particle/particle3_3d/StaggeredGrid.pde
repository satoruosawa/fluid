class StaggeredGrid {
  protected int gridSize;
  protected int numGridX;
  protected int numGridY;
  protected int numGridZ;
  protected float[][][] prevVelocitiesX;
  protected float[][][] velocitiesX;
  protected float[][][] prevVelocitiesY;
  protected float[][][] velocitiesY;
  protected float[][][] prevVelocitiesZ;
  protected float[][][] velocitiesZ;
  protected float[][][] prevPressures;
  protected float[][][] pressures;
  protected boolean isBoundaryConditionFreeSlip;

  public StaggeredGrid(int gridSize, int numGridX, int numGridY, int numGridZ) {
    this.gridSize = gridSize;
    this.numGridX = numGridX;
    this.numGridY = numGridY;
    this.numGridZ = numGridZ;
    prevVelocitiesX = new float[numGridX + 1][numGridY][numGridZ];
    velocitiesX = new float[numGridX + 1][numGridY][numGridZ];
    for (int k = 0; k < numGridZ; k++) {
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX + 1; i++) {
          prevVelocitiesX[i][j][k] = 0.0;
          velocitiesX[i][j][k] = 0.0;
        }
      }
    }
    prevVelocitiesY = new float[numGridX][numGridY + 1][numGridZ];
    velocitiesY = new float[numGridX][numGridY + 1][numGridZ];
    for (int k = 0; k < numGridZ; k++) {
      for (int j = 0; j < numGridY + 1; j++) {
        for (int i = 0; i < numGridX; i++) {
          prevVelocitiesY[i][j][k] = 0.0;
          velocitiesY[i][j][k] = 0.0;
        }
      }
    }
    prevVelocitiesZ = new float[numGridX][numGridY][numGridZ + 1];
    velocitiesZ = new float[numGridX][numGridY][numGridZ + 1];
    for (int k = 0; k < numGridZ + 1; k++) {
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX; i++) {
          prevVelocitiesZ[i][j][k] = 0.0;
          velocitiesZ[i][j][k] = 0.0;
        }
      }
    }
    prevPressures = new float[numGridX][numGridY][numGridZ];
    pressures = new float[numGridX][numGridY][numGridZ];
    for (int k = 0; k < numGridZ; k++) {
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX; i++) {
          prevPressures[i][j][k] = 0.0;
          pressures[i][j][k] = 0.0;
        }
      }
    }
    isBoundaryConditionFreeSlip = true;
  }

  public void update() {
    // Navier Stokes equations
    updteConvection();
    updateDiffusion();
    updatePressure();
  }

  protected void updteConvection() {
    resetVelocities();
    for (int k = 0; k < numGridZ; k++) {
      for (int j = 0; j < numGridY; j++) {
      for (int i = 0; i < numGridX; i++) {
        // semi-Lagrangian
        PVector position = convertPositionFromGridIndexF(new PVector(i, j, k));
        PVector prevVelocity = calculateCenterPrevVelocity(i, j, k);
        PVector backTracedPosition = PVector.sub(position, prevVelocity);
        PVector backTracedGridIndexF =
          convertGridIndexFFromPosition(backTracedPosition);
        PVector backTracedPrevVelocity =
          calculateLerpPrevVelocity(backTracedGridIndexF);
        addVelocityX(i - 0.5, j, k, backTracedPrevVelocity.x / 2.0);
        addVelocityX(i + 0.5, j, k, backTracedPrevVelocity.x / 2.0);
        addVelocityY(i, j - 0.5, k, backTracedPrevVelocity.y / 2.0);
        addVelocityY(i, j + 0.5, k, backTracedPrevVelocity.y / 2.0);
        addVelocityZ(i, j, k - 0.5, backTracedPrevVelocity.z / 2.0);
        addVelocityZ(i, j, k + 0.5, backTracedPrevVelocity.z / 2.0);
      }
    }
  }
    copyVelocitiesToPrevVelocities();
  }

  protected void resetVelocities() {
    for (int k = 0; k < numGridZ; k++) {
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX + 1; i++) {
          velocitiesX[i][j][k] = 0.0;
        }
      }
    }
    for (int k = 0; k < numGridZ; k++) {
      for (int j = 0; j < numGridY + 1; j++) {
        for (int i = 0; i < numGridX; i++) {
          velocitiesY[i][j][k] = 0.0;
        }
      }
    }
    for (int k = 0; k < numGridZ + 1; k++) {
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX; i++) {
          velocitiesZ[i][j][k] = 0.0;
        }
      }
    }
  }

  protected void updateDiffusion() {
    // Explicit way
    // h = dx = dy = rectSize
    // Dynamic and kinematic viscosity [nu]
    // surroundRatio = nu * dt / (h * h)
    float surroundRatio = 0.16; // 0 - (1 / 6.0)
    float centerRatio = 1 - 6 * surroundRatio;
    // or you can define this way
    // float centerRatio = 0.16; // 0 - 1
    // float surroundRatio = (1 - centerRatio) / 6.0;
    for (int k = 1; k < numGridZ - 1; k++) {
      for (int j = 1; j < numGridY - 1; j++) {
        for (int i = 1; i < numGridX; i++) {
          float gridIndexXH = i - 0.5;
          int gridIndexY = j;
          int gridIndexZ = k;
          float left = getPrevVelocityX(gridIndexXH - 1, gridIndexY, gridIndexZ);
          float right = getPrevVelocityX(gridIndexXH + 1, gridIndexY, gridIndexZ);
          float top = getPrevVelocityX(gridIndexXH, gridIndexY - 1, gridIndexZ);
          float bottom = getPrevVelocityX(gridIndexXH, gridIndexY + 1, gridIndexZ);
          float back = getPrevVelocityX(gridIndexXH, gridIndexY, gridIndexZ - 1);
          float front = getPrevVelocityX(gridIndexXH, gridIndexY, gridIndexZ + 1);
          float total = left + right + top + bottom + back + front;
          velocitiesX[i][j][k] =
            getPrevVelocityX(gridIndexXH, gridIndexY, gridIndexZ) * centerRatio +
            total * surroundRatio;
        }
      }
    }
    for (int k = 1; k < numGridZ - 1; k++) {
      for (int j = 1; j < numGridY; j++) {
        for (int i = 1; i < numGridX - 1; i++) {
          int gridIndexX = i;
          float gridIndexYH = j - 0.5;
          int gridIndexZ = k;
          float left = getPrevVelocityY(gridIndexX - 1, gridIndexYH, gridIndexZ);
          float right = getPrevVelocityY(gridIndexX + 1, gridIndexYH, gridIndexZ);
          float top = getPrevVelocityY(gridIndexX, gridIndexYH - 1, gridIndexZ);
          float bottom = getPrevVelocityY(gridIndexX, gridIndexYH + 1, gridIndexZ);
          float back = getPrevVelocityY(gridIndexX, gridIndexYH, gridIndexZ - 1);
          float front = getPrevVelocityY(gridIndexX, gridIndexYH, gridIndexZ + 1);
          float total = left + right + top + bottom + back + front;
          velocitiesY[i][j][k] =
            getPrevVelocityY(gridIndexX, gridIndexYH, gridIndexZ) * centerRatio +
            total * surroundRatio;
        }
      }
    }
    for (int k = 1; k < numGridZ; k++) {
      for (int j = 1; j < numGridY - 1; j++) {
        for (int i = 1; i < numGridX - 1; i++) {
          int gridIndexX = i;
          int gridIndexY = j;
          float gridIndexZH = k - 0.5;
          float left = getPrevVelocityZ(gridIndexX - 1, gridIndexY, gridIndexZH);
          float right = getPrevVelocityZ(gridIndexX + 1, gridIndexY, gridIndexZH);
          float top = getPrevVelocityZ(gridIndexX, gridIndexY - 1, gridIndexZH);
          float bottom = getPrevVelocityZ(gridIndexX, gridIndexY + 1, gridIndexZH);
          float back = getPrevVelocityZ(gridIndexX, gridIndexY, gridIndexZH - 1);
          float front = getPrevVelocityZ(gridIndexX, gridIndexY, gridIndexZH + 1);
          float total = left + right + top + bottom + back + front;
          velocitiesZ[i][j][k] =
            getPrevVelocityZ(gridIndexX, gridIndexY, gridIndexZH) * centerRatio +
            total * surroundRatio;
        }
      }
    }
    copyVelocitiesToPrevVelocities();
  }

  protected void updatePressure() {
    // Incompressible
    // SOR (Successive over-relaxation)
    int numSorRepeat = 3;
    float sorRelaxationFactor = 1.0; // should more than 1
    // h = dx = dy = rectSize
    // Density [rho]
    // poissonCoef = h * rho / dt
    float poissonCoef = 0.01;
    for (int l = 0; l < numSorRepeat; l++) {
      for (int k = 0; k < numGridZ; k++) {
        for (int j = 0; j < numGridY; j++) {
          for (int i = 0; i < numGridX; i++) {
            pressures[i][j][k] =
              (1 - sorRelaxationFactor) * getPrevPressure(i, j, k) +
              sorRelaxationFactor * calculatePoissonsEquation(i, j, k, poissonCoef);
          }
        }
      }
      for (int k = 0; k < numGridZ; k++) {
        for (int j = 0; j < numGridY; j++) {
          for (int i = 0; i < numGridX; i++) {
            prevPressures[i][j][k] = pressures[i][j][k];
          }
        }
      }
    }
    for (int k = 0; k < numGridZ; k++) {
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX + 1; i++) {
          float leftPressure = getPrevPressure(i - 1, j, k);
          float rightPressure = getPrevPressure(i + 1, j, k);
          velocitiesX[i][j][k] = prevVelocitiesX[i][j][k] -
            (rightPressure - leftPressure) / poissonCoef;
        }
      }
    }
    for (int k = 0; k < numGridZ; k++) {
      for (int j = 0; j < numGridY + 1; j++) {
        for (int i = 0; i < numGridX; i++) {
          float topPressure = getPrevPressure(i, j - 1, k);
          float bottomPressure = getPrevPressure(i, j + 1, k);
          velocitiesY[i][j][k] = prevVelocitiesY[i][j][k] -
            (bottomPressure - topPressure) / poissonCoef;
        }
      }
    }
    for (int k = 0; k < numGridZ + 1; k++) {
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX; i++) {
          float backPressure = getPrevPressure(i, j, k - 1);
          float frontPressure = getPrevPressure(i, j, k + 1);
          velocitiesZ[i][j][k] = prevVelocitiesZ[i][j][k] -
            (frontPressure - backPressure) / poissonCoef;
        }
      }
    }
    copyVelocitiesToPrevVelocities();
  }

  protected float calculatePoissonsEquation(
    int gridIndexX, int gridIndexY, int gridIndexZ, float poissonCoef) {
    float leftVelocityX = getPrevVelocityX(gridIndexX - 0.5, gridIndexY, gridIndexZ);
    float rightVelocityX = getPrevVelocityX(gridIndexX + 0.5, gridIndexY, gridIndexZ);
    float topVelocityY = getPrevVelocityY(gridIndexX, gridIndexY - 0.5, gridIndexZ);
    float bottomVelocityY = getPrevVelocityY(gridIndexX, gridIndexY + 0.5, gridIndexZ);
    float backVelocityZ = getPrevVelocityZ(gridIndexX, gridIndexY, gridIndexZ - 0.5);
    float frontVelocityZ = getPrevVelocityZ(gridIndexX, gridIndexY, gridIndexZ + 0.5);
    float divVelocity = poissonCoef *
      (rightVelocityX - leftVelocityX +
        bottomVelocityY - topVelocityY +
        frontVelocityZ - backVelocityZ);
    float leftPressure = getPrevPressure(gridIndexX - 1, gridIndexY, gridIndexZ);
    float rightPressure = getPrevPressure(gridIndexX + 1, gridIndexY, gridIndexZ);
    float topPressure = getPrevPressure(gridIndexX, gridIndexY - 1, gridIndexZ);
    float bottomPressure = getPrevPressure(gridIndexX, gridIndexY + 1, gridIndexZ);
    float backPressure = getPrevPressure(gridIndexX, gridIndexY, gridIndexZ - 1);
    float frontPressure = getPrevPressure(gridIndexX, gridIndexY, gridIndexZ + 1);
    return (leftPressure + rightPressure +
      topPressure + bottomPressure +
      backPressure + frontPressure -
      divVelocity) / 6.0;
  }

  protected void copyVelocitiesToPrevVelocities() {
    for (int k = 0; k < numGridZ; k++) {
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX + 1; i++) {
          prevVelocitiesX[i][j][k] = velocitiesX[i][j][k];
        }
      }
    }
    for (int k = 0; k < numGridZ; k++) {
      for (int j = 0; j < numGridY + 1; j++) {
        for (int i = 0; i < numGridX; i++) {
          prevVelocitiesY[i][j][k] = velocitiesY[i][j][k];
        }
      }
    }
    for (int k = 0; k < numGridZ + 1; k++) {
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX; i++) {
          prevVelocitiesZ[i][j][k] = velocitiesZ[i][j][k];
        }
      }
    }
  }

  protected float getPrevPressure(
    int gridIndexX, int gridIndexY, int gridIndexZ) {
    if (gridIndexX < 0 || gridIndexX >= numGridX ||
      gridIndexY < 0 || gridIndexY >= numGridY ||
      gridIndexZ < 0 || gridIndexZ >= numGridZ) {
      return 0.0;
    }
    return prevPressures[gridIndexX][gridIndexY][gridIndexZ];
  }

  public void addLerpPrevVelocity(PVector position, PVector velocity) {
    PVector gridIndexF = convertGridIndexFFromPosition(position.copy());
    addLerpPrevVelocityX(gridIndexF, velocity.x);
    addLerpPrevVelocityY(gridIndexF, velocity.y);
    addLerpPrevVelocityZ(gridIndexF, velocity.z);
  }

  protected void addLerpPrevVelocityX(PVector gridIndexF, float velocityX) {
    if (gridIndexF.x < -0.5 || gridIndexF.x >= numGridX - 0.5 ||
      gridIndexF.y < 0.0 || gridIndexF.y >= numGridY - 1.0 ||
      gridIndexF.z < 0.0 || gridIndexF.z >= numGridZ - 1.0) {
      // Out of Field.
      return;
    }
    float leftH = floor(gridIndexF.x + 0.5) - 0.5;
    float coefX = gridIndexF.x - leftH;
    int top = int(gridIndexF.y);
    float coefY = gridIndexF.y - top;
    int back = int(gridIndexF.z);
    float coefZ = gridIndexF.z - back;
    addPrevVelocityX(leftH, top, back,
      velocityX * (1 - coefX) * (1 - coefY) * (1 - coefZ));
    addPrevVelocityX(leftH + 1, top, back,
      velocityX * coefX * (1 - coefY) * (1 - coefZ));
    addPrevVelocityX(leftH, top + 1, back,
      velocityX * (1 - coefX) * coefY * (1 - coefZ));
    addPrevVelocityX(leftH + 1, top + 1, back,
      velocityX * coefX * coefY * (1 - coefZ));
    addPrevVelocityX(leftH, top, back + 1,
      velocityX * (1 - coefX) * (1 - coefY) * coefZ);
    addPrevVelocityX(leftH + 1, top, back + 1,
      velocityX * coefX * (1 - coefY) * coefZ);
    addPrevVelocityX(leftH, top + 1, back + 1,
      velocityX * (1 - coefX) * coefY * coefZ);
    addPrevVelocityX(leftH + 1, top + 1, back + 1,
      velocityX * coefX * coefY * coefZ);
  }

  protected void addPrevVelocityX(
    float gridIndexXH, int gridIndexY, int gridIndexZ, float velocityX) {
    // gridIndexXH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = int(gridIndexXH + 1.0);
    int indexY = gridIndexY;
    int indexZ = gridIndexZ;
    if (indexX < 0 || indexX >= numGridX + 1 ||
      indexY < 0 || indexY >= numGridY ||
      indexZ < 0 || indexZ >= numGridZ) {
      println("No index in prevVelocitiesX. @addPrevVelocityX");
      return;
    }
    prevVelocitiesX[indexX][indexY][indexZ] += velocityX;
  }

  protected void addVelocityX(
    float gridIndexXH, int gridIndexY, int gridIndexZ, float velocityX) {
    // gridIndexXH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = int(gridIndexXH + 1.0);
    int indexY = gridIndexY;
    int indexZ = gridIndexZ;
    if (indexX < 0 || indexX >= numGridX + 1 ||
      indexY < 0 || indexY >= numGridY ||
      indexZ < 0 || indexZ >= numGridZ) {
      println("No index in velocitiesX. @addVelocityX");
      return;
    }
    velocitiesX[indexX][indexY][indexZ] += velocityX;
  }

  protected void addLerpPrevVelocityY(PVector gridIndexF, float velocityY) {
    if (gridIndexF.x < 0.0 || gridIndexF.x >= numGridX - 1.0 ||
      gridIndexF.y < -0.5 || gridIndexF.y >= numGridY - 0.5 ||
      gridIndexF.z < 0.0 || gridIndexF.z >= numGridZ - 1.0) {
      // Out of Field.
      return;
    }
    int leftX = int(gridIndexF.x);
    float coefX = gridIndexF.x - leftX;
    float topYH = floor(gridIndexF.y + 0.5) - 0.5;
    float coefY = gridIndexF.y - topYH;
    int backZ = int(gridIndexF.z);
    float coefZ = gridIndexF.z - backZ;
    addPrevVelocityY(leftX, topYH, backZ, velocityY * (1 - coefX) * (1 - coefY) * (1 - coefZ));
    addPrevVelocityY(leftX + 1, topYH, backZ, velocityY * coefX * (1 - coefY) * (1 - coefZ));
    addPrevVelocityY(leftX, topYH + 1, backZ, velocityY * (1 - coefX) * coefY * (1 - coefZ));
    addPrevVelocityY(leftX + 1, topYH + 1, backZ, velocityY * coefX * coefY * (1 - coefZ));
    addPrevVelocityY(leftX, topYH, backZ + 1, velocityY * (1 - coefX) * (1 - coefY) * coefZ);
    addPrevVelocityY(leftX + 1, topYH, backZ + 1, velocityY * coefX * (1 - coefY) * coefZ);
    addPrevVelocityY(leftX, topYH + 1, backZ + 1, velocityY * (1 - coefX) * coefY * coefZ);
    addPrevVelocityY(leftX + 1, topYH + 1, backZ + 1, velocityY * coefX * coefY * coefZ);
  }

  protected void addPrevVelocityY(
    int gridIndexX, float gridIndexYH, int gridIndexZ, float velocityY) {
    // gridIndexYH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = gridIndexX;
    int indexY = int(gridIndexYH + 1.0);
    int indexZ = gridIndexZ;
    if (indexX < 0 || indexX >= numGridX ||
      indexY < 0 || indexY >= numGridY + 1 ||
      indexZ < 0 || indexZ >= numGridZ) {
      println("No index in prevVelocitiesY. @addPrevVelocityY");
      return;
    }
    prevVelocitiesY[indexX][indexY][indexZ] += velocityY;
  }

  protected void addVelocityY(
    int gridIndexX, float gridIndexYH, int gridIndexZ, float velocityY) {
    // gridIndexYH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = gridIndexX;
    int indexY = int(gridIndexYH + 1.0);
    int indexZ = gridIndexZ;
    if (indexX < 0 || indexX >= numGridX ||
      indexY < 0 || indexY >= numGridY + 1 ||
      indexZ < 0 || indexZ >= numGridZ) {
      println("No index in velocitiesY. @addVelocityY");
      return;
    }
    velocitiesY[indexX][indexY][indexZ] += velocityY;
  }

  protected void addLerpPrevVelocityZ(PVector gridIndexF, float velocityZ) {
    if (gridIndexF.x < 0.0 || gridIndexF.x >= numGridX - 1.0 ||
      gridIndexF.y < 0.0 || gridIndexF.y >= numGridY - 1.0 ||
      gridIndexF.z < -0.5 || gridIndexF.z >= numGridZ - 0.5) {
      // Out of Field.
      return;
    }
    int leftX = int(gridIndexF.x);
    float coefX = gridIndexF.x - leftX;
    int topY = int(gridIndexF.y);
    float coefY = gridIndexF.y - topY;
    float backZH = floor(gridIndexF.z + 0.5) - 0.5;
    float coefZ = gridIndexF.z - backZH;
    addPrevVelocityZ(leftX, topY, backZH, velocityZ * (1 - coefX) * (1 - coefY) * (1 - coefZ));
    addPrevVelocityZ(leftX + 1, topY, backZH, velocityZ * coefX * (1 - coefY) * (1 - coefZ));
    addPrevVelocityZ(leftX, topY + 1, backZH, velocityZ * (1 - coefX) * coefY * (1 - coefZ));
    addPrevVelocityZ(leftX + 1, topY + 1, backZH, velocityZ * coefX * coefY * (1 - coefZ));
    addPrevVelocityZ(leftX, topY, backZH + 1, velocityZ * (1 - coefX) * (1 - coefY) * coefZ);
    addPrevVelocityZ(leftX + 1, topY, backZH + 1, velocityZ * coefX * (1 - coefY) * coefZ);
    addPrevVelocityZ(leftX, topY + 1, backZH + 1, velocityZ * (1 - coefX) * coefY * coefZ);
    addPrevVelocityZ(leftX + 1, topY + 1, backZH + 1, velocityZ * coefX * coefY * coefZ);
  }

  protected void addPrevVelocityZ(
    int gridIndexX, int gridIndexY, float gridIndexZH, float velocityZ) {
    // gridIndexZH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = gridIndexX;
    int indexY = gridIndexY;
    int indexZ = int(gridIndexZH + 1.0);
    if (indexX < 0 || indexX >= numGridX ||
      indexY < 0 || indexY >= numGridY ||
      indexZ < 0 || indexZ >= numGridZ + 1) {
      println("No index in prevVelocitiesZ. @addPrevVelocityZ");
      return;
    }
    prevVelocitiesZ[indexX][indexY][indexZ] += velocityZ;
  }

  protected void addVelocityZ(
    int gridIndexX, int gridIndexY, float gridIndexZH, float velocityZ) {
    // gridIndexZH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = gridIndexX;
    int indexY = gridIndexY;
    int indexZ = int(gridIndexZH + 1.0);
    if (indexX < 0 || indexX >= numGridX ||
      indexY < 0 || indexY >= numGridY ||
      indexZ < 0 || indexZ >= numGridZ + 1) {
      println("No index in velocitiesZ. @addVelocityZ");
      return;
    }
    velocitiesZ[indexX][indexY][indexZ] += velocityZ;
  }

  public PVector convertPositionFromGridIndexF(PVector gridIndexF) {
    return gridIndexF.add(0.5, 0.5, 0.5).mult(gridSize);
  }

  public PVector convertGridIndexFFromPosition(PVector position) {
    return position.div(gridSize).sub(0.5, 0.5, 0.5);
  }

  protected PVector calculateLerpPrevVelocity(PVector gridIndexF) {
    if (gridIndexF.x < 0.5 || gridIndexF.x >= numGridX - 1.5 ||
      gridIndexF.y < 0.5 || gridIndexF.y >= numGridY - 1.5 ||
      gridIndexF.z < 0.5 || gridIndexF.z >= numGridZ - 1.5) {
      // Out of Field.
      return new PVector(0, 0, 0);
    }
    return new PVector(
      calculateLerpPrevVelocityX(gridIndexF),
      calculateLerpPrevVelocityY(gridIndexF),
      calculateLerpPrevVelocityZ(gridIndexF)
    );
  }

  protected PVector calculateCenterPrevVelocity(
    int gridIndexX, int gridIndexY, int gridIndexZ) {
    if (gridIndexX < 0 || gridIndexX >= numGridX ||
      gridIndexY < 0 || gridIndexY >= numGridY ||
      gridIndexZ < 0 || gridIndexZ >= numGridZ) {
      println("Out of field. @calculateCenterPrevVelocity");
      return new PVector();
    }
    float prevVelocityX = (
        getPrevVelocityX(gridIndexX - 0.5, gridIndexY, gridIndexZ) +
        getPrevVelocityX(gridIndexX + 0.5, gridIndexY, gridIndexZ)
      ) / 2.0;
    float prevVelocityY = (
        getPrevVelocityY(gridIndexX, gridIndexY - 0.5, gridIndexZ) +
        getPrevVelocityY(gridIndexX, gridIndexY + 0.5, gridIndexZ)
      ) / 2.0;
    float prevVelocityZ = (
        getPrevVelocityZ(gridIndexX, gridIndexY, gridIndexZ - 0.5) +
        getPrevVelocityZ(gridIndexX, gridIndexY, gridIndexZ + 0.5)
      ) / 2.0;
    return new PVector(prevVelocityX, prevVelocityY, prevVelocityZ);
  }

  protected float calculateLerpPrevVelocityX(PVector gridIndexF) {
    if (gridIndexF.x < -0.5 || gridIndexF.x >= numGridX - 0.5 ||
      gridIndexF.y < 0.0 || gridIndexF.y >= numGridY - 1.0 ||
      gridIndexF.z < 0.0 || gridIndexF.z >= numGridZ - 1.0) {
      // Out of Field.
      return 0.0;
    }
    float leftH = floor(gridIndexF.x + 0.5) - 0.5;
    float coefX = gridIndexF.x - leftH;
    int top = int(gridIndexF.y);
    float coefY = gridIndexF.y - top;
    int back = int(gridIndexF.z);
    float coefZ = gridIndexF.z - back;
    float topBackLerp = lerp(
      getPrevVelocityX(leftH, top, back),
      getPrevVelocityX(leftH + 1, top, back),
      coefX
    );
    float bottomBackLerp = lerp(
      getPrevVelocityX(leftH, top + 1, back),
      getPrevVelocityX(leftH + 1, top + 1, back),
      coefX
    );
    float backLerp = lerp(topBackLerp, bottomBackLerp, coefY);
    float topFrontLerp = lerp(
      getPrevVelocityX(leftH, top, back + 1),
      getPrevVelocityX(leftH + 1, top, back + 1),
      coefX
    );
    float bottomFrontLerp = lerp(
      getPrevVelocityX(leftH, top + 1, back + 1),
      getPrevVelocityX(leftH + 1, top + 1, back + 1),
      coefX
    );
    float frontLerp = lerp(topFrontLerp, bottomFrontLerp, coefY);
    return lerp(backLerp, frontLerp, coefZ);
  }

  protected float getPrevVelocityX(
    float gridIndexXH, int gridIndexY, int gridIndexZ) {
    // gridIndexXH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = int(gridIndexXH + 1.0);
    int indexY = gridIndexY;
    int indexZ = gridIndexZ;
    if (indexX < 0 || indexX >= numGridX + 1 ||
      indexY < 0 || indexY >= numGridY ||
      indexZ < 0 || indexZ >= numGridZ) {
      println("No index in prevVelocitiesX. @getPrevVelocityX");
      return 0.0;
    }
    if (indexX == 1 || indexX == numGridX - 1) {
      // On the wall
      return 0.0;
    } else if (indexX == 0) {
      // In the wall
      return -prevVelocitiesX[2][indexY][indexZ];
    } else if (indexX == numGridX) {
      // In the wall
      return -prevVelocitiesX[numGridX - 2][indexY][indexZ];
    }
    // XXX: Maybe Add condition indexY == 0 && indexZ == 0
    if (indexY == 0) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesX[indexX][1][indexZ];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesX[indexX][1][indexZ];
    } else if (indexY == numGridY - 1) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesX[indexX][numGridY - 2][indexZ];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesX[indexX][numGridY - 2][indexZ];
    }
    if (indexZ == 0) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesX[indexX][indexY][1];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesX[indexX][indexY][1];
    } else if (indexZ == numGridZ - 1) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesX[indexX][indexY][numGridZ - 2];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesX[indexX][indexY][numGridZ - 2];
    }
    return prevVelocitiesX[indexX][indexY][indexZ];
  }

  protected float calculateLerpPrevVelocityY(PVector gridIndexF) {
    if (gridIndexF.x < 0.0 || gridIndexF.x >= numGridX - 1.0 ||
      gridIndexF.y < -0.5 || gridIndexF.y >= numGridY - 0.5 ||
      gridIndexF.z < 0.0 || gridIndexF.z >= numGridZ - 1.0) {
      // Out of Field.
      return 0.0;
    }
    int left = int(gridIndexF.x);
    float coefX = gridIndexF.x - left;
    float topH = floor(gridIndexF.y + 0.5) - 0.5;
    float coefY = gridIndexF.y - topH;
    int back = int(gridIndexF.z);
    float coefZ = gridIndexF.z - back;
    float topBackLerp = lerp(
      getPrevVelocityY(left, topH, back),
      getPrevVelocityY(left + 1, topH, back),
      coefX
    );
    float bottomBackLerp = lerp(
      getPrevVelocityY(left, topH + 1, back),
      getPrevVelocityY(left + 1, topH + 1, back),
      coefX
    );
    float backLerp = lerp(topBackLerp, bottomBackLerp, coefY);
    float topFrontLerp = lerp(
      getPrevVelocityY(left, topH, back + 1),
      getPrevVelocityY(left + 1, topH, back + 1),
      coefX
    );
    float bottomFrontLerp = lerp(
      getPrevVelocityY(left, topH + 1, back + 1),
      getPrevVelocityY(left + 1, topH + 1, back + 1),
      coefX
    );
    float frontLerp = lerp(topFrontLerp, bottomFrontLerp, coefY);
    return lerp(backLerp, frontLerp, coefZ);
  }

  protected float getPrevVelocityY(
    int gridIndexX, float gridIndexYH, int gridIndexZ) {
    // gridIndexY should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = gridIndexX;
    int indexY = int(gridIndexYH + 1.0);
    int indexZ = gridIndexZ;
    if (indexX < 0 || indexX >= numGridX ||
      indexY < 0 || indexY >= numGridY + 1 ||
      indexZ < 0 || indexZ >= numGridZ) {
      println("No index in prevVelocitiesY. @getPrevVelocityY");
      return 0.0;
    }
    if (indexY == 1 || indexY == numGridY - 1) {
      // On the wall
      return 0.0;
    } else if (indexY == 0) {
      // In the wall
      return -prevVelocitiesY[indexX][2][indexZ];
    } else if (indexY == numGridY) {
      // In the wall
      return -prevVelocitiesY[indexX][numGridY - 2][indexZ];
    }
    // XXX: Maybe Add condition indexX == 0 && indexZ == 0
    if (indexX == 0) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesY[1][indexY][indexZ];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesY[1][indexY][indexZ];
    } else if (indexX == numGridX - 1) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesY[indexX - 2][indexY][indexZ];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesY[indexX - 2][indexY][indexZ];
    }
    if (indexZ == 0) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesY[indexX][indexY][1];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesY[indexX][indexY][1];
    } else if (indexZ == numGridZ - 1) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesY[indexX][indexY][numGridZ - 2];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesY[indexX][indexY][numGridZ - 2];
    }
    return prevVelocitiesY[indexX][indexY][indexZ];
  }

  protected float calculateLerpPrevVelocityZ(PVector gridIndexF) {
    if (gridIndexF.x < 0.0 || gridIndexF.x >= numGridX - 1.0 ||
      gridIndexF.y < 0.0 || gridIndexF.y >= numGridY - 1.0 ||
      gridIndexF.z < -0.5 || gridIndexF.z >= numGridZ - 0.5) {
      // Out of Field.
      return 0.0;
    }
    int left = int(gridIndexF.x);
    float coefX = gridIndexF.x - left;
    int top = int(gridIndexF.y);
    float coefY = gridIndexF.y - top;
    float backH = floor(gridIndexF.z + 0.5) - 0.5;
    float coefZ = gridIndexF.z - backH;
    float topBackLerp = lerp(
      getPrevVelocityZ(left, top, backH),
      getPrevVelocityZ(left + 1, top, backH),
      coefX
    );
    float bottomBackLerp = lerp(
      getPrevVelocityZ(left, top + 1, backH),
      getPrevVelocityZ(left + 1, top + 1, backH),
      coefX
    );
    float backLerp = lerp(topBackLerp, bottomBackLerp, coefY);
    float topFrontLerp = lerp(
      getPrevVelocityZ(left, top, backH + 1),
      getPrevVelocityZ(left + 1, top, backH + 1),
      coefX
    );
    float bottomFrontLerp = lerp(
      getPrevVelocityZ(left, top + 1, backH + 1),
      getPrevVelocityZ(left + 1, top + 1, backH + 1),
      coefX
    );
    float frontLerp = lerp(topFrontLerp, bottomFrontLerp, coefY);
    return lerp(backLerp, frontLerp, coefZ);
  }

  protected float getPrevVelocityZ(
    int gridIndexX, int gridIndexY, float gridIndexZH) {
    // gridIndexY should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = gridIndexX;
    int indexY = gridIndexY;
    int indexZ = int(gridIndexZH + 1.0);
    if (indexX < 0 || indexX >= numGridX ||
      indexY < 0 || indexY >= numGridY ||
      indexZ < 0 || indexZ >= numGridZ + 1) {
      println("No index in prevVelocitiesZ. @getPrevVelocityZ");
      return 0.0;
    }
    if (indexZ == 1 || indexZ == numGridZ - 1) {
      // On the wall
      return 0.0;
    } else if (indexZ == 0) {
      // In the wall
      return -prevVelocitiesZ[indexX][indexY][2];
    } else if (indexZ == numGridZ) {
      // In the wall
      return -prevVelocitiesZ[indexX][indexY][numGridZ - 2];
    }
    // XXX: Maybe Add condition indexX == 0 && indexZ == 0
    if (indexX == 0) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesZ[1][indexY][indexZ];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesZ[1][indexY][indexZ];
    } else if (indexX == numGridX - 1) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesZ[indexX - 2][indexY][indexZ];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesZ[indexX - 2][indexY][indexZ];
    }
    if (indexY == 0) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesZ[indexX][1][indexZ];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesZ[indexX][1][indexZ];
    } else if (indexY == numGridY - 1) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesZ[indexX][numGridY - 2][indexZ];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesZ[indexX][numGridY - 2][indexZ];
    }
    return prevVelocitiesZ[indexX][indexY][indexZ];
  }

  public void draw() {
    for (int k = 0; k < numGridZ; k++) {
      for (int j = 0; j < numGridY; j++) {
        for (int i = 0; i < numGridX; i++) {
          noStroke();
          fill(0, 0, 200);
          PVector position = convertPositionFromGridIndexF(new PVector(i, j, k));
          float pressure = prevPressures[i][j][k];
          pushMatrix(); {
            translate(position.x, position.y, position.z);
            box(pressure * 20, pressure * 20, pressure * 20);
          } popMatrix();
          stroke(200, 0, 0);
          strokeWeight(1);
          noFill();
          PVector velocity = calculateCenterPrevVelocity(i, j, k);
          line(
            position.x,
            position.y,
            position.z,
            position.x + velocity.x * 5,
            position.y + velocity.y * 5,
            position.z + velocity.z * 5
          );
        }
      }
    }
  }
}
