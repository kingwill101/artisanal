import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/chat_model.dart';
import '../theme.dart';
import '../widgets/footer_bar.dart';

class AgentOverview extends w.StatelessWidget {
  AgentOverview({
    required this.model,
    super.key,
  });

  final ChatModel model;

  @override
  w.Widget build(w.BuildContext context) {
    final rows = <w.Widget>[
      _row('Agent', model.agentName),
      _row('Model', model.modelName),
      _row('Provider', model.providerName),
      _row('Working directory', model.workingDirectory),
      _row('Context tokens', '${model.contextTokens}'),
      _row('Context window', '${model.contextPercentage}%'),
      _row('Cost', '\$${model.cost.toStringAsFixed(2)}'),
    ];

    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Expanded(
          child: w.Padding(
            padding: const w.EdgeInsets.only(left: 2, right: 2, top: 1, bottom: 1),
            child: w.Column(
              crossAxisAlignment: w.CrossAxisAlignment.stretch,
              children: [
                w.Text(
                  'Agent Overview',
                  style: style.Style()..foreground(OC.text)..bold(),
                ),
                w.SizedBox(height: 1),
                ...rows,
              ],
            ),
          ),
        ),
        FooterBar(
          workingDirectory: model.workingDirectory,
          lspCount: model.lspServers.length,
          mcpCount: model.mcpServers.length,
          statusHint: '/agent',
          mode: model.mode
        ),
      ],
    );
  }

  w.Widget _row(String label, String value) {
    return w.Row(
      children: [
        w.Text(
          '$label:',
          style: style.Style()..foreground(OC.textMuted),
        ),
        w.SizedBox(width: 2),
        w.Text(
          value,
          style: style.Style()..foreground(OC.text),
        ),
      ],
    );
  }
}
