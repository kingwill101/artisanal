import 'package:artisanal/markdown.dart' as markdown;
import 'package:artisanal/runtime.dart' as runtime;

void main() {
  final entrypointTypes = <Type>[runtime.Cmd, markdown.MarkdownRenderer];
  if (entrypointTypes.isEmpty) {
    throw StateError('Artisanal web entrypoints were not loaded.');
  }
}
