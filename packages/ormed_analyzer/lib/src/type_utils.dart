import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';

String? modelTypeNameFromExpression(
  Expression? target,
  String containerTypeName,
) {
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
  if (type.element.name != containerTypeName) return null;
  if (type.typeArguments.isEmpty) return null;
  final modelType = type.typeArguments.first;
  return modelType.getDisplayString();
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
