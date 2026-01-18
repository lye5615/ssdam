import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../interfaces/i_photo_service.dart';
import '../../models/photo_model.dart';
import '../../models/ocr_result.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/constants/app_constants.dart';
import '../gemini_service.dart';
import '../../../core/constants/secrets.dart';

class MockPhotoService implements IPhotoService {
  // We need to keep track of processed assets for the mock session
  final Set<String> _processedAssetIds = {};
  
  // Optional real Gemini service for Hybrid mode
  final GeminiService _geminiService = GeminiService();

  @override
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    
    try {
      print('🔐 [Mock] 권한 요청 시작...');
      final photoPermission = await PhotoManager.requestPermissionExtend();
      if (photoPermission.isAuth) return true;
      
      final photosPermission = await Permission.photos.request();
      return photoPermission.isAuth || 
             (photosPermission == PermissionStatus.granted || 
              photosPermission == PermissionStatus.limited);
    } catch (e) {
      print('❌ [Mock] 권한 요청 오류: $e');
      return false;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    if (kIsWeb) return true;
    
    try {
      final photoPermission = await PhotoManager.requestPermissionExtend();
      if (photoPermission.isAuth) return true;
      
      final permissionStatus = await Permission.photos.status;
      return photoPermission.isAuth || 
             (permissionStatus == PermissionStatus.granted || 
              permissionStatus == PermissionStatus.limited);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<XFile>> pickImagesFromWeb() async {
    return []; // Mock empty selection
  }

  @override
  Future<List<AssetEntity>> getLatestScreenshots({int count = 50}) async {
    if (kIsWeb) return [];
    
    if (!await hasPermissions()) {
      print('❌ [Mock] 갤러리 접근 권한 없음');
      return [];
    }

    try {
      final allAlbums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: false,
      );
      
      AssetPathEntity? screenshotAlbum;
      for (final album in allAlbums) {
        final albumName = album.name.toLowerCase();
        if (albumName.contains('screenshot') || 
            albumName.contains('스크린샷') ||
            albumName.contains('screen') ||
            albumName.contains('capture')) {
          screenshotAlbum = album;
          break;
        }
      }
      
      if (screenshotAlbum != null) {
        return await screenshotAlbum.getAssetListRange(start: 0, end: count);
      }
      
      // Fallback to all photos if no screenshot album
      final allPhotos = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
      if (allPhotos.isNotEmpty) {
        final allAssets = await allPhotos.first.getAssetListRange(start: 0, end: count * 3);
        // Simple filter
         final screenshots = <AssetEntity>[];
         for (final asset in allAssets) {
           final title = (asset.title ?? '').toLowerCase();
           if (title.contains('screenshot') || title.contains('스크린샷')) {
             screenshots.add(asset);
             if (screenshots.length >= count) break;
           }
         }
         // If filtering yields too few, just return recent photos for testing purposes in Mock mode
         return screenshots.isNotEmpty ? screenshots : allAssets.sublist(0, count.clamp(0, allAssets.length));
      }
      
      return [];
    } catch (e) {
      print('❌ [Mock] 사진 로드 실패: $e');
      return [];
    }
  }

  @override
  Future<List<PhotoModel>> processNewScreenshots(String userId, {bool forceReprocess = false, List<String>? customCategories}) async {
    final screenshots = await getLatestScreenshots();
    final processedPhotos = <PhotoModel>[];

    print('📊 [Mock] 현재 스크린샷 수: ${screenshots.length}');
    print('📊 [Mock] 기존 처리된 Asset ID 수: ${_processedAssetIds.length}');
    if (customCategories != null) {
      print('🏷️ [Mock] 사용자 정의 카테고리: $customCategories');
    }

    for (final screenshot in screenshots) {
      if (!forceReprocess && _processedAssetIds.contains(screenshot.id)) {
        continue;
      }

      // In Mock mode, we don't actually upload or do heavy OCR.
      // We just create a dummy PhotoModel wrapping the real local file.
      try {
        final file = await screenshot.file;
        if (file == null) continue;

        _processedAssetIds.add(screenshot.id);

        // Check if we can use Real AI
        final useRealAI = geminiApiKey.isNotEmpty;
        OCRResult ocrResult;
        
        if (useRealAI) {
           print('🤖 [Mock] Hybrid Mode: Real Gemini AI Classification...');
           // processImage handles calling Gemini
           try {
             ocrResult = await _geminiService.processImage(file, customCategories: customCategories);
           } catch (e) {
             print('⚠️ [Mock] Real AI failed, falling back to mock: $e');
             ocrResult = _createMockResult(file.path, screenshot.createDateTime);
           }
        } else {
           print('🎲 [Mock] Using Mock Classification (Random)...');
           ocrResult = _createMockResult(file.path, screenshot.createDateTime);
        }

        final photoModel = PhotoModel(
          id: 'mock_photo_${screenshot.id}',
          localPath: file.path,
          fileName: 'screenshot_${screenshot.createDateTime.millisecondsSinceEpoch}.jpg',
          captureDate: screenshot.createDateTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: userId,
          albumId: await getOrCreateAlbumForCategory(userId, ocrResult.category),
          category: ocrResult.category,
          ocrText: ocrResult.text,
          metadata: {
            'confidence': ocrResult.confidence,
            'processing_version': '1.0',
            'reasoning': ocrResult.reasoning,
          },
          tags: ocrResult.tags,
          assetEntityId: screenshot.id,
          isFavorite: false,
        );

        // Save to Mock Firestore
        await ServiceLocator.firestoreService.createPhoto(photoModel);
        await ServiceLocator.firestoreService.updateAlbumPhotoCount(photoModel.albumId);
        
        processedPhotos.add(photoModel);
        print('✅ [Mock] 가짜 처리 완료: ${photoModel.fileName} -> ${ocrResult.category}');
        
      } catch (e) {
        print('❌ [Mock] 처리 실패: $e');
      }
    }

    return processedPhotos;
  }
  
  OCRResult _createMockResult(String filePath, DateTime date) {
    final mockCategory = _determineMockCategory(date);
    return OCRResult(
      text: "Mock OCR Text for ${path.basename(filePath)}",
      category: mockCategory,
      confidence: 0.99,
      tags: ['mock', 'hybrid', mockCategory],
      reasoning: 'Mock Hybrid Processing (Random)',
    );
  }

  String _determineMockCategory(DateTime date) {
    // Deterministic random category
    final categories = AppConstants.defaultCategories;
    return categories[date.millisecondsSinceEpoch % categories.length];
  }

  @override
  Future<OCRResult> processImageBytes(Uint8List bytes, String fileName) async {
    return OCRResult(
      text: "Mock OCR Text",
      category: "정보/참고용",
      confidence: 0.9,
      tags: ["mock", "test"],
      reasoning: "Mock reasoning",
    );
  }

  @override
  Future<OCRResult> processImage(File file) async {
    return OCRResult(
      text: "Mock OCR Text from File",
      category: "정보/참고용",
      confidence: 0.9,
      tags: ["mock", "file"],
      reasoning: "Mock reasoning",
    );
  }

  @override
  Future<String> createPhoto(PhotoModel photo) async {
    return await ServiceLocator.firestoreService.createPhoto(photo);
  }

  @override
  Future<void> updateAlbumPhotoCount(String albumId) async {
    await ServiceLocator.firestoreService.updateAlbumPhotoCount(albumId);
  }

  @override
  Future<void> movePhotoToAlbum(String photoId, String newAlbumId) async {
     // Implement if needed for full mock interaction
  }

  @override
  Future<void> togglePhotoFavorite(String photoId) async {
    // Implement if needed
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    await ServiceLocator.firestoreService.deletePhoto(photoId);
  }

  @override
  Future<List<PhotoModel>> searchPhotos(String userId, String query) async {
    final allPhotos = await ServiceLocator.firestoreService.getUserPhotos(userId);
    
    if (query.trim().isEmpty) {
      return [];
    }
    
    print('🔍 Search Debug (Mock): Query="$query", Total Photos=${allPhotos.length}');
    
    final results = allPhotos.where((photo) {
      // Skip photos that don't have any keyword metadata
      final hasTags = photo.tags.isNotEmpty;
      final hasHints = photo.textHints != null && photo.textHints!.isNotEmpty;
      
      if (!hasTags && !hasHints) {
        print('⏭️  [SKIP] ${photo.fileName} - No tags or hints (unprocessed)');
        return false;
      }
      
      // ONLY search tags and textHints - NOT category or OCR text
      final tags = photo.tags.join(' ').toLowerCase();
      final textHints = photo.textHints?.join(' ').toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      
      final matTags = tags.isNotEmpty && tags.contains(searchQuery);
      final matHints = textHints.isNotEmpty && textHints.contains(searchQuery);
      
      final isMatch = matTags || matHints;
      
      if (isMatch) {
        print('✅ [MATCH] ${photo.fileName}');
        print('   - Matched in: ${matTags ? "TAGS" : ""} ${matHints ? "TEXT_HINTS" : ""}');
        print('   - Tags: ${photo.tags}');
        print('   - Hints: ${photo.textHints}');
      }
      
      return isMatch;
    }).toList();
    
    print('🎯 Search Results (Mock): ${results.length} photos matched query "$query"');
    return results;
  }

  @override
  Future<Uint8List?> generateThumbnail(String localPath) async {
     // Try to generate real thumbnail if possible, or return null
     try {
       final file = File(localPath);
       if (!await file.exists()) return null;
       // We can't easily get AssetEntity from path without scanning, 
       // but for now return null and let UI handle it (Provider might cache)
       return null; 
     } catch (e) {
       return null;
     }
  }

  @override
  Future<String> getFolderLocationInfo() async {
    return "Mock Folder Location (Hybrid)";
  }

  @override
  Future<void> createAllCategoryFolders(String userId) async {}

  @override
  Future<String> getCategoryFolderPath(String category, String userId) async {
    return "/mock/path/$category";
  }

  @override
  Future<String> getOrCreateAlbumForCategory(String userId, String category) async {
    // Delegate to MockFirestoreService to find the album
    final albums = await ServiceLocator.firestoreService.getUserAlbums(userId);
    try {
      return albums.firstWhere((a) => a.name == category).id;
    } catch (e) {
      return 'album_0'; // Fallback
    }
  }
}
