import 'export_file_stub.dart'
    if (dart.library.io) 'export_file_io.dart'
    if (dart.library.html) 'export_file_web.dart';

Future<String> saveExportFile(String fileName, String content) {
  return saveExportFileImpl(fileName, content);
}
