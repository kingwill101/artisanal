import 'package:artisanal/tui.dart' as tui;

import '../client/client.dart';
import '../models/action_prompt.dart';
import '../models/dashboard_data.dart';
import '../models/display_item.dart';
import '../models/item_kind.dart';
import '../state/notifiers.dart';
import '../utils/repository_input.dart';
import 'messages.dart';

final class GithubDashboardActionCoordinator {
  GithubDashboardActionCoordinator({
    required this.client,
    required this.data,
    required this.queue,
    required this.detail,
    required this.loadDashboard,
  });

  final GithubDashboardClient Function() client;
  final GithubDataNotifier data;
  final GithubQueueNotifier queue;
  final GithubDetailNotifier detail;
  final tui.Cmd Function({bool clearDashboard}) loadDashboard;

  bool handlesMessage(tui.Msg msg) {
    return msg is GithubActionCompletedMsg || msg is GithubActionFailedMsg;
  }

  tui.Cmd? handleMessage(tui.Msg msg) {
    if (msg is GithubActionCompletedMsg) {
      detail.applyActionCompleted(msg.message);
      return null;
    }
    if (msg is GithubActionFailedMsg) {
      detail.applyActionError(msg.message);
      return null;
    }
    return null;
  }

  tui.Cmd openActionPrompt(GithubActionPromptKind kind) {
    final item = queue.selectedItem;
    if (item == null || !item.supportsIssueActions) return tui.Cmd.none();
    detail.openActionPrompt(kind, item);
    return tui.Cmd.none();
  }

  tui.Cmd openDiffCommentPrompt(GithubDiffCommentTarget? target) {
    final item = detail.diffItem ?? queue.selectedItem;
    if (item == null ||
        item.target != GithubDisplayTarget.pullRequest ||
        target == null) {
      detail.applyNotice('No commentable diff line selected.');
      return tui.Cmd.none();
    }
    detail.openActionPrompt(
      GithubActionPromptKind.addReviewComment,
      item,
      diffTarget: target,
    );
    return tui.Cmd.none();
  }

  tui.Cmd openRepositoryPrompt() {
    detail.openRepositoryPrompt();
    return tui.Cmd.none();
  }

  tui.Cmd openRepositoryList() {
    if ((data.dashboard?.repositories ?? const []).isEmpty) {
      detail.applyNotice('No repositories loaded for this target.');
      return tui.Cmd.none();
    }
    detail.openRepositoryList();
    return tui.Cmd.none();
  }

  tui.Cmd closeRepositoryList() {
    detail.closeRepositoryList();
    return tui.Cmd.none();
  }

  tui.Cmd closeActionPrompt() {
    detail.closeActionPrompt();
    return tui.Cmd.none();
  }

  tui.Cmd closeRepositoryPrompt() {
    detail.closeRepositoryPrompt();
    return tui.Cmd.none();
  }

  tui.Cmd submitRepository(String input) {
    final target = parseGithubDashboardTarget(input);
    if (input.trim().isNotEmpty && target == null) {
      detail.applyRepositoryPromptError(
        'Use @me, owner/org, owner/repo, or a github.com URL.',
      );
      return tui.Cmd.none();
    }
    data.setTarget(repository: target?.repository, owner: target?.owner);
    detail.closeRepositoryPrompt();
    queue.resetSelection();
    return loadDashboard(clearDashboard: true);
  }

  tui.Cmd toggleSelectedPullRequestDraft() {
    final item = queue.selectedItem;
    final repository = data.repositoryFor(item);
    if (item == null ||
        repository == null ||
        item.target != GithubDisplayTarget.pullRequest) {
      return tui.Cmd.none();
    }
    final isDraft = item.kind == 'draft';
    return tui.Cmd(() async {
      try {
        await client().togglePullRequestDraft(
          repository: repository,
          number: item.number,
          isDraft: isDraft,
        );
        return GithubActionCompletedMsg(
          isDraft
              ? 'Pull request marked ready.'
              : 'Pull request converted to draft.',
        );
      } catch (error) {
        return GithubActionFailedMsg(error.toString());
      }
    });
  }

  tui.Cmd submitMergeAction(GithubPullRequestMergeAction action) {
    final item = detail.mergeInfoItem;
    final repository = data.repositoryFor(item);
    if (item == null ||
        repository == null ||
        item.target != GithubDisplayTarget.pullRequest) {
      return tui.Cmd.none();
    }
    detail.startAction();
    return tui.Cmd(() async {
      try {
        await client().mergePullRequest(
          repository: repository,
          number: item.number,
          action: action,
        );
        return GithubActionCompletedMsg('${action.pastTense}.');
      } catch (error) {
        return GithubActionFailedMsg(error.toString());
      }
    });
  }

  tui.Cmd toggleRepositoryLabel(GithubRepositoryLabel label) {
    final item = detail.repositoryLabelsItem;
    final repository = data.repositoryFor(item);
    final kind = _kindFor(item);
    if (item == null || repository == null || kind == null) {
      return tui.Cmd.none();
    }
    final active = item.labels
        .map((name) => name.toLowerCase())
        .contains(label.name.toLowerCase());
    detail.startAction();
    return tui.Cmd(() async {
      try {
        if (active) {
          await client().removeLabels(
            repository: repository,
            kind: kind,
            number: item.number,
            labels: [label.name],
          );
          return GithubActionCompletedMsg('Label removed: ${label.name}.');
        }
        await client().addLabels(
          repository: repository,
          kind: kind,
          number: item.number,
          labels: [label.name],
        );
        return GithubActionCompletedMsg('Label added: ${label.name}.');
      } catch (error) {
        return GithubActionFailedMsg(error.toString());
      }
    });
  }

  tui.Cmd submitActionPrompt(String value) {
    final prompt = detail.actionPrompt;
    final repository = data.repositoryFor(prompt?.item);
    if (prompt == null || repository == null) {
      return tui.Cmd.none();
    }
    final kind = _kindFor(prompt.item);

    final comment = value.trim();
    final labels = value
        .split(',')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    if (prompt.kind == GithubActionPromptKind.addComment && comment.isEmpty) {
      detail.applyActionError('Comment body is required.');
      return tui.Cmd.none();
    }
    if (prompt.kind == GithubActionPromptKind.addReviewComment &&
        comment.isEmpty) {
      detail.applyActionError('Comment body is required.');
      return tui.Cmd.none();
    }
    if (prompt.kind == GithubActionPromptKind.addReviewComment &&
        prompt.diffTarget == null) {
      detail.applyActionError('No diff line selected.');
      return tui.Cmd.none();
    }
    if (prompt.kind != GithubActionPromptKind.addReviewComment &&
        kind == null) {
      return tui.Cmd.none();
    }
    if (prompt.kind == GithubActionPromptKind.addLabels && labels.isEmpty) {
      detail.applyActionError('Enter at least one label.');
      return tui.Cmd.none();
    }
    if (prompt.kind == GithubActionPromptKind.removeLabels && labels.isEmpty) {
      detail.applyActionError('Enter at least one label.');
      return tui.Cmd.none();
    }
    final mergeAction = GithubPullRequestMergeAction.parse(value);
    if (prompt.kind == GithubActionPromptKind.mergePullRequest &&
        mergeAction == null) {
      detail.applyActionError('Unknown merge action.');
      return tui.Cmd.none();
    }
    if (prompt.kind == GithubActionPromptKind.closePullRequest &&
        value.trim().toLowerCase() != 'close') {
      detail.applyActionError('Type close to confirm.');
      return tui.Cmd.none();
    }

    detail.startAction();
    return tui.Cmd(() async {
      try {
        switch (prompt.kind) {
          case GithubActionPromptKind.addComment:
            await client().addComment(
              repository: repository,
              kind: kind!,
              number: prompt.item.number,
              body: comment,
            );
            return const GithubActionCompletedMsg('Comment added.');
          case GithubActionPromptKind.addReviewComment:
            final target = prompt.diffTarget!;
            final commitId = await _headCommitForPrompt(prompt, repository);
            await client().addPullRequestReviewComment(
              repository: repository,
              number: prompt.item.number,
              commitId: commitId,
              path: target.path,
              line: target.line,
              side: target.side,
              body: comment,
              startLine: target.startLine,
              startSide: target.startSide,
            );
            return GithubActionCompletedMsg(
              'Review comment added at ${target.label}.',
            );
          case GithubActionPromptKind.addLabels:
            await client().addLabels(
              repository: repository,
              kind: kind!,
              number: prompt.item.number,
              labels: labels,
            );
            return GithubActionCompletedMsg(
              'Labels added: ${labels.join(', ')}',
            );
          case GithubActionPromptKind.removeLabels:
            await client().removeLabels(
              repository: repository,
              kind: kind!,
              number: prompt.item.number,
              labels: labels,
            );
            return GithubActionCompletedMsg(
              'Labels removed: ${labels.join(', ')}',
            );
          case GithubActionPromptKind.mergePullRequest:
            await client().mergePullRequest(
              repository: repository,
              number: prompt.item.number,
              action: mergeAction!,
            );
            return GithubActionCompletedMsg('${mergeAction.pastTense}.');
          case GithubActionPromptKind.closePullRequest:
            await client().closePullRequest(
              repository: repository,
              number: prompt.item.number,
            );
            return const GithubActionCompletedMsg('Pull request closed.');
        }
      } catch (error) {
        return GithubActionFailedMsg(error.toString());
      }
    });
  }

  Future<String> _headCommitForPrompt(
    GithubActionPrompt prompt,
    String repository,
  ) async {
    if (prompt.item.headRefOid.trim().isNotEmpty) {
      return prompt.item.headRefOid;
    }
    final pullRequest = await client().loadPullRequest(
      repository: repository,
      number: prompt.item.number,
    );
    return pullRequest.headRefOid;
  }

  GithubItemKind? _kindFor(GithubDisplayItem? item) {
    if (item == null) return null;
    return switch (item.target) {
      GithubDisplayTarget.issue => GithubItemKind.issue,
      GithubDisplayTarget.pullRequest => GithubItemKind.pullRequest,
      GithubDisplayTarget.workflowRun => null,
    };
  }
}
