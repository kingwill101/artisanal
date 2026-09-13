import 'package:artisanal/runtime.dart' show ProgramRenderSnapshot;

import 'capture.dart';

/// Converts a recorded runtime frame into the canonical [TerminalCapture].
///
/// Runtime snapshots are diagnostic records and their `toJson` representation
/// intentionally contains only text summaries. A native frame is therefore
/// required here; falling back to [ProgramRenderSnapshot.lines] would produce
/// a different, lossy capture.
TerminalCapture captureProgramFrame(ProgramRenderSnapshot snapshot) {
  final nativeFrame = snapshot.nativeFrame;
  if (nativeFrame == null) {
    throw StateError(
      'program snapshot has no nativeFrame; enable native frame recording',
    );
  }
  final buffer = nativeFrame.toBuffer();
  try {
    return TerminalCapture.fromBuffer(buffer);
  } finally {
    // TerminalCapture.fromBuffer copies the cells; release the owned source
    // buffer regardless of validation or drawable rejection.
    buffer.dispose();
  }
}
