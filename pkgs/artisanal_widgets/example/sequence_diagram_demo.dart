//
// Demonstrates the SequenceDiagramChart widget in an interactive TUI app.
//
// Run with: dart run example/sequence_diagram_demo.dart
//

import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/charting.dart' show SequenceDiagramTheme;
import 'package:artisanal/uv.dart' show UvStyle, UvColor;
import 'package:artisanal_widgets/charting.dart' as tui;

import '_editor_demo_theme.dart' as demo_theme;

void main() async {
  final app = tui.WidgetApp(SequenceDiagramDemo());
  await runtime.runProgram(
    app,
    options: const runtime.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: runtime.MouseMode.allMotion,
      startupProbes: false,
    ),
  );
}

class SequenceDiagramDemo extends tui.StatefulWidget {
  SequenceDiagramDemo({super.key});

  @override
  tui.State createState() => _SequenceDiagramDemoState();
}

class _SequenceDiagramDemoState extends tui.State<SequenceDiagramDemo> {
  int _selectedExample = 0;
  bool _showTheme = false;

  tui.Theme get theme => demo_theme.resolveEditorDemoTheme('adaptive');

  final List<_DiagramExample> _examples = [
    _DiagramExample(
      title: 'Basic Request/Response',
      mermaid: '''
sequenceDiagram
  participant C as Client
  participant S as Server

  C->>S: GET /api/users
  S-->>C: 200 OK + JSON
''',
    ),
    _DiagramExample(
      title: 'Authentication Flow',
      mermaid: '''
sequenceDiagram
  participant U as User
  participant W as Web App
  participant A as Auth Server
  participant R as Resource API

  U->>W: Click Login
  W->>A: POST /oauth/authorize
  A-->>U: Login form
  U->>A: Submit credentials
  A-->>W: Auth code
  W->>A: POST /oauth/token
  A-->>W: Access token
  W->>R: GET /api/data (Bearer)
  R-->>W: 200 OK
  W-->>U: Display data
''',
    ),
    _DiagramExample(
      title: 'Error Handling with Alt',
      mermaid: '''
sequenceDiagram
  participant App as App
  participant API as API
  participant DB as Database

  App->>API: POST /order
  API->>DB: INSERT order

  alt Success
    DB-->>API: 201 Created
    API-->>App: Order confirmed
  else Database error
    DB--xAPI: Connection failed
    API--xApp: 503 Service Unavailable
  end

  note over App,API: Retry with exponential backoff
''',
    ),
    _DiagramExample(
      title: 'Loop with Autonumber',
      mermaid: '''
sequenceDiagram
  autonumber
  participant L as Load Balancer
  participant W1 as Worker 1
  participant W2 as Worker 2
  participant Q as Queue

  L->>Q: Enqueue task

  loop Process until empty
    Q->>W1: Dequeue task
    W1-->>Q: Task done
    Q->>W2: Dequeue task
    W2-->>Q: Task done
  end

  note over W1,W2: Workers run in parallel
''',
    ),
    _DiagramExample(
      title: 'Microservices Protocol',
      mermaid: '''
sequenceDiagram
  autonumber 10 5
  participant GW as API Gateway
  participant Auth as Auth Service
  participant User as User Service
  participant Order as Order Service
  participant Notify as Notification Svc

  GW->>Auth: Validate JWT
  Auth-->>GW: Valid

  par Process order
    GW->>Order: Create order
    Order->>User: Verify user exists
    User-->>Order: User OK
    Order-->>GW: 201 Created
  and Send notification
    GW->>Notify: Send email
    Notify-->>GW: Queued
  end

  critical If payment fails
    Order-->>GW: Rollback order
  end
''',
    ),
  ];

  @override
  tui.Widget build(tui.BuildContext context) {
    final media = tui.MediaQuery.of(context);
    final width = media.size.width.round();

    return tui.ThemeScope(
      theme: theme,
      child: tui.Column(
        gap: 1,
        children: [
          _buildHeader(width),
          _buildExampleSelector(),
          _buildDiagram(),
          tui.Divider(width: width > 0 ? width : 72),
          _buildFooter(),
        ],
      ),
    );
  }

  tui.Widget _buildHeader(int width) {
    return tui.SizedBox(
      width: width > 0 ? width : null,
      child: tui.Frame(
        padding: const tui.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        background: theme.surface,
        child: tui.Row(
          mainAxisSize: tui.MainAxisSize.max,
          mainAxisAlignment: tui.MainAxisAlignment.spaceBetween,
          children: [
            tui.Row(
              gap: 1,
              children: [
                tui.Icon(tui.Icons.star, color: theme.primary),
                tui.Text('Sequence Diagram Widget', style: theme.titleLarge),
              ],
            ),
            tui.Text(
              '${_selectedExample + 1} / ${_examples.length}',
              style: theme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  tui.Widget _buildExampleSelector() {
    return tui.Row(
      gap: 1,
      children: [
        for (var i = 0; i < _examples.length; i++)
          tui.Button(
            label: _examples[i].title.length > 12
                ? _examples[i].title.substring(0, 12)
                : _examples[i].title,
            variant: i == _selectedExample
                ? tui.ButtonVariant.primary
                : tui.ButtonVariant.ghost,
            size: tui.ButtonSize.small,
            onPressed: () {
              setState(() => _selectedExample = i);
              return null;
            },
          ),
      ],
    );
  }

  tui.Widget _buildDiagram() {
    final example = _examples[_selectedExample];
    return tui.Frame(
      padding: const tui.EdgeInsets.all(1),
      background: theme.surface,
      child: tui.Column(
        gap: 1,
        children: [
          tui.Text(example.title, style: theme.titleMedium),
          tui.SequenceDiagramChart(
            mermaid: example.mermaid,
            diagramTheme: _showTheme
                ? SequenceDiagramTheme(
                    participantBox: UvStyle(
                      fg: UvColor.rgb(134, 225, 200),
                    ),
                    participantLabel: UvStyle(
                      fg: UvColor.rgb(228, 239, 232),
                    ),
                    lifeline: UvStyle(
                      fg: UvColor.rgb(134, 225, 200),
                    ),
                    request: UvStyle(
                      fg: UvColor.rgb(134, 225, 200),
                    ),
                    response: UvStyle(
                      fg: UvColor.rgb(230, 177, 126),
                    ),
                    note: UvStyle(
                      fg: UvColor.rgb(215, 229, 221),
                      bg: UvColor.rgb(36, 56, 47),
                    ),
                    fragment: UvStyle(
                      fg: UvColor.rgb(154, 184, 169),
                    ),
                    fragmentLabel: UvStyle(
                      fg: UvColor.rgb(154, 184, 169),
                      bg: UvColor.rgb(28, 43, 36),
                    ),
                    group: UvStyle(
                      fg: UvColor.rgb(76, 99, 89),
                    ),
                    rect: UvStyle(
                      fg: UvColor.rgb(180, 180, 180),
                      bg: UvColor.rgb(40, 40, 40),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  tui.Widget _buildFooter() {
    return tui.Row(
      gap: 3,
      children: [
        tui.Text('←/→: examples', style: theme.labelSmall),
        tui.Checkbox(
          value: _showTheme,
          label: tui.Text('Custom theme', style: theme.labelSmall),
          onChanged: (value) {
            setState(() => _showTheme = value);
            return null;
          },
        ),
        tui.Text('q: quit', style: theme.labelSmall),
      ],
    );
  }

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg is runtime.KeyMsg) {
      final key = msg.key;

      if (key.char == 'q' || key.char == 'Q') {
        return runtime.Cmd.quit();
      }

      if (key.char == 'ArrowLeft' || key.char == 'h') {
        setState(() {
          _selectedExample =
              (_selectedExample - 1 + _examples.length) % _examples.length;
        });
      }
      if (key.char == 'ArrowRight' || key.char == 'l') {
        setState(() {
          _selectedExample = (_selectedExample + 1) % _examples.length;
        });
      }
    }
    return null;
  }
}

class _DiagramExample {
  const _DiagramExample({required this.title, required this.mermaid});
  final String title;
  final String mermaid;
}
