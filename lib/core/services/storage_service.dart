import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadIncidentImage(
      String incidentId, String localFilePath) async {
    try {
      final file = File(localFilePath);
      if (!await file.exists()) return null;

      final fileName = '${const Uuid().v4()}.jpg';
      final ref = _storage
          .ref()
          .child('incidents')
          .child(incidentId)
          .child(fileName);

      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Storage upload error: $e');
      return null;
    }
  }

  Future<List<String>> uploadMultipleImages(
      String incidentId, List<String> filePaths) async {
    final urls = <String>[];
    for (final path in filePaths) {
      final url = await uploadIncidentImage(incidentId, path);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  Future<void> deleteIncidentMedia(String incidentId) async {
    try {
      final ref = _storage.ref().child('incidents').child(incidentId);
      final list = await ref.listAll();
      for (final item in list.items) {
        await item.delete();
      }
    } catch (e) {
      print('Delete error: $e');
    }
  }
}
