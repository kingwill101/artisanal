import 'dart:io';

import 'package:nocterm/nocterm.dart';

/// Interactive TUI demo for displaying images in a scrollable ListView.
///
/// Features:
/// - Multiple images displayed in a scrollable list
/// - Tab/arrow keys to switch between rendering protocols
/// - Each item shows an image with a label
///
/// Usage:
///   dart run example/image_listview_demo.dart `<image_path>`
///
/// Controls:
///   Tab / Arrow Keys - Switch protocol
///   Up/Down - Scroll the list
///   Q / Escape - Quit
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run example/image_listview_demo.dart <image_path>');
    print('');
    print(
        'Example: dart run example/image_listview_demo.dart ~/Pictures/photo.png');
    exit(1);
  }

  final imagePath = args[0];

  // Verify image exists
  final file = File(imagePath);
  if (!await file.exists()) {
    print('Error: Image file not found: $imagePath');
    exit(1);
  }

  await runApp(ImageListViewDemo(imagePath: imagePath));
}

class ImageListViewDemo extends StatefulComponent {
  final String imagePath;

  const ImageListViewDemo({super.key, required this.imagePath});

  @override
  State<ImageListViewDemo> createState() => _ImageListViewDemoState();
}

class _ImageListViewDemoState extends State<ImageListViewDemo> {
  int _selectedProtocolIndex = 0;

  final List<ImageProtocol> _protocols = [
    ImageProtocol.kitty,
    ImageProtocol.iterm2,
    ImageProtocol.sixel,
    ImageProtocol.unicodeBlocks,
  ];

  // Simulated gallery items
  final List<String> _galleryLabels = [
    'Featured Image',
    'Landscape View',
    'Portrait Shot',
    'Thumbnail Preview',
    'Cover Art',
    'Banner Image',
    'Profile Picture',
    'Background',
    'Hero Image',
    'Gallery Item',
  ];

  void _nextProtocol() {
    setState(() {
      _selectedProtocolIndex = (_selectedProtocolIndex + 1) % _protocols.length;
    });
  }

  void _prevProtocol() {
    setState(() {
      _selectedProtocolIndex =
          (_selectedProtocolIndex - 1 + _protocols.length) % _protocols.length;
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
    final protocol = _protocols[_selectedProtocolIndex];

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
          setState(() => _selectedProtocolIndex = 0);
          return true;
        }
        if (event.logicalKey == LogicalKey.digit2) {
          setState(() => _selectedProtocolIndex = 1);
          return true;
        }
        if (event.logicalKey == LogicalKey.digit3) {
          setState(() => _selectedProtocolIndex = 2);
          return true;
        }
        if (event.logicalKey == LogicalKey.digit4) {
          setState(() => _selectedProtocolIndex = 3);
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
                    'Image ListView Demo',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Source: ${component.imagePath}',
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
                    final isSelected = idx == _selectedProtocolIndex;
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

            // Image ListView - fills available space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.grey),
                  ),
                  child: ListView.builder(
                    itemCount: _galleryLabels.length,
                    itemBuilder: (context, index) {
                      return _buildImageItem(
                        index: index,
                        label: _galleryLabels[index],
                        protocol: protocol,
                      );
                    },
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
                    '↑↓: Scroll  ',
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

  Component _buildImageItem({
    required int index,
    required String label,
    required ImageProtocol protocol,
  }) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        border: BoxBorder(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image thumbnail
          Container(
            width: 16,
            height: 8,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.cyan.withOpacity(0.5)),
            ),
            child: Image.file(
              component.imagePath,
              height: 8,
              fit: BoxFit.contain,
              protocol: protocol,
              placeholder: const Center(
                child: Text('...', style: TextStyle(color: Colors.grey)),
              ),
              errorWidget: const Center(
                child: Text('[!]', style: TextStyle(color: Colors.red)),
              ),
            ),
          ),

          const SizedBox(width: 2),

          // Label and metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.brightWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Item #${index + 1} • Protocol: ${_protocolName(protocol)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 1),
                Text(
                  'Path: ${component.imagePath}',
                  style: TextStyle(color: Colors.cyan.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
