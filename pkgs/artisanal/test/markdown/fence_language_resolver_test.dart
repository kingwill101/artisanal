import 'package:artisanal/markdown.dart';
import 'package:test/test.dart';

void main() {
  group('FenceLanguageResolver.resolve', () {
    test('normalizes common aliases', () {
      expect(FenceLanguageResolver.resolve('js'), 'javascript');
      expect(FenceLanguageResolver.resolve('tsx'), 'typescript');
      expect(FenceLanguageResolver.resolve('zsh'), 'bash');
      expect(FenceLanguageResolver.resolve('c#'), 'cs');
      expect(FenceLanguageResolver.resolve('proto'), 'protobuf');
      expect(FenceLanguageResolver.resolve('{.yml}'), 'yaml');
    });

    test('supports filename-style fence labels', () {
      expect(FenceLanguageResolver.resolve('main.rs'), 'rust');
      expect(FenceLanguageResolver.resolve('Dockerfile'), 'dockerfile');
      expect(FenceLanguageResolver.resolve('pubspec.yaml'), 'yaml');
      expect(FenceLanguageResolver.resolve('build.gradle.kts'), 'kotlin');
      expect(FenceLanguageResolver.resolve('Component.jsx'), 'javascript');
    });

    test('falls back to cleaned raw language label when unknown', () {
      expect(FenceLanguageResolver.resolve('dart'), 'dart');
      expect(FenceLanguageResolver.resolve('Mermaid'), 'mermaid');
      expect(FenceLanguageResolver.resolve(null), isNull);
      expect(FenceLanguageResolver.resolve('   '), isNull);
    });
  });

  group('FenceLanguageResolver.resolveFilename', () {
    test('handles nested paths and dotfiles', () {
      expect(FenceLanguageResolver.resolveFilename('src/app/main.rs'), 'rust');
      expect(FenceLanguageResolver.resolveFilename('/tmp/.zshrc'), 'bash');
      expect(FenceLanguageResolver.resolveFilename('CMakeLists.txt'), 'cmake');
    });

    test('returns null when no supported filename mapping exists', () {
      expect(FenceLanguageResolver.resolveFilename('README'), isNull);
      expect(FenceLanguageResolver.resolveFilename('Cargo.lock'), isNull);
    });
  });
}
