import 'dart:io';

import 'package:nocterm/nocterm.dart';

/// Interactive TUI demo for displaying images with different protocols.
///
/// Features:
/// - Tab to switch between rendering protocols
/// - Auto-detects terminal capabilities
/// - Shows the same image using Kitty, iTerm2, Sixel, or Unicode blocks
///
/// Usage:
///   dart run example/image_demo.dart `<image_path>`
///
/// Controls:
///   Tab / Arrow Keys - Switch protocol
///   Q / Escape - Quit
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run example/image_demo.dart <image_path>');
    print('');
    print('Example: dart run example/image_demo.dart ~/Pictures/photo.png');
    exit(1);
  }

  final imagePath = args[0];

  // Verify image exists
  final file = File(imagePath);
  if (!await file.exists()) {
    print('Error: Image file not found: $imagePath');
    exit(1);
  }

  await runApp(ImageDemo(imagePath: imagePath));
}

class ImageDemo extends StatefulComponent {
  final String imagePath;

  const ImageDemo({super.key, required this.imagePath});

  @override
  State<ImageDemo> createState() => _ImageDemoState();
}

class _ImageDemoState extends State<ImageDemo> {
  int _selectedIndex = 0;

  final List<ImageProtocol> _protocols = [
    ImageProtocol.kitty,
    ImageProtocol.iterm2,
    ImageProtocol.sixel,
    ImageProtocol.unicodeBlocks,
  ];

  void _nextProtocol() {
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % _protocols.length;
    });
  }

  void _prevProtocol() {
    setState(() {
      _selectedIndex =
          (_selectedIndex - 1 + _protocols.length) % _protocols.length;
    });
  }

  String _protocolName(ImageProtocol protocol) {
    switch (protocol) {
      case ImageProtocol.kitty:
        return 'Kitty';
      case ImageProtocol.iterm2:
        return 'iTerm2';
      case ImageProtocol.sixel:
        return 'Sixel';
      case ImageProtocol.unicodeBlocks:
        return 'Unicode Blocks';
    }
  }

  @override
  Component build(BuildContext context) {
    final protocol = _protocols[_selectedIndex];

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.tab ||
            event.logicalKey == LogicalKey.arrowRight) {
          _nextProtocol();
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowLeft) {
          _prevProtocol();
          return true;
        }
        if (event.logicalKey == LogicalKey.keyQ ||
            event.logicalKey == LogicalKey.escape) {
          exit(0);
        }
        // Number keys to directly select protocol
        if (event.logicalKey == LogicalKey.digit1) {
          setState(() => _selectedIndex = 0);
          return true;
        }
        if (event.logicalKey == LogicalKey.digit2) {
          setState(() => _selectedIndex = 1);
          return true;
        }
        if (event.logicalKey == LogicalKey.digit3) {
          setState(() => _selectedIndex = 2);
          return true;
        }
        if (event.logicalKey == LogicalKey.digit4) {
          setState(() => _selectedIndex = 3);
          return true;
        }
        return false;
      },
      child: Container(
        color: const Color.fromRGB(24, 24, 32),
        child: Column(
          children: [
            // Header
            Container(
              color: const Color.fromRGB(40, 40, 60),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Row(
                children: [
                  const Text(
                    'Image Demo',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    component.imagePath,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 1),

            // Protocol selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  const Text('Protocol: ',
                      style: TextStyle(color: Colors.grey)),
                  ..._protocols.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final proto = entry.value;
                    final isSelected = idx == _selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Text(
                        '[${idx + 1}] ${_protocolName(proto)}',
                        style: TextStyle(
                          color: isSelected ? Colors.cyan : Colors.grey,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 1),

            // Image display - fills available space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.grey),
                  ),
                  padding: const EdgeInsets.all(1),
                  child: Image.file(
                    component.imagePath,
                    // No width/height specified - will expand to fill available space
                    fit: BoxFit.contain,
                    protocol: protocol,
                    placeholder: const Center(
                      child: Text('Loading...',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    errorWidget: const Center(
                      child: Text('Failed to load image',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              color: const Color.fromRGB(40, 40, 60),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  const Text(
                    'Tab/←→: Switch Protocol  ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const Text(
                    '1-4: Direct Select  ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const Text(
                    'Q: Quit',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    'Current: ${_protocolName(protocol)}',
                    style: const TextStyle(color: Colors.cyan),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
