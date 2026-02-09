import 'dart:async';
import 'dart:math' as math;
import 'package:nocterm/nocterm.dart';

/// Full-screen bento grid with shader effects
void main() async {
  await runApp(const BentoFullDemo());
}

class BentoFullDemo extends StatefulComponent {
  const BentoFullDemo({super.key});

  @override
  State<BentoFullDemo> createState() => _BentoFullDemoState();
}

class _BentoFullDemoState extends State<BentoFullDemo> {
  Timer? _timer;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 45), (_) {
      setState(() => _time += 0.04);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // All animation speeds are integers for perfect looping (complete cycles at _time = 2π)
  Color _glow(Color base, [double speed = 1.0, double min = 0.5]) {
    final factor = min + (1 - min) * (math.sin(_time * speed.round()) + 1) / 2;
    return Color.fromRGB(
      (base.red * factor).toInt().clamp(0, 255),
      (base.green * factor).toInt().clamp(0, 255),
      (base.blue * factor).toInt().clamp(0, 255),
    );
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.keyQ) {
          shutdownApp();
          return true;
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth.toInt();
          final totalHeight = constraints.maxHeight.toInt();

          // Calculate layout dimensions
          final heroWidth = (totalWidth * 0.65).toInt().toDouble();
          final sidebarWidth =
              (totalWidth - heroWidth - 3).toDouble(); // -3 for padding and gap
          // Bottom bar: 3 rows (1 padding top + 1 content + 1 padding bottom) + 2 border = 5
          // Feature cards: 6 rows
          // Gaps: 2 (SizedBox height 1 each)
          // Container padding: 2 (1 top + 1 bottom)
          // Total reserved: 5 + 6 + 2 + 2 = 15
          final heroHeight = (totalHeight - 15).toDouble();
          final featureCardHeight = 6.0;

          return Container(
            decoration: BoxDecoration(color: Color(0xFF080810)),
            padding: EdgeInsets.all(1),
            child: Column(
              children: [
                // Row 1: Hero + sidebar
                SizedBox(
                  height: heroHeight,
                  child: Row(
                    children: [
                      // Hero panel
                      SizedBox(
                        width: heroWidth,
                        child: _buildHeroPanel(
                            heroWidth.toInt(), heroHeight.toInt()),
                      ),
                      SizedBox(width: 1),
                      // Sidebar
                      SizedBox(
                        width: sidebarWidth,
                        child: Column(
                          children: [
                            SizedBox(
                              height: (heroHeight - 1) / 2,
                              child: _buildStatsPanel(sidebarWidth.toInt()),
                            ),
                            SizedBox(height: 1),
                            SizedBox(
                              height: (heroHeight - 1) / 2,
                              child: _buildCodePanel(sidebarWidth.toInt()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1),
                // Row 2: Feature cards
                SizedBox(
                  height: featureCardHeight,
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildFeatureCard('⚡', 'setState()',
                              'Reactive updates', Color(0xFFff6b9d), 0)),
                      SizedBox(width: 1),
                      Expanded(
                          child: _buildFeatureCard('📦', '50+ Widgets',
                              'Row, Column...', Color(0xFFfeca57), 1)),
                      SizedBox(width: 1),
                      Expanded(
                          child: _buildFeatureCard('🎨', '6 Themes',
                              'Nord, Dracula...', Color(0xFF48dbfb), 2)),
                      SizedBox(width: 1),
                      Expanded(
                          child: _buildFeatureCard('🔥', 'Hot Reload',
                              'Instant updates', Color(0xFFff9f43), 3)),
                      SizedBox(width: 1),
                      Expanded(
                          child: _buildFeatureCard('✓', 'Testing',
                              'testNocterm()', Color(0xFF1dd1a1), 4)),
                    ],
                  ),
                ),
                SizedBox(height: 1),
                // Row 3: Bottom bar with wave
                _buildBottomBar(totalWidth - 2),
              ],
            ),
          );
        },
      ),
    );
  }

  Component _buildHeroPanel(int width, int height) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0c0c14),
        border: BoxBorder.all(color: _glow(Color(0xFF6040a0), 0.5, 0.3)),
      ),
      child: Stack(
        children: [
          // Plasma background
          _buildPlasmaBackground(width - 2, height - 2),
          // Content overlay
          Center(
            child: Container(
              decoration: BoxDecoration(color: Color(0xDD080810)),
              padding: EdgeInsets.all(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAsciiTitle(),
                  SizedBox(height: 1),
                  Text(
                    '════════════════════════════════════════════════════',
                    style: TextStyle(color: Color(0xFF3a3a5a)),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Build beautiful terminal UIs with Flutter patterns',
                    style: TextStyle(color: Color(0xFF9999bb)),
                  ),
                  Text(
                    'StatefulComponent • setState() • Row • Column • hot reload',
                    style: TextStyle(color: Color(0xFF666688)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Component _buildPlasmaBackground(int w, int h) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int y = 0; y < h; y++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int x = 0; x < w; x++)
                Text(
                  _plasmaChar(x, y, w, h),
                  style: TextStyle(color: _plasmaColor(x, y, w, h)),
                ),
            ],
          ),
      ],
    );
  }

  String _plasmaChar(int x, int y, int w, int h) {
    final v = _plasmaValue(x / w, y / h);
    if (v > 0.7) return '█';
    if (v > 0.5) return '▓';
    if (v > 0.3) return '▒';
    if (v > 0.1) return '░';
    if (v > -0.1) return '·';
    if (v > -0.4) return '˙';
    return ' ';
  }

  double _plasmaValue(double nx, double ny) {
    final v1 = math.sin(nx * 12 + _time * 1);
    final v2 = math.cos(ny * 10 + _time * 1);
    final v3 = math.sin((nx + ny) * 8 + _time * 1);
    final v4 = math.cos(math.sqrt(nx * nx + ny * ny) * 15 - _time * 1);
    return (v1 + v2 + v3 + v4) / 4;
  }

  Color _plasmaColor(int x, int y, int w, int h) {
    final v = _plasmaValue(x / w, y / h);
    final r = (math.sin(v * 3 + _time * 1) * 60 + 80).toInt().clamp(20, 140);
    final g = (math.sin(v * 3 + 2) * 40 + 30).toInt().clamp(10, 80);
    final b =
        (math.sin(v * 3 + 4 + _time * 1) * 80 + 140).toInt().clamp(60, 220);
    return Color.fromRGB(r, g, b);
  }

  Component _buildAsciiTitle() {
    final glow = _glow(Color(0xFFc0a0ff), 2, 0.7);
    final lines = [
      '███╗   ██╗ ██████╗  ██████╗████████╗███████╗██████╗ ███╗   ███╗',
      '████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║',
      '██╔██╗ ██║██║   ██║██║        ██║   █████╗  ██████╔╝██╔████╔██║',
      '██║╚██╗██║██║   ██║██║        ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║',
      '██║ ╚████║╚██████╔╝╚██████╗   ██║   ███████╗██║  ██║██║ ╚═╝ ██║',
      '╚═╝  ╚═══╝ ╚═════╝  ╚═════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines) Text(line, style: TextStyle(color: glow)),
      ],
    );
  }

  Component _buildStatsPanel(int width) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0c0c14),
        border: BoxBorder.all(color: Color(0xFF2a2a3a)),
      ),
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📊 Stats', style: TextStyle(color: Color(0xFF6a6a8a))),
          Text('─' * (width - 4), style: TextStyle(color: Color(0xFF2a2a3a))),
          SizedBox(height: 1),
          _buildStatRow('Widgets', '50+', Color(0xFFff6b9d)),
          _buildStatRow('Themes', '6', Color(0xFF48dbfb)),
          _buildStatRow('Tests', '✓', Color(0xFF1dd1a1)),
          _buildStatRow('Reload', '🔥', Color(0xFFff9f43)),
        ],
      ),
    );
  }

  Component _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Color(0xFF6a6a8a))),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Component _buildCodePanel(int width) {
    final lines = [
      ('class', ' App ', 'extends', ' StatefulComponent'),
      ('  int', ' counter', ' = ', '0;'),
      ('', '', '', ''),
      ('  void', ' increment', '()', ' {'),
      ('    ', 'setState', '(() =>', ' counter++);'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0c0c14),
        border: BoxBorder.all(color: Color(0xFF2a2a3a)),
      ),
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📝 Code', style: TextStyle(color: Color(0xFF6a6a8a))),
          Text('─' * (width - 4), style: TextStyle(color: Color(0xFF2a2a3a))),
          for (int i = 0; i < lines.length; i++)
            Builder(builder: (context) {
              // Smooth wave that travels down the code lines
              final wave = math.sin(_time * 1 - i * 0.8);
              final intensity = ((wave + 1) / 2).clamp(0.0, 1.0); // 0 to 1

              return Container(
                decoration: BoxDecoration(
                  color: Color.fromRGB(
                    (0x1a + (intensity * 0x10)).toInt(),
                    (0x1a + (intensity * 0x10)).toInt(),
                    (0x2a + (intensity * 0x15)).toInt(),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(lines[i].$1,
                        style: TextStyle(color: Color(0xFFc678dd))),
                    Text(lines[i].$2,
                        style: TextStyle(color: Color(0xFF98c379))),
                    Text(lines[i].$3,
                        style: TextStyle(color: Color(0xFFe5c07b))),
                    Text(lines[i].$4,
                        style: TextStyle(color: Color(0xFF61afef))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Component _buildFeatureCard(
      String icon, String title, String desc, Color color, int idx) {
    // Smooth wave across feature cards - each card has a phase offset
    final wave = math.sin(_time * 1 - idx * 1.2);
    final intensity = ((wave + 1) / 2).clamp(0.0, 1.0); // 0 to 1

    // Lerp helper
    int lerp(int a, int b, double t) => (a + (b - a) * t).toInt().clamp(0, 255);

    // Smoothly interpolate border color (from dark gray to subtle accent)
    final borderColor = Color.fromRGB(
      lerp(0x2a, color.red ~/ 3, intensity),
      lerp(0x2a, color.green ~/ 3, intensity),
      lerp(0x3a, color.blue ~/ 3, intensity),
    );

    // Smoothly interpolate icon color (from gray to full color)
    final iconColor = Color.fromRGB(
      lerp(0x5a, color.red, intensity),
      lerp(0x5a, color.green, intensity),
      lerp(0x6a, color.blue, intensity),
    );

    // Smoothly interpolate text brightness
    final titleBrightness = lerp(0x8a, 0xcc, intensity);
    final descBrightness = lerp(0x4a, 0x6a, intensity);

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0c0c14),
        border: BoxBorder.all(color: borderColor),
      ),
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$icon ', style: TextStyle(color: iconColor)),
              Text(
                title,
                style: TextStyle(
                  color: Color.fromRGB(titleBrightness, titleBrightness,
                      lerp(titleBrightness, 255, 0.1)),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            '─────────────',
            style: TextStyle(color: Color(0xFF1a1a2a)),
          ),
          Text(desc,
              style: TextStyle(
                  color: Color.fromRGB(descBrightness, descBrightness,
                      lerp(descBrightness, 255, 0.1)))),
        ],
      ),
    );
  }

  Component _buildBottomBar(int width) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0c0c14),
        border: BoxBorder.all(color: Color(0xFF2a2a3a)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✦ ', style: TextStyle(color: _glow(Color(0xFFc678dd), 2))),
              Text('nocterm',
                  style: TextStyle(
                      color: Color(0xFFffffff), fontWeight: FontWeight.bold)),
              Text(' v0.3.5', style: TextStyle(color: Color(0xFF4a4a5a))),
            ],
          ),
          // Wave animation
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildWave(),
          ),
          Text('[q] quit', style: TextStyle(color: Color(0xFF4a4a5a))),
        ],
      ),
    );
  }

  List<Component> _buildWave() {
    return [
      for (int i = 0; i < 30; i++)
        Text(
          _waveChar(i),
          style: TextStyle(
            color: Color.fromRGB(
              (80 + math.sin(_time * 2 + i * 0.2) * 60).toInt(),
              (50 + math.cos(_time * 2 + i * 0.15) * 30).toInt(),
              (140 + math.sin(_time * 1 + i * 0.25) * 80).toInt(),
            ),
          ),
        ),
    ];
  }

  String _waveChar(int i) {
    final v = math.sin(_time * 2 + i * 0.3);
    if (v > 0.5) return '█';
    if (v > 0) return '▓';
    if (v > -0.5) return '▒';
    return '░';
  }
}
