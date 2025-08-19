
final int cols = 100;
final int rows = 100;
final int cellSize = 8;

Spot[][] grid = new Spot[cols][rows];
ArrayList<Spot> openSet = new ArrayList<Spot>();
ArrayList<Spot> closedSet = new ArrayList<Spot>();
ArrayList<Spot> path = new ArrayList<Spot>();

Spot start, end;

float maxG = 1;
PGraphics staticLayer;
color[] heatmapColors = new color[256];

void settings() {
  size(cols * cellSize, rows * cellSize);
  smooth(8);
}

void setup() {
  frameRate(144);
  staticLayer = createGraphics(width, height);

  // Init grid
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j] = new Spot(i, j);
    }
  }

  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j].addNeighbours(grid);
    }
  }

  generateSolvableMaze();

  // Start/end
  start = grid[0][0];
  end = grid[cols - 1][rows - 1];
  openSet.add(start);

  // Build static grid
  staticLayer.beginDraw();
  staticLayer.background(240);
  staticLayer.stroke(220);
  for (int i = 0; i <= cols; i++) staticLayer.line(i * cellSize, 0, i * cellSize, height);
  for (int j = 0; j <= rows; j++) staticLayer.line(0, j * cellSize, width, j * cellSize);
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      if (grid[i][j].wall) {
        staticLayer.fill(30);
        staticLayer.noStroke();
        staticLayer.rect(i * cellSize, j * cellSize, cellSize, cellSize);
      }
    }
  }
  staticLayer.endDraw();

  buildHeatmap();
}

void draw() {
  image(staticLayer, 0, 0);

  if (openSet.size() > 0) {
    Spot current = getLowestF(openSet);
    if (current == end) {
      reconstructPath(current);
      noLoop();
    }

    openSet.remove(current);
    closedSet.add(current);

    for (Spot neighbor : current.neighbours) {
      if (!closedSet.contains(neighbor) && !neighbor.wall) {
        float tempG = current.g + 1;
        if (!openSet.contains(neighbor)) openSet.add(neighbor);
        if (tempG < neighbor.g || neighbor.g == 0) {
          neighbor.g = tempG;
          neighbor.h = dist(neighbor.i, neighbor.j, end.i, end.j);
          neighbor.f = neighbor.g + neighbor.h;
          neighbor.previous = current;
          if (neighbor.g > maxG) maxG = neighbor.g;
        }
      }
    }
  } else {
    println("No path found");
    noLoop();
  }

  noStroke();
  for (Spot s : closedSet) {
    int index = int(constrain(s.g / maxG * 255, 0, 255));
    color tileColor = heatmapColors[index];
    s.drawTile(tileColor, false);  // use your custom drawTile() method
  }


  fill(150, 255, 150);
  for (Spot s : openSet) rect(s.i * cellSize, s.j * cellSize, cellSize, cellSize);

  if (path.size() > 0) {
    float pulse = sin(frameCount * 0.1) * 0.5 + 0.5;
    stroke(255, 0, 200, 150 + pulse * 100);
    strokeWeight(2 + pulse * 2);
    noFill();
    beginShape();
    for (Spot s : path) vertex(s.i * cellSize + cellSize / 2, s.j * cellSize + cellSize / 2);
    endShape();
  }

  fill(0, 200, 255); noStroke();
  ellipse(start.i * cellSize + cellSize/2, start.j * cellSize + cellSize/2, cellSize * 0.6, cellSize * 0.6);
  fill(255, 0, 200);
  ellipse(end.i * cellSize + cellSize/2, end.j * cellSize + cellSize/2, cellSize * 0.6, cellSize * 0.6);
}

void generateSolvableMaze() {
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j].wall = true;
    }
  }

  ArrayList<Spot> stack = new ArrayList<Spot>();
  Spot[][] cells = new Spot[cols / 2][rows / 2];

  for (int x = 0; x < cols / 2; x++) {
    for (int y = 0; y < rows / 2; y++) {
      cells[x][y] = grid[x * 2 + 1][y * 2 + 1];
      cells[x][y].wall = false;
    }
  }

  Spot current = cells[0][0];
  boolean[][] visited = new boolean[cols / 2][rows / 2];
  visited[0][0] = true;

  stack.add(current);

  while (!stack.isEmpty()) {
    current = stack.get(stack.size() - 1);
    int cx = current.i / 2;
    int cy = current.j / 2;

    ArrayList<PVector> unvisited = new ArrayList<PVector>();
    if (cx > 0 && !visited[cx - 1][cy]) unvisited.add(new PVector(cx - 1, cy));
    if (cx < cols / 2 - 1 && !visited[cx + 1][cy]) unvisited.add(new PVector(cx + 1, cy));
    if (cy > 0 && !visited[cx][cy - 1]) unvisited.add(new PVector(cx, cy - 1));
    if (cy < rows / 2 - 1 && !visited[cx][cy + 1]) unvisited.add(new PVector(cx, cy + 1));

    if (unvisited.size() > 0) {
      PVector next = unvisited.get(int(random(unvisited.size())));
      int nx = int(next.x);
      int ny = int(next.y);

      int wallX = current.i + (nx - cx);
      int wallY = current.j + (ny - cy);
      grid[wallX][wallY].wall = false;

      visited[nx][ny] = true;
      stack.add(cells[nx][ny]);
    } else {
      stack.remove(stack.size() - 1);
    }
  }

  grid[0][0].wall = false;
  grid[1][0].wall = false;
  grid[cols - 1][rows - 1].wall = false;
  grid[cols - 2][rows - 1].wall = false;
}

void buildHeatmap() {
  for (int i = 0; i < 256; i++) {
    float t = i / 255.0;
    if (t < 0.5) {
      heatmapColors[i] = lerpColor(color(0, 100, 255), color(0, 255, 0), t * 2);  // Blue to Green
    } else {
      heatmapColors[i] = lerpColor(color(0, 255, 0), color(255, 50, 0), (t - 0.5) * 2);  // Green to Red
    }
  }
}

void reconstructPath(Spot current) {
  path.clear();
  Spot temp = current;
  path.add(temp);
  while (temp.previous != null) {
    path.add(temp.previous);
    temp = temp.previous;
  }
}

Spot getLowestF(ArrayList<Spot> list) {
  Spot best = list.get(0);
  for (Spot s : list) {
    if (s.f < best.f) best = s;
  }
  return best;
}

class Spot {
  int i, j;
  float f = 0, g = 0, h = 0;
  boolean wall = false;
  Spot previous = null;
  ArrayList<Spot> neighbours = new ArrayList<Spot>();

  Spot(int i, int j) {
    this.i = i;
    this.j = j;
  }

  void addNeighbours(Spot[][] grid) {
    if (i < cols - 1) neighbours.add(grid[i + 1][j]);
    if (i > 0) neighbours.add(grid[i - 1][j]);
    if (j < rows - 1) neighbours.add(grid[i][j + 1]);
    if (j > 0) neighbours.add(grid[i][j - 1]);
  }
  
  void drawTile(color col, boolean isWall) {
    if (isWall) {
      fill(30);
      noStroke();
      rect(i * cellSize, j * cellSize, cellSize, cellSize);
    } else {
      fill(col);
      noStroke();
      rect(i * cellSize + 1, j * cellSize + 1, cellSize - 2, cellSize - 2, 3);
    }
}
}
