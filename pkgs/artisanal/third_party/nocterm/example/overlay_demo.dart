import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const OverlayDemo());
}

class OverlayDemo extends StatefulComponent {
  const OverlayDemo({super.key});

  @override
  State<OverlayDemo> createState() => _OverlayDemoState();
}

class _OverlayDemoState extends State<OverlayDemo> {
  OverlayEntry? _overlayEntry;
  late OverlayState _overlayState;

  @override
  void initState() {
    super.initState();
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => KeyboardListener(
        autofocus: true,
        onKeyEvent: (event) {
          if (event == LogicalKey.escape) {
            _hideOverlay();
            return true;
          }
          return false;
        },
        // Use Stack to layer the barrier behind the dialog
        child: Stack(
          children: [
            // Animated dimming barrier that fades in
            FadeModalBarrier(
              color: Colors.black.withOpacity(0.6),
              dismissible: true,
              onDismiss: _hideOverlay,
              duration: const Duration(milliseconds: 150),
            ),
            // The actual dialog
            Positioned(
              left: 10,
              top: 5,
              child: Container(
                width: 30,
                height: 10,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.cyan),
                  // Give the dialog a background so it's visible against the dim
                  color: Colors.black,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Overlay Window'),
                      const SizedBox(height: 1),
                      Text(
                        'Background is dimmed!',
                        style: TextStyle(color: Colors.green),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Press ESC to close',
                        style: TextStyle(
                            color: Colors.yellow, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    _overlayState.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Component build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) {
            // Store the overlay state for later use
            Future.microtask(() {
              _overlayState = Overlay.of(context);
            });

            return KeyboardListener(
              autofocus: true,
              onKeyEvent: (event) {
                if (event == LogicalKey.escape) {
                  if (_overlayEntry != null) {
                    _hideOverlay();
                  } else {
                    shutdownApp();
                  }
                  return true;
                } else if (event == LogicalKey.keyO) {
                  if (_overlayEntry == null) {
                    _showOverlay();
                  }
                  return true;
                }
                return false;
              },
              child: Container(
                color: null, // Terminal default background
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Overlay Demo',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                          'This demo shows overlays with animated dimming background'),
                      const SizedBox(height: 1),
                      Text(
                        'The background fades to dark when the overlay appears!',
                        style: TextStyle(color: Colors.green),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          border: BoxBorder.all(color: Colors.yellow),
                        ),
                        child: Column(
                          children: [
                            Text('Press "O" to show overlay',
                                style: TextStyle(color: Colors.yellow)),
                            Text('Press ESC to close overlay/exit',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
