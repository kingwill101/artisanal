import 'package:artisanal/charting.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

void main() {
  final heading = Style().bold().foreground(Colors.cyan);
  final dim = Style().foreground(Colors.gray);
  final green = Style().bold().foreground(Colors.green);

  print(heading.render('Artisanal Sequence Diagram Demo'));
  print(dim.render('Mermaid sequence diagram parser and renderer'));
  print('');

  _printSection(
    green.render('1. Basic Authentication Flow'),
    _render('''
sequenceDiagram
  participant C as Client
  participant S as Server
  participant DB as Database

  C->>S: POST /login
  S->>DB: Query user
  DB-->>S: User record
  S-->>C: 200 OK + JWT
'''),
  );

  _printSection(
    green.render('2. Request with Error Handling'),
    _render('''
sequenceDiagram
  participant App as Application
  participant API as API Gateway
  participant Svc as Microservice

  App->>API: GET /users/123
  API->>Svc: Forward request
  Svc--xApp: 500 Internal Error

  alt Retry
    App->>API: GET /users/123 (retry)
    API->>Svc: Forward request
    Svc-->>App: 200 OK + User data
  else Give up
    App->>App: Show error to user
  end
'''),
  );

  _printSection(
    green.render('3. Complex Protocol with Fragments'),
    _render('''
sequenceDiagram
  autonumber
  participant W as Web
  participant GW as Gateway
  participant Auth as Auth Service
  participant Res as Resource Svc

  W->>GW: POST /api/data
  GW->>Auth: Validate token

  alt Valid token
    Auth-->>GW: 200 OK
    GW->>Res: Process request

    loop Retry on timeout
      Res-->>GW: Processing...
    end

    Res-->>GW: 201 Created
    GW-->>W: 201 + Location
  else Invalid token
    Auth-->>GW: 401 Unauthorized
    GW-->>W: 401 + WWW-Authenticate
  end

  note over W,GW: All responses include CORS headers
'''),
  );

  _printSection(
    green.render('4. Bubble API (SequenceDiagramModel)'),
    _bubbleDemo(),
  );
}

String _render(String mermaid) {
  return renderSequenceDiagram(mermaid);
}

void _printSection(String title, String content) {
  print(title);
  print(content);
  print('');
}

String _bubbleDemo() {
  final model = SequenceDiagramModel(
    mermaid: '''
sequenceDiagram
  participant U as User
  participant UI as UI Bubble
  participant M as Model

  U->>UI: Type text
  UI->>M: update(msg)
  M-->>UI: (newState, cmd)
  UI-->>U: view()
''',
    width: 60,
    height: 16,
  );

  final lines = [
    'Model created with mermaid source:',
    '  isValid: ${model.isValid}',
    '  participants: ${model.participantCount}',
    '  messages: ${model.messageCount}',
    '  steps: ${model.stepCount}',
    '',
    'Rendered output:',
    model.view(),
  ];
  return lines.join('\n');
}
