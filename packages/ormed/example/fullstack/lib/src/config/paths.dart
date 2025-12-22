import 'package:path/path.dart' as p;

class AppPaths {
  static const databaseFile = 'database.sqlite';
  static const templatesDir = 'templates';
  static const uploadsDir = 'uploads';

  static String templatePath(String file) => p.join(templatesDir, file);
  static String uploadPath(String file) => p.join(uploadsDir, file);
}
