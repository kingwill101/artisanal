import 'package:ormed/ormed.dart';

/// Configuration describing how a driver should run the shared test suites.
class DriverTestConfig {
  const DriverTestConfig({
    required this.driverName,
    this.supportsReturning = false,
    this.supportsCaseInsensitiveLike = false,
    this.identifierQuote = '"',
    this.supportsQueryDeletes = false,
    this.supportsThreadCount = false,
    this.supportsAdHocQueryUpdates = false,
    this.supportsAdvancedQueryBuilders = false,
    this.supportsSqlPreviews = false,
    this.supportsJoins = true,
    this.supportsRightJoin = true,
    this.supportsDistinctOn = false,
    this.supportsInsertUsing = true,
    this.supportsSchemaIntrospection = true,
    this.supportsWhereRaw = true,
    this.supportsSelectRaw = true,
    Set<DriverCapability>? capabilities,
  }) : _capabilities = capabilities ?? const {};

  final String driverName;
  final bool supportsReturning;
  final bool supportsCaseInsensitiveLike;
  final String identifierQuote;
  final bool supportsQueryDeletes;
  final bool supportsThreadCount;
  final bool supportsAdHocQueryUpdates;
  final bool supportsAdvancedQueryBuilders;
  final bool supportsSqlPreviews;
  final bool supportsJoins;
  final bool supportsRightJoin;
  final bool supportsDistinctOn;
  final bool supportsInsertUsing;
  final bool supportsSchemaIntrospection;
  final bool supportsWhereRaw;
  final bool supportsSelectRaw;
  final Set<DriverCapability> _capabilities;

  /// Reports whether the driver exposes the requested capability.
  bool supportsCapability(DriverCapability capability) {
    if (_capabilities.contains(capability)) return true;
    switch (capability) {
      case DriverCapability.joins:
        return supportsJoins;
      case DriverCapability.insertUsing:
        return supportsInsertUsing;
      case DriverCapability.queryDeletes:
        return supportsQueryDeletes;
      case DriverCapability.schemaIntrospection:
        return supportsSchemaIntrospection;
      case DriverCapability.returning:
        return supportsReturning;
      case DriverCapability.threadCount:
        return supportsThreadCount;
      case DriverCapability.adHocQueryUpdates:
        return supportsAdHocQueryUpdates;
      case DriverCapability.advancedQueryBuilders:
        return supportsAdvancedQueryBuilders;
      case DriverCapability.sqlPreviews:
        return supportsSqlPreviews;
      case DriverCapability.increment:
        return false;
      case DriverCapability.transactions:
        return _capabilities.contains(DriverCapability.transactions);
      case DriverCapability.rawSQL:
        return supportsWhereRaw && supportsSelectRaw;
      case DriverCapability.relationAggregates:
        return _capabilities.contains(DriverCapability.relationAggregates);
      case DriverCapability.caseInsensitiveLike:
        return supportsCaseInsensitiveLike;
      case DriverCapability.rightJoin:
        return supportsRightJoin;
      case DriverCapability.distinctOn:
        return supportsDistinctOn;
      case DriverCapability.databaseManagement:
        return _capabilities.contains(DriverCapability.databaseManagement);
      case DriverCapability.foreignKeyConstraintControl:
        return _capabilities.contains(
          DriverCapability.foreignKeyConstraintControl,
        );
    }
  }
}
