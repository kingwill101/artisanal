import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const TextFieldDemo());
}

class TextFieldDemo extends StatefulComponent {
  const TextFieldDemo({super.key});

  @override
  State<TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<TextFieldDemo> {
  final _controller = TextEditingController();
  final List<String> _messages = [];

  @override
  Component build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '✎ TextField',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('› ',
                  style: TextStyle(
                      color: Colors.magenta, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 30,
                child: TextField(
                  controller: _controller,
                  focused: true,
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _messages.insert(0, value);
                        if (_messages.length > 3) _messages.removeLast();
                      });
                      _controller.clear();
                    }
                  },
                  placeholder: 'Type here...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          SizedBox(
            width: 34,
            height: 5,
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.gray),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Messages appear here',
                        style: TextStyle(color: Colors.gray),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _messages.length && i < 3; i++)
                          Text(
                            _messages[i],
                            style: TextStyle(
                              color: i == 0 ? Colors.cyan : Colors.white,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
