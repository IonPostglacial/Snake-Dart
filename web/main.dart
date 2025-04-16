import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:math' as math;

const cellSize   = 10;
const gridWidth  = 40;
const gridHeight = 40;

const colorBackground = '#000000';
const colorSnake      = '#00ff00';
const colorApple      = '#ff0000';

enum Direction {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  final int dx;
  final int dy;

  const Direction(this.dx, this.dy);

  bool isOppositeOf(Direction other) =>
    (dx == -other.dx) && (dy == -other.dy);
}

class Snake {
  final List<int> xs = List.filled(gridWidth * gridHeight, 0);
  final List<int> ys = List.filled(gridWidth * gridHeight, 0);

  int length = 0;
  int _head = 0;
  Direction _direction = Direction.right;

  int appleX = 0;
  int appleY = 0;

  double stepPeriod = 300.0;
  int score = 0;
  int _nextReward = 10;

  void init() {
    score = 0;
    stepPeriod = 300.0;
    _nextReward = 10;

    teleportApple();

    length = 4;
    _head = 3;
    _direction = Direction.right;

    xs[0] = 0;  ys[0] = 0;
    xs[1] = 1;  ys[1] = 0;
    xs[2] = 2;  ys[2] = 0;
    xs[3] = 3;  ys[3] = 0;
  }

  bool willEatApple() {
    final hx = xs[_head];
    final hy = ys[_head];
    return (hx + _direction.dx == appleX &&
            hy + _direction.dy == appleY);
  }

  bool eatsItself() {
    for (int i = 0; i < length; i++) {
      if (i == _head) continue;
      if (xs[_head] == xs[i] && ys[_head] == ys[i]) {
        return true;
      }
    }
    return false;
  }

  bool isOutOfBounds() {
    final hx = xs[_head];
    final hy = ys[_head];
    return (hx < 0 || hx >= gridWidth || hy < 0 || hy >= gridHeight);
  }

  void moveAhead() {
    final hx = xs[_head];
    final hy = ys[_head];
    final nextX = hx + _direction.dx;
    final nextY = hy + _direction.dy;

    _head = (_head == length - 1) ? 0 : _head + 1;
    xs[_head] = nextX;
    ys[_head] = nextY;
  }

  void grow() {
    final hx = xs[_head];
    final hy = ys[_head];
    final nextX = hx + _direction.dx;
    final nextY = hy + _direction.dy;

    if (_head == length - 1) {
      xs[length] = nextX;
      ys[length] = nextY;
    } else {
      for (int i = length; i > _head; i--) {
        xs[i] = xs[i - 1];
        ys[i] = ys[i - 1];
      }
      xs[_head + 1] = nextX;
      ys[_head + 1] = nextY;
    }
    length++;
    _head++;
  }

  void changeDirection(Direction d) {
    if (!_direction.isOppositeOf(d)) {
      _direction = d;
    }
  }

  void teleportApple() {
    final rand = math.Random();
    appleX = rand.nextInt(gridWidth);
    appleY = rand.nextInt(gridHeight);
  }

  void speedUpGame() {
    if (stepPeriod > 50) {
      stepPeriod -= 25;
    }
  }

  void updateScore() {
    score += _nextReward;
    _nextReward += 10;
  }
}

void paintBackground(web.CanvasRenderingContext2D ctx) {
  ctx.fillStyle = colorBackground.toJS;
  ctx.fillRect(0, 0, gridWidth * cellSize, gridHeight * cellSize);
}

void paintSnake(web.CanvasRenderingContext2D ctx, Snake snake) {
  ctx.fillStyle = colorSnake.toJS;
  for (int i = 0; i < snake.length; i++) {
    ctx.fillRect(
      snake.xs[i] * cellSize,
      snake.ys[i] * cellSize,
      cellSize,
      cellSize
    );
  }
}

void paintApple(web.CanvasRenderingContext2D ctx, Snake snake) {
  ctx.fillStyle = colorApple.toJS;
  ctx.fillRect(
    snake.appleX * cellSize,
    snake.appleY * cellSize,
    cellSize,
    cellSize
  );
}

void repaint(web.CanvasRenderingContext2D ctx, Snake snake) {
  paintBackground(ctx);
  paintSnake(ctx, snake);
  paintApple(ctx, snake);
}

void main() {
  final canvas = web.document.querySelector('#gamescreen') as web.HTMLCanvasElement?;
  if (canvas == null) {
    web.window.alert('Cannot find #gamescreen');
    return;
  }

  canvas.width  = gridWidth * cellSize;
  canvas.height = gridHeight * cellSize;

  final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
  if (ctx == null) {
    web.window.alert('Cannot get 2D context');
    return;
  }

  final scoreElement = web.document.querySelector('#score');

  final snake = Snake()..init();

  void handleKeyDown(web.KeyboardEvent e) {
    e.stopPropagation();
    switch (e.code) {
      case "ArrowDown":
        snake.changeDirection(Direction.down);
      case "ArrowUp":
        snake.changeDirection(Direction.up);
      case "ArrowLeft":
        snake.changeDirection(Direction.left);
      case "ArrowRight":
        snake.changeDirection(Direction.right);
    }
  }

  web.window.onKeyDown.listen(handleKeyDown);

  var lastUpdateTimestamp = -1.0;
  void step(double timestamp) {
    if (lastUpdateTimestamp < 0.0) {
      lastUpdateTimestamp = timestamp;
    }
    final progress = timestamp - lastUpdateTimestamp;

    if (progress >= snake.stepPeriod) {
      lastUpdateTimestamp = timestamp;

      if (snake.willEatApple()) {
        snake.grow();
        snake.teleportApple();
        snake.speedUpGame();
        snake.updateScore();
        if (scoreElement != null) {
          scoreElement.textContent = snake.score.toString();
        }
      } else {
        snake.moveAhead();
      }

      if (snake.isOutOfBounds() || snake.eatsItself()) {
        web.window.alert('Game Over!');
        web.window.location.reload();
        return;
      }
      repaint(ctx, snake);
    }
    web.window.requestAnimationFrame(step.toJS);
  }

  repaint(ctx, snake);
  web.window.requestAnimationFrame(step.toJS);
}
