import 'package:artisanal/style.dart'
    show Color, Colors, HorizontalAlign, Style, VerticalAlign;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../app/compile_time_flags.dart';
import '../../models/dashboard_data.dart';
import '../../models/display_item.dart';
import 'panels.dart';
import '../label_style.dart';
import '../../utils/time.dart';
import '../markdown/body.dart';
import '../../utils/text_format.dart';

w.Widget githubDetailPane({
  required w.Theme theme,
  required GithubDashboardData dashboard,
  required GithubDisplayItem? selectedItem,
  required bool navigating,
  required w.ScrollController controller,
  required GithubDisplayItem? commentsItem,
  required List<GithubCommentItem> comments,
  required bool commentsLoading,
  required String? commentsError,
  required GithubDisplayItem? commitsItem,
  required List<GithubPullRequestCommit> commits,
  required bool commitsLoading,
  required String? commitsError,
  required GithubDisplayItem? reviewCommentsItem,
  required List<GithubPullRequestReviewComment> reviewComments,
  required bool reviewCommentsLoading,
  required String? reviewCommentsError,
  required GithubDisplayItem? diffItem,
  required String diff,
  required List<GithubPullRequestDiffFile> diffFiles,
  required int diffFileIndex,
  required bool diffLoading,
  required String? diffError,
  required w.DiffViewMode diffViewMode,
  w.GitDiffController? diffController,
  List<w.DiffCommentLineHighlight> diffCommentHighlights =
      const <w.DiffCommentLineHighlight>[],
  tui.Cmd? Function(w.DiffCommentAnchor anchor)? onDiffCommentAnchorSelected,
  tui.Cmd? Function(int index)? onDiffFileSelected,
  required GithubDisplayItem? mergeInfoItem,
  required GithubPullRequestMergeInfo? mergeInfo,
  required bool mergeInfoLoading,
  required String? mergeInfoError,
  required GithubDisplayItem? repositoryLabelsItem,
  required List<GithubRepositoryLabel> repositoryLabels,
  required bool repositoryLabelsLoading,
  required String? repositoryLabelsError,
  required GithubDisplayItem? runDetailItem,
  required GithubWorkflowRunDetail? runDetail,
  required bool runDetailLoading,
  required String? runDetailError,
  required tui.Cmd? Function(int index) onTabChanged,
  required int height,
  required int width,
}) {
  if (selectedItem == null) {
    return _repositorySummary(theme, dashboard);
  }
  final showingComments = _sameItem(selectedItem, commentsItem);
  final showingCommits = _sameItem(selectedItem, commitsItem);
  final showingReviewComments = _sameItem(selectedItem, reviewCommentsItem);
  final showingDiff = _sameItem(selectedItem, diffItem);
  final showingMergeInfo = _sameItem(selectedItem, mergeInfoItem);
  final showingRepositoryLabels = _sameItem(selectedItem, repositoryLabelsItem);
  final showingRun = _sameItem(selectedItem, runDetailItem);
  final detailBodyHeight = (height - 4).clamp(4, height).toInt();
  return w.Column(
    crossAxisAlignment: w.CrossAxisAlignment.stretch,
    children: [
      _detailHeader(theme, selectedItem),
      _detailTabs(
        theme: theme,
        item: selectedItem,
        showingComments: showingComments,
        showingCommits: showingCommits,
        showingReviewComments: showingReviewComments,
        showingDiff: showingDiff,
        showingRun: showingRun,
        onChanged: onTabChanged,
      ),
      w.Divider(
        width: 80,
        style: theme.bodySmall.copy()..foreground(theme.border),
      ),
      if (showingDiff)
        _inlineDiff(
          theme: theme,
          item: selectedItem,
          diff: diff,
          diffFiles: diffFiles,
          diffFileIndex: diffFileIndex,
          loading: diffLoading,
          error: diffError,
          viewMode: diffViewMode,
          diffController: diffController,
          diffCommentHighlights: diffCommentHighlights,
          onDiffCommentAnchorSelected: onDiffCommentAnchorSelected,
          onDiffFileSelected: onDiffFileSelected,
          controller: controller,
          height: detailBodyHeight,
          width: width,
        )
      else if (showingMergeInfo)
        _inlineMergeInfo(
          theme: theme,
          item: selectedItem,
          info: mergeInfo,
          loading: mergeInfoLoading,
          error: mergeInfoError,
          controller: controller,
        )
      else if (showingRepositoryLabels)
        _inlineRepositoryLabels(
          theme: theme,
          labels: repositoryLabels,
          loading: repositoryLabelsLoading,
          error: repositoryLabelsError,
          controller: controller,
        )
      else if (showingRun)
        _inlineRunDetail(
          theme: theme,
          item: selectedItem,
          detail: runDetail,
          loading: runDetailLoading,
          error: runDetailError,
          controller: controller,
        )
      else if (showingCommits)
        _inlineCommits(
          theme: theme,
          item: selectedItem,
          commits: commits,
          loading: commitsLoading,
          error: commitsError,
          controller: controller,
        )
      else if (showingReviewComments)
        _inlineReviewComments(
          theme: theme,
          item: selectedItem,
          comments: reviewComments,
          loading: reviewCommentsLoading,
          error: reviewCommentsError,
          controller: controller,
        )
      else if (navigating)
        // While the user scrolls rapidly, skip the expensive markdown /
        // avatar-image render and show a cheap spinner placeholder instead.
        // The debounce timer in _GithubCliDashboardState will clear the flag
        // once the user pauses, triggering a full render of the real content.
        w.Expanded(child: githubNavigatingPanel(theme))
      else
        _inlineBody(
          theme,
          selectedItem,
          controller,
          showingComments: showingComments,
          comments: comments,
          commentsLoading: commentsLoading,
          commentsError: commentsError,
        ),
    ],
  );
}

w.Widget _detailTabs({
  required w.Theme theme,
  required GithubDisplayItem item,
  required bool showingComments,
  required bool showingCommits,
  required bool showingReviewComments,
  required bool showingDiff,
  required bool showingRun,
  required tui.Cmd? Function(int index) onChanged,
}) {
  final tabs = <w.TabItem>[
    if (item.supportsIssueActions)
      w.TabItem('Conversation ${item.commentCount}'),
    if (item.target == GithubDisplayTarget.pullRequest)
      w.TabItem('Commits${_commitCountLabel(item)}'),
    if (item.target == GithubDisplayTarget.pullRequest)
      const w.TabItem('Reviews'),
    if (item.target == GithubDisplayTarget.pullRequest)
      w.TabItem('Files changed${_fileCountLabel(item)}'),
    if (item.target == GithubDisplayTarget.workflowRun)
      const w.TabItem('Run info'),
  ];
  if (tabs.isEmpty) return w.Text('', style: theme.bodySmall);

  final index = switch (item.target) {
    GithubDisplayTarget.pullRequest when showingCommits => 1,
    GithubDisplayTarget.pullRequest when showingReviewComments => 2,
    GithubDisplayTarget.pullRequest when showingDiff => 3,
    GithubDisplayTarget.workflowRun => 0,
    _ => 0,
  };

  return w.Row(
    gap: 1,
    children: [
      w.Tabs(tabs: tabs, index: index, onChanged: onChanged),
      if (showingComments)
        w.Text(
          'loaded',
          style: theme.bodySmall.copy()..foreground(theme.muted),
        ),
    ],
  );
}

w.Widget _inlineBody(
  w.Theme theme,
  GithubDisplayItem item,
  w.ScrollController controller, {
  bool showingComments = false,
  List<GithubCommentItem> comments = const [],
  bool commentsLoading = false,
  String? commentsError,
}) {
  final hint = theme.bodySmall.copy()..foreground(theme.muted);
  return w.Expanded(
    child: w.ScrollArea(
      controller: controller,
      showScrollbar: true,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        gap: 1,
        children: [
          if (item.target == GithubDisplayTarget.pullRequest &&
              item.checks.uniqueItems.isNotEmpty)
            _checksSection(theme, item.checks),
          _timelineCard(
            theme: theme,
            author: item.author,
            avatarUrl: item.authorAvatarUrl,
            metadata:
                '${item.author} / updated ${relativeGithubTime(item.updatedAt)}',
            fallbackMarkdown: '_No description provided._',
            rawText: item.body,
          ),
          if (showingComments) ...[
            w.Divider(
              width: 80,
              style: theme.bodySmall.copy()..foreground(theme.border),
            ),
            w.Text(
              'All comments ${item.kind.toUpperCase()} #${item.number}',
              style: theme.titleMedium,
            ),
            if (commentsError != null)
              w.Text(
                commentsError,
                style: theme.bodyMedium.copy()..foreground(theme.error),
              ),
            if (commentsLoading && comments.isEmpty)
              w.Text('Loading comments from gh...', style: hint),
            if (!commentsLoading && comments.isEmpty && commentsError == null)
              w.Text('No comments returned by gh.', style: hint),
            for (final comment in comments)
              _commentCard(theme, comment),
          ],
        ],
      ),
    ),
  );
}

w.Widget _checksSection(w.Theme theme, GithubCheckSummary checks) {
  final unique = checks.uniqueItems;
  final left = unique.take((unique.length / 2).ceil()).toList(growable: false);
  final right = unique.skip(left.length).toList(growable: false);
  final rows = left.length > right.length ? left.length : right.length;

  return w.Frame(
    background: theme.surface,
    padding: const w.EdgeInsets.symmetric(horizontal: 1, vertical: 1),
    child: w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Row(
          children: [
            w.Text('Checks', style: theme.titleMedium),
            w.Spacer(size: 1),
            w.Text(
              checks.countLabel,
              style: theme.bodySmall.copy()..foreground(theme.muted),
            ),
          ],
        ),
        for (var index = 0; index < rows; index++)
          w.Row(
            children: [
              if (index < left.length)
                _checkItem(theme, left[index], maxWidth: 30),
              if (index < left.length && index < right.length) w.Spacer(),
              if (index < right.length)
                _checkItem(theme, right[index], maxWidth: 34),
            ],
          ),
      ],
    ),
  );
}

w.Widget _checkItem(
  w.Theme theme,
  GithubCheckItem check, {
  required int maxWidth,
}) {
  final color = check.failing
      ? Colors.red
      : check.passing
      ? Colors.green
      : check.status == 'in_progress'
      ? Colors.warning
      : theme.muted;
  return w.Row(
    children: [
      w.Text(check.icon, style: theme.bodyMedium.copy()..foreground(color)),
      w.Spacer(size: 1),
      w.Text(
        check.name,
        style: theme.bodyMedium,
        overflow: w.TextOverflow.ellipsis,
        maxWidth: maxWidth,
      ),
    ],
  );
}

w.Widget _inlineReviewComments({
  required w.Theme theme,
  required GithubDisplayItem item,
  required List<GithubPullRequestReviewComment> comments,
  required bool loading,
  required String? error,
  required w.ScrollController controller,
}) {
  return w.Expanded(
    child: w.Scrollbar(
      controller: controller,
      child: _reviewCommentList(
        theme: theme,
        item: item,
        comments: comments,
        loading: loading,
        error: error,
        controller: controller,
      ),
    ),
  );
}

w.Widget _inlineCommits({
  required w.Theme theme,
  required GithubDisplayItem item,
  required List<GithubPullRequestCommit> commits,
  required bool loading,
  required String? error,
  required w.ScrollController controller,
}) {
  return w.Expanded(
    child: w.Scrollbar(
      controller: controller,
      child: _commitList(
        theme: theme,
        item: item,
        commits: commits,
        loading: loading,
        error: error,
        controller: controller,
      ),
    ),
  );
}

w.Widget _commitList({
  required w.Theme theme,
  required GithubDisplayItem item,
  required List<GithubPullRequestCommit> commits,
  required bool loading,
  required String? error,
  required w.ScrollController controller,
}) {
  final statusCount =
      (error == null ? 0 : 1) +
      (loading && commits.isEmpty ? 1 : 0) +
      (!loading && commits.isEmpty ? 1 : 0);
  final commitStart = 1 + statusCount;
  return w.VirtualListView.builder(
    controller: controller,
    itemExtent: 4,
    separator: '',
    itemCount: commitStart + commits.length,
    itemBuilder: (context, index) {
      var cursor = 0;
      if (index == cursor++) {
        return w.Text('Commits PR #${item.number}', style: theme.titleMedium);
      }
      if (error != null && index == cursor++) {
        return w.Text(
          error,
          style: theme.bodyMedium.copy()..foreground(theme.error),
        );
      }
      final hint = theme.bodySmall.copy()..foreground(theme.muted);
      if (loading && commits.isEmpty && index == cursor++) {
        return w.Text('Loading commits from gh api...', style: hint);
      }
      if (!loading && commits.isEmpty && index == cursor++) {
        return w.Text('No commits returned by gh.', style: hint);
      }
      return w.SizedBox(
        height: 4,
        child: _commitRow(theme, commits[index - cursor]),
      );
    },
  );
}

w.Widget _commitRow(w.Theme theme, GithubPullRequestCommit commit) {
  final hint = theme.bodySmall.copy()..foreground(theme.muted);
  final verifiedStyle = theme.bodySmall.copy()
    ..foreground(commit.verified ? Colors.green : Colors.warning);
  final author = commit.displayAuthor;
  return w.Frame(
    background: theme.surface,
    padding: const w.EdgeInsets.symmetric(horizontal: 1),
    child: w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Row(
          children: [
            w.Text(
              commit.messageHeadline,
              style: theme.bodyMedium,
              overflow: w.TextOverflow.ellipsis,
              maxWidth: 72,
            ),
            w.Spacer(),
            w.Text(
              commit.verified ? 'verified' : 'unverified',
              style: verifiedStyle,
            ),
            w.Spacer(size: 1),
            w.Text(commit.shortSha, style: hint),
          ],
        ),
        w.Text(
          '$author committed ${relativeGithubTime(commit.committedAt)}',
          style: hint,
          overflow: w.TextOverflow.ellipsis,
          maxWidth: 96,
        ),
      ],
    ),
  );
}

w.Widget _reviewCommentList({
  required w.Theme theme,
  required GithubDisplayItem item,
  required List<GithubPullRequestReviewComment> comments,
  required bool loading,
  required String? error,
  required w.ScrollController controller,
}) {
  final statusCount =
      (error == null ? 0 : 1) +
      (loading && comments.isEmpty ? 1 : 0) +
      (!loading && comments.isEmpty ? 1 : 0);
  final commentStart = 1 + statusCount;
  return w.VirtualListView.builder(
    controller: controller,
    variableHeight: true,
    estimatedItemExtent: 7,
    separator: '\n',
    itemCount: commentStart + comments.length,
    itemBuilder: (context, index) {
      var cursor = 0;
      if (index == cursor++) {
        return w.Text(
          'Review comments PR #${item.number}',
          style: theme.titleMedium,
        );
      }
      if (error != null && index == cursor++) {
        return w.Text(
          error,
          style: theme.bodyMedium.copy()..foreground(theme.error),
        );
      }
      final hint = theme.bodySmall.copy()..foreground(theme.muted);
      if (loading && comments.isEmpty && index == cursor++) {
        return w.Text('Loading review comments from gh api...', style: hint);
      }
      if (!loading && comments.isEmpty && index == cursor++) {
        return w.Text('No file review comments returned by gh.', style: hint);
      }
      final comment = comments[index - cursor];
      return _timelineCard(
        theme: theme,
        author: comment.author,
        avatarUrl: comment.avatarUrl,
        metadata:
            '${comment.path}:${comment.line} ${comment.side} / ${comment.author} / ${relativeGithubTime(comment.createdAt)}',
        fallbackMarkdown: '_Empty comment._',
        rawText: comment.body,
      );
    },
  );
}

w.Widget _inlineMergeInfo({
  required w.Theme theme,
  required GithubDisplayItem item,
  required GithubPullRequestMergeInfo? info,
  required bool loading,
  required String? error,
  required w.ScrollController controller,
}) {
  final hint = theme.bodySmall.copy()..foreground(theme.muted);
  final ok = theme.bodyMedium.copy()..foreground(Colors.green);
  final warn = theme.bodyMedium.copy()..foreground(Colors.warning);
  return w.Expanded(
    child: w.ScrollArea(
      controller: controller,
      showScrollbar: true,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        gap: 1,
        children: [
          w.Text(
            'Merge readiness PR #${item.number}',
            style: theme.titleMedium,
          ),
          if (error != null)
            w.Text(
              error,
              style: theme.bodyMedium.copy()..foreground(theme.error),
            ),
          if (loading && info == null)
            w.Text('Loading merge info from gh...', style: hint),
          if (info != null) ...[
            _mergeReadinessText(
              theme: theme,
              info: info,
              ok: ok,
              warn: warn,
              hint: hint,
            ),
          ],
        ],
      ),
    ),
  );
}

w.Widget _mergeReadinessText({
  required w.Theme theme,
  required GithubPullRequestMergeInfo info,
  required Style ok,
  required Style warn,
  required Style hint,
}) {
  final methods = info.allowedMethods;
  final methodsLabel = methods.isEmpty ? 'none' : methods.join(', ');
  final methodPolicy = info.mergeMethodPolicyKnown
      ? ''
      : ' (repo policy not reported by gh)';
  return w.Column(
    crossAxisAlignment: w.CrossAxisAlignment.stretch,
    gap: 1,
    children: [
      w.Text(
        info.isCleanlyMergeable ? 'Ready to merge' : 'Needs attention',
        style: info.isCleanlyMergeable ? ok : warn,
      ),
      w.Text('state ${info.state.toLowerCase()}', style: theme.bodyMedium),
      w.Text(
        'mergeable ${info.mergeable.toLowerCase()}',
        style: theme.bodyMedium,
      ),
      w.Text(
        'review ${info.reviewDecision.toLowerCase()}',
        style: theme.bodyMedium,
      ),
      w.Text(info.checks.label, style: theme.bodyMedium),
      w.Text('methods $methodsLabel$methodPolicy', style: theme.bodyMedium),
      w.Text(
        'actions ${info.availableActions.map((action) => action.name).join(', ')}',
        style: hint,
        softWrap: true,
        maxWidth: 96,
      ),
      w.Text(
        'Use palette: Merge pull request, Toggle ready/draft, Close pull request.',
        style: hint,
        softWrap: true,
        maxWidth: 96,
      ),
    ],
  );
}

w.Widget _inlineRepositoryLabels({
  required w.Theme theme,
  required List<GithubRepositoryLabel> labels,
  required bool loading,
  required String? error,
  required w.ScrollController controller,
}) {
  final hint = theme.bodySmall.copy()..foreground(theme.muted);
  return w.Expanded(
    child: w.ScrollArea(
      controller: controller,
      showScrollbar: true,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        gap: 1,
        children: [
          w.Text('Repository labels', style: theme.titleMedium),
          if (error != null)
            w.Text(
              error,
              style: theme.bodyMedium.copy()..foreground(theme.error),
            ),
          if (loading && labels.isEmpty)
            w.Text('Loading labels from gh...', style: hint),
          if (!loading && labels.isEmpty)
            w.Text('No labels returned by gh.', style: hint),
          w.Wrap(
            spacing: 1,
            runSpacing: 1,
            children: [
              for (final label in labels)
                w.Badge(
                  label.name,
                  background: labelBackgroundColor(label),
                  foreground: labelForegroundColor(label),
                  paddingLeft: 1,
                  paddingRight: 1,
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

w.Widget _commentCard(w.Theme theme, GithubCommentItem comment) {
  return _timelineCard(
    theme: theme,
    author: comment.author,
    avatarUrl: comment.avatarUrl,
    metadata: '${comment.author} / ${relativeGithubTime(comment.createdAt)}',
    fallbackMarkdown: '_Empty comment._',
    rawText: comment.body,
  );
}

w.Widget _timelineCard({
  required w.Theme theme,
  required String author,
  required String avatarUrl,
  required String metadata,
  required String fallbackMarkdown,
  required String rawText,
  bool showImageGallery = githubCliNetworkImagesEnabled,
}) {
  final hint = theme.bodySmall.copy()..foreground(theme.muted);
  return w.Frame(
    background: theme.surface,
    padding: const w.EdgeInsets.symmetric(horizontal: 1, vertical: 1),
    child: w.Row(
      gap: 1,
      crossAxisAlignment: w.CrossAxisAlignment.start,
      children: [
        _avatarImage(theme, author: author, avatarUrl: avatarUrl),
        w.Expanded(
          child: w.Column(
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Text(
                metadata,
                style: hint,
                overflow: w.TextOverflow.ellipsis,
                maxWidth: 100,
              ),
              GithubMarkdownBody(
                data: rawText,
                fallbackMarkdown: fallbackMarkdown,
                maxWidth: 82,
                textStyle: theme.bodyMedium,
              ),
              if (showImageGallery) ..._imageGallery(theme, rawText),
            ],
          ),
        ),
      ],
    ),
  );
}

// Keep timeline rows text-first by default. The profile harness showed avatar
// decoding/rendering competing with issue-list scrolling for little value.
bool get _showTimelineAvatarImages => githubCliNetworkImagesEnabled;

const _attachmentPreviewMaxBytes = 16 * 1024 * 1024;
const _attachmentPreviewAllowedContentTypes = <String>{
  'image/png',
  'image/jpeg',
  'image/webp',
  'image/gif',
};

w.Widget _avatarImage(
  w.Theme theme, {
  required String author,
  required String avatarUrl,
}) {
  final fallback = _avatarFallback(theme, author);
  if (!_showTimelineAvatarImages || avatarUrl.isEmpty) return fallback;
  return w.Container(
    width: 8,
    height: 4,
    child: w.Image(
      image: w.NetworkImage(_githubAvatarThumbnailUrl(avatarUrl)),
      width: 8,
      height: 4,
      fit: w.BoxFit.cover,
      renderMode: w.ImageRenderMode.auto,
      placeholder: fallback,
      errorWidget: fallback,
    ),
  );
}

String _githubAvatarThumbnailUrl(String avatarUrl) {
  final uri = Uri.tryParse(avatarUrl);
  if (uri == null || uri.host != 'avatars.githubusercontent.com') {
    return avatarUrl;
  }
  if (uri.queryParameters.containsKey('s')) return avatarUrl;
  return uri
      .replace(queryParameters: {...uri.queryParameters, 's': '64'})
      .toString();
}

w.Widget _avatarFallback(w.Theme theme, String author) {
  final initial = author.isEmpty ? '?' : author.substring(0, 1).toUpperCase();
  return w.Container(
    width: 8,
    height: 4,
    background: theme.surfaceVariant ?? theme.surface,
    align: HorizontalAlign.center,
    verticalAlign: VerticalAlign.center,
    child: w.Text(
      initial,
      style: theme.titleMedium.copy()..foreground(theme.onSurface),
    ),
  );
}

List<w.Widget> _imageGallery(w.Theme theme, String rawText) {
  final images = githubImageReferences(rawText).take(3).toList(growable: false);
  if (images.isEmpty) return const <w.Widget>[];
  final hint = theme.bodySmall.copy()..foreground(theme.muted);
  return [
    for (final image in images)
      w.Frame(
        background: theme.background,
        padding: const w.EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        child: w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Text(
              image.alt.isEmpty ? image.url : image.alt,
              style: hint,
              overflow: w.TextOverflow.ellipsis,
              maxWidth: 90,
            ),
            w.Image(
              image: w.NetworkImage(
                image.url,
                maximumBytes: _attachmentPreviewMaxBytes,
                decodeFrame: 0,
                allowedContentTypes: _attachmentPreviewAllowedContentTypes,
              ),
              width: 48,
              height: 12,
              fit: w.BoxFit.contain,
              renderMode: w.ImageRenderMode.auto,
              placeholder: w.Text('Loading image...', style: hint),
              errorWidget: w.Text(
                'Preview skipped; open attachment.',
                style: hint,
              ),
            ),
          ],
        ),
      ),
  ];
}

w.Widget _inlineDiff({
  required w.Theme theme,
  required GithubDisplayItem item,
  required String diff,
  required List<GithubPullRequestDiffFile> diffFiles,
  required int diffFileIndex,
  required bool loading,
  required String? error,
  required w.DiffViewMode viewMode,
  w.GitDiffController? diffController,
  required List<w.DiffCommentLineHighlight> diffCommentHighlights,
  tui.Cmd? Function(w.DiffCommentAnchor anchor)? onDiffCommentAnchorSelected,
  tui.Cmd? Function(int index)? onDiffFileSelected,
  required w.ScrollController controller,
  required int height,
  required int width,
}) {
  final hint = theme.bodySmall.copy()..foreground(theme.muted);
  final targetWidth = width.clamp(40, 180).toInt();
  if (loading && diff.isEmpty) {
    return w.Expanded(
      child: w.Text('Loading PR files from GitHub...', style: hint),
    );
  }
  if (error != null) {
    return w.Expanded(
      child: w.Text(
        error,
        style: theme.bodyMedium.copy()..foreground(theme.error),
      ),
    );
  }
  if (diff.trim().isEmpty) {
    return w.Expanded(child: w.Text('No diff returned by gh.', style: hint));
  }
  final viewportHeight = (height - 2 - (loading ? 1 : 0))
      .clamp(4, height)
      .toInt();
  final selectedFile = diffFiles.isEmpty
      ? null
      : diffFiles[diffFileIndex.clamp(0, diffFiles.length - 1)];
  final rightWidth = diffFiles.isEmpty
      ? targetWidth
      : (targetWidth - _diffFileListWidth(targetWidth) - 2).clamp(40, 180);
  return w.Expanded(
    child: w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      gap: 1,
      children: [
        _diffHeader(
          theme: theme,
          item: item,
          files: diffFiles,
          selectedIndex: diffFileIndex,
          viewMode: viewMode,
        ),
        if (loading) w.Text('Loading more PR files...', style: hint),
        w.Expanded(
          child: diffFiles.isEmpty
              ? _selectedFileDiff(
                  diff: diff,
                  width: rightWidth,
                  height: viewportHeight,
                  viewMode: viewMode,
                  controller: diffController,
                  scrollController: controller,
                  diffCommentHighlights: diffCommentHighlights,
                  onDiffCommentAnchorSelected: onDiffCommentAnchorSelected,
                )
              : w.Row(
                  crossAxisAlignment: w.CrossAxisAlignment.stretch,
                  children: [
                    _diffFileSidebar(
                      theme: theme,
                      files: diffFiles,
                      selectedIndex: diffFileIndex,
                      width: _diffFileListWidth(targetWidth),
                      height: viewportHeight,
                      onSelected: onDiffFileSelected,
                    ),
                    w.VerticalDivider(
                      height: viewportHeight,
                      style: theme.bodySmall.copy()..foreground(theme.border),
                    ),
                    w.Expanded(
                      child: _selectedFileDiff(
                        diff: diff,
                        selectedFile: selectedFile,
                        width: rightWidth,
                        height: viewportHeight,
                        viewMode: viewMode,
                        controller: diffController,
                        scrollController: controller,
                        diffCommentHighlights: diffCommentHighlights,
                        onDiffCommentAnchorSelected:
                            onDiffCommentAnchorSelected,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    ),
  );
}

w.Widget _diffHeader({
  required w.Theme theme,
  required GithubDisplayItem item,
  required List<GithubPullRequestDiffFile> files,
  required int selectedIndex,
  required w.DiffViewMode viewMode,
}) {
  final hint = theme.bodySmall.copy()..foreground(theme.muted);
  final addStyle = theme.bodySmall.copy()
    ..foreground(Colors.green)
    ..bold();
  final deleteStyle = theme.bodySmall.copy()
    ..foreground(Colors.red)
    ..bold();
  final total = _changeTotals(item, files);
  final hasTotals = total.files > 0;
  final selected = files.isEmpty
      ? null
      : files[selectedIndex.clamp(0, files.length - 1)];
  return w.Row(
    children: [
      w.Text(
        'Files changed PR #${item.number}',
        style: theme.titleMedium,
        overflow: w.TextOverflow.ellipsis,
        maxWidth: 32,
      ),
      if (hasTotals) ...[
        w.Spacer(size: 2),
        w.Text('+${total.additions}', style: addStyle),
        w.Spacer(size: 1),
        w.Text('-${total.deletions}', style: deleteStyle),
        w.Spacer(size: 1),
        w.Text('${total.files} files', style: hint),
      ],
      if (selected != null) ...[
        w.Spacer(size: 2),
        w.Text('${selectedIndex + 1}/${files.length}', style: hint),
      ],
      w.Spacer(),
      w.Text(
        '${_diffViewModeLabel(viewMode)} · [/] files · s layout',
        style: hint,
      ),
    ],
  );
}

w.Widget _diffFileSidebar({
  required w.Theme theme,
  required List<GithubPullRequestDiffFile> files,
  required int selectedIndex,
  required int width,
  required int height,
  required tui.Cmd? Function(int index)? onSelected,
}) {
  return _DiffFileSidebar(
    appTheme: theme,
    files: files,
    selectedIndex: selectedIndex,
    width: width,
    height: height,
    onSelected: onSelected,
  );
}

final class _DiffFileSidebar extends w.StatefulWidget {
  _DiffFileSidebar({
    required this.appTheme,
    required this.files,
    required this.selectedIndex,
    required this.width,
    required this.height,
    required this.onSelected,
  });

  final w.Theme appTheme;
  final List<GithubPullRequestDiffFile> files;
  final int selectedIndex;
  final int width;
  final int height;
  final tui.Cmd? Function(int index)? onSelected;

  @override
  w.State<_DiffFileSidebar> createState() => _DiffFileSidebarState();
}

final class _DiffFileSidebarState extends w.State<_DiffFileSidebar> {
  static const _rowHeight = 2;
  static const _wheelRows = _rowHeight * 3;

  final _controller = w.WidgetScrollController();

  int get _listHeight => (widget.height - 3).clamp(1, widget.height).toInt();

  @override
  void initState() {
    super.initState();
    _syncSelectedIntoView();
  }

  @override
  tui.Cmd? didUpdateWidget(covariant _DiffFileSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.files.length != widget.files.length ||
        oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.height != widget.height) {
      _syncSelectedIntoView();
    }
    return null;
  }

  void _syncSelectedIntoView() {
    if (widget.files.isEmpty) return;
    final listHeight = _listHeight;
    _controller.updateMetrics(
      viewportExtent: listHeight,
      contentExtent: widget.files.length * _rowHeight,
    );
    final selected = widget.selectedIndex.clamp(0, widget.files.length - 1);
    final selectedTop = selected * _rowHeight;
    final selectedBottom = selectedTop + _rowHeight - 1;
    final viewportTop = _controller.offset;
    final viewportBottom = viewportTop + listHeight - 1;
    if (selectedTop < viewportTop) {
      _controller.jumpTo(selectedTop);
    } else if (selectedBottom > viewportBottom) {
      _controller.jumpTo(selectedBottom - listHeight + 1);
    }
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.SizedBox(
      width: widget.width,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Text('Files', style: widget.appTheme.titleSmall),
          w.Expanded(
            child: w.Scrollbar(
              controller: _controller,
              child: w.VirtualListView.builder(
                controller: _controller,
                width: widget.width,
                height: _listHeight,
                itemExtent: _rowHeight,
                cacheExtentItems: 16,
                separator: '',
                handleKeys: false,
                mouseWheelDelta: _wheelRows,
                itemCount: widget.files.length,
                itemBuilder: (context, index) => w.SizedBox(
                  height: _rowHeight,
                  child: _diffFileRow(
                    theme: widget.appTheme,
                    file: widget.files[index],
                    selected: index == widget.selectedIndex,
                    width: widget.width,
                    onTap: widget.onSelected == null
                        ? null
                        : () => widget.onSelected!(index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

w.Widget _diffFileRow({
  required w.Theme theme,
  required GithubPullRequestDiffFile file,
  required bool selected,
  required int width,
  required tui.Cmd? Function()? onTap,
}) {
  final bg = selected ? theme.listRowSelectedBackground : theme.surface;
  final foreground = selected
      ? theme.listRowSelectedForeground
      : theme.listRowForeground;
  final muted = selected
      ? theme.listRowSelectedMutedForeground
      : theme.listRowMutedForeground;
  final titleStyle = theme.bodySmall.copy()
    ..foreground(foreground)
    ..bold();
  final metaStyle = theme.bodySmall.copy()..foreground(muted);
  final addStyle = theme.bodySmall.copy()
    ..foreground(
      selected ? theme.listRowSelectedAccentForeground : Colors.green,
    );
  final deleteStyle = theme.bodySmall.copy()
    ..foreground(selected ? theme.listRowSelectedAccentForeground : Colors.red);
  final statusStyle = theme.bodySmall.copy()
    ..foreground(selected ? theme.listRowSelectedMutedForeground : theme.muted);
  final title = _ellipsizePath(file.filename, (width - 2).clamp(8, 80));
  final child = w.Container(
    color: bg,
    padding: const w.EdgeInsets.symmetric(horizontal: 1),
    child: w.Text.rich(
      w.TextSpan(
        children: [
          w.TextSpan(text: title, style: titleStyle),
          const w.TextSpan(text: '\n'),
          w.TextSpan(text: '+${file.additions}', style: addStyle),
          const w.TextSpan(text: ' '),
          w.TextSpan(text: '-${file.deletions}', style: deleteStyle),
          const w.TextSpan(text: ' '),
          w.TextSpan(text: _fileStateLabel(file), style: statusStyle),
          if (file.displayChanges > 0) ...[
            const w.TextSpan(text: ' '),
            w.TextSpan(text: '${file.displayChanges}c', style: metaStyle),
          ],
        ],
      ),
      softWrap: false,
    ),
  );
  if (onTap == null) return child;
  return w.GestureDetector(onTap: onTap, child: child);
}

w.Widget _selectedFileDiff({
  required String diff,
  GithubPullRequestDiffFile? selectedFile,
  required int width,
  required int height,
  required w.DiffViewMode viewMode,
  w.GitDiffController? controller,
  required w.ScrollController scrollController,
  required List<w.DiffCommentLineHighlight> diffCommentHighlights,
  tui.Cmd? Function(w.DiffCommentAnchor anchor)? onDiffCommentAnchorSelected,
}) {
  return w.GitDiffViewer(
    diff: diff,
    width: width,
    height: height,
    wrapLines: true,
    viewMode: selectedFile?.isCollapsed == true
        ? w.DiffViewMode.unified
        : viewMode,
    controller: controller,
    scrollController: scrollController,
    handleKeys: false,
    commentHighlights: selectedFile?.isCollapsed == true
        ? const <w.DiffCommentLineHighlight>[]
        : diffCommentHighlights,
    onCommentAnchorSelected: selectedFile?.isCollapsed == true
        ? null
        : onDiffCommentAnchorSelected,
  );
}

int _diffFileListWidth(int width) {
  if (width < 90) return 24;
  if (width < 130) return 32;
  return 42;
}

String _fileCountLabel(GithubDisplayItem item) {
  return item.changedFiles == 0 ? '' : ' ${item.changedFiles}';
}

String _commitCountLabel(GithubDisplayItem item) {
  return item.commitCount == 0 ? '' : ' ${item.commitCount}';
}

({int additions, int deletions, int files}) _changeTotals(
  GithubDisplayItem item,
  List<GithubPullRequestDiffFile> files,
) {
  final additions = item.additions == 0
      ? files.fold<int>(0, (sum, file) => sum + file.additions)
      : item.additions;
  final deletions = item.deletions == 0
      ? files.fold<int>(0, (sum, file) => sum + file.deletions)
      : item.deletions;
  final fileCount = item.changedFiles == 0 ? files.length : item.changedFiles;
  return (additions: additions, deletions: deletions, files: fileCount);
}

String _fileStateLabel(GithubPullRequestDiffFile file) {
  if (file.isCollapsed) return 'collapsed';
  if (file.isBinary) return 'binary';
  if (file.status.isEmpty) return 'modified';
  return file.status;
}

String _ellipsizePath(String value, int maxWidth) {
  if (maxWidth <= 0) return '';
  if (value.length <= maxWidth) return value;
  if (maxWidth <= 3) return value.substring(0, maxWidth);
  final slash = value.lastIndexOf('/');
  if (slash > 0) {
    final name = value.substring(slash + 1);
    final parent = value.substring(0, slash);
    if (name.length + 4 < maxWidth) {
      final parentWidth = maxWidth - name.length - 4;
      return '${parent.substring(0, parentWidth)}.../$name';
    }
  }
  return '${value.substring(0, maxWidth - 3)}...';
}

String _diffViewModeLabel(w.DiffViewMode mode) {
  return switch (mode) {
    w.DiffViewMode.unified => 'unified',
    w.DiffViewMode.sideBySide => 'side-by-side',
    w.DiffViewMode.pretty => 'pretty',
  };
}

w.Widget _inlineRunDetail({
  required w.Theme theme,
  required GithubDisplayItem item,
  required GithubWorkflowRunDetail? detail,
  required bool loading,
  required String? error,
  required w.ScrollController controller,
}) {
  final hint = theme.bodySmall.copy()..foreground(theme.muted);
  return w.Expanded(
    child: w.ScrollArea(
      controller: controller,
      showScrollbar: true,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        gap: 1,
        children: [
          w.Text('Run #${item.number}', style: theme.titleMedium),
          if (error != null)
            w.Text(
              error,
              style: theme.bodyMedium.copy()..foreground(theme.error),
            ),
          if (loading && detail == null)
            w.Text('Loading run details from gh...', style: hint),
          if (detail != null) _runDetailBody(theme, detail),
        ],
      ),
    ),
  );
}

w.Widget _runDetailBody(w.Theme theme, GithubWorkflowRunDetail detail) {
  final run = detail.run;
  final statusColor = run.hasFailures ? Colors.red : Colors.green;
  final hint = theme.bodySmall.copy()..foreground(theme.muted);
  return w.Column(
    crossAxisAlignment: w.CrossAxisAlignment.stretch,
    gap: 1,
    children: [
      w.Row(
        gap: 1,
        children: [
          w.Badge(
            run.statusLabel,
            background: statusColor,
            foreground: Colors.black,
          ),
          w.Badge(
            run.workflowName,
            background: theme.surface,
            foreground: theme.onSurface,
          ),
          w.Badge(
            run.event,
            background: theme.surface,
            foreground: theme.muted,
          ),
        ],
      ),
      w.Text(
        '${run.headBranch} / ${relativeGithubTime(run.updatedAt ?? run.createdAt)}',
        style: hint,
      ),
      if (detail.headSha.isNotEmpty)
        w.Text('sha ${detail.headSha}', style: hint),
      w.Text(
        'jobs ${detail.successfulJobCount}/${detail.jobs.length} passing',
        style: theme.bodyMedium,
      ),
      for (final job in detail.jobs) _jobCard(theme, job),
    ],
  );
}

w.Widget _jobCard(w.Theme theme, GithubWorkflowJobItem job) {
  final color = job.hasFailures ? Colors.red : Colors.green;
  return w.Frame(
    background: theme.surface,
    padding: const w.EdgeInsets.symmetric(horizontal: 1, vertical: 1),
    child: w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Row(
          children: [
            w.Text(
              job.statusLabel,
              style: theme.bodyMedium.copy()..foreground(color),
            ),
            w.Spacer(size: 1),
            w.Text(job.name, style: theme.bodyMedium),
          ],
        ),
        for (final step in job.steps.take(12))
          w.Text(
            '${step.hasFailures ? 'x' : 'v'} ${step.number}. ${step.name} (${step.statusLabel})',
            style: theme.bodySmall.copy()
              ..foreground(step.hasFailures ? Colors.red : theme.muted),
            overflow: w.TextOverflow.ellipsis,
            maxWidth: 120,
          ),
        if (job.steps.length > 12)
          w.Text(
            '+${job.steps.length - 12} more steps',
            style: theme.bodySmall.copy()..foreground(theme.muted),
          ),
      ],
    ),
  );
}

bool _sameItem(GithubDisplayItem? left, GithubDisplayItem? right) {
  return left != null &&
      right != null &&
      left.target == right.target &&
      left.number == right.number &&
      (left.repository.isEmpty ||
          right.repository.isEmpty ||
          left.repository == right.repository);
}

w.Widget _detailHeader(w.Theme theme, GithubDisplayItem item) {
  final statusColor = item.hasWarning ? Colors.red : Colors.green;
  final statusText = item.target == GithubDisplayTarget.issue
      ? ''
      : item.status;
  final labelBadges = _detailLabelBadges(theme, item, statusColor);
  return w.Column(
    crossAxisAlignment: w.CrossAxisAlignment.stretch,
    children: [
      w.Row(
        children: [
          w.Text(
            item.kind.toUpperCase(),
            style: theme.bodyMedium.copy()..foreground(theme.muted),
          ),
          w.Spacer(size: 1),
          w.Expanded(
            child: w.Text(
              '#${item.number} ${item.title}',
              style: theme.titleMedium,
              overflow: w.TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      w.Wrap(
        spacing: 1,
        runSpacing: 0,
        children: [
          ...labelBadges,
          if (statusText.trim().isNotEmpty && !item.labels.contains(statusText))
            w.Badge(
              statusText,
              background: theme.surface,
              foreground: statusColor,
            ),
          w.Badge(
            '@${item.author}',
            background: theme.surface,
            foreground: theme.onSurface,
          ),
          w.Badge(
            relativeGithubTime(item.updatedAt),
            background: theme.surface,
            foreground: theme.muted,
          ),
          w.Badge(
            item.footer,
            background: theme.surface,
            foreground: theme.muted,
          ),
        ],
      ),
    ],
  );
}

List<w.Widget> _detailLabelBadges(
  w.Theme theme,
  GithubDisplayItem item,
  Color statusColor,
) {
  final labels = _displayLabels(item);
  if (labels.isNotEmpty) {
    return <w.Widget>[
      for (final label in labels.take(4))
        w.Badge(
          label.name,
          background: labelBackgroundColor(label, fallback: Colors.warning),
          foreground: labelForegroundColor(label),
        ),
    ];
  }
  if (item.status.trim().isEmpty) return const <w.Widget>[];
  return <w.Widget>[
    w.Badge(item.status, background: theme.surface, foreground: statusColor),
  ];
}

List<GithubRepositoryLabel> _displayLabels(GithubDisplayItem item) {
  if (item.labelDetails.isNotEmpty) return item.labelDetails;
  if (item.labels.isEmpty) return const <GithubRepositoryLabel>[];
  return item.labels
      .map((name) => GithubRepositoryLabel(name: name, color: ''))
      .toList(growable: false);
}

w.Widget _repositorySummary(w.Theme theme, GithubDashboardData dashboard) {
  final repo = dashboard.repository;
  return w.Column(
    crossAxisAlignment: w.CrossAxisAlignment.stretch,
    gap: 1,
    children: [
      w.Text(
        repo.nameWithOwner,
        style: theme.titleLarge.copy()..foreground(Colors.warning),
      ),
      if (repo.description.isNotEmpty)
        w.Text(repo.description, style: theme.bodyMedium),
      w.Row(
        gap: 1,
        children: [
          if (repo.primaryLanguage.isNotEmpty)
            w.Badge(
              repo.primaryLanguage,
              background: Colors.cyan,
              foreground: Colors.black,
            ),
          w.Badge(
            '${repo.stars} stars',
            background: theme.surface,
            foreground: theme.onSurface,
          ),
          w.Badge(
            '${repo.forks} forks',
            background: theme.surface,
            foreground: theme.onSurface,
          ),
          if (repo.defaultBranch.isNotEmpty)
            w.Badge(
              repo.defaultBranch,
              background: theme.surface,
              foreground: theme.muted,
            ),
        ],
      ),
      w.Divider(
        width: 80,
        style: theme.bodySmall.copy()..foreground(theme.border),
      ),
      w.Text(
        'Open Issues       ${dashboard.openIssueCount}',
        style: theme.bodyMedium,
      ),
      w.Text(
        'Open Pull Requests ${dashboard.openPullRequestCount}',
        style: theme.bodyMedium,
      ),
      w.Text(
        'Workflow Runs      ${dashboard.workflowRunCount}',
        style: theme.bodyMedium,
      ),
      w.Text(
        'Workflows          ${dashboard.workflowCount}',
        style: theme.bodyMedium,
      ),
      if (repo.latestRelease.isNotEmpty)
        w.Text(
          'Latest release     ${repo.latestRelease}',
          style: theme.bodyMedium,
        ),
      w.Text(
        'Move through the queue to preview work here. Press enter for a focused modal.',
        style: theme.bodySmall.copy()..foreground(theme.muted),
      ),
    ],
  );
}
