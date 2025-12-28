import 'package:liquify/liquify.dart';

// #region template-renderer
class TemplateRenderer {
  TemplateRenderer(this.root, {Map<String, Object?>? sharedData})
    : _sharedData = sharedData ?? <String, Object?>{};

  final Root root;
  final Map<String, Object?> _sharedData;

  Future<String> render(String templatePath, Map<String, Object?> data) async {
    final template = Template.fromFile(
      templatePath,
      root,
      data: {..._sharedData, ...data},
    );
    return template.renderAsync();
  }
}

// #endregion template-renderer
