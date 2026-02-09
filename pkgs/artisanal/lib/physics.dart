/// Physics helpers (Forge2D adapters) for Artisanal.
///
/// Experimental: this API is still evolving and may change in minor releases.
/// This library exposes lightweight wrappers plus common forge2d types
/// so you can integrate physics into UV/TUI demos without extra setup.
@experimental
library;

import 'package:meta/meta.dart' show experimental;

export 'src/physics/physics.dart';
export 'package:forge2d/forge2d.dart' show Joint, RevoluteJoint, DistanceJoint;
