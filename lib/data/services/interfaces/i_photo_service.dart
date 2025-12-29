import 'dart:io';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/photo_model.dart';
import '../../models/ocr_result.dart';

abstract class IPhotoService {
  // Permissions
  Future<bool> requestPermissions();
  Future<bool> hasPermissions();

  // Web
  Future<List<XFile>> pickImagesFromWeb();
  
  // Local Media
  Future<List<AssetEntity>> getLatestScreenshots({int count = 50});
  Future<List<PhotoModel>> processNewScreenshots(String userId, {bool forceReprocess = false, List<String>? customCategories});
  Future<Uint8List?> generateThumbnail(String localPath);
  
  // Directory & Files
  Future<String> getFolderLocationInfo();
  Future<void> createAllCategoryFolders(String userId);
  Future<String> getCategoryFolderPath(String category, String userId); // Added based on context
  
  // Processing
  Future<OCRResult> processImageBytes(Uint8List bytes, String fileName);
  Future<OCRResult> processImage(File file);
  
  // Photo Operations (delegated or direct)
  Future<String> createPhoto(PhotoModel photo);
  Future<void> updateAlbumPhotoCount(String albumId);
  Future<void> movePhotoToAlbum(String photoId, String newAlbumId);
  Future<void> togglePhotoFavorite(String photoId);
  Future<void> deletePhoto(String photoId);
  Future<List<PhotoModel>> searchPhotos(String userId, String query);
  
  // Helpers
  Future<String> getOrCreateAlbumForCategory(String userId, String category);
}
