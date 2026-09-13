/// Native image exports of captured terminal cells.
///
/// Uses software TrueType rasterization and `package:image`; no browser or
/// Flutter engine is needed. Import `artisanal_capture.dart` for the
/// platform-independent cell capture API.
library;

export 'src/export.dart';
export 'package:ultraviolet/raster.dart';
