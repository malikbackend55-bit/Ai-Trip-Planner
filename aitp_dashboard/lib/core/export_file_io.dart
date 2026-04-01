import 'dart:io';

Future<String> saveExportFileImpl(String fileName, String content) async {
  final file = File('${Directory.systemTemp.path}${Platform.pathSeparator}$fileName');
  await file.writeAsString(content);
  return file.path;
}
