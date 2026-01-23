import 'package:artisanal/src/unicode/width.dart' as w;
import 'package:test/test.dart';

void main() {
  test('emoji width is configurable at runtime', () {
    final prev = w.emojiPresentationWidth;
    try {
      w.setEmojiPresentationWidth(1);
      expect(w.emojiPresentationWidth, 1);
      expect(w.stringWidth('🍕'), 1);

      w.setEmojiPresentationWidth(2);
      expect(w.emojiPresentationWidth, 2);
      expect(w.stringWidth('🍕'), 2);

      // Ignore invalid values.
      w.setEmojiPresentationWidth(99);
      expect(w.emojiPresentationWidth, 2);
    } finally {
      w.emojiPresentationWidth = prev;
    }
  });
}
