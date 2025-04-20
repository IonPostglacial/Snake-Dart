import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

const cellSize   = 10;
const gridWidth  = 40;
const gridHeight = 40;

final colorBackground = '#000000'.toJS;
final colorSnake      = '#00ff00'.toJS;
final colorApple      = '#ff0000'.toJS;

const int dirRight = 0;
const int dirDown  = 1;
const int dirLeft  = 2;
const int dirUp    = 3;

final _dx = <int>[1, 0, -1, 0];
final _dy = <int>[0, 1, 0, -1];

bool _isOpposite(int c1, int c2) => switch (c1) {
  dirRight => c2 == dirLeft,
  dirDown  => c2 == dirUp,
  dirLeft  => c2 == dirRight,
  dirUp    => c2 == dirDown,
  _ => true,
};

class _DirectionsBuffer {
  final int capacity;
  final Uint8List _data;

  _DirectionsBuffer(this.capacity)
      : _data = Uint8List((capacity + 3) >> 2);

  void setAt(int index, int dirCode) {
    final byteIndex = index >> 2;
    final shift     = (index & 3) << 1;

    final oldByte = _data[byteIndex];
    final mask   = ~(3 << shift) & 0xFF;
    final newVal = (oldByte & mask) | (dirCode << shift);

    _data[byteIndex] = newVal;
  }

  int getAt(int index) {
    final byteIndex = index >> 2;
    final shift     = (index & 3) << 1;
    return (_data[byteIndex] >> shift) & 3;
  }
}

class Snake {
  final _DirectionsBuffer _directions = _DirectionsBuffer(gridWidth * gridHeight);

  int _tailIndex = 0;
  int length = 4;
  int _headIndex = 4 - 2;
  int _directionCode = dirRight;

  int headX = 3;
  int headY = 0;

  int tailX = 0;
  int tailY = 0;

  int appleX = 0;
  int appleY = 0;

  double stepPeriod = 300.0;
  int score = 0;
  int _nextReward = 10;

  Snake() {
    teleportApple();
  }

  int _moveIndexForward(int idx) {
    idx++;
    if (idx == _directions.capacity) {
      idx = 0;
    }
    return idx;
  }

  bool willEatApple() {
    final dx = _dx[_directionCode];
    final dy = _dy[_directionCode];
    return (headX + dx == appleX && headY + dy == appleY);
  }

  bool isOutOfBounds() =>
      headX < 0 || headX >= gridWidth ||
      headY < 0 || headY >= gridHeight;

  bool eatsItself() {
    int cx = tailX, cy = tailY;
    int idx = _tailIndex;

    for (int i = 0; i < length - 1; i++) {
      if (cx == headX && cy == headY) {
        return true;
      }
      final code = _directions.getAt(idx);
      idx = _moveIndexForward(idx);
      cx += _dx[code];
      cy += _dy[code];
    }
    return false;
  }

  void _move(bool isGrowing) {
    _headIndex = _moveIndexForward(_headIndex);
    _directions.setAt(_headIndex, _directionCode);

    headX += _dx[_directionCode];
    headY += _dy[_directionCode];

    if (!isGrowing) {
      final tailCode = _directions.getAt(_tailIndex);
      tailX += _dx[tailCode];
      tailY += _dy[tailCode];
      _tailIndex = _moveIndexForward(_tailIndex);
    } else {
      length++;
    }
  }

  void moveAhead() => _move(false);
  void grow() => _move(true);

  void changeDirection(int newCode) {
    if (!_isOpposite(_directionCode, newCode)) {
      _directionCode = newCode;
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
  ctx.fillStyle = colorBackground;
  ctx.fillRect(0, 0, gridWidth * cellSize, gridHeight * cellSize);
}

void paintSnake(web.CanvasRenderingContext2D ctx, Snake snake) {
  ctx.fillStyle = colorSnake;

  int cx = snake.tailX;
  int cy = snake.tailY;
  int idx = snake._tailIndex;

  for (int i = 0; i < snake.length; i++) {
    ctx.fillRect(cx * cellSize, cy * cellSize, cellSize, cellSize);

    if (i < snake.length - 1) {
      final code = snake._directions.getAt(idx);
      idx = snake._moveIndexForward(idx);
      cx += _dx[code];
      cy += _dy[code];
    }
  }
}

void paintApple(web.CanvasRenderingContext2D ctx, Snake snake) {
  ctx.fillStyle = colorApple;
  ctx.fillRect(
    snake.appleX * cellSize,
    snake.appleY * cellSize,
    cellSize,
    cellSize
  );
}

void repaint(web.CanvasRenderingContext2D ctx, Snake snake, bool gameOver) {
  paintBackground(ctx);
  if (gameOver) {
    ctx.fillStyle = "red".toJS;
    ctx.font = "bold 24px monospace";
    ctx.textAlign = "center";
    final centerX = (gridWidth  * cellSize) / 2;
    final centerY = (gridWidth * cellSize) / 2;
    ctx.fillText("OH NO, GAME OVER :(", centerX, centerY);
  } else {
    paintSnake(ctx, snake);
    paintApple(ctx, snake);
  }
}

void main() {
  bool gameOver = false;
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
  var snake = Snake();

  void handleKeyDown(web.KeyboardEvent e) {
    if (gameOver) {
      snake = Snake();
      gameOver = false;
    }
    switch (e.code) {
      case 'ArrowRight':
        snake.changeDirection(dirRight);
      case 'ArrowDown':
        snake.changeDirection(dirDown);
      case 'ArrowLeft':
        snake.changeDirection(dirLeft);
      case 'ArrowUp':
        snake.changeDirection(dirUp);
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
        scoreElement?.textContent = snake.score.toString();
      } else {
        snake.moveAhead();
      }
      if (snake.isOutOfBounds() || snake.eatsItself()) {
        gameOver = true;
      }
      repaint(ctx, snake, gameOver);
    }
    web.window.requestAnimationFrame(step.toJS);
  }
  repaint(ctx, snake, gameOver);
  web.window.requestAnimationFrame(step.toJS);
}
