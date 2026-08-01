# Build terminal output with Liquid

Liquid tags can describe panels, stacks, text, progress, and charts in a
template instead of Dart code. This integration is experimental and may change
in a minor release. The API is exported by
`package:artisanal/artisanal.dart`.

## Quick Start

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  registerLiquidUiTags();

  final template = LiquidTemplate.parse('''
{% panel title:"Stats" width:32 padding:1 border:"rounded" %}
{% vstack gap:1 %}
{% text content:"CPU" bold:true %}
{% progress value:0.72 width:24 color:"#00bbf9" %}
|
{% text content:"RAM" bold:true %}
{% progress value:43 width:24 color:"#f72585" %}
{% endvstack %}
{% endpanel %}
''');

  final output = template.render();
  print(output);
}
```

## Custom Tags

Use Liquify's `environmentSetup` callback when tags and filters should be
registered only for one template environment.

```dart
import 'package:artisanal/artisanal.dart';
import 'package:liquify/liquify.dart' as liquify;

void main() {
  final template = liquify.Template.parse(
    '{% text content:"Hello" %}',
    environmentSetup: (environment) {
      registerLiquidUiTags(environment: environment);
    },
  );
  print(template.render());
}
```

## Things to keep in mind

- This module is `@experimental` and may change in minor releases.
- Tag parsing and render targets are still evolving.

## Where to go next

- [docs_index.md](docs_index.md) - Full documentation index
- [style.md](style.md)
- [uv.md](uv.md)
