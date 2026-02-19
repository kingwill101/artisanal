import 'dart:async';
import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

double _clampDouble(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

void _writeLine(
  Screen screen,
  int x,
  int y,
  String text, {
  UvStyle style = const UvStyle(),
  int? maxWidth,
}) {
  final limit = maxWidth == null
      ? text.length
      : math.min(text.length, maxWidth);
  for (var i = 0; i < limit; i++) {
    screen.setCell(x + i, y, Cell(content: text[i], style: style));
  }
}

void main() async {
  final terminal = Terminal();
  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();
  terminal.setScrollOptim(false);
  terminal.setSynchronizedOutput(true);

  final frameStep = const Duration(milliseconds: 24);
  const paddleSpeed = 1.0;
  const aiSpeed = 0.7;
  const baseBallSpeedX = 34.0;

  var hardClear = true;
  var paused = false;
  var aiRight = true;

  var leftScore = 0;
  var rightScore = 0;

  var width = math.max(20, terminal.bounds().width);
  var height = math.max(8, terminal.bounds().height - 2);

  int paddleHeight() => math.max(3, math.min(7, height ~/ 4));

  var leftY = (height - paddleHeight()) / 2.0;
  var rightY = (height - paddleHeight()) / 2.0;

  var ballX = width / 2.0;
  var ballY = height / 2.0;
  var ballVx = baseBallSpeedX;
  var ballVy = 10.0;

  int? prevLeftTop;
  int? prevRightTop;
  int? prevBallX;
  int? prevBallY;
  var prevPaddleHeight = 0;

  final bg = const UvStyle(bg: UvColor.rgb(8, 12, 22));
  final paddleStyle = const UvStyle(
    fg: UvColor.rgb(228, 237, 246),
    bg: UvColor.rgb(8, 12, 22),
    attrs: Attr.bold,
  );
  final ballStyle = const UvStyle(
    fg: UvColor.rgb(255, 200, 110),
    bg: UvColor.rgb(8, 12, 22),
    attrs: Attr.bold,
  );
  final netStyle = const UvStyle(
    fg: UvColor.rgb(66, 78, 98),
    bg: UvColor.rgb(8, 12, 22),
  );
  final hudStyle = const UvStyle(
    fg: UvColor.rgb(214, 223, 234),
    bg: UvColor.rgb(20, 24, 34),
  );
  final helpStyle = const UvStyle(
    fg: UvColor.rgb(145, 161, 180),
    bg: UvColor.rgb(20, 24, 34),
  );

  void resetBall({required bool toRight}) {
    ballX = width / 2.0;
    ballY = height / 2.0;
    ballVx = (toRight ? 1 : -1) * baseBallSpeedX;
    ballVy = (math.Random().nextDouble() - 0.5) * 24.0;
  }

  void resetGame() {
    leftScore = 0;
    rightScore = 0;
    leftY = (height - paddleHeight()) / 2.0;
    rightY = (height - paddleHeight()) / 2.0;
    resetBall(toRight: math.Random().nextBool());
  }

  void handleResize(int w, int h) {
    width = math.max(20, w);
    height = math.max(8, h - 2);
    leftY = _clampDouble(leftY, 0, (height - paddleHeight()).toDouble());
    rightY = _clampDouble(rightY, 0, (height - paddleHeight()).toDouble());
    ballX = _clampDouble(ballX, 0, (width - 1).toDouble());
    ballY = _clampDouble(ballY, 0, (height - 1).toDouble());
  }

  Cell backgroundCellAt(int x, int y) {
    if (x == width ~/ 2 && y.isEven) {
      return Cell(content: '│', style: netStyle);
    }
    return Cell(content: ' ', style: bg);
  }

  bool inPlayBounds(int x, int y) =>
      x >= 0 && y >= 0 && x < width && y < height;

  void drawStaticField() {
    terminal.fill(Cell(content: ' ', style: bg));
    final midX = width ~/ 2;
    for (var y = 0; y < height; y++) {
      if (y.isEven) {
        terminal.setCell(midX, y, Cell(content: '│', style: netStyle));
      }
    }
  }

  void clearPreviousDynamic() {
    final leftX = 2;
    final rightX = width - 3;

    if (prevBallX != null &&
        prevBallY != null &&
        inPlayBounds(prevBallX!, prevBallY!)) {
      terminal.setCell(
        prevBallX!,
        prevBallY!,
        backgroundCellAt(prevBallX!, prevBallY!),
      );
    }

    if (prevLeftTop != null) {
      for (var i = 0; i < prevPaddleHeight; i++) {
        final y = prevLeftTop! + i;
        if (inPlayBounds(leftX, y)) {
          terminal.setCell(leftX, y, backgroundCellAt(leftX, y));
        }
      }
    }

    if (prevRightTop != null) {
      for (var i = 0; i < prevPaddleHeight; i++) {
        final y = prevRightTop! + i;
        if (inPlayBounds(rightX, y)) {
          terminal.setCell(rightX, y, backgroundCellAt(rightX, y));
        }
      }
    }
  }

  void step(double dtSeconds) {
    if (paused) return;

    final frameScale = dtSeconds / (1 / 60.0);

    if (aiRight) {
      final center = rightY + paddleHeight() / 2.0;
      if ((ballY - center).abs() > 0.6) {
        rightY += (ballY > center ? aiSpeed : -aiSpeed) * frameScale;
      }
    }

    leftY = _clampDouble(leftY, 0, (height - paddleHeight()).toDouble());
    rightY = _clampDouble(rightY, 0, (height - paddleHeight()).toDouble());

    ballX += ballVx * dtSeconds;
    ballY += ballVy * dtSeconds;

    if (ballY <= 0) {
      ballY = 0;
      ballVy = ballVy.abs();
    } else if (ballY >= height - 1) {
      ballY = (height - 1).toDouble();
      ballVy = -ballVy.abs();
    }

    final leftX = 2;
    final rightX = width - 3;
    final leftTop = leftY.round();
    final rightTop = rightY.round();
    final pH = paddleHeight();

    if (ballVx < 0 &&
        ballX <= leftX + 1 &&
        ballY >= leftTop &&
        ballY <= leftTop + pH - 1) {
      ballX = (leftX + 1).toDouble();
      ballVx = ballVx.abs() * 1.03;
      final norm = (ballY - (leftTop + pH / 2)) / (pH / 2);
      ballVy += norm * 15.0;
    }

    if (ballVx > 0 &&
        ballX >= rightX - 1 &&
        ballY >= rightTop &&
        ballY <= rightTop + pH - 1) {
      ballX = (rightX - 1).toDouble();
      ballVx = -ballVx.abs() * 1.03;
      final norm = (ballY - (rightTop + pH / 2)) / (pH / 2);
      ballVy += norm * 15.0;
    }

    ballVy = _clampDouble(ballVy, -34, 34);

    if (ballX < 0) {
      rightScore++;
      resetBall(toRight: true);
    } else if (ballX > width - 1) {
      leftScore++;
      resetBall(toRight: false);
    }
  }

  void render() {
    final bounds = terminal.bounds();
    final playW = math.max(20, bounds.width);
    final playH = math.max(8, bounds.height - 2);
    if (playW != width || playH != height) {
      handleResize(playW, bounds.height);
      hardClear = true;
    }

    if (hardClear) {
      terminal.clear();
      terminal.clearScreen();
      drawStaticField();
      hardClear = false;
      prevLeftTop = null;
      prevRightTop = null;
      prevBallX = null;
      prevBallY = null;
      prevPaddleHeight = 0;
    } else {
      clearPreviousDynamic();
    }

    final pH = paddleHeight();
    final leftTop = leftY.round();
    final rightTop = rightY.round();
    final leftX = 2;
    final rightX = width - 3;
    for (var i = 0; i < pH; i++) {
      terminal.setCell(
        leftX,
        leftTop + i,
        Cell(content: '█', style: paddleStyle),
      );
      terminal.setCell(
        rightX,
        rightTop + i,
        Cell(content: '█', style: paddleStyle),
      );
    }

    final ballXi = ballX.round();
    final ballYi = ballY.round();
    terminal.setCell(ballXi, ballYi, Cell(content: '●', style: ballStyle));

    final title =
        'PONG  $leftScore : $rightScore  ${paused
            ? "paused"
            : aiRight
            ? "ai-right"
            : "2p"}';
    final help = 'w/s left  ↑/↓ right  a ai toggle  p pause  r reset  q quit';

    if (bounds.height >= 2) {
      terminal.fillArea(
        Cell(content: ' ', style: hudStyle),
        rect(0, bounds.height - 2, bounds.width, 1),
      );
      _writeLine(
        terminal,
        0,
        bounds.height - 2,
        title,
        style: hudStyle,
        maxWidth: bounds.width,
      );
    }
    if (bounds.height >= 1) {
      terminal.fillArea(
        Cell(content: ' ', style: helpStyle),
        rect(0, bounds.height - 1, bounds.width, 1),
      );
      _writeLine(
        terminal,
        0,
        bounds.height - 1,
        help,
        style: helpStyle,
        maxWidth: bounds.width,
      );
    }

    prevLeftTop = leftTop;
    prevRightTop = rightTop;
    prevBallX = ballXi;
    prevBallY = ballYi;
    prevPaddleHeight = pH;

    terminal.draw();
  }

  final timer = Timer.periodic(frameStep, (_) {
    step(frameStep.inMicroseconds / 1000000.0);
    render();
  });

  try {
    resetBall(toRight: true);
    render();
    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
        handleResize(event.width, event.height);
        hardClear = true;
        render();
        continue;
      }

      if (event is! KeyEvent) continue;
      if (event.matchString('q', 'esc', 'ctrl+c')) break;

      if (event.matchString('w')) {
        leftY -= paddleSpeed;
      } else if (event.matchString('s')) {
        leftY += paddleSpeed;
      } else if (event.matchString('up')) {
        if (!aiRight) rightY -= paddleSpeed;
      } else if (event.matchString('down')) {
        if (!aiRight) rightY += paddleSpeed;
      } else if (event.matchString('a')) {
        aiRight = !aiRight;
      } else if (event.matchString('p', ' ')) {
        paused = !paused;
      } else if (event.matchString('r')) {
        resetGame();
      } else if (event.matchString('j')) {
        if (!aiRight) rightY += paddleSpeed;
      } else if (event.matchString('k')) {
        if (!aiRight) rightY -= paddleSpeed;
      }

      leftY = _clampDouble(leftY, 0, (height - paddleHeight()).toDouble());
      rightY = _clampDouble(rightY, 0, (height - paddleHeight()).toDouble());
      render();
    }
  } finally {
    timer.cancel();
    terminal.showCursor();
    terminal.exitAltScreen();
    await terminal.stop();
  }
}
