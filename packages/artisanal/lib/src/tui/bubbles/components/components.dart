/// Display components used by the artisanal-style I/O layer.
///
/// These components follow bubble conventions: they render to strings via
/// [DisplayComponent.render] and can be printed directly or composed into a model's
/// `view()`.
library;

// Base classes
export 'base.dart';

// Layout components
export 'layout.dart';

// Text components
export 'text.dart';

// List components
export 'list.dart';

// Box components
export 'box.dart';

// Progress components
export 'progress.dart';
export 'progress_bar.dart';

// Output components (Panel, Tree, Columns, etc.)
export 'output.dart';
export 'tree.dart';

// Table components
export 'table.dart';

// Two column detail components
export 'two_column_detail.dart';

// Styled block components
export 'styled_block.dart';

// Exception components
export 'exception.dart';

// Link components
export 'link.dart';

// Artisanal-style facade helpers
export 'titled_block.dart';

// Markdown components
export 'markdown.dart';
