enum FullTextMode { natural, boolean, phrase, websearch }

class FullTextWhere {
  FullTextWhere({
    required List<String> columns,
    required this.value,
    this.language,
    this.mode = FullTextMode.natural,
    this.expanded = false,
    this.tableName,
    this.tablePrefix,
    this.tableAlias,
    this.indexName,
    this.schema,
  }) : columns = List.unmodifiable(columns);

  final List<String> columns;
  final Object value;
  final String? language;
  final FullTextMode mode;
  final bool expanded;
  final String? tableName;
  final String? tablePrefix;
  final String? tableAlias;
  final String? indexName;
  final String? schema;
}
