import 'package:artisanal_widgets/widgets.dart' show ChangeNotifier;

import '../models/action_prompt.dart';
import '../models/dashboard_data.dart';
import '../models/display_item.dart';

/// Owns inline detail and modal state.
final class GithubDetailNotifier extends ChangeNotifier {
  GithubDisplayItem? _detailItem;
  GithubDisplayItem? get detailItem => _detailItem;

  void openDetail(GithubDisplayItem item) {
    _detailItem = item;
    notifyListeners();
  }

  void closeDetail() {
    if (_detailItem == null) return;
    _detailItem = null;
    notifyListeners();
  }

  GithubDisplayItem? _commentsItem;
  List<GithubCommentItem> _comments = const <GithubCommentItem>[];
  bool _commentsLoading = false;
  String? _commentsError;

  GithubDisplayItem? get commentsItem => _commentsItem;
  List<GithubCommentItem> get comments => _comments;
  bool get commentsLoading => _commentsLoading;
  String? get commentsError => _commentsError;

  void openComments(GithubDisplayItem item) {
    _clearActiveDetailPane();
    _commentsItem = item;
    _comments = const <GithubCommentItem>[];
    _commentsLoading = true;
    _commentsError = null;
    notifyListeners();
  }

  void applyCommentsLoaded(List<GithubCommentItem> comments) {
    _comments = comments;
    _commentsLoading = false;
    _commentsError = null;
    notifyListeners();
  }

  void applyCommentsError(String message) {
    _commentsError = message;
    _commentsLoading = false;
    notifyListeners();
  }

  void closeComments() {
    if (_commentsItem == null) return;
    _commentsItem = null;
    _comments = const <GithubCommentItem>[];
    _commentsError = null;
    _commentsLoading = false;
    notifyListeners();
  }

  GithubDisplayItem? _reviewCommentsItem;
  List<GithubPullRequestReviewComment> _reviewComments =
      const <GithubPullRequestReviewComment>[];
  bool _reviewCommentsLoading = false;
  String? _reviewCommentsError;

  GithubDisplayItem? get reviewCommentsItem => _reviewCommentsItem;
  List<GithubPullRequestReviewComment> get reviewComments => _reviewComments;
  bool get reviewCommentsLoading => _reviewCommentsLoading;
  String? get reviewCommentsError => _reviewCommentsError;

  void openReviewComments(GithubDisplayItem item) {
    _clearActiveDetailPane();
    _reviewCommentsItem = item;
    _reviewComments = const <GithubPullRequestReviewComment>[];
    _reviewCommentsLoading = true;
    _reviewCommentsError = null;
    notifyListeners();
  }

  void applyReviewCommentsLoaded(
    List<GithubPullRequestReviewComment> comments,
  ) {
    _reviewComments = comments;
    _reviewCommentsLoading = false;
    _reviewCommentsError = null;
    notifyListeners();
  }

  void applyReviewCommentsError(String message) {
    _reviewCommentsError = message;
    _reviewCommentsLoading = false;
    notifyListeners();
  }

  void closeReviewComments() {
    if (_reviewCommentsItem == null) return;
    _reviewCommentsItem = null;
    _reviewComments = const <GithubPullRequestReviewComment>[];
    _reviewCommentsError = null;
    _reviewCommentsLoading = false;
    notifyListeners();
  }

  GithubDisplayItem? _commitsItem;
  List<GithubPullRequestCommit> _commits = const <GithubPullRequestCommit>[];
  bool _commitsLoading = false;
  String? _commitsError;

  GithubDisplayItem? get commitsItem => _commitsItem;
  List<GithubPullRequestCommit> get commits => _commits;
  bool get commitsLoading => _commitsLoading;
  String? get commitsError => _commitsError;

  void openCommits(GithubDisplayItem item) {
    _clearActiveDetailPane();
    _commitsItem = item;
    _commits = const <GithubPullRequestCommit>[];
    _commitsLoading = true;
    _commitsError = null;
    notifyListeners();
  }

  void applyCommitsLoaded(List<GithubPullRequestCommit> commits) {
    _commits = commits;
    _commitsLoading = false;
    _commitsError = null;
    notifyListeners();
  }

  void applyCommitsError(String message) {
    _commitsError = message;
    _commitsLoading = false;
    notifyListeners();
  }

  void closeCommits() {
    if (_commitsItem == null) return;
    _commitsItem = null;
    _commits = const <GithubPullRequestCommit>[];
    _commitsError = null;
    _commitsLoading = false;
    notifyListeners();
  }

  GithubDisplayItem? _diffItem;
  String _diff = '';
  List<GithubPullRequestDiffFile> _diffFiles =
      const <GithubPullRequestDiffFile>[];
  int _diffFileIndex = 0;
  bool _diffLoading = false;
  String? _diffError;
  List<GithubPullRequestReviewComment> _diffReviewComments =
      const <GithubPullRequestReviewComment>[];

  GithubDisplayItem? get diffItem => _diffItem;
  String get diff => _diff;
  List<GithubPullRequestDiffFile> get diffFiles => _diffFiles;
  int get diffFileIndex => _diffFileIndex;
  bool get diffLoading => _diffLoading;
  String? get diffError => _diffError;
  List<GithubPullRequestReviewComment> get diffReviewComments =>
      _diffReviewComments;

  void openDiff(GithubDisplayItem item) {
    _clearActiveDetailPane();
    _diffItem = item;
    _diff = '';
    _diffFiles = const <GithubPullRequestDiffFile>[];
    _diffFileIndex = 0;
    _diffLoading = true;
    _diffError = null;
    notifyListeners();
  }

  void applyDiffLoaded(String diff) {
    _diff = diff;
    _diffFiles = const <GithubPullRequestDiffFile>[];
    _diffFileIndex = 0;
    _diffLoading = false;
    _diffError = null;
    notifyListeners();
  }

  void applyDiffChunk(GithubPullRequestDiffChunk chunk) {
    if (_diffItem == null) return;
    if (chunk.files.isEmpty && chunk.text.isEmpty) return;
    final hadFiles = _diffFiles.isNotEmpty;
    if (chunk.files.isNotEmpty) {
      _diffFiles = List.unmodifiable([..._diffFiles, ...chunk.files]);
      if (!hadFiles) {
        _diffFileIndex = 0;
        _diff = _diffFiles.first.toUnifiedPatch();
      } else if (_diffFileIndex >= _diffFiles.length) {
        _diffFileIndex = _diffFiles.length - 1;
        _diff = _diffFiles[_diffFileIndex].toUnifiedPatch();
      }
    } else if (!hadFiles) {
      _diff += chunk.text;
    }
    _diffLoading = true;
    _diffError = null;
    notifyListeners();
  }

  void applyDiffFinished() {
    if (_diffItem == null || !_diffLoading) return;
    _diffLoading = false;
    notifyListeners();
  }

  bool selectDiffFile(int index) {
    if (_diffFiles.isEmpty || index < 0 || index >= _diffFiles.length) {
      return false;
    }
    if (_diffFileIndex == index) return false;
    _diffFileIndex = index;
    _diff = _diffFiles[index].toUnifiedPatch();
    notifyListeners();
    return true;
  }

  bool moveDiffFile(int delta) {
    if (_diffFiles.isEmpty || delta == 0) return false;
    final next = (_diffFileIndex + delta).clamp(0, _diffFiles.length - 1);
    return selectDiffFile(next);
  }

  void applyDiffError(String message) {
    _diffError = message;
    _diffLoading = false;
    notifyListeners();
  }

  void applyDiffReviewCommentsLoaded(
    List<GithubPullRequestReviewComment> comments,
  ) {
    _diffReviewComments = comments;
    notifyListeners();
  }

  void closeDiff() {
    if (_diffItem == null) return;
    _diffItem = null;
    _diff = '';
    _diffFiles = const <GithubPullRequestDiffFile>[];
    _diffFileIndex = 0;
    _diffError = null;
    _diffLoading = false;
    _diffReviewComments = const <GithubPullRequestReviewComment>[];
    notifyListeners();
  }

  GithubDisplayItem? _mergeInfoItem;
  GithubPullRequestMergeInfo? _mergeInfo;
  bool _mergeInfoLoading = false;
  String? _mergeInfoError;

  GithubDisplayItem? get mergeInfoItem => _mergeInfoItem;
  GithubPullRequestMergeInfo? get mergeInfo => _mergeInfo;
  bool get mergeInfoLoading => _mergeInfoLoading;
  String? get mergeInfoError => _mergeInfoError;

  void openMergeInfo(GithubDisplayItem item) {
    _mergeInfoItem = item;
    _mergeInfo = null;
    _mergeInfoLoading = true;
    _mergeInfoError = null;
    notifyListeners();
  }

  void applyMergeInfoLoaded(GithubPullRequestMergeInfo info) {
    _mergeInfo = info;
    _mergeInfoLoading = false;
    _mergeInfoError = null;
    notifyListeners();
  }

  void applyMergeInfoError(String message) {
    _mergeInfoError = message;
    _mergeInfoLoading = false;
    notifyListeners();
  }

  void closeMergeInfo() {
    if (_mergeInfoItem == null) return;
    _mergeInfoItem = null;
    _mergeInfo = null;
    _mergeInfoError = null;
    _mergeInfoLoading = false;
    _actionPrompt = null;
    _actionPromptError = null;
    _actionRunning = false;
    notifyListeners();
  }

  GithubDisplayItem? _repositoryLabelsItem;
  List<GithubRepositoryLabel> _repositoryLabels =
      const <GithubRepositoryLabel>[];
  bool _repositoryLabelsLoading = false;
  String? _repositoryLabelsError;

  GithubDisplayItem? get repositoryLabelsItem => _repositoryLabelsItem;
  List<GithubRepositoryLabel> get repositoryLabels => _repositoryLabels;
  bool get repositoryLabelsLoading => _repositoryLabelsLoading;
  String? get repositoryLabelsError => _repositoryLabelsError;

  void openRepositoryLabels(GithubDisplayItem item) {
    _repositoryLabelsItem = item;
    _repositoryLabels = const <GithubRepositoryLabel>[];
    _repositoryLabelsLoading = true;
    _repositoryLabelsError = null;
    notifyListeners();
  }

  void applyRepositoryLabelsLoaded(List<GithubRepositoryLabel> labels) {
    _repositoryLabels = labels;
    _repositoryLabelsLoading = false;
    _repositoryLabelsError = null;
    notifyListeners();
  }

  void applyRepositoryLabelsError(String message) {
    _repositoryLabelsError = message;
    _repositoryLabelsLoading = false;
    notifyListeners();
  }

  void closeRepositoryLabels() {
    if (_repositoryLabelsItem == null) return;
    _repositoryLabelsItem = null;
    _repositoryLabels = const <GithubRepositoryLabel>[];
    _repositoryLabelsError = null;
    _repositoryLabelsLoading = false;
    _actionPrompt = null;
    _actionPromptError = null;
    _actionRunning = false;
    notifyListeners();
  }

  GithubDisplayItem? _runDetailItem;
  GithubWorkflowRunDetail? _runDetail;
  bool _runDetailLoading = false;
  String? _runDetailError;

  GithubDisplayItem? get runDetailItem => _runDetailItem;
  GithubWorkflowRunDetail? get runDetail => _runDetail;
  bool get runDetailLoading => _runDetailLoading;
  String? get runDetailError => _runDetailError;

  void openRunDetail(GithubDisplayItem item) {
    _clearActiveDetailPane();
    _runDetailItem = item;
    _runDetail = null;
    _runDetailLoading = true;
    _runDetailError = null;
    notifyListeners();
  }

  void applyRunDetailLoaded(GithubWorkflowRunDetail detail) {
    _runDetail = detail;
    _runDetailLoading = false;
    _runDetailError = null;
    notifyListeners();
  }

  void applyRunDetailError(String message) {
    _runDetailError = message;
    _runDetailLoading = false;
    notifyListeners();
  }

  void closeRunDetail() {
    if (_runDetailItem == null) return;
    _runDetailItem = null;
    _runDetail = null;
    _runDetailError = null;
    _runDetailLoading = false;
    notifyListeners();
  }

  GithubActionPrompt? _actionPrompt;
  String? _actionPromptError;
  bool _actionRunning = false;

  GithubActionPrompt? get actionPrompt => _actionPrompt;
  String? get actionPromptError => _actionPromptError;
  bool get actionRunning => _actionRunning;

  void openActionPrompt(
    GithubActionPromptKind kind,
    GithubDisplayItem item, {
    GithubDiffCommentTarget? diffTarget,
  }) {
    _actionPrompt = GithubActionPrompt(
      kind: kind,
      item: item,
      diffTarget: diffTarget,
    );
    _actionPromptError = null;
    _actionRunning = false;
    notifyListeners();
  }

  void closeActionPrompt() {
    if (_actionPrompt == null) return;
    _actionPrompt = null;
    _actionPromptError = null;
    _actionRunning = false;
    notifyListeners();
  }

  void startAction() {
    _actionRunning = true;
    _actionPromptError = null;
    notifyListeners();
  }

  void applyActionError(String message) {
    _actionPromptError = message;
    _actionRunning = false;
    notifyListeners();
  }

  bool _searchOpen = false;
  bool _repoPromptOpen = false;
  bool _repositoryListOpen = false;
  String? _repoPromptError;
  String? _notice;

  bool get searchOpen => _searchOpen;

  void openSearch() {
    _searchOpen = true;
    notifyListeners();
  }

  void closeSearch() {
    if (!_searchOpen) return;
    _searchOpen = false;
    notifyListeners();
  }

  bool get repoPromptOpen => _repoPromptOpen;
  bool get repositoryListOpen => _repositoryListOpen;
  String? get repoPromptError => _repoPromptError;
  String? get notice => _notice;

  void openRepositoryPrompt() {
    _repoPromptOpen = true;
    _repoPromptError = null;
    notifyListeners();
  }

  void closeRepositoryPrompt() {
    if (!_repoPromptOpen) return;
    _repoPromptOpen = false;
    _repoPromptError = null;
    notifyListeners();
  }

  void applyRepositoryPromptError(String message) {
    _repoPromptError = message;
    notifyListeners();
  }

  void openRepositoryList() {
    _repositoryListOpen = true;
    notifyListeners();
  }

  void closeRepositoryList() {
    if (!_repositoryListOpen) return;
    _repositoryListOpen = false;
    notifyListeners();
  }

  void applyNotice(String? message) {
    _notice = message;
    if (message != null) notifyListeners();
  }

  void _clearActiveDetailPane() {
    _commentsItem = null;
    _commitsItem = null;
    _reviewCommentsItem = null;
    _diffItem = null;
    _runDetailItem = null;
    _diff = '';
    _diffFiles = const <GithubPullRequestDiffFile>[];
    _diffFileIndex = 0;
    _diffError = null;
    _diffLoading = false;
    _diffReviewComments = const <GithubPullRequestReviewComment>[];
  }

  /// Close all inline modals at once, for example on tab switch or data reload.
  void closeAllInlineDetails() {
    final wasOpen =
        _diffItem != null ||
        _runDetailItem != null ||
        _commentsItem != null ||
        _commitsItem != null ||
        _reviewCommentsItem != null ||
        _mergeInfoItem != null ||
        _repositoryLabelsItem != null ||
        _repositoryListOpen;
    _diffItem = null;
    _diff = '';
    _diffFiles = const <GithubPullRequestDiffFile>[];
    _diffFileIndex = 0;
    _diffError = null;
    _diffLoading = false;
    _diffReviewComments = const <GithubPullRequestReviewComment>[];
    _runDetailItem = null;
    _runDetail = null;
    _runDetailError = null;
    _runDetailLoading = false;
    _commentsItem = null;
    _comments = const <GithubCommentItem>[];
    _commentsError = null;
    _commentsLoading = false;
    _commitsItem = null;
    _commits = const <GithubPullRequestCommit>[];
    _commitsError = null;
    _commitsLoading = false;
    _reviewCommentsItem = null;
    _reviewComments = const <GithubPullRequestReviewComment>[];
    _reviewCommentsError = null;
    _reviewCommentsLoading = false;
    _mergeInfoItem = null;
    _mergeInfo = null;
    _mergeInfoError = null;
    _mergeInfoLoading = false;
    _repositoryLabelsItem = null;
    _repositoryLabels = const <GithubRepositoryLabel>[];
    _repositoryLabelsError = null;
    _repositoryLabelsLoading = false;
    _repositoryListOpen = false;
    _actionPrompt = null;
    _actionPromptError = null;
    _actionRunning = false;
    if (wasOpen) notifyListeners();
  }

  void applyActionCompleted(String message) {
    _notice = message;
    closeActionPrompt();
    closeMergeInfo();
    closeRepositoryLabels();
  }
}
