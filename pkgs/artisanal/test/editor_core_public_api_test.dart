import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

void main() {
  test('stable editor_core entrypoint exposes core primitives and aliases', () {
    final document = TextDocument(text: 'alpha\nbeta');
    final buffer = TextBuffer(text: 'gamma');
    final editor = EditBuffer(text: 'delta');
    final state = EditBufferState();
    final view = EditorView(width: 12, height: 4, softWrap: true);

    expect(document.text, 'alpha\nbeta');
    expect(buffer.text, 'gamma');
    expect(editor.text, 'delta');
    expect(state.cursor, const TextPosition(line: 0, column: 0));
    expect(view.effectiveContentWidth(), 12);
  });
}
