import 'dart:io';

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class RawSqlInterpolationRule extends AnalysisRule {
  static const String _codeName = 'ormed_raw_sql_interpolation';
  static const String _message =
      'Raw SQL interpolation detected without bindings.';
  static const String _correction =
      'Use bindings instead of string interpolation.';
  static const LintCode _defaultCode = LintCode(
    _codeName,
    _message,
    correctionMessage: _correction,
    severity: DiagnosticSeverity.WARNING,
  );

  RawSqlInterpolationRule()
    : super(
        name: _codeName,
        description:
            'Warns when raw SQL strings use interpolation without bindings.',
      );

  LintCode _code = _defaultCode;
  bool _enabled = true;

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    _configure(context);
    if (!_enabled) {
      return;
    }
    registry.addMethodInvocation(this, _Visitor(this));
  }

  void _configure(RuleContext context) {
    final severity = _resolveSeverity(context);
    _enabled = severity != null;
    if (!_enabled) {
      return;
    }
    _code = LintCode(
      _codeName,
      _message,
      correctionMessage: _correction,
      severity: severity!,
    );
  }

  DiagnosticSeverity? _resolveSeverity(RuleContext context) {
    final root =
        context.package?.root.path ?? context.definingUnit.file.parent.path;
    final optionsPath = p.join(root, 'analysis_options.yaml');
    final file = File(optionsPath);
    if (!file.existsSync()) {
      return DiagnosticSeverity.WARNING;
    }
    try {
      final content = file.readAsStringSync();
      final yaml = loadYaml(content);
      if (yaml is! YamlMap) {
        return DiagnosticSeverity.WARNING;
      }
      final ormed = yaml['ormed'];
      if (ormed is! YamlMap) {
        return DiagnosticSeverity.WARNING;
      }
      final lints = ormed['lints'];
      if (lints is! YamlMap) {
        return DiagnosticSeverity.WARNING;
      }
      final rawValue = lints['raw_sql_interpolation'];
      if (rawValue == null) {
        return DiagnosticSeverity.WARNING;
      }
      final normalized = rawValue.toString().trim().toLowerCase();
      switch (normalized) {
        case 'ignore':
        case 'off':
        case 'false':
          return null;
        case 'info':
          return DiagnosticSeverity.INFO;
        case 'error':
          return DiagnosticSeverity.ERROR;
        case 'warning':
        default:
          return DiagnosticSeverity.WARNING;
      }
    } catch (_) {
      return DiagnosticSeverity.WARNING;
    }
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
    'joinRaw',
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
