import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../type_utils.dart';

class UpdateDeleteWithoutWhereRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_update_delete_without_where',
    'Update/delete called without any constraints.',
    correctionMessage: 'Add a where clause before update or delete.',
    severity: DiagnosticSeverity.WARNING,
  );

  UpdateDeleteWithoutWhereRule()
    : super(
        name: 'ormed_update_delete_without_where',
        description: 'Warns when update/delete is called without where.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final tracker = _QueryChainTracker();
    registry.addMethodInvocation(this, _UpdateDeleteVisitor(this, tracker));
  }
}

class OffsetWithoutOrderRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_offset_without_order',
    'Offset used without an orderBy clause.',
    correctionMessage: 'Add an orderBy before using offset.',
    severity: DiagnosticSeverity.WARNING,
  );

  OffsetWithoutOrderRule()
    : super(
        name: 'ormed_offset_without_order',
        description: 'Warns when offset is used without orderBy.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final tracker = _QueryChainTracker();
    registry.addMethodInvocation(this, _OffsetVisitor(this, tracker));
  }
}

class LimitWithoutOrderRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_limit_without_order',
    'Limit used without an orderBy clause.',
    correctionMessage: 'Add an orderBy before using limit.',
    severity: DiagnosticSeverity.WARNING,
  );

  LimitWithoutOrderRule()
    : super(
        name: 'ormed_limit_without_order',
        description: 'Warns when limit is used without orderBy.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final tracker = _QueryChainTracker();
    registry.addMethodInvocation(this, _LimitVisitor(this, tracker));
  }
}

class GetWithoutLimitRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_get_without_limit',
    'Query results fetched without a limit.',
    correctionMessage: 'Add a limit or use chunk/paginate helpers.',
    severity: DiagnosticSeverity.WARNING,
  );

  GetWithoutLimitRule()
    : super(
        name: 'ormed_get_without_limit',
        description:
            'Warns when get/rows/getPartial is called without a limit.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final tracker = _QueryChainTracker();
    registry.addMethodInvocation(this, _GetWithoutLimitVisitor(this, tracker));
  }
}

class _UpdateDeleteVisitor extends SimpleAstVisitor<void> {
  _UpdateDeleteVisitor(this.rule, this.tracker);

  final UpdateDeleteWithoutWhereRule rule;
  final _QueryChainTracker tracker;

  static const Set<String> _methods = {'update', 'delete'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_methods.contains(node.methodName.name)) return;

    final target = node.realTarget ?? node.target;
    final modelType = modelTypeNameFromExpression(target, 'Query');
    if (modelType == null) return;

    if (_chainContainsMethod(target, _whereMethods)) {
      return;
    }

    final chainState = tracker.stateFor(node);
    final targetElement = _queryElementFromExpression(target);
    if (targetElement != null && chainState.hasWhere(targetElement)) {
      return;
    }

    rule.reportAtNode(node.methodName);
  }
}

class _OffsetVisitor extends SimpleAstVisitor<void> {
  _OffsetVisitor(this.rule, this.tracker);

  final OffsetWithoutOrderRule rule;
  final _QueryChainTracker tracker;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'offset') return;

    final target = node.realTarget ?? node.target;
    final modelType = modelTypeNameFromExpression(target, 'Query');
    if (modelType == null) return;

    if (_chainContainsMethod(target, _orderMethods)) {
      return;
    }

    final chainState = tracker.stateFor(node);
    final targetElement = _queryElementFromExpression(target);
    if (targetElement != null && chainState.hasOrder(targetElement)) {
      return;
    }

    rule.reportAtNode(node.methodName);
  }
}

class _LimitVisitor extends SimpleAstVisitor<void> {
  _LimitVisitor(this.rule, this.tracker);

  final LimitWithoutOrderRule rule;
  final _QueryChainTracker tracker;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'limit') return;

    final target = node.realTarget ?? node.target;
    final modelType = modelTypeNameFromExpression(target, 'Query');
    if (modelType == null) return;

    if (_chainContainsMethod(target, _orderMethods)) {
      return;
    }

    final chainState = tracker.stateFor(node);
    final targetElement = _queryElementFromExpression(target);
    if (targetElement != null && chainState.hasOrder(targetElement)) {
      return;
    }

    rule.reportAtNode(node.methodName);
  }
}

class _GetWithoutLimitVisitor extends SimpleAstVisitor<void> {
  _GetWithoutLimitVisitor(this.rule, this.tracker);

  final GetWithoutLimitRule rule;
  final _QueryChainTracker tracker;

  static const Set<String> _queryMethods = {'get', 'rows', 'getPartial'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (methodName == 'all') {
      if (_isAllInvocation(node)) {
        rule.reportAtNode(node.methodName);
      }
      return;
    }
    if (!_queryMethods.contains(methodName)) return;

    final target = node.realTarget ?? node.target;
    final modelType = modelTypeNameFromExpression(target, 'Query');
    if (modelType == null) return;

    if (_chainContainsMethod(target, _limitMethods)) {
      return;
    }

    final chainState = tracker.stateFor(node);
    final targetElement = _queryElementFromExpression(target);
    if (targetElement != null && chainState.hasLimit(targetElement)) {
      return;
    }

    rule.reportAtNode(node.methodName);
  }
}

bool _isAllInvocation(MethodInvocation node) {
  final element = node.methodName.element;
  if (element is MethodElement) {
    final enclosing = element.enclosingElement;
    if (enclosing is ClassElement) {
      if (enclosing.name == 'Model') {
        return element.isStatic;
      }
      if (enclosing.name == 'ModelCompanion') {
        return !element.isStatic;
      }
      if (element.isStatic && _isGeneratedCompanion(enclosing)) {
        return true;
      }
    }
  }

  final target = node.realTarget ?? node.target;
  final modelCompanionType = modelTypeNameFromExpression(
    target,
    'ModelCompanion',
  );
  if (modelCompanionType != null) return true;

  return false;
}

bool _isGeneratedCompanion(ClassElement element) {
  for (final method in element.methods) {
    if (!method.isStatic || method.name != 'query') continue;
    final returnType = method.returnType;
    if (returnType is InterfaceType && returnType.element.name == 'Query') {
      return true;
    }
  }
  return false;
}

class _QueryChainState {
  bool hasWhere = false;
  bool hasOrder = false;
  bool hasLimit = false;

  bool get isEmpty => !hasWhere && !hasOrder && !hasLimit;

  _QueryChainState copy() {
    return _QueryChainState()
      ..hasWhere = hasWhere
      ..hasOrder = hasOrder
      ..hasLimit = hasLimit;
  }

  void merge(_QueryChainState other) {
    hasWhere = hasWhere || other.hasWhere;
    hasOrder = hasOrder || other.hasOrder;
    hasLimit = hasLimit || other.hasLimit;
  }

  void applyMethod(String methodName) {
    if (_whereMethods.contains(methodName)) {
      hasWhere = true;
    }
    if (_orderMethods.contains(methodName)) {
      hasOrder = true;
    }
    if (_limitMethods.contains(methodName)) {
      hasLimit = true;
    }
  }
}

class _QueryChainStateMap {
  final Map<Element, _QueryChainState> _states = {};

  bool hasWhere(Element element) => _states[element]?.hasWhere ?? false;
  bool hasOrder(Element element) => _states[element]?.hasOrder ?? false;
  bool hasLimit(Element element) => _states[element]?.hasLimit ?? false;

  _QueryChainState stateFor(Element element) =>
      _states[element]?.copy() ?? _QueryChainState();

  void setState(Element element, _QueryChainState state) {
    _states[element] = state.copy();
  }

  void update(Element element, void Function(_QueryChainState state) update) {
    final state = _states[element] ?? _QueryChainState();
    update(state);
    _states[element] = state;
  }
}

class _QueryChainTracker {
  final Map<FunctionBody, _QueryChainStateMap> _cache = {};

  _QueryChainStateMap stateFor(AstNode node) {
    final body = node.thisOrAncestorOfType<FunctionBody>();
    if (body == null) return _QueryChainStateMap();
    return _cache.putIfAbsent(body, () => _collect(body));
  }

  _QueryChainStateMap _collect(FunctionBody body) {
    final map = _QueryChainStateMap();
    final collector = _QueryChainStateCollector(map);
    collector.collect(body);
    return map;
  }
}

class _QueryChainStateCollector extends RecursiveAstVisitor<void> {
  _QueryChainStateCollector(this.state);

  final _QueryChainStateMap state;

  void collect(FunctionBody body) {
    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        statement.accept(this);
      }
    } else if (body is ExpressionFunctionBody) {
      body.expression.accept(this);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Skip nested function bodies; we only track within the current function.
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Skip nested functions.
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Skip nested methods.
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element != null && _isQueryType(element.type)) {
      final nextState = _stateFromExpression(node.initializer, state);
      state.setState(element, nextState ?? _QueryChainState());
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final targetElement = _queryElementFromExpression(node.leftHandSide);
    if (targetElement != null) {
      final nextState = _stateFromExpression(node.rightHandSide, state);
      state.setState(targetElement, nextState ?? _QueryChainState());
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    final targetElement = _queryElementFromExpression(node.target);
    if (targetElement != null) {
      final modifiers = _modifiersFromCascade(node);
      if (!modifiers.isEmpty) {
        state.update(targetElement, (current) => current.merge(modifiers));
      }
    }
    super.visitCascadeExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.parent is MethodInvocation || node.parent is CascadeExpression) {
      super.visitMethodInvocation(node);
      return;
    }
    final targetElement = _baseQueryElementFromChain(node);
    if (targetElement != null) {
      final modifiers = _modifiersFromMethodChain(node);
      if (!modifiers.isEmpty) {
        state.update(targetElement, (current) => current.merge(modifiers));
      }
    }
    super.visitMethodInvocation(node);
  }
}

_QueryChainState? _stateFromExpression(
  Expression? expression,
  _QueryChainStateMap state,
) {
  if (expression == null) return null;
  if (expression is ParenthesizedExpression) {
    return _stateFromExpression(expression.expression, state);
  }
  if (expression is SimpleIdentifier ||
      expression is PropertyAccess ||
      expression is PrefixedIdentifier) {
    final element = _queryElementFromExpression(expression);
    if (element != null) {
      return state.stateFor(element);
    }
  }
  if (expression is CascadeExpression) {
    if (!_isQueryType(expression.staticType)) return null;
    final base =
        _stateFromExpression(expression.target, state) ?? _QueryChainState();
    base.merge(_modifiersFromCascade(expression));
    return base;
  }
  if (expression is MethodInvocation) {
    if (!_isQueryType(expression.staticType)) return null;
    final base =
        _stateFromExpression(
          expression.realTarget ?? expression.target,
          state,
        ) ??
        _QueryChainState();
    base.applyMethod(expression.methodName.name);
    return base;
  }
  if (_isQueryType(expression.staticType)) {
    return _QueryChainState();
  }
  return null;
}

_QueryChainState _modifiersFromMethodChain(MethodInvocation node) {
  final state = _QueryChainState();
  MethodInvocation? current = node;
  while (current != null) {
    state.applyMethod(current.methodName.name);
    final target = current.realTarget ?? current.target;
    if (target is MethodInvocation) {
      current = target;
    } else {
      break;
    }
  }
  return state;
}

_QueryChainState _modifiersFromCascade(CascadeExpression node) {
  final state = _QueryChainState();
  for (final section in node.cascadeSections) {
    if (section is MethodInvocation) {
      state.applyMethod(section.methodName.name);
    }
  }
  return state;
}

Element? _baseQueryElementFromChain(MethodInvocation node) {
  Expression? target = node.realTarget ?? node.target;
  while (target is MethodInvocation) {
    target = target.realTarget ?? target.target;
  }
  return _queryElementFromExpression(target);
}

Element? _queryElementFromExpression(Expression? expression) {
  if (expression == null) return null;
  Element? element;
  if (expression is SimpleIdentifier) {
    element = expression.element;
  } else if (expression is PrefixedIdentifier) {
    element = expression.element;
  } else if (expression is PropertyAccess) {
    element = expression.propertyName.element;
  }
  if (element == null) return null;
  return _isQueryType(_elementType(element)) ? element : null;
}

bool _isQueryType(DartType? type) {
  return type is InterfaceType && type.element.name == 'Query';
}

DartType? _elementType(Element element) {
  if (element is VariableElement) {
    return element.type;
  }
  if (element is PropertyAccessorElement) {
    return element.returnType;
  }
  return null;
}

const Set<String> _whereMethods = {
  'where',
  'whereEquals',
  'whereNotEquals',
  'whereIn',
  'whereNotIn',
  'whereNull',
  'whereNotNull',
  'whereLike',
  'whereNotLike',
  'whereILike',
  'whereNotILike',
  'whereBetween',
  'whereNotBetween',
  'whereColumn',
  'whereRaw',
  'whereHas',
  'whereHasTyped',
  'orWhere',
  'orWhereEquals',
  'orWhereNotEquals',
  'orWhereIn',
  'orWhereNotIn',
  'orWhereNull',
  'orWhereNotNull',
  'orWhereLike',
  'orWhereNotLike',
  'orWhereILike',
  'orWhereNotILike',
  'orWhereBetween',
  'orWhereNotBetween',
  'orWhereColumn',
  'orWhereRaw',
  'orWhereHas',
  'orWhereHasTyped',
};

const Set<String> _limitMethods = {'limit'};

const Set<String> _orderMethods = {
  'orderBy',
  'orderByRaw',
  'orderByExtension',
  'orderByRandom',
};

bool _chainContainsMethod(Expression? target, Set<String> methods) {
  Expression? current = target;
  while (current is MethodInvocation) {
    final methodName = current.methodName.name;
    if (methods.contains(methodName)) return true;
    current = current.realTarget ?? current.target;
  }
  return false;
}
