import '../client/json.dart';

final class GithubRepositoryLabel {
  const GithubRepositoryLabel({required this.name, required this.color});

  final String name;
  final String color;

  static GithubRepositoryLabel fromJson(Map<String, Object?> json) {
    final color = ghString(json['color']);
    return GithubRepositoryLabel(
      name: ghString(json['name']),
      color: color.isEmpty || color.startsWith('#') ? color : '#$color',
    );
  }
}
