import '../client/json.dart';

final class GithubWorkflowRunItem {
  const GithubWorkflowRunItem({
    required this.databaseId,
    required this.number,
    required this.attempt,
    required this.workflowName,
    required this.displayTitle,
    required this.status,
    required this.conclusion,
    required this.event,
    required this.headBranch,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
  });

  final int databaseId;
  final int number;
  final int attempt;
  final String workflowName;
  final String displayTitle;
  final String status;
  final String conclusion;
  final String event;
  final String headBranch;
  final String url;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get statusLabel {
    if (conclusion.isNotEmpty) return conclusion.toLowerCase();
    if (status.isNotEmpty) return status.toLowerCase();
    return 'unknown';
  }

  bool get hasFailures {
    final value = conclusion.toLowerCase();
    return value == 'failure' ||
        value == 'cancelled' ||
        value == 'timed_out' ||
        value == 'action_required';
  }

  static GithubWorkflowRunItem fromJson(Map<String, Object?> json) {
    return GithubWorkflowRunItem(
      databaseId: ghInt(json['databaseId'] ?? json['id']),
      number: ghInt(json['number'] ?? json['run_number']),
      attempt: ghInt(json['attempt'] ?? json['run_attempt']),
      workflowName: ghString(
        json['workflowName'] ?? json['name'],
        fallback: 'workflow',
      ),
      displayTitle: ghString(
        json['displayTitle'] ?? json['display_title'],
        fallback: 'workflow run',
      ),
      status: ghString(json['status']),
      conclusion: ghString(json['conclusion']),
      event: ghString(json['event'], fallback: 'event'),
      headBranch: ghString(
        json['headBranch'] ?? json['head_branch'],
        fallback: 'branch',
      ),
      url: ghString(json['url'] ?? json['html_url']),
      createdAt: ghDate(json['createdAt'] ?? json['created_at']),
      updatedAt: ghDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}
