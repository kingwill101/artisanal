import 'package:ultraviolet/ultraviolet.dart' as ultraviolet;

void main() {
  final entrypointTypes = <Type>[ultraviolet.UvStyle];
  if (entrypointTypes.isEmpty) {
    throw StateError('Ultraviolet entrypoint was not loaded.');
  }
}
