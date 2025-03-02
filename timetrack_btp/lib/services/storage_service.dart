import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final ImagePicker _picker = ImagePicker();

  // Capture d'une photo à partir de la caméra
  static Future<String?> capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (photo == null) {
        return null;
      }

      // Sauvegarder l'image dans le stockage local
      return await savePhotoToLocalStorage(File(photo.path));
    } catch (e) {
      print('Error capturing photo: $e');
      return null;
    }
  }

  // Sélection d'une photo à partir de la galerie
  static Future<String?> pickPhotoFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (photo == null) {
        return null;
      }

      // Sauvegarder l'image dans le stockage local
      return await savePhotoToLocalStorage(File(photo.path));
    } catch (e) {
      print('Error picking photo: $e');
      return null;
    }
  }

  // Sauvegarder une photo dans le stockage local
  static Future<String> savePhotoToLocalStorage(File photoFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String photosDir = path.join(appDir.path, 'photos');
      
      // Créer le dossier s'il n'existe pas
      final Directory photosDirFolder = Directory(photosDir);
      if (!await photosDirFolder.exists()) {
        await photosDirFolder.create(recursive: true);
      }

      // Générer un nom de fichier unique
      final String fileName = '${Uuid().v4()}.jpg';
      final String filePath = path.join(photosDir, fileName);

      // Copier l'image dans le stockage local
      await photoFile.copy(filePath);

      return filePath;
    } catch (e) {
      print('Error saving photo: $e');
      throw e;
    }
  }

  // Supprimer une photo du stockage local
  static Future<bool> deletePhoto(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }
}