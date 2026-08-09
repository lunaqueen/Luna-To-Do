import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageService {
  static const _fileName = 'luna_todo.json';

  Future<File> get _file async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}/$_fileName');
  }

  Future<Map<String, dynamic>> load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return {};
      final value = jsonDecode(await file.readAsString());
      return value is Map<String, dynamic> ? value : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    final file = await _file;
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }
}
