import 'package:artisanal/bubbles.dart';

void main(List<String> arguments) {
  final lineCount = arguments.isEmpty ? 5000 : int.parse(arguments.first);
  final frameCount = arguments.length < 2 ? 30 : int.parse(arguments[1]);
  final lines = List<String>.generate(
    lineCount,
    (line) => 'final value$line = "line $line";',
    growable: false,
  );
  final textarea = TextAreaModel(
    prompt: '',
    showLineNumbers: true,
    softWrap: false,
    width: 120,
    height: 40,
  )..value = lines.join('\n');
  final decorations = <TextDecorationRange>[];
  var offset = 0;
  for (final line in lines) {
    decorations
      ..add(
        TextDecorationRange(
          startOffset: offset,
          endOffset: offset + 5,
          styleKey: 'syntax.keyword',
        ),
      )
      ..add(
        TextDecorationRange(
          startOffset: offset + line.length - 9,
          endOffset: offset + line.length - 1,
          styleKey: 'syntax.literal.string',
        ),
      );
    offset += line.length + 1;
  }

  final indexing = Stopwatch()..start();
  textarea.setDecorationLayer('syntax', decorations);
  indexing.stop();
  textarea
    ..setCursor(lineCount - 1, 0)
    ..view();

  final rendering = Stopwatch()..start();
  for (var frame = 0; frame < frameCount; frame++) {
    textarea.view();
  }
  rendering.stop();

  final millisecondsPerFrame =
      rendering.elapsedMicroseconds / frameCount / 1000;
  print('lines: $lineCount');
  print('decorations: ${textarea.decorations.length}');
  print('decoration indexing: ${indexing.elapsedMilliseconds} ms');
  print(
    '$frameCount frames: ${rendering.elapsedMilliseconds} ms '
    '(${millisecondsPerFrame.toStringAsFixed(2)} ms/frame)',
  );
}
