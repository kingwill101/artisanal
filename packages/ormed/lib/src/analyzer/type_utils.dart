import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';

InterfaceType? interfaceTypeFromExpression(Expression? target) {
  if (target == null) return null;
  DartType? type = target.staticType;
  if (type == null && target is SimpleIdentifier) {
    type = _typeFromElement(target.element);
  } else if (type == null && target is PrefixedIdentifier) {
    type = _typeFromElement(target.element);
  } else if (type == null && target is PropertyAccess) {
    type = _typeFromElement(target.propertyName.element);
  }

  if (type is! InterfaceType) return null;
  return type;
}

String? modelTypeNameFromExpression(
  Expression? target,
  String containerTypeName,
) {
  final type = interfaceTypeFromExpression(target);
  if (type == null) return null;
  if (type.element.name != containerTypeName) return null;
  if (type.typeArguments.isEmpty) return null;
  final modelType = type.typeArguments.first;
  return modelType.getDisplayString();
}

String? interfaceTypeNameFromExpression(Expression? target) {
  final type = interfaceTypeFromExpression(target);
  if (type == null) return null;
  return type.element.name;
}

String? simpleStringLiteralValue(Expression expression) {
  if (expression is SimpleStringLiteral) {
    return expression.value;
  }
  if (expression is AdjacentStrings) {
    final buffer = StringBuffer();
    for (final string in expression.strings) {
      if (string is SimpleStringLiteral) {
        buffer.write(string.value);
      } else {
        return null;
      }
    }
    return buffer.toString();
  }
  return null;
}

String? stringLiteralValue(Expression expression) {
  if (expression is SimpleStringLiteral) {
    return expression.value;
  }
  if (expression is AdjacentStrings) {
    final buffer = StringBuffer();
    for (final string in expression.strings) {
      if (string is SimpleStringLiteral) {
        buffer.write(string.value);
      } else {
        return null;
      }
    }
    return buffer.toString();
  }
  if (expression is StringInterpolation) {
    return expression.toSource();
  }
  return null;
}

List<String> stringLiteralList(Expression expression) {
  if (expression is! ListLiteral) {
    return const [];
  }
  final values = <String>[];
  for (final element in expression.elements) {
    if (element is! Expression) continue;
    final value = stringLiteralValue(element);
    if (value == null) {
      return const [];
    }
    values.add(value);
  }
  return values;
}

List<String> simpleStringLiteralList(Expression expression) {
  if (expression is! ListLiteral) {
    return const [];
  }
  final values = <String>[];
  for (final element in expression.elements) {
    if (element is! Expression) continue;
    final value = simpleStringLiteralValue(element);
    if (value == null) {
      return const [];
    }
    values.add(value);
  }
  return values;
}

DartType? _typeFromElement(Element? element) {
  if (element is PropertyAccessorElement) {
    return element.returnType;
  }
  if (element is VariableElement) {
    return element.type;
  }
  return null;
}
