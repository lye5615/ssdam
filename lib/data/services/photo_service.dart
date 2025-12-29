import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../../core/constants/app_constants.dart';
import '../models/reminder_model.dart';
import '../models/ocr_result.dart';
import 'firestore_service.dart';
import 'gemini_service.dart';
import 'interfaces/i_photo_service.dart';

class FirebasePhotoService implements IPhotoService {
  // Use FirebaseFirestoreService (will be renamed shortly)
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final GeminiService _geminiService = GeminiService();

  @override
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return true;
    }
    
    try {
      print('🔐 권한 요청 시작...');
      
      final photoPermission = await PhotoManager.requestPermissionExtend();
      print('📸 PhotoManager 권한 요청 결과: ${photoPermission.isAuth}');
      
      if (photoPermission.isAuth) {
        print('✅ PhotoManager 권한으로 충분합니다.');
        return true;
      }
      
      final photosPermission = await Permission.photos.request();
      print('📷 Permission.photos 요청 결과: $photosPermission');
      
      if (photosPermission == PermissionStatus.permanentlyDenied) {
        print('⚠️ 권한이 영구적으로 거부되었습니다. 설정에서 수동으로 허용해야 합니다.');
        return false;
      }
      
      final isAuthorized = photoPermission.isAuth || 
                          (photosPermission == PermissionStatus.granted || 
                           photosPermission == PermissionStatus.limited);
      
      print('✅ 최종 권한 요청 결과: $isAuthorized');
      return isAuthorized;
    } catch (e) {
      print('❌ 권한 요청 오류: $e');
      return false;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    if (kIsWeb) {
      return true;
    }
    
    try {
      print('🔐 권한 상태 확인 중...');
      
      final photoPermission = await PhotoManager.requestPermissionExtend();
      print('📸 PhotoManager 권한 상태: ${photoPermission.isAuth}');
      
      if (photoPermission.isAuth) {
        print('✅ PhotoManager 권한으로 충분합니다.');
        return true;
      }
      
      final permissionStatus = await Permission.photos.status;
      print('📷 Permission.photos 상태: $permissionStatus');
      
      final isAuthorized = photoPermission.isAuth || 
                          (permissionStatus == PermissionStatus.granted || 
                           permissionStatus == PermissionStatus.limited);
      
      print('✅ 최종 권한 상태: $isAuthorized');
      return isAuthorized;
    } catch (e) {
      print('❌ 권한 확인 오류: $e');
      return false;
    }
  }

  @override
  Future<List<XFile>> pickImagesFromWeb() async {
    if (!kIsWeb) {
      throw Exception('이 메서드는 웹에서만 사용할 수 있습니다.');
    }
    
    print('📸 ImagePicker 초기화 중...');
    final ImagePicker picker = ImagePicker();
    
    print('🖼️ 다중 이미지 선택 요청 중...');
    final List<XFile> images = await picker.pickMultiImage();
    print('📁 선택된 이미지 수: ${images.length}');
    
    if (images.isEmpty) {
      print('❌ 사용자가 이미지를 선택하지 않았습니다.');
      return [];
    }
    
    print('✅ ${images.length}개 이미지 선택 완료');
    return images;
  }

  @override
  Future<List<AssetEntity>> getLatestScreenshots({int count = 50}) async {
    if (kIsWeb) {
      return [];
    }
    
    final hasPermission = await hasPermissions();
    if (!hasPermission) {
      print('❌ 갤러리 접근 권한이 없습니다.');
      throw Exception('갤러리 접근 권한이 필요합니다.');
    }

    print('📸 갤러리 접근 권한 확인 완료');

    try {
      final allAlbums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: false,
      );
      
      print('📁 전체 앨범 수: ${allAlbums.length}');
      
      AssetPathEntity? screenshotAlbum;
      for (final album in allAlbums) {
        final albumName = album.name.toLowerCase();
        print('📁 앨범 확인: $albumName');
        if (albumName.contains('screenshot') || 
            albumName.contains('스크린샷') ||
            albumName.contains('screen') ||
            albumName.contains('capture')) {
          screenshotAlbum = album;
          print('📷 스크린샷 앨범 발견: ${album.name}');
          break;
        }
      }
      
      if (screenshotAlbum != null) {
        final screenshotAssets = await screenshotAlbum.getAssetListRange(
          start: 0,
          end: count,
        );
        print('📷 스크린샷 ${screenshotAssets.length}개 로드 완료');
        return screenshotAssets;
      }
      
      print('⚠️ 스크린샷 앨범을 찾을 수 없어 전체 사진에서 스크린샷을 필터링합니다.');
      final allPhotos = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );
      
      if (allPhotos.isNotEmpty) {
        final allAssets = await allPhotos.first.getAssetListRange(
          start: 0,
          end: count * 3,
        );
        
        final screenshots = <AssetEntity>[];
        for (final asset in allAssets) {
          final fileName = asset.title ?? '';
          final filePath = asset.relativePath ?? '';
          
          if (fileName.toLowerCase().contains('screenshot') ||
              fileName.toLowerCase().contains('스크린샷') ||
              fileName.toLowerCase().contains('screen') ||
              fileName.toLowerCase().contains('capture') ||
              filePath.toLowerCase().contains('screenshot') ||
              filePath.toLowerCase().contains('스크린샷') ||
              filePath.toLowerCase().contains('screen') ||
              filePath.toLowerCase().contains('capture')) {
            screenshots.add(asset);
            print('📷 스크린샷 발견: $fileName (경로: $filePath)');
            if (screenshots.length >= count) break;
          }
        }
        
        print('📷 필터링된 스크린샷 ${screenshots.length}개 로드 완료');
        return screenshots;
      }
      
      print('⚠️ 사진이 없습니다.');
      return [];
    } catch (e) {
      print('❌ 사진 로드 실패: $e');
      throw Exception('사진 로드 실패: $e');
    }
  }

  @override
  Future<List<PhotoModel>> processNewScreenshots(String userId, {bool forceReprocess = false, List<String>? customCategories}) async {
    final screenshots = await getLatestScreenshots();
    final processedPhotos = <PhotoModel>[];

    Set<String> existingAssetIds = {};
    Set<String> processedInThisRun = {};
    
    if (!forceReprocess) {
      final existingPhotos = await _firestoreService.getUserPhotos(userId, limit: 100);
      existingAssetIds = existingPhotos
          .where((p) => p.assetEntityId != null)
          .map((p) => p.assetEntityId!)
          .toSet();
    }

    print('📊 기존 처리된 사진 수: ${forceReprocess ? 0 : existingAssetIds.length}');
    print('📊 기존 AssetEntity ID 수: ${existingAssetIds.length}');
    print('📊 현재 스크린샷 수: ${screenshots.length}');
    print('🔄 강제 재처리 모드: $forceReprocess');
    if (customCategories != null) {
      print('🏷️ 사용자 정의 카테고리 ${customCategories.length}개 사용');
    }

    for (final screenshot in screenshots) {
      try {
        final file = await screenshot.file;
        if (file == null) continue;

        if (processedInThisRun.contains(screenshot.id)) {
          print('⏭️ 이번 실행에서 이미 처리된 스크린샷 건너뛰기: ${screenshot.id}');
          continue;
        }

        if (!forceReprocess && existingAssetIds.contains(screenshot.id)) {
          print('⏭️ 이미 처리된 스크린샷 건너뛰기: ${screenshot.id}');
          continue;
        }

        processedInThisRun.add(screenshot.id);

        print('🔄 새 스크린샷 처리 시작: ${screenshot.id}');

        final ocrResult = await _geminiService.processImage(file, customCategories: customCategories);
        
        Map<String, dynamic>? productSearch;
        if (ocrResult.category == '제품' || ocrResult.category == '옷') {
          try {
            print('🛍️ 제품 검색 트리거: 카테고리=${ocrResult.category}');
            productSearch = await _geminiService.extractProductInfoFromFile(file);
            final linkCount = (productSearch['links'] is Map) ? (productSearch['links'] as Map).length : 0;
            print('🛍️ 제품 검색 완료: 링크 ${linkCount}개');
          } catch (e) {
            print('❌ 제품 검색 실패: $e');
          }
        }
        
        final movedFilePath = await _moveFileToCategoryFolder(file, ocrResult.category, userId);
        
        final photoModel = PhotoModel(
          id: '',
          localPath: movedFilePath,
          fileName: path.basename(movedFilePath),
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
            'original_path': file.path,
            'reasoning': ocrResult.reasoning,
            if (productSearch != null) 'product_search': productSearch,
          },
          tags: ocrResult.tags,
          assetEntityId: screenshot.id,
        );

        PhotoModel savedPhoto;
        if (forceReprocess) {
          final existingPhotos = await _firestoreService.getUserPhotos(userId, limit: 100);
          final existingPhoto = existingPhotos.firstWhere(
            (p) => p.assetEntityId == screenshot.id,
            orElse: () => PhotoModel.empty(),
          );
          
          if (existingPhoto.id.isNotEmpty) {
            final updatedPhoto = existingPhoto.copyWith(
              localPath: movedFilePath,
              fileName: path.basename(movedFilePath),
              category: ocrResult.category,
              ocrText: ocrResult.text,
              albumId: await getOrCreateAlbumForCategory(userId, ocrResult.category),
              updatedAt: DateTime.now(),
              metadata: {
                ...existingPhoto.metadata,
                'confidence': ocrResult.confidence,
                'processing_version': '1.0',
                'original_path': file.path,
                'reasoning': ocrResult.reasoning,
                'reclassified_at': DateTime.now().toIso8601String(),
              },
              tags: ocrResult.tags,
            );
            
            await _firestoreService.updatePhoto(updatedPhoto);
            savedPhoto = updatedPhoto;
            print('🔄 기존 사진 업데이트: ${savedPhoto.fileName} → ${ocrResult.category} 폴더');
          } else {
            final photoId = await _firestoreService.createPhoto(photoModel);
            savedPhoto = photoModel.copyWith(id: photoId);
            print('✅ 새 사진 생성: ${savedPhoto.fileName} → ${ocrResult.category} 폴더');
          }
        } else {
          final photoId = await _firestoreService.createPhoto(photoModel);
          savedPhoto = photoModel.copyWith(id: photoId);
          print('✅ 사진 처리 완료: ${savedPhoto.fileName} → ${ocrResult.category} 폴더');
        }
        
        processedPhotos.add(savedPhoto);
        
        await _firestoreService.updateAlbumPhotoCount(savedPhoto.albumId);
        
        print('📁 저장 위치: $movedFilePath');

        try {
          final deadlineResult = await _geminiService.extractDeadlineInfoFromFile(file);
          if (deadlineResult['has_deadline'] == true &&
              deadlineResult['notifications'] is List) {
            final List notifications = deadlineResult['notifications'];
            print('🔔 기한 알림 생성 시작: ${notifications.length}개');
            for (final n in notifications) {
              try {
                final reminderDate = DateTime.parse(n as String);
                final reminder = ReminderModel(
                  id: '',
                  photoId: savedPhoto.id,
                  userId: userId,
                  title: '기한 알림: ${deadlineResult['deadline']}',
                  description: '스크린샷 기반 자동 생성 알림',
                  reminderDate: reminderDate,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  isCompleted: false,
                  isNotified: false,
                  type: ReminderType.deadline,
                  metadata: {
                    'photoFileName': savedPhoto.fileName,
                    'album': deadlineResult['album'],
                    'deadline': deadlineResult['deadline'],
                  },
                );
                final reminderId = await _firestoreService.createReminder(reminder);
                print('🔔 알림 생성 완료: $reminderId @ ${reminder.reminderDate.toIso8601String()}');
              } catch (e) {
                print('⚠️ 알림 생성 실패: $e');
              }
            }
          } else {
            print('ℹ️ 기한 정보 없음 또는 알림 0개');
          }
        } catch (e) {
          print('❌ 기한 정보 처리 실패: $e');
        }
        
      } catch (e) {
        print('Error processing screenshot: $e');
        continue;
      }
    }

    return processedPhotos;
  }

  @override
  Future<String> getOrCreateAlbumForCategory(String userId, String category) async {
    final albums = await _firestoreService.getUserAlbums(userId);
    
    AlbumModel? existingAlbum;
    try {
      existingAlbum = albums.firstWhere((album) => album.name == category);
    } catch (e) {
      existingAlbum = null;
    }
    
    if (existingAlbum != null) {
      return existingAlbum.id;
    }

    final categoryIndex = AppConstants.defaultCategories.indexOf(category);
    final colorCode = categoryIndex >= 0 && categoryIndex < AppConstants.defaultCategories.length
        ? '#${(0xFF000000 | (categoryIndex * 0x123456)).toRadixString(16).substring(2)}'
        : '#6B73FF';

    final newAlbum = AlbumModel(
      id: '',
      name: category,
      description: '$category 관련 스크린샷',
      iconPath: _getCategoryIcon(category),
      colorCode: colorCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
      isDefault: AppConstants.defaultCategories.contains(category),
    );

    return await _firestoreService.createAlbum(newAlbum);
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case '정보/참고용':
        return '📄';
      case '대화/메시지':
        return '💬';
      case '학습/업무 메모':
        return '📝';
      case '재미/밈/감정':
        return '😄';
      case '일정/예약':
        return '📅';
      case '증빙/거래':
        return '💳';
      case '옷':
        return '👕';
      case '제품':
        return '📦';
      default:
        return '📷';
    }
  }

  @override
  Future<void> movePhotoToAlbum(String photoId, String newAlbumId) async {
    final photoDoc = await _firestoreService.firestore
        .collection(AppConstants.photosCollection)
        .doc(photoId)
        .get();
    
    if (!photoDoc.exists) return;
    
    final photo = PhotoModel.fromJson({...photoDoc.data()!, 'id': photoId});
    final oldAlbumId = photo.albumId;
    
    final updatedPhoto = photo.copyWith(
      albumId: newAlbumId,
      updatedAt: DateTime.now(),
    );
    
    await _firestoreService.updatePhoto(updatedPhoto);
    
    await _firestoreService.updateAlbumPhotoCount(oldAlbumId);
    await _firestoreService.updateAlbumPhotoCount(newAlbumId);
  }

  @override
  Future<void> togglePhotoFavorite(String photoId) async {
    final photoDoc = await _firestoreService.firestore
        .collection(AppConstants.photosCollection)
        .doc(photoId)
        .get();
    
    if (!photoDoc.exists) return;
    
    final photo = PhotoModel.fromJson({...photoDoc.data()!, 'id': photoId});
    final updatedPhoto = photo.copyWith(
      isFavorite: !photo.isFavorite,
      updatedAt: DateTime.now(),
    );
    
    await _firestoreService.updatePhoto(updatedPhoto);
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    final photoDoc = await _firestoreService.firestore
        .collection(AppConstants.photosCollection)
        .doc(photoId)
        .get();
    
    if (!photoDoc.exists) return;
    
    final photo = PhotoModel.fromJson({...photoDoc.data()!, 'id': photoId});
    await _firestoreService.deletePhoto(photoId);
    
    await _firestoreService.updateAlbumPhotoCount(photo.albumId);
  }

  @override
  Future<Uint8List?> generateThumbnail(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final assets = await PhotoManager.getAssetListRange(
        start: 0,
        end: 1,
      );
      
      for (final asset in assets) {
        final assetFile = await asset.file;
        if (assetFile?.path == localPath) {
          return await asset.thumbnailData;
        }
      }
      
      return null;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  @override
  Future<List<PhotoModel>> searchPhotos(String userId, String query) async {
    final allPhotos = await _firestoreService.getUserPhotos(userId);
    
    return allPhotos.where((photo) {
      final ocrText = photo.ocrText?.toLowerCase() ?? '';
      final fileName = photo.fileName.toLowerCase();
      final category = photo.category.toLowerCase();
      final tags = photo.tags.join(' ').toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return ocrText.contains(searchQuery) ||
             fileName.contains(searchQuery) ||
             category.contains(searchQuery) ||
             tags.contains(searchQuery);
    }).toList();
  }

  Future<String> _moveFileToCategoryFolder(File originalFile, String category, String userId) async {
    try {
      print('📁 파일 이동 시작: ${originalFile.path} → $category 폴더');
      
      String targetDir;
      
      if (Platform.isIOS) {
        return await _saveToPhotosAlbum(originalFile, category);
      } else if (Platform.isAndroid) {
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            targetDir = path.join(downloadsDir.path, 'FinalCapture', category);
          } else {
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              targetDir = path.join(externalDir.path, '..', 'Download', 'FinalCapture', category);
              targetDir = path.normalize(targetDir);
            } else {
              throw Exception('외부 저장소 접근 불가');
            }
          }
        } catch (e) {
          print('⚠️ 외부 저장소 접근 실패, 앱 폴더 사용: $e');
          final appDir = await getApplicationDocumentsDirectory();
          targetDir = path.join(appDir.path, 'FinalCapture', 'Photos', category);
        }
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        targetDir = path.join(appDir.path, 'FinalCapture', 'Photos', category);
      }
      
      final categoryDir = Directory(targetDir);
      
      if (!await categoryDir.exists()) {
        await categoryDir.create(recursive: true);
        print('📂 카테고리 폴더 생성: ${categoryDir.path}');
      }
      
      final originalFileName = path.basename(originalFile.path);
      final fileExtension = path.extension(originalFileName);
      final fileNameWithoutExt = path.basenameWithoutExtension(originalFileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${fileNameWithoutExt}_$timestamp$fileExtension';
      
      final newFilePath = path.join(categoryDir.path, newFileName);
      
      await originalFile.copy(newFilePath);
      print('📋 파일 복사 완료: $newFilePath');
      
      try {
        await originalFile.delete();
        print('🗑️ 원본 파일 삭제: ${originalFile.path}');
      } catch (e) {
        print('⚠️ 원본 파일 삭제 실패 (무시): $e');
      }
      
      return newFilePath;
    } catch (e) {
      print('❌ 파일 이동 실패: $e');
      return originalFile.path;
    }
  }

  Future<String> _saveToPhotosAlbum(File file, String category) async {
    try {
      print('📱 iOS Photos 앨범에 저장 중...');
      
      final result = await PhotoManager.editor.saveImage(
        await file.readAsBytes(),
        title: 'FinalCapture_${category}_${DateTime.now().millisecondsSinceEpoch}',
        filename: 'FinalCapture_${category}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      print('✅ Photos 앨범에 저장 완료: ${result?.id}');
      return file.path;
    } catch (e) {
      print('❌ Photos 앨범 저장 실패: $e');
      return file.path;
    }
  }

  @override
  Future<String> getCategoryFolderPath(String category, String userId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'FinalCapture', 'Photos', category);
  }

  @override
  Future<void> createAllCategoryFolders(String userId) async {
    try {
      String baseDir;
      
      if (Platform.isIOS) {
        print('📱 iOS: Photos 앨범에 저장됩니다');
        return;
      } else if (Platform.isAndroid) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          baseDir = path.join(downloadsDir.path, 'FinalCapture');
        } else {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            baseDir = path.join(externalDir.path, '..', 'Download', 'FinalCapture');
            baseDir = path.normalize(baseDir);
          } else {
            throw Exception('외부 저장소 접근 불가');
          }
        }
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        baseDir = path.join(appDir.path, 'FinalCapture', 'Photos');
      }
      
      final baseDirectory = Directory(baseDir);
      
      if (!await baseDirectory.exists()) {
        await baseDirectory.create(recursive: true);
        print('📂 기본 폴더 생성: ${baseDirectory.path}');
      }
      
      for (final category in AppConstants.defaultCategories) {
        final categoryDir = Directory(path.join(baseDir, category));
        if (!await categoryDir.exists()) {
          await categoryDir.create(recursive: true);
          print('📂 카테고리 폴더 생성: ${categoryDir.path}');
        }
      }
      
      print('📁 사용자 접근 가능한 폴더 위치: $baseDir');
    } catch (e) {
      print('❌ 카테고리 폴더 생성 실패: $e');
    }
  }

  @override
  Future<String> getFolderLocationInfo() async {
    if (Platform.isIOS) {
      return 'iOS Photos 앨범에 저장됩니다. Photos 앱에서 확인하세요.';
    } else if (Platform.isAndroid) {
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          return 'Android Downloads/FinalCapture 폴더에 저장됩니다.\n경로: ${downloadsDir.path}/FinalCapture';
        } else {
          return 'Android Downloads 폴더에 저장됩니다.';
        }
      } catch (e) {
        return 'Android Downloads 폴더에 저장됩니다.';
      }
    } else {
      return '앱 전용 폴더에 저장됩니다.';
    }
  }

  // From Extension
  @override
  Future<OCRResult> processImage(File file) async {
    return await _geminiService.processImage(file);
  }
  
  @override
  Future<OCRResult> processImageBytes(Uint8List bytes, String fileName) async {
    return await _geminiService.processImageBytes(bytes, fileName);
  }
  
  @override
  Future<String> createPhoto(PhotoModel photo) async {
    return await _firestoreService.createPhoto(photo);
  }
  
  @override
  Future<void> updateAlbumPhotoCount(String albumId) async {
    await _firestoreService.updateAlbumPhotoCount(albumId);
  }
}