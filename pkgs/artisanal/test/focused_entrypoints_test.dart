import 'package:artisanal/charting.dart' as charting;
import 'package:artisanal/git_diff.dart' as git_diff;
import 'package:artisanal/layout.dart' as layout;
import 'package:artisanal/markdown.dart' as markdown;
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/scoring.dart' as scoring;
import 'package:artisanal/text_editing.dart' as text_editing;
import 'package:test/test.dart';

void main() {
  test('focused entrypoints expose their stable public types', () {
    expect(charting.ChartRamp, isA<Type>());
    expect(git_diff.GitDiffModel, isA<Type>());
    expect(layout.Layout, isA<Type>());
    expect(markdown.MarkdownRenderer, isA<Type>());
    expect(runtime.ProgramOptions, isA<Type>());
    expect(scoring.BayesianScorer, isA<Type>());
    expect(text_editing.TextDocument, isA<Type>());
  });
}
