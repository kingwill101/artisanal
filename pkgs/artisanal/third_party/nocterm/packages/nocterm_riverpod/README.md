# nocterm_riverpod

Riverpod support for nocterm - A reactive caching and data-binding framework for terminal user interfaces.

## Features

- 🎯 **Full Riverpod Integration** - Use all Riverpod providers in your TUI apps
- 🔄 **Automatic Rebuilds** - Components rebuild automatically when providers change
- 📦 **State Management** - Manage complex state with providers
- 🎨 **ChangeNotifier Support** - Use ChangeNotifier for mutable state
- 🔍 **Computed Values** - Create derived state with Provider
- ♻️ **Auto-Dispose** - Automatic cleanup of unused providers

## Installation

Add `nocterm_riverpod` to your `pubspec.yaml`:

```yaml
dependencies:
  nocterm_riverpod:
    path: packages/nocterm_riverpod  # or from pub.dev when published
```

## Usage

### Basic Setup

Wrap your app with `ProviderScope`:

```dart
import 'package:nocterm/nocterm.dart';
import 'package:nocterm_riverpod/nocterm_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### Creating Providers

```dart
// Simple provider
final greetingProvider = Provider<String>((ref) => 'Hello, World!');

// State provider for mutable state
final counterProvider = StateProvider<int>((ref) => 0);

// Computed provider
final doubledProvider = Provider<int>((ref) {
  final count = ref.watch(counterProvider);
  return count * 2;
});

// ChangeNotifier provider
class Counter extends ChangeNotifier {
  int _count = 0;
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
}

final counterNotifierProvider = ChangeNotifierProvider((ref) => Counter());
```

### Using Providers in Components

```dart
class MyComponent extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    // Watch - rebuilds when provider changes
    final greeting = context.watch(greetingProvider);
    final count = context.watch(counterProvider);
    
    return Column(
      children: [
        Text(greeting),
        Text('Count: $count'),
        // Read - doesn't rebuild
        TextButton(
          onPressed: () {
            // Modify state
            context.read(counterProvider.notifier).state++;
          },
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

### Listening to Changes

```dart
class ListenerComponent extends StatefulComponent {
  @override
  State<ListenerComponent> createState() => _ListenerComponentState();
}

class _ListenerComponentState extends State<ListenerComponent> {
  @override
  void initState() {
    super.initState();
    
    // Listen to provider changes
    context.listen(counterProvider, (previous, next) {
      print('Counter changed from $previous to $next');
    });
  }
  
  @override
  Component build(BuildContext context) {
    return Text('Listening to changes...');
  }
}
```

### Provider Overrides

```dart
// Useful for testing or different configurations
ProviderScope(
  overrides: [
    counterProvider.overrideWithValue(StateController(42)),
  ],
  child: MyApp(),
)
```

## API Reference

### BuildContext Extensions

- `context.watch(provider)` - Read and subscribe to changes
- `context.read(provider)` - Read without subscribing
- `context.listen(provider, callback)` - Listen with callback
- `context.refresh(provider)` - Refresh a provider
- `context.invalidate(provider)` - Invalidate a provider

### Supported Providers

All standard Riverpod providers are supported:
- `Provider`
- `StateProvider`
- `FutureProvider`
- `StreamProvider`
- `StateNotifierProvider`
- `NotifierProvider`
- `AsyncNotifierProvider`
- `ChangeNotifierProvider` (nocterm-specific)

## Example

See the [example](example/) directory for a complete Todo app demonstrating:
- State management with providers
- Computed values
- Filtering and derived state
- User interaction handling

Run the example:

```bash
cd packages/nocterm_riverpod
dart run example/todo_app.dart
```

## Testing

```bash
cd packages/nocterm_riverpod
dart test
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Same as nocterm - see the main project for license details.
