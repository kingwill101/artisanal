# Diff Viewer Refactor Plan: artisanal_widgets Integration

## Executive Summary

This plan outlines the strategy for migrating the Git diff viewer from its current string-injection approach (approach A) to a new widget-based rendering system using artisanal_widgets. The primary goals are:

1. **Restore rich comment rendering** - restore avatar images, markdown formatting, and the full comment card experience
2. **Fix positioning bugs** - ensure comments appear under the correct diff lines
3. **Implement side-aware placement** - align comments with addition/removal sides in unified vs side-by-side views
4. **Preserve all existing data structures** - maintain compatibility with the bubbles implementation

## Current Problem Statement

### Issues with Approach A (String Injection)
1. **Loss of Rich Rendering** - Comments lose avatar images and markdown formatting, becoming plain text frames
2. **Incorrect Positioning** - Comments appear under wrong lines (e.g., line 393 appears under hunk header @@ -397,8 instead)
3. **Side Placement Issues** - Comments don't align correctly with addition/removal columns in side-by-side view
4. **Limited Customization** - String-based rendering cannot preserve complex widget layouts

### Technical Constraints
- `GitDiffModel` (artisanal) owns all diff data and anchors
- `DiffCommentAnchor` and `DiffCommentLineHighlight` structures must remain unchanged
- All comment rendering logic currently uses string injection through `inlineCommentLines`
- The model is rendering-agnostic and cannot hold widget references

## Target Architecture

### Data Layer (Unchanged)
- `GitDiffModel` in `artisanal/lib/src/tui/bubbles/git_diff.dart`
- All anchor computation (`_computeUnifiedCommentAnchors`, `_computeSideBySideCommentAnchors`)
- Comment line highlighting system
- All comment data structures and mapping utilities

### New Rendering Layer (artisanal_widgets)
```
Controller -> Model (GitDiffModel - unchanged)
              |
              | Comments → mapReviewCommentsToRenderLines()
              |                  |
              |                  +→ Build DiffCommentBlock objects (new)
              |
              | GitDiffViewer (artisanal_widgets)
                 -> SingleChildScrollView (scroll owner)
                    -> Column (diff lines + rich comment widgets)
                    -> Gesture handling for taps
```

### Key Architectural Changes
1. **GitDiffViewer accepts `commentBlocks` parameter** alongside `inlineCommentLines`
2. **Dual-mode support** - accepts both old (string) and new (widget) comment rendering
3. **Widget-based rendering** - uses `_timelineCard`, `_avatarImage`, `GithubMarkdownBody` components
4. **Proper scroll coordination** - uses SingleChildScrollView as scroll owner (doesn't fight ViewportModel)

## Technical Implementation Strategy

### Phase 1: Core Infrastructure (Weeks 1-2)

#### 1.1 Extend GitDiffController
- Add `commentBlocks` field to controller state
- Add `setCommentBlocks()` method for updating widget-based comments
- Maintain `inlineComments` for backward compatibility
- Update `_notifyListeners()` to handle both comment types

#### 1.2 Update GitDiffViewer Widget
- Add `commentBlocks` parameter (type: `List<DiffCommentBlock>`)
- Add `inlineCommentLines` parameter (type: `Map<int, List<String>>`)
- Implement `_hasCommentBlocks` property
- Store `commentBlocks` in widget state

#### 1.3 Update Model Contract
- Model unchanged - still computes all anchors
- Controller bridges model anchors to widget commentBlocks
- Controller can convert commentLine mappings to DiffCommentBlock objects

### Phase 2: Widget Building Infrastructure (Weeks 3-4)

#### 2.1 Enhance DiffCommentBlock
- Add `side` parameter (DiffCommentSide?)
- Support for positioning in side-by-side view
- Height reservation for scroll metrics

#### 2.2 Create Widget Building Pipeline
- New method `_buildDiffCommentBlocks()` in detail_pane.dart
- Converts `Map<int, List<GithubPullRequestReviewComment>>` to `List<DiffCommentBlock>`
- Uses existing `_timelineCard`, `_avatarImage`, `GithubMarkdownBody`
- Creates rich comment widgets with proper styling and layout

#### 2.3 Update GitDiffViewer Implementation
- Implement `_buildContent()` method for widget-based rendering
- Compose column with diff lines and comment widgets
- Build `_rowToRenderedLine` mapping for tap handling
- Update scroll metrics to include comment block heights

### Phase 3: Scroll and Interaction (Weeks 5-6)

#### 3.1 Update Scroll Logic
- When comment blocks exist: use SingleChildScrollView with external controller
- When no comment blocks: maintain current behavior
- Fixed scroll metrics: `contentExtent = model.viewport.totalLineCount + totalCommentBlockHeight`
- Proper coordination between external controller and model

#### 3.2 Implement Tap Handling
- Map tapped content row back to diff render-line using `_rowToRenderedLine`
- Support side-aware selection in side-by-side mode
- Use `_sideForLocalX()` to determine left/right panel
- Resolve comment anchors using controller's `commentAnchorAt()`

#### 3.3 Update Gesture Detection
- Modified `_handleTapDown()` to handle both rendering modes
- Differentiate between widget-based and string-based rendering
- Proper coordinate transformation for both modes

### Phase 4: Migration and Testing (Weeks 7-8)

#### 4.1 Dual-Mode Support
- Controller accepts both `inlineComments` and `commentBlocks`
- Gradual rollout of new widget-based rendering
- Fallback to string injection for edge cases
- Feature flag based on comment rendering mode

#### 4.2 Comprehensive Testing
- Unit tests for DiffCommentBlock creation
- Integration tests for widget rendering
- Positioning tests (verify correct line placement)
- Side-aware placement tests
- Scroll integration tests
- Performance tests
- Visual regression tests

#### 4.3 Backward Compatibility
- Existing string injection tests continue to pass
- New widget-based tests added
- Both rendering modes produce equivalent visual results
- Seamless transition between modes

## Detailed Technical Plan

### DiffCommentBlock Class
```dart
class DiffCommentBlock {
  const DiffCommentBlock({
    required this.renderLine,
    required this.child,
    required this.height,
    this.side,
  });

  // Properties as defined above
  final int renderLine;
  final Widget child;
  final int height;
  final DiffCommentSide? side;
}
```

### Widget Building Pipeline
```dart
Map<int, List<String>> commentsByLine = mapReviewCommentsToRenderLines(
  diffReviewComments,
  controller.model.commentAnchors,
);

// Convert string-based comments to widget-based comments
final commentBlocks = _buildDiffCommentBlocks(
  theme: theme,
  commentsByLine: commentsByLine,
  width: width,
  controller: diffController,
);
```

### GitDiffViewer Changes
```dart
GitDiffViewer(
  // Existing parameters unchanged...
  commentBlocks: commentBlocks,
  inlineCommentLines: const {}, // Disable string injection for this instance
);
```

### Scroll Metrics Calculation
```dart
int get totalCommentBlockHeight =>
    widget.commentBlocks.fold(0, (sum, b) => sum + b.height);

int contentExtent = 
    _controller.model.viewport.totalLineCount + _totalCommentBlockHeight;
```

### Widget Building Implementation
```dart
Widget _buildContent() {
  final model = _controller.model;
  final renderedLines = model.renderedLines;
  final children = <Widget>[];
  final rowToRendered = <int, int>{};

  // Sort comment blocks by renderLine
  final sorted = [...widget.commentBlocks]
    ..sort((a, b) => a.renderLine.compareTo(b.renderLine));
  
  var blockIdx = 0;
  var row = 0;

  for (var i = 0; i < renderedLines.length; i++) {
    // Add diff line
    children.add(Text(renderedLines[i], softWrap: false));
    rowToRendered[row] = i;
    row++;

    // Add any comment blocks for this render line
    while (blockIdx < sorted.length && sorted[blockIdx].renderLine == i) {
      final block = sorted[blockIdx];
      children.add(_positionedComment(block, model));
      
      // Reserve rows for this comment block
      for (var h = 0; h < block.height; h++) {
        rowToRendered[row] = i;
        row++;
      }
      
      blockIdx++;
    }
  }

  _rowToRenderedLine = rowToRendered;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}
```

### Side-Aware Positioning
```dart
Widget _positionedComment(DiffCommentBlock block, GitDiffModel model) {
  if (model.viewMode != DiffViewMode.sideBySide || block.side == null) {
    return block.child;
  }

  // Position comment in correct panel for side-by-side view
  final half = (model.width / 2).ceil();
  if (block.side == DiffCommentSide.right) {
    return Padding(
      padding: EdgeInsets.only(left: half),
      child: block.child,
    );
  }
  return Padding(
    padding: EdgeInsets.only(right: half),
    child: block.child,
  );
}
```

## Migration Strategy

### Gradual Rollout
1. **Phase 1**: New widget-based rendering for new PRs/comments
2. **Phase 2**: Gradual conversion of existing inline comments
3. **Phase 3**: Full migration to widget-based rendering
4. **Fallback**: Maintain string injection for edge cases or compatibility

### Backward Compatibility
- Dual-mode controller accepts both rendering approaches
- Feature flag controls which rendering mode is used
- Tests verify both modes produce equivalent visual results
- Seamless transition between modes

### Testing Timeline
1. **Week 1-2**: Core infrastructure and widget building
2. **Week 3-4**: Scroll and interaction fixes
3. **Week 5-6**: Integration testing and dual-mode support
4. **Week 7-8**: Performance testing and production deployment

## Risk Assessment

### High-Risk Areas
1. **Scroll Coordination**: Complex interaction between controller, model, and widget rendering
2. **Tap Mapping**: Accurate row->renderLine mapping with multi-row comment cards
3. **Positioning Bugs**: Correct line placement requires careful handling of view modes

### Mitigation Strategies
1. **Comprehensive Testing**: Extensive test coverage for all rendering modes
2. **Incremental Rollout**: Gradual migration reduces impact of any issues
3. **Feature Flags**: Ability to rollback quickly if issues arise

### Acceptable Risks
1. **Performance**: Slightly higher CPU for widget building vs string rendering
2. **Memory**: Widget tree may use more memory than string approach
3. **Initial Complexity**: New code paths more complex than simple string injection

## Success Criteria

### Functional Requirements
- ✅ Rich comment features preserved (avatars, images, markdown)
- ✅ Comments render under correct diff lines
- ✅ Side-aware placement in unified and side-by-side modes
- ✅ Tap interactions resolve to correct comment anchors
- ✅ All existing functionality preserved

### Performance Requirements
- ✅ Scroll performance comparable to existing implementation
- ✅ No memory leaks or excessive CPU usage
- ✅ Responsive UI with many comment blocks

### Quality Requirements
- ✅ Code quality meets project standards
- ✅ Comprehensive test coverage
- ✅ Backward compatibility maintained
- ✅ Documentation updated

## Testing Strategy

### New Test Coverage
1. **Widget Rendering Tests**: Verify comment widgets render correctly
2. **Positioning Tests**: Ensure comments appear under correct diff lines
3. **Side-Aware Tests**: Validate correct column placement in side-by-side mode
4. **Scroll Integration**: Test scroll behavior with comment blocks
5. **Tap Interaction**: Verify tap-to-select works with widget overlays

### Backward Compatibility
1. **Dual-Mode Tests**: Ensure both string injection and widget modes work
2. **Regression Tests**: Compare rendering to ensure no visual regressions
3. **Performance Tests**: Verify scroll performance is acceptable

## Open Issues

### Known Issues
1. **Single-file limitation**: HTTP + CLI clients only render comments for current file
2. **Scroll coordination complexity**: Complex interaction between scrolling systems
3. **Layout dependencies**: Widget building depends on accurate model state

### Action Items
1. **[Separate Issue]** Fix HTTP + CLI clients to support multi-file comment rendering
2. **[Plan]** Investigate optimization opportunities for widget building
3. **[Separate Issue]** Document widget rendering behavior for edge cases

## Implementation Dependencies

### Required Changes
- **artisanal_widgets/lib/src/widgets/components/git_diff.dart** - Core changes
- **artisanal_widgets/example/github_cli/lib/src/ui/dashboard/detail_pane.dart** - Widget building
- **artisanal_widgets/test/components/git_diff_test.dart** - Test updates
- **artisanal_widgets/lib/src/widgets/components/git_diff.dart** - Scroll logic updates

### External Dependencies
- No external dependencies required
- All changes are within existing codebases

## Conclusion

This refactoring plan preserves all existing data structures while upgrading the rendering layer to use artisanal_widgets capabilities. The approach:

1. **Leverages existing component infrastructure** (`_timelineCard`, `_avatarImage`, etc.)
2. **Maintains full backward compatibility** through dual-mode support
3. **Fixes critical issues** with positioning and side placement
4. **Provides clear migration path** with incremental rollout
5. **Includes comprehensive testing** and risk mitigation

The key insight is that widget-based rendering provides the richness and flexibility needed for modern comment cards while proper scroll coordination ensures smooth user experience. This migration will result in a more robust, feature-rich diff viewer that maintains all the richness of the review comments.

## References

- `diff_comment_mapper.dart` - Comment to line anchor mapping
- `git_diff.dart` - Core diff model and anchors
- `detail_pane.dart` - Existing comment rendering implementation
- `git_diff_test.dart` - Existing test infrastructure