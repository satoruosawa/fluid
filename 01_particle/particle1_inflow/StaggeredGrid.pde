class StaggeredGrid {
  protected int gridWidth;
  protected int numGridX;
  protected int numGridY;
  protected float[][] prevVelocitiesX;
  protected float[][] velocitiesX;
  protected float[][] prevVelocitiesY;
  protected float[][] velocitiesY;
  protected float[][] prevPressures;
  protected float[][] pressures;
  protected boolean isBoundaryConditionFreeSlip;

  public StaggeredGrid(int gridWidth, int numGridX, int numGridY) {
    this.gridWidth = gridWidth;
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
    for (int j = 0; j < numGridY; j++) {
      for (int i = 0; i < numGridX; i++) {
        // semi-Lagrangian
        PVector position = convertPositionFromGridIndexF(new PVector(i, j));
        PVector prevVelocity = calculateCenterPrevVelocity(i, j);
        PVector backTracedPosition = PVector.sub(position, prevVelocity);
        PVector backTracedGridIndexF =
          convertGridIndexFFromPosition(backTracedPosition);
        PVector backTracedPrevVelocity =
          calculateLerpPrevVelocity(backTracedGridIndexF);
        addVelocityX(i - 0.5, j, backTracedPrevVelocity.x / 2.0);
        addVelocityX(i + 0.5, j, backTracedPrevVelocity.x / 2.0);
        addVelocityY(i, j - 0.5, backTracedPrevVelocity.y / 2.0);
        addVelocityY(i, j + 0.5, backTracedPrevVelocity.y / 2.0);
      }
    }
    copyVelocitiesToPrevVelocities();
  }

  protected void resetVelocities() {
    for (int j = 0; j < numGridY; j++) {
      for (int i = 0; i < numGridX + 1; i++) {
        velocitiesX[i][j] = 0.0;
      }
    }
    for (int j = 0; j < numGridY + 1; j++) {
      for (int i = 0; i < numGridX; i++) {
        velocitiesY[i][j] = 0.0;
      }
    }
  }

  protected void updateDiffusion() {
    // Explicit way
    // h = dx = dy = rectSize
    // Dynamic and kinematic viscosity [nu]
    // surroundRatio = nu * dt / (h * h)
    float surroundRatio = 0.2; // 0 - 0.25
    float centerRatio = 1 - 4 * surroundRatio;
    // or you can define this way
    // float centerRatio = 0.2; // 0 - 1
    // float surroundRatio = (1 - centerRatio) / 4.0;
    for (int j = 1; j < numGridY - 1; j++) {
      for (int i = 1; i < numGridX; i++) {
        float gridIndexXH = i - 0.5;
        int gridIndexY = j;
        float left = getPrevVelocityX(gridIndexXH - 1, gridIndexY);
        float right = getPrevVelocityX(gridIndexXH + 1, gridIndexY);
        float top = getPrevVelocityX(gridIndexXH, gridIndexY - 1);
        float bottom = getPrevVelocityX(gridIndexXH, gridIndexY + 1);
        float total = left + right + top + bottom;
        velocitiesX[i][j] =
          getPrevVelocityX(gridIndexXH, gridIndexY) * centerRatio +
          total * surroundRatio;
      }
    }
    for (int j = 1; j < numGridY; j++) {
      for (int i = 1; i < numGridX - 1; i++) {
        int gridIndexX = i;
        float gridIndexYH = j - 0.5;
        float left = getPrevVelocityY(gridIndexX - 1, gridIndexYH);
        float right = getPrevVelocityY(gridIndexX + 1, gridIndexYH);
        float top = getPrevVelocityY(gridIndexX, gridIndexYH - 1);
        float bottom = getPrevVelocityY(gridIndexX, gridIndexYH + 1);
        float total = left + right + top + bottom;
        velocitiesY[i][j] =
          getPrevVelocityY(gridIndexX, gridIndexYH) * centerRatio +
          total * surroundRatio;
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
      for (int i = 0; i < numGridX + 1; i++) {
        float leftPressure = getPrevPressure(i - 1, j);
        float rightPressure = getPrevPressure(i + 1, j);
        velocitiesX[i][j] = prevVelocitiesX[i][j] -
          (rightPressure - leftPressure) / poissonCoef;
      }
    }
    for (int j = 0; j < numGridY + 1; j++) {
      for (int i = 0; i < numGridX; i++) {
        float topPressure = getPrevPressure(i, j - 1);
        float bottomPressure = getPrevPressure(i, j + 1);
        velocitiesY[i][j] = prevVelocitiesY[i][j] -
          (bottomPressure - topPressure) / poissonCoef;
      }
    }
    copyVelocitiesToPrevVelocities();
  }

  protected float calculatePoissonsEquation(
    int gridIndexX, int gridIndexY, float poissonCoef) {
    float leftVelocityX = getPrevVelocityX(gridIndexX - 0.5, gridIndexY);
    float rightVelocityX = getPrevVelocityX(gridIndexX + 0.5, gridIndexY);
    float topVelocityY = getPrevVelocityY(gridIndexX, gridIndexY - 0.5);
    float bottomVelocityY = getPrevVelocityY(gridIndexX, gridIndexY + 0.5);
    float divVelocity = poissonCoef *
      (rightVelocityX - leftVelocityX + bottomVelocityY - topVelocityY);
    float leftPressure = getPrevPressure(gridIndexX - 1, gridIndexY);
    float rightPressure = getPrevPressure(gridIndexX + 1, gridIndexY);
    float topPressure = getPrevPressure(gridIndexX, gridIndexY - 1);
    float bottomPressure = getPrevPressure(gridIndexX, gridIndexY + 1);
    return (leftPressure + rightPressure + topPressure + bottomPressure -
      divVelocity) / 4.0;
  }

  protected void copyVelocitiesToPrevVelocities() {
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

  protected float getPrevPressure(int gridIndexX, int gridIndexY) {
    if (gridIndexX < 0 || gridIndexX >= numGridX ||
      gridIndexY < 0 || gridIndexY >= numGridY) {
      return 0.0;
    }
    return prevPressures[gridIndexX][gridIndexY];
  }

  public void addLerpPrevVelocity(PVector position, PVector velocity) {
    PVector gridIndexF = convertGridIndexFFromPosition(position.copy());
    addLerpPrevVelocityX(gridIndexF, velocity.x);
    addLerpPrevVelocityY(gridIndexF, velocity.y);
  }

  protected void addLerpPrevVelocityX(PVector gridIndexF, float velocityX) {
    if (gridIndexF.x < -0.5 || gridIndexF.x >= numGridX - 0.5 ||
      gridIndexF.y < 0.0 || gridIndexF.y >= numGridY - 1.0) {
      // Out of Field.
      return;
    }
    float leftH = floor(gridIndexF.x + 0.5) - 0.5;
    float coefX = gridIndexF.x - leftH;
    int top = int(gridIndexF.y);
    float coefY = gridIndexF.y - top;
    addPrevVelocityX(leftH, top, velocityX * (1 - coefX) * (1 - coefY));
    addPrevVelocityX(leftH + 1, top, velocityX * coefX * (1 - coefY));
    addPrevVelocityX(leftH, top + 1, velocityX * (1 - coefX) * coefY);
    addPrevVelocityX(leftH + 1, top + 1, velocityX * coefX * coefY);
  }

  protected void addPrevVelocityX(
    float gridIndexXH, int gridIndexY, float velocityX) {
    // gridIndexXH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = int(gridIndexXH + 1.0);
    int indexY = gridIndexY;
    if (indexX < 0 || indexX >= numGridX + 1 ||
      indexY < 0 || indexY >= numGridY) {
      println("No index in prevVelocitiesX. @addPrevVelocityX");
      return;
    }
    prevVelocitiesX[indexX][indexY] += velocityX;
  }

  protected void addVelocityX(
    float gridIndexXH, int gridIndexY, float velocityX) {
    // gridIndexXH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = int(gridIndexXH + 1.0);
    int indexY = gridIndexY;
    if (indexX < 0 || indexX >= numGridX + 1 ||
      indexY < 0 || indexY >= numGridY) {
      println("No index in velocitiesX. @addVelocityX");
      return;
    }
    velocitiesX[indexX][indexY] += velocityX;
  }

  protected void addLerpPrevVelocityY(PVector gridIndexF, float velocityY) {
    if (gridIndexF.x < 0.0 || gridIndexF.x >= numGridX - 1.0 ||
      gridIndexF.y < -0.5 || gridIndexF.y >= numGridY - 0.5) {
      // Out of Field.
      return;
    }
    int leftX = int(gridIndexF.x);
    float coefX = gridIndexF.x - leftX;
    float topYH = floor(gridIndexF.y + 0.5) - 0.5;
    float coefY = gridIndexF.y - topYH;
    addPrevVelocityY(leftX, topYH, velocityY * (1 - coefX) * (1 - coefY));
    addPrevVelocityY(leftX + 1, topYH, velocityY * coefX * (1 - coefY));
    addPrevVelocityY(leftX, topYH + 1, velocityY * (1 - coefX) * coefY);
    addPrevVelocityY(leftX + 1, topYH + 1, velocityY * coefX * coefY);
  }

  protected void addPrevVelocityY(
    int gridIndexX, float gridIndexYH, float velocityY) {
    // gridIndexYH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = gridIndexX;
    int indexY = int(gridIndexYH + 1.0);
    if (indexX < 0 || indexX >= numGridX ||
      indexY < 0 || indexY >= numGridY + 1) {
      println("No index in prevVelocitiesY. @addPrevVelocityY");
      return;
    }
    prevVelocitiesY[indexX][indexY] += velocityY;
  }

  protected void addVelocityY(
    int gridIndexX, float gridIndexYH, float velocityY) {
    // gridIndexYH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = gridIndexX;
    int indexY = int(gridIndexYH + 1.0);
    if (indexX < 0 || indexX >= numGridX ||
      indexY < 0 || indexY >= numGridY + 1) {
      println("No index in velocitiesY. @addVelocityY");
      return;
    }
    velocitiesY[indexX][indexY] += velocityY;
  }

  public PVector convertPositionFromGridIndexF(PVector gridIndexF) {
    return gridIndexF.add(0.5, 0.5).mult(gridWidth);
  }

  public PVector convertGridIndexFFromPosition(PVector position) {
    return position.div(gridWidth).sub(0.5, 0.5);
  }

  protected PVector calculateLerpPrevVelocity(PVector gridIndexF) {
    if (gridIndexF.x < 0.5 || gridIndexF.x >= numGridX - 1.5 ||
      gridIndexF.y < 0.5 || gridIndexF.y >= numGridY - 1.5) {
      // Out of Field.
      return new PVector(0, 0);
    }
    return new PVector(
      calculateLerpPrevVelocityX(gridIndexF),
      calculateLerpPrevVelocityY(gridIndexF)
    );
  }

  protected PVector calculateCenterPrevVelocity(int gridIndexX, int gridIndexY) {
    if (gridIndexX < 0 || gridIndexX >= numGridX ||
      gridIndexY < 0 || gridIndexY >= numGridY) {
      println("Out of field. @calculateCenterPrevVelocity");
      return new PVector();
    }
    float prevVelocityX = (getPrevVelocityX(gridIndexX - 0.5, gridIndexY) +
      getPrevVelocityX(gridIndexX + 0.5, gridIndexY)) / 2.0;
    float prevVelocityY = (getPrevVelocityY(gridIndexX, gridIndexY - 0.5) +
      getPrevVelocityY(gridIndexX, gridIndexY + 0.5)) / 2.0;
    return new PVector(prevVelocityX, prevVelocityY);
  }

  protected float calculateLerpPrevVelocityX(PVector gridIndexF) {
    if (gridIndexF.x < -0.5 || gridIndexF.x >= numGridX - 0.5 ||
      gridIndexF.y < 0.0 || gridIndexF.y >= numGridY - 1.0) {
      // Out of Field.
      return 0.0;
    }
    float leftH = floor(gridIndexF.x + 0.5) - 0.5;
    float coefX = gridIndexF.x - leftH;
    int top = int(gridIndexF.y);
    float coefY = gridIndexF.y - top;
    float topLerp = lerp(
      getPrevVelocityX(leftH, top),
      getPrevVelocityX(leftH + 1, top),
      coefX
    );
    float bottomLerp = lerp(
      getPrevVelocityX(leftH, top + 1),
      getPrevVelocityX(leftH + 1, top + 1),
      coefX
    );
    return lerp(topLerp, bottomLerp, coefY);
  }

  protected float getPrevVelocityX(float gridIndexXH, int gridIndexY) {
    // gridIndexXH should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = int(gridIndexXH + 1.0);
    int indexY = gridIndexY;
    if (indexX < 0 || indexX >= numGridX + 1 ||
      indexY < 0 || indexY >= numGridY) {
      println("No index in prevVelocitiesX. @getPrevVelocityX");
      return 0.0;
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

  protected float calculateLerpPrevVelocityY(PVector gridIndexF) {
    if (gridIndexF.x < 0.0 || gridIndexF.x >= numGridX - 1.0 ||
      gridIndexF.y < -0.5 || gridIndexF.y >= numGridY - 0.5) {
      // Out of Field.
      return 0.0;
    }
    int left = int(gridIndexF.x);
    float coefX = gridIndexF.x - left;
    float topH = floor(gridIndexF.y + 0.5) - 0.5;
    float coefY = gridIndexF.y - topH;
    float topLerp = lerp(
      getPrevVelocityY(left, topH),
      getPrevVelocityY(left + 1, topH),
      coefX
    );
    float bottomLerp = lerp(
      getPrevVelocityY(left, topH + 1),
      getPrevVelocityY(left + 1, topH + 1),
      coefX
    );
    return lerp(topLerp, bottomLerp, coefY);
  }

  protected float getPrevVelocityY(int gridIndexX, float gridIndexYH) {
    // gridIndexY should be -0.5, 0.5, 1.5, 2.5, ...
    int indexX = gridIndexX;
    int indexY = int(gridIndexYH + 1.0);
    if (indexX < 0 || indexX >= numGridX ||
      indexY < 0 || indexY >= numGridY + 1) {
      println("No index in prevVelocitiesY. @getPrevVelocityY");
      return 0.0;
    }
    if (indexY == 1 || indexY == numGridY - 1) {
      // On the wall
      return 0.0;
    } else if (indexY == 0) {
      // In the wall
      return -prevVelocitiesY[indexX][2];
    } else if (indexY == numGridY) {
      // In the wall
      return -prevVelocitiesY[indexX][numGridY - 2];
    }
    if (indexX == 0) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesY[1][indexY];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesY[1][indexY];
    } else if (indexX == numGridX - 1) {
      if (isBoundaryConditionFreeSlip) {
        // Free-slip condition(Neumann boundary condition)
        return prevVelocitiesY[indexX - 2][indexY];
      }
      // Non-slip condition(Dirichlet boundary condition)
      return -prevVelocitiesY[indexX - 2][indexY];
    }
    return prevVelocitiesY[indexX][indexY];
  }

  public void draw() {
    for (int j = 0; j < numGridY; j++) {
      for (int i = 0; i < numGridX; i++) {
        noStroke();
        fill(0, 0, 200);
        PVector position = convertPositionFromGridIndexF(new PVector(i, j));
        float pressure = prevPressures[i][j];
        ellipse(position.x, position.y, pressure * 20, pressure * 20);
        stroke(200, 0, 0);
        strokeWeight(1);
        noFill();
        PVector velocity = calculateCenterPrevVelocity(i, j);
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
