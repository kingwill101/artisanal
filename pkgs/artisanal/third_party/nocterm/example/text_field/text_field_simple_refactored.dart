import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const SimpleTextFieldDemo());
}

class SimpleTextFieldDemo extends StatefulComponent {
  const SimpleTextFieldDemo({super.key});

  @override
  State<SimpleTextFieldDemo> createState() => _SimpleTextFieldDemoState();
}

class _SimpleTextFieldDemoState extends State<SimpleTextFieldDemo> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Managing focus state explicitly
  int _focusedFieldIndex = 0;
  static const int _totalFields = 3;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'John Doe';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleTabNavigation({bool reverse = false}) {
    setState(() {
      if (reverse) {
        _focusedFieldIndex =
            (_focusedFieldIndex - 1 + _totalFields) % _totalFields;
      } else {
        _focusedFieldIndex = (_focusedFieldIndex + 1) % _totalFields;
      }
    });
  }

  bool _handleGlobalKey(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.tab && !event.isShiftPressed) {
      _handleTabNavigation(reverse: false);
      return true;
    } else if (event.logicalKey == LogicalKey.tab && event.isShiftPressed) {
      _handleTabNavigation(reverse: true);
      return true;
    }
    return false;
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true, // Always capture keys at the top level
      onKeyEvent: _handleGlobalKey,
      child: Container(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simple TextField Demo - Refactored',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            Text(
              'Focused Field: ${_getFocusedFieldName()}',
              style: TextStyle(color: Colors.yellow),
            ),
            const SizedBox(height: 2),

            // Name field
            Text('Name:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _nameController,
              focused: _focusedFieldIndex == 0,
              onFocusChange: (focused) {
                if (focused) {
                  setState(() => _focusedFieldIndex = 0);
                }
              },
              placeholder: 'Enter your name',
              width: 30,
              decoration: InputDecoration(
                border: BoxBorder.all(color: Colors.gray),
                focusedBorder: BoxBorder.all(color: Colors.green),
                contentPadding: const EdgeInsets.symmetric(horizontal: 1),
              ),
              onSubmitted: (value) {
                setState(() => _focusedFieldIndex = 1);
              },
            ),

            const SizedBox(height: 1),

            // Email field
            Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _emailController,
              focused: _focusedFieldIndex == 1,
              onFocusChange: (focused) {
                if (focused) {
                  setState(() => _focusedFieldIndex = 1);
                }
              },
              placeholder: 'user@example.com',
              width: 30,
              decoration: InputDecoration(
                border: BoxBorder.all(color: Colors.gray),
                focusedBorder: BoxBorder.all(color: Colors.green),
                contentPadding: const EdgeInsets.symmetric(horizontal: 1),
              ),
              onSubmitted: (value) {
                setState(() => _focusedFieldIndex = 2);
              },
            ),

            const SizedBox(height: 1),

            // Password field
            Text('Password:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _passwordController,
              focused: _focusedFieldIndex == 2,
              onFocusChange: (focused) {
                if (focused) {
                  setState(() => _focusedFieldIndex = 2);
                }
              },
              placeholder: 'Enter password',
              obscureText: true,
              width: 30,
              decoration: InputDecoration(
                border: BoxBorder.all(color: Colors.gray),
                focusedBorder: BoxBorder.all(color: Colors.green),
                contentPadding: const EdgeInsets.symmetric(horizontal: 1),
              ),
              onSubmitted: (value) {
                setState(() => _focusedFieldIndex = 0);
              },
            ),

            const SizedBox(height: 2),
            Text('Press Tab to move forward, Shift+Tab to move backward'),
            Text('Press Escape to exit'),
          ],
        ),
      ),
    );
  }

  String _getFocusedFieldName() {
    switch (_focusedFieldIndex) {
      case 0:
        return 'Name';
      case 1:
        return 'Email';
      case 2:
        return 'Password';
      default:
        return 'None';
    }
  }
}
