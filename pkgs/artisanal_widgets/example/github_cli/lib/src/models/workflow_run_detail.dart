import '../client/json.dart';
import 'workflow_run.dart';

final class GithubWorkflowRunDetail {
  const GithubWorkflowRunDetail({
    required this.run,
    required this.jobs,
    required this.headSha,
    required this.startedAt,
  });

  final GithubWorkflowRunItem run;
  final List<GithubWorkflowJobItem> jobs;
  final String headSha;
  final DateTime? startedAt;

  int get failedJobCount {
    return jobs
        .where((job) => job.conclusion.toLowerCase() == 'failure')
        .length;
  }

  int get successfulJobCount {
    return jobs
        .where((job) => job.conclusion.toLowerCase() == 'success')
        .length;
  }

  static GithubWorkflowRunDetail fromJson(Map<String, Object?> json) {
    return GithubWorkflowRunDetail(
      run: GithubWorkflowRunItem.fromJson(json),
      jobs: ghList(json['jobs'])
          .map((item) => GithubWorkflowJobItem.fromJson(ghMap(item)))
          .toList(growable: false),
      headSha: ghString(json['headSha']),
      startedAt: ghDate(json['startedAt']),
    );
  }
}

final class GithubWorkflowJobItem {
  const GithubWorkflowJobItem({
    required this.name,
    required this.status,
    required this.conclusion,
    required this.startedAt,
    required this.completedAt,
    required this.steps,
  });

  final String name;
  final String status;
  final String conclusion;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<GithubWorkflowStepItem> steps;

  String get statusLabel {
    if (conclusion.isNotEmpty) return conclusion.toLowerCase();
    if (status.isNotEmpty) return status.toLowerCase();
    return 'unknown';
  }

  bool get hasFailures => conclusion.toLowerCase() == 'failure';

  static GithubWorkflowJobItem fromJson(Map<String, Object?> json) {
    return GithubWorkflowJobItem(
      name: ghString(json['name'], fallback: 'job'),
      status: ghString(json['status']),
      conclusion: ghString(json['conclusion']),
      startedAt: ghDate(json['startedAt']),
      completedAt: ghDate(json['completedAt']),
      steps: ghList(json['steps'])
          .map((item) => GithubWorkflowStepItem.fromJson(ghMap(item)))
          .toList(growable: false),
    );
  }
}

final class GithubWorkflowStepItem {
  const GithubWorkflowStepItem({
    required this.number,
    required this.name,
    required this.status,
    required this.conclusion,
  });

  final int number;
  final String name;
  final String status;
  final String conclusion;

  String get statusLabel {
    if (conclusion.isNotEmpty) return conclusion.toLowerCase();
    if (status.isNotEmpty) return status.toLowerCase();
    return 'unknown';
  }

  bool get hasFailures => conclusion.toLowerCase() == 'failure';

  static GithubWorkflowStepItem fromJson(Map<String, Object?> json) {
    return GithubWorkflowStepItem(
      number: ghInt(json['number']),
      name: ghString(json['name'], fallback: 'step'),
      status: ghString(json['status']),
      conclusion: ghString(json['conclusion']),
    );
  }
}
