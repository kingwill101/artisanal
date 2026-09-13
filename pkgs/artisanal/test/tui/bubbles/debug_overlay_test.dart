import 'package:artisanal/src/tui/bubbles/debug_overlay.dart';
import 'package:artisanal/src/tui/devtools.dart' show DevToolsMessageEntry;
import 'package:artisanal/src/tui/model.dart' show OutputLogEntry;
import 'package:artisanal/src/tui/msg.dart' show OutputSource;
import 'package:artisanal/style.dart' show Style;
import 'package:ultraviolet/core.dart' as uv;

import 'package:test/test.dart';

void main() {
  // =========================================================================
  // DebugOverlayMode
  // =========================================================================

  group('DebugOverlayMode', () {
    test('has three tab values', () {
      expect(DebugOverlayMode.values, hasLength(3));
      expect(DebugOverlayMode.values.map((e) => e.name), [
        'metrics',
        'messages',
        'output',
      ]);
    });
  });

  // =========================================================================
  // DebugOverlayModel construction
  // =========================================================================

  group('DebugOverlayModel', () {
    late DebugOverlayModel overlay;

    setUp(() {
      overlay = DebugOverlayModel.initial(
        terminalWidth: 80,
        terminalHeight: 24,
      );
    });

    test('initial defaults', () {
      expect(overlay.enabled, isFalse);
      expect(overlay.mode, DebugOverlayMode.metrics);
      expect(overlay.messageEntries, isEmpty);
      expect(overlay.outputEntries, isEmpty);
      expect(overlay.maxDisplayMessages, 8);
      expect(overlay.maxDisplayOutput, 8);
    });

    test('copyWith preserves new fields', () {
      final entries = [
        DevToolsMessageEntry(
          timestamp: DateTime.utc(2025, 6, 15),
          messageType: 'KeyMsg',
          summary: 'key: runes [113]',
          processingTime: const Duration(microseconds: 100),
        ),
      ];
      final outputs = [
        OutputLogEntry(
          line: 'hello',
          source: OutputSource.stdout,
          timestamp: DateTime.utc(2025, 6, 15),
        ),
      ];

      final updated = overlay.copyWith(
        mode: DebugOverlayMode.output,
        messageEntries: entries,
        outputEntries: outputs,
        maxDisplayMessages: 5,
        maxDisplayOutput: 3,
      );

      expect(updated.mode, DebugOverlayMode.output);
      expect(updated.messageEntries, same(entries));
      expect(updated.outputEntries, same(outputs));
      expect(updated.maxDisplayMessages, 5);
      expect(updated.maxDisplayOutput, 3);
    });

    // -----------------------------------------------------------------------
    // cycleMode
    // -----------------------------------------------------------------------

    group('cycleMode', () {
      test('cycles through each tab', () {
        var m = overlay;
        expect(m.mode, DebugOverlayMode.metrics);

        m = m.cycleMode();
        expect(m.mode, DebugOverlayMode.messages);

        m = m.cycleMode();
        expect(m.mode, DebugOverlayMode.output);

        m = m.cycleMode();
        expect(m.mode, DebugOverlayMode.metrics);
      });

      test('resets panel position on cycle', () {
        final positioned = overlay.copyWith(panelX: 10, panelY: 5);
        expect(positioned.panelX, 10);

        final cycled = positioned.cycleMode();
        expect(cycled.panelX, isNull);
        expect(cycled.panelY, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // panel() rendering — metrics mode
    // -----------------------------------------------------------------------

    group('panel() metrics mode', () {
      test('renders metrics panel (default mode)', () {
        final m = overlay.copyWith(enabled: true);
        final rendered = m.panel();
        // Should contain typical render metrics labels.
        expect(rendered, contains('FPS:'));
        expect(rendered, contains('Frame Time:'));
        expect(rendered, contains('Render Time:'));
        expect(rendered, contains('Frames:'));
        expect(rendered, contains('Renderer:'));
      });

      test('does not contain message or output sections', () {
        final m = overlay.copyWith(enabled: true);
        final rendered = m.panel();
        // In metrics-only mode, no section headers.
        expect(rendered, isNot(contains('Messages')));
        expect(rendered, isNot(contains('Output')));
      });
    });

    // -----------------------------------------------------------------------
    // panel() rendering — messages mode
    // -----------------------------------------------------------------------

    group('panel() messages mode', () {
      test('shows empty state when no messages', () {
        final m = overlay.copyWith(
          enabled: true,
          mode: DebugOverlayMode.messages,
        );
        final rendered = m.panel();
        expect(rendered, contains('no messages'));
      });

      test('renders message entries', () {
        final entries = [
          DevToolsMessageEntry(
            timestamp: DateTime.utc(2025, 6, 15),
            messageType: 'KeyMsg',
            summary: 'key: runes [113]',
            processingTime: const Duration(microseconds: 250),
          ),
          DevToolsMessageEntry(
            timestamp: DateTime.utc(2025, 6, 15),
            messageType: 'CustomMsg<String>',
            summary: 'custom: hello',
            processingTime: const Duration(microseconds: 80),
          ),
        ];
        final m = overlay.copyWith(
          enabled: true,
          mode: DebugOverlayMode.messages,
          messageEntries: entries,
        );
        final rendered = m.panel();
        expect(rendered, contains('key: runes'));
        expect(rendered, contains('custom: hello'));
        // Panel title should be "Messages".
        expect(rendered, contains('Messages'));
      });

      test('respects maxDisplayMessages', () {
        final entries = List.generate(
          12,
          (i) => DevToolsMessageEntry(
            timestamp: DateTime.utc(2025, 6, 15),
            messageType: 'CustomMsg<String>',
            summary: 'msg-$i',
            processingTime: const Duration(microseconds: 10),
          ),
        );
        final m = overlay.copyWith(
          enabled: true,
          mode: DebugOverlayMode.messages,
          messageEntries: entries,
          maxDisplayMessages: 5,
        );
        final rendered = m.panel();
        // Should show first 5 entries and a "(+7 more)" line.
        expect(rendered, contains('msg-0'));
        expect(rendered, contains('msg-4'));
        expect(rendered, isNot(contains('msg-5')));
        expect(rendered, contains('+7 more'));
      });

      test('does not show metrics in messages mode', () {
        final m = overlay.copyWith(
          enabled: true,
          mode: DebugOverlayMode.messages,
        );
        final rendered = m.panel();
        expect(rendered, isNot(contains('FPS:')));
      });
    });

    // -----------------------------------------------------------------------
    // panel() rendering — output mode
    // -----------------------------------------------------------------------

    group('panel() output mode', () {
      test('shows empty state when no output', () {
        final m = overlay.copyWith(
          enabled: true,
          mode: DebugOverlayMode.output,
        );
        final rendered = m.panel();
        expect(rendered, contains('no output'));
      });

      test('renders output entries', () {
        final entries = [
          OutputLogEntry(
            line: 'Hello from print',
            source: OutputSource.stdout,
            timestamp: DateTime.utc(2025, 6, 15),
          ),
          OutputLogEntry(
            line: 'Error occurred',
            source: OutputSource.stderr,
            timestamp: DateTime.utc(2025, 6, 15),
          ),
        ];
        final m = overlay.copyWith(
          enabled: true,
          mode: DebugOverlayMode.output,
          outputEntries: entries,
        );
        final rendered = m.panel();
        expect(rendered, contains('Hello from print'));
        expect(rendered, contains('Error occurred'));
        // stderr entries get a red "err" prefix.
        expect(rendered, contains('err'));
        // Panel title should be "Captured Output".
        expect(rendered, contains('Captured Output'));
      });

      test('respects maxDisplayOutput', () {
        final entries = List.generate(
          10,
          (i) => OutputLogEntry(
            line: 'line-$i',
            source: OutputSource.stdout,
            timestamp: DateTime.utc(2025, 6, 15),
          ),
        );
        final m = overlay.copyWith(
          enabled: true,
          mode: DebugOverlayMode.output,
          outputEntries: entries,
          maxDisplayOutput: 4,
        );
        final rendered = m.panel();
        expect(rendered, contains('line-0'));
        expect(rendered, contains('line-3'));
        expect(rendered, isNot(contains('line-4')));
        expect(rendered, contains('+6 more'));
      });
    });

    // -----------------------------------------------------------------------
    // panel() rendering — all mode
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // Truncation
    // -----------------------------------------------------------------------

    group('truncation', () {
      test('truncates long message entries', () {
        final entries = [
          DevToolsMessageEntry(
            timestamp: DateTime.utc(2025, 6, 15),
            messageType: 'CustomMsg<String>',
            summary: 'x' * 100,
            processingTime: const Duration(microseconds: 10),
          ),
        ];
        // Use a narrow panel.
        final m = overlay.copyWith(
          enabled: true,
          mode: DebugOverlayMode.messages,
          messageEntries: entries,
          panelWidth: 30,
        );
        final rendered = m.panel();
        // The long line should be truncated with "...".
        expect(rendered, contains('...'));
        // The full 100-char string should NOT appear.
        expect(rendered, isNot(contains('x' * 100)));
      });

      test('truncates long output entries', () {
        final entries = [
          OutputLogEntry(
            line: 'y' * 100,
            source: OutputSource.stdout,
            timestamp: DateTime.utc(2025, 6, 15),
          ),
        ];
        final m = overlay.copyWith(
          enabled: true,
          mode: DebugOverlayMode.output,
          outputEntries: entries,
          panelWidth: 30,
        );
        final rendered = m.panel();
        expect(rendered, contains('...'));
        expect(rendered, isNot(contains('y' * 100)));
      });
    });

    // -----------------------------------------------------------------------
    // Cache invalidation
    // -----------------------------------------------------------------------

    group('cache invalidation', () {
      test('panel changes when mode changes', () {
        final m = overlay.copyWith(enabled: true);
        final metricsPanel = m.panel();

        final messagesModel = m.copyWith(mode: DebugOverlayMode.messages);
        final messagesPanel = messagesModel.panel();

        expect(metricsPanel, isNot(equals(messagesPanel)));
      });

      test('panel changes when message entries change', () {
        final m = overlay.copyWith(
          enabled: true,
          mode: DebugOverlayMode.messages,
        );
        final emptyPanel = m.panel();

        final withMsg = m.copyWith(
          messageEntries: [
            DevToolsMessageEntry(
              timestamp: DateTime.utc(2025, 6, 15),
              messageType: 'KeyMsg',
              summary: 'key: runes',
              processingTime: Duration.zero,
            ),
          ],
        );
        final msgPanel = withMsg.panel();

        expect(emptyPanel, isNot(equals(msgPanel)));
      });

      test('panel changes when output entries change', () {
        final m = overlay.copyWith(
          enabled: true,
          mode: DebugOverlayMode.output,
        );
        final emptyPanel = m.panel();

        final withOut = m.copyWith(
          outputEntries: [
            OutputLogEntry(
              line: 'hello',
              source: OutputSource.stdout,
              timestamp: DateTime.utc(2025, 6, 15),
            ),
          ],
        );
        final outPanel = withOut.panel();

        expect(emptyPanel, isNot(equals(outPanel)));
      });
    });

    // -----------------------------------------------------------------------
    // compose()
    // -----------------------------------------------------------------------

    group('compose', () {
      test('returns base unchanged when disabled', () {
        const base = 'line1\nline2';
        expect(overlay.compose(base), base);
      });

      test('composes OSC 8 links and wide cells at the clip edge', () {
        final m = overlay.copyWith(
          enabled: true,
          terminalWidth: 24,
          terminalHeight: 4,
          panelWidth: 12,
          panelX: 8,
          panelY: 0,
        );
        // Exercise both OSC 8 terminators. The link is deliberately styled
        // and contains a wide grapheme so every boundary is cell-based.
        const stLink =
            '\x1b]8;;https://example.test\x1b\\\x1b[31mAAAAAAA界BCdefghijklmnop'
            '\x1b[0m\x1b]8;;\x1b\\';
        const belLink =
            '\x1b]8;;https://example.test\x07\x1b[32mabcdefghijklmnopqrstuvwx'
            '\x1b[0m\x1b]8;;\x07';
        final composed = m.compose('$stLink\n$belLink');

        // Every OSC introducer must remain an escape sequence after the
        // overlay's prefix/suffix cuts; none of its payload may become text.
        final withoutLinks = composed.replaceAll(
          RegExp(r'\x1b\]8;;[^\x07\x1b]*(?:\x07|\x1b\\)'),
          '',
        );
        expect(withoutLinks, isNot(contains(']8;;')));
        // The clipped panel must not extend beyond the requested screen.
        for (final line in composed.split('\n')) {
          expect(Style.visibleLength(line), lessThanOrEqualTo(24));
        }
        final screen = uv.ScreenBuffer(24, 4);
        uv.StyledString(composed).draw(screen, screen.bounds());
        expect(
          screen.cellAt(7, 0)!.content,
          ' ',
          reason:
              'A wide glyph cut by the panel edge must not straddle layers.',
        );
      });

      test('overlays panel when enabled', () {
        final m = overlay.copyWith(enabled: true);
        const base = 'line1\nline2';
        final composed = m.compose(base);
        // Should contain panel border characters.
        expect(composed, contains('╭'));
        expect(composed, contains('╰'));
      });

      test(
        'keeps panel pen isolated and restores styled or default suffix cells',
        () {
          final m = overlay.copyWith(
            enabled: true,
            terminalWidth: 60,
            terminalHeight: 20,
            panelWidth: 24,
            panelX: 8,
            panelY: 0,
          );
          for (final terminator in <String?>[null, '\x07', '\x1b\\']) {
            final text = 'a' * 60;
            final line = terminator == null
                ? text
                : '\x1b]8;;https://base.test$terminator\x1b[31m$text'
                      '\x1b[0m\x1b]8;;$terminator';
            final base = List.filled(20, line).join('\n');
            final expected = uv.ScreenBuffer(60, 20);
            uv.StyledString(base).draw(expected, expected.bounds());
            final actual = uv.ScreenBuffer(60, 20);
            uv.StyledString(m.compose(base)).draw(actual, actual.bounds());
            for (var row = 0; row < m.panel().split('\n').length; row++) {
              expect(actual.cellAt(59, row)!.content, 'a');
              expect(
                actual.cellAt(59, row)!.style,
                expected.cellAt(59, row)!.style,
              );
              expect(
                actual.cellAt(59, row)!.link,
                expected.cellAt(59, row)!.link,
              );
              expect(
                actual.cellAt(10, row)!.link.isZero,
                isTrue,
                reason: 'Underlying links must not leak into the opaque panel.',
              );
            }
          }
        },
      );
    });

    // -----------------------------------------------------------------------
    // toggle and setEnabled
    // -----------------------------------------------------------------------

    group('toggle / setEnabled', () {
      test('toggle flips enabled', () {
        expect(overlay.enabled, isFalse);
        final toggled = overlay.toggle();
        expect(toggled.enabled, isTrue);
        expect(toggled.toggle().enabled, isFalse);
      });

      test('setEnabled is idempotent', () {
        final a = overlay.setEnabled(false);
        expect(identical(a, overlay), isTrue);
        final b = overlay.setEnabled(true);
        expect(b.enabled, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Backward compatibility
    // -----------------------------------------------------------------------

    group('backward compatibility', () {
      test('initial factory has same defaults as before', () {
        final m = DebugOverlayModel.initial();
        expect(m.panelWidth, 40);
        expect(m.marginRight, 2);
        expect(m.marginTop, 0);
        expect(m.marginBottom, 2);
        expect(m.title, 'Render Metrics');
        expect(m.rendererLabel, 'UV');
        // New fields use defaults.
        expect(m.mode, DebugOverlayMode.metrics);
        expect(m.messageEntries, isEmpty);
        expect(m.outputEntries, isEmpty);
      });

      test('panel renders identical metrics section when no new data', () {
        // With mode=metrics and no message/output entries, the panel
        // should render the same way as the original implementation.
        final m = DebugOverlayModel.initial(
          enabled: true,
          terminalWidth: 80,
          terminalHeight: 24,
        );
        final rendered = m.panel();
        // Must contain all original metric labels.
        for (final expected in [
          'FPS:',
          'Frame Time:',
          'Render Time:',
          'Frames:',
          'Cells:',
          'Renderer:',
        ]) {
          expect(
            rendered,
            contains(expected),
            reason: 'expected label "$expected" in panel',
          );
        }
        // Panel title should be "Render Metrics" (original).
        expect(rendered, contains('Render Metrics'));
      });

      test('customMetrics still rendered in metrics mode', () {
        final m = overlay.copyWith(
          enabled: true,
          customMetrics: {'Version': '1.2.3'},
        );
        final rendered = m.panel();
        expect(rendered, contains('Version:'));
        expect(rendered, contains('1.2.3'));
      });
    });
  });
}
