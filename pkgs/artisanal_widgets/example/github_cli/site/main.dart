import 'package:artisanal/web.dart' show runWidgetAppInBrowser;
import 'package:artisanal_widgets/widgets.dart' show WidgetApp;
import 'package:github_cli/src/app/dashboard.dart';
import 'package:github_cli/src/app/pull_request_view.dart';
import 'package:github_cli/src/client/client_http.dart';
import 'package:github_cli/src/utils/pull_request_input.dart';
import 'package:web/web.dart' as web;

const _defaultRepo = 'dart-lang/sdk';

void main() async {
  final rawSearch = web.window.location.search;
  final query = Uri.tryParse(
    rawSearch.isNotEmpty ? rawSearch : '?',
  )?.queryParameters;
  final token = (query?['token'] ?? '').trim();
  final repo = (query?['repo'] ?? '').trim();
  final prNumber = (query?['pr'] ?? '').trim();

  if (token.isEmpty) {
    _showError('GitHub token is required. Add ?token=ghp_... to the URL.');
    return;
  }

  final effectiveRepo = repo.isNotEmpty ? repo : _defaultRepo;
  final client = GithubHttpClient(token: token);

  if (prNumber.isNotEmpty) {
    final number = int.tryParse(prNumber);
    if (number == null || number < 1) {
      _showError('Invalid PR number: "$prNumber". Must be a positive integer.');
      return;
    }
    await runWidgetAppInBrowser(
      WidgetApp(
        GithubPullRequestView(
          client: client,
          target: GithubPullRequestTarget(
            repository: effectiveRepo,
            number: number,
          ),
        ),
      ),
    );
  } else {
    await runWidgetAppInBrowser(
      WidgetApp(
        GithubCliDashboard(
          client: client,
          repository: effectiveRepo,
          limit: 20,
        ),
      ),
    );
  }
}

void _showError(String message) {
  final canvas = web.document.createElement('div') as web.HTMLDivElement;
  canvas.style.color = 'red';
  canvas.style.fontFamily = 'monospace';
  canvas.style.padding = '20px';
  canvas.textContent = message;
  web.document.body!.appendChild(canvas);
}
