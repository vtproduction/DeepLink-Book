import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportExportFileService {
  Future<bool> saveExportFile({
    required String fileName,
    required String content,
  }) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Export Project',
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(content)),
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );

    return uri != null;
  }

  Future<String?> pickImportFileContent() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Import Project',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );

    if (file == null) {
      return null;
    }

    return utf8.decode(await file.readAsBytes());
  }
}

final importExportFileServiceProvider = Provider<ImportExportFileService>((
  ref,
) {
  return ImportExportFileService();
});

String buildProjectExportFileName(String projectName) {
  final normalized = projectName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  final safeName = normalized.isEmpty ? 'project' : normalized;

  return '$safeName.deeplink-book.json';
}
