import 'package:ormed/ormed.dart';

String qualifiedColumn(DriverExtensionContext context, String column) {
  if (column.contains('.')) {
    return column
        .split('.')
        .map(context.grammar.wrapIdentifier)
        .join('.');
  }
  return '${context.tableIdentifier}.${context.grammar.wrapIdentifier(column)}';
}
