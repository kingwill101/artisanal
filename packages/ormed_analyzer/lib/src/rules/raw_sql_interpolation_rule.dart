import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

class RawSqlInterpolationRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_raw_sql_interpolation',
    'Raw SQL interpolation detected without bindings.',
    correctionMessage: 'Use bindings instead of string interpolation.',
    severity: DiagnosticSeverity.WARNING,
  );

  RawSqlInterpolationRule()
    : super(
        name: 'ormed_raw_sql_interpolation',
        description:
            'Warns when raw SQL strings use interpolation without bindings.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final RawSqlInterpolationRule rule;

  static const Set<String> _rawMethods = {
    'whereRaw',
    'orWhereRaw',
    'orderByRaw',
    'groupByRaw',
    'havingRaw',
    'orHavingRaw',
    'selectRaw',
  };

  static const Set<String> _rawTargets = {
    'Query',
    'PredicateBuilder',
    'JoinBuilder',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (!_rawMethods.contains(methodName)) return;

    final targetType = (node.realTarget ?? node.target)?.staticType;
    if (targetType is! InterfaceType) return;
    if (!_rawTargets.contains(targetType.element.name)) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final sqlArg = args.first;
    if (!_containsInterpolation(sqlArg)) return;

    final hasBindings =
        args.length > 1 ||
        args.any(
          (arg) => arg is NamedExpression && arg.name.label.name == 'bindings',
        );

    if (!hasBindings) {
      rule.reportAtNode(sqlArg);
    }
  }

  bool _containsInterpolation(Expression expression) {
    if (expression is StringInterpolation) {
      return true;
    }
    if (expression is AdjacentStrings) {
      return expression.strings.any(_containsInterpolation);
    }
    return false;
  }
}
