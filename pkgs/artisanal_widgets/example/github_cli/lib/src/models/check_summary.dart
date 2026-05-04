import '../client/json.dart';

final class GithubCheckItem {
  const GithubCheckItem({
    required this.name,
    required this.status,
    required this.conclusion,
  });

  final String name;
  final String status;
  final String conclusion;

  bool get completed => status == 'completed';

  bool get passing =>
      completed &&
      (conclusion == 'success' ||
          conclusion == 'neutral' ||
          conclusion == 'skipped');

  bool get failing =>
      completed &&
      (conclusion == 'failure' ||
          conclusion == 'cancelled' ||
          conclusion == 'timed_out');

  bool get pending => !completed;

  String get icon {
    if (passing) return '✓';
    if (failing) return '✗';
    if (status == 'in_progress') return '●';
    if (status == 'queued') return '○';
    return '·';
  }

  static GithubCheckItem fromJson(Object? value) {
    final map = ghMap(value);
    final type = ghString(map['__typename']);
    final state = ghString(map['state']).toUpperCase();
    final rawStatus = ghString(map['status']).toUpperCase();
    final rawConclusion = ghString(map['conclusion']).toUpperCase();
    final isStatusContext =
        type == 'StatusContext' ||
        map['context'] != null ||
        map['state'] != null && map['status'] == null;
    final name = ghString(
      isStatusContext ? map['context'] : map['name'],
      fallback: 'check',
    );

    if (isStatusContext) {
      return GithubCheckItem(
        name: name,
        status: state == 'PENDING' ? 'in_progress' : 'completed',
        conclusion: _normalizeStatusContextConclusion(state),
      );
    }

    return GithubCheckItem(
      name: name,
      status: _normalizeCheckStatus(rawStatus),
      conclusion: _normalizeCheckConclusion(rawConclusion),
    );
  }
}

final class GithubCheckSummary {
  const GithubCheckSummary({
    required this.total,
    required this.passed,
    required this.failed,
    required this.pending,
    this.items = const <GithubCheckItem>[],
  });

  static const empty = GithubCheckSummary(
    total: 0,
    passed: 0,
    failed: 0,
    pending: 0,
  );

  final int total;
  final int passed;
  final int failed;
  final int pending;
  final List<GithubCheckItem> items;

  bool get hasFailures => failed > 0;

  String get countLabel {
    if (total == 0) return 'none';
    if (pending > 0) return '${total - pending}/$total';
    return '$passed/$total';
  }

  String get label => 'checks $countLabel';

  List<GithubCheckItem> get uniqueItems {
    final seen = <String, GithubCheckItem>{};
    for (final check in items) {
      final existing = seen[check.name];
      if (existing == null || check.completed && !existing.completed) {
        seen[check.name] = check;
      }
    }
    return seen.values.toList(growable: false);
  }

  static GithubCheckSummary fromJson(Object? value) {
    final contexts = ghList(ghMap(value)['contexts']);
    final rawItems = contexts.isNotEmpty ? contexts : ghList(value);
    final items = rawItems
        .map(GithubCheckItem.fromJson)
        .toList(growable: false);
    var passed = 0;
    var failed = 0;
    var pending = 0;
    for (final item in items) {
      if (item.passing) {
        passed++;
      } else if (item.failing) {
        failed++;
      } else {
        pending++;
      }
    }
    return GithubCheckSummary(
      total: items.length,
      passed: passed,
      failed: failed,
      pending: pending,
      items: items,
    );
  }
}

String _normalizeCheckStatus(String raw) {
  return switch (raw) {
    'COMPLETED' => 'completed',
    'IN_PROGRESS' => 'in_progress',
    'QUEUED' => 'queued',
    _ => 'pending',
  };
}

String _normalizeCheckConclusion(String raw) {
  return switch (raw) {
    'SUCCESS' => 'success',
    'FAILURE' || 'ERROR' => 'failure',
    'NEUTRAL' => 'neutral',
    'SKIPPED' => 'skipped',
    'CANCELLED' => 'cancelled',
    'TIMED_OUT' => 'timed_out',
    _ => '',
  };
}

String _normalizeStatusContextConclusion(String raw) {
  return switch (raw) {
    'SUCCESS' => 'success',
    'FAILURE' || 'ERROR' => 'failure',
    _ => '',
  };
}
