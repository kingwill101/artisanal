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
  return TerminalCapture.fromBuffer(nativeFrame.toBuffer());
}
