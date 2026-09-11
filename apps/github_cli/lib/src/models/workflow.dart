import '../client/json.dart';

final class GithubWorkflowItem {
  const GithubWorkflowItem({
    required this.id,
    required this.name,
    required this.path,
    required this.state,
  });

  final int id;
  final String name;
  final String path;
  final String state;

  static GithubWorkflowItem fromJson(Map<String, Object?> json) {
    return GithubWorkflowItem(
      id: ghInt(json['id']),
      name: ghString(json['name'], fallback: 'workflow'),
      path: ghString(json['path']),
      state: ghString(json['state'], fallback: 'unknown'),
    );
  }
}
