# Liquid Templates (Experimental)

Artisanal provides Liquid tag adapters for building UI blocks in templates. This API is experimental and may change in minor releases.

## Quick Start

```dart
import 'package:artisanal/liquid.dart';

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

Register tags and filters on a `LiquidEnvironment` when you need isolated behavior per template.

```dart
import 'package:artisanal/liquid.dart';

void main() {
  final env = LiquidEnvironment()..registerUiTags();
  final template = LiquidTemplate.parse('{% text content:"Hello" %}', env: env);
  print(template.render());
}
```

## Gotchas

- This module is `@experimental` and may change in minor releases.
- Tag parsing and render targets are still evolving.

## Related Docs

- [docs_index.md](docs_index.md) - Full documentation index
- [style.md](style.md)
- [uv.md](uv.md)
