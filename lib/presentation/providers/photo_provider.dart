import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:typed_data';
import '../../data/models/photo_model.dart';
import '../../data/models/album_model.dart';
import '../../data/models/ocr_result.dart';
import '../../data/services/interfaces/i_photo_service.dart';
import '../../data/services/interfaces/i_firestore_service.dart';
import '../../core/di/service_locator.dart';

class PhotoProvider extends ChangeNotifier {
  IPhotoService get _photoService => ServiceLocator.photoService;
  IFirestoreService get _firestoreService => ServiceLocator.firestoreService;
  
  List<PhotoModel> _photos = [];
  List<PhotoModel> _recentPhotos = [];
  List<PhotoModel> _favoritePhotos = [];
  List<AssetEntity> _latestScreenshots = [];
  final List<AssetEntity> _favoriteScreenshots = []; // 즐겨찾기된 스크린샷들
  
  // 웹에서 이미지 캐시 (메모리 저장)
  final Map<String, Uint8List> _webImageCache = {};
  
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _hasPermissions = false;

  // Getters
  List<PhotoModel> get photos => _photos;
  List<PhotoModel> get recentPhotos => _recentPhotos;
  List<PhotoModel> get favoritePhotos => _favoritePhotos;
  List<AssetEntity> get latestScreenshots => _latestScreenshots;
  List<AssetEntity> get favoriteScreenshots => _favoriteScreenshots;
  
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasPermissions => _hasPermissions;
  
  // 웹 이미지 캐시 getter
  Uint8List? getWebImageBytes(String photoId) => _webImageCache[photoId];

  // 권한 확인 및 요청
  Future<bool> requestPermissions() async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔐 권한 요청 시작...');
      _hasPermissions = await _photoService.requestPermissions();
      
      if (!_hasPermissions) {
        _errorMessage = '갤러리 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.';
        print('❌ 권한 요청 실패: $_errorMessage');
      } else {
        print('✅ 권한 요청 성공');
      }
      
      return _hasPermissions;
    } catch (e) {
      _errorMessage = '권한 요청 실패: $e';
      print('❌ 권한 요청 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 권한 상태 확인
  Future<void> checkPermissions() async {
    try {
      print('🔐 PhotoProvider에서 권한 상태 확인 중...');
      _hasPermissions = await _photoService.hasPermissions();
      print('📱 PhotoProvider 권한 상태: $_hasPermissions');
    } catch (e) {
      _errorMessage = '권한 확인 실패: $e';
      print('❌ 권한 확인 실패: $e');
      _hasPermissions = false;
    }
    notifyListeners();
  }

  // 최신 스크린샷 로드
  Future<void> loadLatestScreenshots() async {
    if (!_hasPermissions) {
      print('🔐 권한이 없어 권한 확인 중...');
      await checkPermissions();
      if (!_hasPermissions) {
        print('❌ 권한이 없어 스크린샷을 로드할 수 없습니다.');
        return;
      }
    }

    try {
      _setLoading(true);
      _clearError();
      
      print('📸 최신 스크린샷 로드 시작...');
      _latestScreenshots = await _photoService.getLatestScreenshots();
      print('✅ 스크린샷 로드 완료: ${_latestScreenshots.length}개');
      
    } catch (e) {
      _errorMessage = '스크린샷 로드 실패: $e';
      print('❌ 스크린샷 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 갤러리 변화 감지 시작
  // 갤러리 변화 감지 기능 제거 (사용자 요청: 수동 불러오기만 사용)
  // void startGalleryChangeListener() { ... }
  // void stopGalleryChangeListener() { ... }



  // 웹에서 사진 선택 및 처리
  Future<List<PhotoModel>> pickAndProcessImages(String userId) async {
    if (!kIsWeb) {
      _errorMessage = '이 기능은 웹에서만 사용할 수 있습니다.';
      return [];
    }

    try {
      _setProcessing(true);
      _clearError();
      
      print('🔄 웹에서 사진 선택 시작...');
      
      // 웹에서 사진 선택
      final selectedImages = await _photoService.pickImagesFromWeb();
      print('📁 선택된 이미지 수: ${selectedImages.length}');
      
      if (selectedImages.isEmpty) {
        print('❌ 선택된 이미지가 없습니다.');
        return [];
      }
      
      final processedPhotos = <PhotoModel>[];
      
      for (int i = 0; i < selectedImages.length; i++) {
        final xFile = selectedImages[i];
        print('🖼️ 이미지 ${i + 1}/${selectedImages.length} 처리 중: ${xFile.name}');
        
        try {
          // 웹에서는 XFile을 직접 사용하여 이미지 처리
          print('🤖 OCR 처리 시작...');
          final ocrResult = await _processWebImage(xFile);
          print('✅ OCR 완료 - 카테고리: ${ocrResult.category}, 신뢰도: ${ocrResult.confidence}');
          
          // 웹에서도 카테고리별 폴더로 파일 이동 (참고: mock/real impl detail)
          // Since _moveWebFileToCategoryFolder is specific to provider logic (using XFile), we keep it here but it's risky if it depends on FS.
          // However, XFile is platform agnostic (mostly).
          
          // Wait, _moveWebFileToCategoryFolder was purely provider logic in original code?
          // I removed it from Provider but didn't put it in Interface because it takes XFile.
          
          final movedFilePath = await _moveWebFileToCategoryFolder(xFile, ocrResult.category, userId);
          
          // PhotoModel 생성 (이동된 파일 경로 사용)
          final photoModel = PhotoModel(
            id: '', // Firestore에서 생성됨
            localPath: movedFilePath,
            fileName: xFile.name,
            captureDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: userId,
            albumId: await _photoService.getOrCreateAlbumForCategory(userId, ocrResult.category),
            category: ocrResult.category,
            ocrText: ocrResult.text,
            metadata: {
              'confidence': ocrResult.confidence,
              'processing_version': '1.0',
              'source': 'web_upload',
              'original_path': xFile.path,
              'reasoning': ocrResult.reasoning,
              // 웹에서는 바이트 데이터를 저장하지 않음 (Firestore 문서 크기 제한)
              'web_image_size': kIsWeb ? (await xFile.readAsBytes()).length : null,
            },
            tags: ocrResult.tags,
          );

          print('💾 Firestore에 저장 중...');
          // Firestore에 저장
          final photoId = await _photoService.createPhoto(photoModel);
          final savedPhoto = photoModel.copyWith(id: photoId);
          
          // 웹에서는 XFile 데이터를 메모리에 임시 저장
          if (kIsWeb) {
            _webImageCache[photoId] = await xFile.readAsBytes();
          }
          
          processedPhotos.add(savedPhoto);
          print('✅ 사진 저장 완료: $photoId → ${ocrResult.category} 폴더');
          
          // 앨범 사진 개수 업데이트
          await _photoService.updateAlbumPhotoCount(savedPhoto.albumId);
          
        } catch (e) {
          print('❌ 이미지 처리 오류: $e');
          _errorMessage = '이미지 처리 중 오류 발생: $e';
          continue;
        }
      }
      
      print('🔄 로컬 목록 업데이트 중...');
      // 로컬 목록 업데이트
      _photos.insertAll(0, processedPhotos);
      _recentPhotos.insertAll(0, processedPhotos);
      
      // UI 업데이트를 위해 notifyListeners 호출
      notifyListeners();
      
      print('✅ 총 ${processedPhotos.length}개 사진 처리 완료');
      return processedPhotos;
    } catch (e) {
      print('❌ 사진 처리 실패: $e');
      _errorMessage = '사진 처리 실패: $e';
      return [];
    } finally {
      _setProcessing(false);
    }
  }

  // 새로운 스크린샷 처리
  Future<List<PhotoModel>> processNewScreenshots(String userId, {bool forceReprocess = false}) async {
    if (kIsWeb) {
      // 웹에서는 수동으로 사진을 선택하도록 안내
      _errorMessage = '웹에서는 "사진 업로드" 버튼을 사용해주세요.';
      return [];
    }
    
    if (!_hasPermissions) {
      await checkPermissions();
      if (!_hasPermissions) return [];
    }

    try {
      _setProcessing(true);
      _clearError();
      
      // Get custom categories (albums)
      final albums = await _firestoreService.getUserAlbums(userId);
      final customCategories = albums.map((a) => a.name).toList();
      
      final newPhotos = await _photoService.processNewScreenshots(
        userId, 
        forceReprocess: forceReprocess,
        customCategories: customCategories,
      );
      
      // 로컬 목록 업데이트
      _photos.insertAll(0, newPhotos);
      _recentPhotos.insertAll(0, newPhotos);
      
      return newPhotos;
    } catch (e) {
      _errorMessage = '스크린샷 처리 실패: $e';
      return [];
    } finally {
      _setProcessing(false);
    }
  }

  // 사용자의 모든 사진 로드
  Future<void> loadUserPhotos(String userId) async {
    try {
      print('📸 loadUserPhotos 시작: $userId');
      _setLoading(true);
      _clearError();
      
      print('📸 사용자 사진 로드 시작: $userId');
      
      // Firestore에서 사진 목록 로드
      print('📸 FirestoreService(ServiceLocator) 사용');
      
      _photos = await _firestoreService.getUserPhotos(userId);
      print('📸 Firestore에서 로드된 사진 수: ${_photos.length}');
      
      _recentPhotos = _photos.take(20).toList();
      print('📸 최근 사진 목록 생성 완료: ${_recentPhotos.length}개');
      
      // 카테고리별 사진 수 확인
      final categoryCounts = <String, int>{};
      for (final photo in _photos) {
        categoryCounts[photo.category] = (categoryCounts[photo.category] ?? 0) + 1;
      }
      
      print('📸 카테고리별 사진 수:');
      for (final entry in categoryCounts.entries) {
        print('📸 카테고리 "${entry.key}": ${entry.value}개 사진');
      }
      
      // 웹에서 기존 사진들을 위한 이미지 캐시 초기화
      if (kIsWeb) {
        _initializeWebImageCache();
      }
      
      print('📸 loadUserPhotos 완료');
      
    } catch (e) {
      _errorMessage = '사진 로드 실패: $e';
      print('❌ 사진 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 즐겨찾기 사진 로드
  Future<void> loadFavoritePhotos(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      _favoritePhotos = await _firestoreService.getFavoritePhotos(userId);
      
    } catch (e) {
      _errorMessage = '즐겨찾기 로드 실패: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 사진을 다른 앨범으로 이동
  Future<bool> movePhotoToAlbum(String photoId, String newAlbumId, {String? newCategoryName}) async {
    try {
      _clearError();
      
      await _photoService.movePhotoToAlbum(photoId, newAlbumId);
      
      // 로컬 목록에서 해당 사진 업데이트
      _updatePhotoInLists(photoId, (photo) {
        var updated = photo.copyWith(albumId: newAlbumId);
        if (newCategoryName != null) {
          updated = updated.copyWith(category: newCategoryName);
        }
        return updated;
      });
      
      return true;
    } catch (e) {
      _errorMessage = '사진 이동 실패: $e';
      return false;
    }
  }

  // 사진 즐겨찾기 토글
  Future<bool> togglePhotoFavorite(String photoId) async {
    try {
      _clearError();
      
      await _photoService.togglePhotoFavorite(photoId);
      
      // 로컬 목록에서 해당 사진 업데이트
      _updatePhotoInLists(photoId, (photo) => photo.copyWith(isFavorite: !photo.isFavorite));
      
      return true;
    } catch (e) {
      _errorMessage = '즐겨찾기 토글 실패: $e';
      return false;
    }
  }

  // 사진 삭제
  Future<bool> deletePhoto(String photoId) async {
    try {
      _clearError();
      
      await _photoService.deletePhoto(photoId);
      
      // 로컬 목록에서 제거
      _photos.removeWhere((photo) => photo.id == photoId);
      _recentPhotos.removeWhere((photo) => photo.id == photoId);
      _favoritePhotos.removeWhere((photo) => photo.id == photoId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '사진 삭제 실패: $e';
      return false;
    }
  }

  // 사진 검색
  Future<List<PhotoModel>> searchPhotos(String userId, String query) async {
    if (query.trim().isEmpty) return [];

    try {
      _clearError();
      
      return await _photoService.searchPhotos(userId, query);
    } catch (e) {
      _errorMessage = '검색 실패: $e';
      return [];
    }
  }

  // 앨범별 사진 로드
  Future<List<PhotoModel>> loadAlbumPhotos(String albumId, String userId) async {
    try {
      _clearError();
      
      return await _firestoreService.getAlbumPhotos(albumId, userId);
    } catch (e) {
      _errorMessage = '앨범 사진 로드 실패: $e';
      return [];
    }
  }

  // 웹에서 이미지 처리 (XFile 사용) - Internal helper
  Future<OCRResult> _processWebImage(XFile xFile) async {
    try {
      final bytes = await xFile.readAsBytes();
      print('📊 이미지 크기: ${bytes.length} bytes');
      
      // Delegate to service
      final ocrResult = await _photoService.processImageBytes(bytes, xFile.name);
      
      return ocrResult;
    } catch (e) {
      print('❌ 웹 이미지 처리 오류: $e');
      return OCRResult(
        text: '',
        category: '정보/참고용',
        confidence: 0.5,
        tags: ['웹업로드'],
        reasoning: '웹 이미지 처리 실패: $e',
      );
    }
  }

  // 웹에서 파일을 카테고리별 폴더로 이동 (Internal helper)
  Future<String> _moveWebFileToCategoryFolder(XFile xFile, String category, String userId) async {
    try {
      print('📁 웹 파일 이동(Mock) 시작: ${xFile.name} → $category 폴더');
      return 'web_download/${category}_${DateTime.now().millisecondsSinceEpoch}_${xFile.name}';
    } catch (e) {
      print('❌ 웹 파일 이동 실패: $e');
      return xFile.path;
    }
  }

  // Helper methods (unchanged)
  void _updatePhotoInLists(String photoId, PhotoModel Function(PhotoModel) updater) {
    // _photos 업데이트
    final photoIndex = _photos.indexWhere((photo) => photo.id == photoId);
    if (photoIndex != -1) {
      _photos[photoIndex] = updater(_photos[photoIndex]);
    }

    // _recentPhotos 업데이트
    final recentIndex = _recentPhotos.indexWhere((photo) => photo.id == photoId);
    if (recentIndex != -1) {
      _recentPhotos[recentIndex] = updater(_recentPhotos[recentIndex]);
    }

    // _favoritePhotos 업데이트
    final favoriteIndex = _favoritePhotos.indexWhere((photo) => photo.id == photoId);
    if (favoriteIndex != -1) {
      final updatedPhoto = updater(_favoritePhotos[favoriteIndex]);
      if (updatedPhoto.isFavorite) {
        _favoritePhotos[favoriteIndex] = updatedPhoto;
      } else {
        _favoritePhotos.removeAt(favoriteIndex);
      }
    } else {
      // 즐겨찾기가 추가된 경우
      // _photos에서 찾아야 함 (이미 업데이트된 상태여야 함)
      // 하지만 여기서는 updater를 사용해 새 상태를 만들어야 함
      final mainPhotoIndex = _photos.indexWhere((photo) => photo.id == photoId);
      if (mainPhotoIndex != -1) {
        // 이미 _photos는 위에서 업데이트됨
        final updatedPhoto = _photos[mainPhotoIndex];
        if (updatedPhoto.isFavorite) {
          _favoritePhotos.insert(0, updatedPhoto);
        }
      } 
      // 만약 _photos에 없다면 (예: 부분 로드), _recentPhotos 확인
      else {
          final recentIndex = _recentPhotos.indexWhere((photo) => photo.id == photoId);
          if (recentIndex != -1) {
             final updatedPhoto = _recentPhotos[recentIndex];
             if (updatedPhoto.isFavorite) {
                _favoritePhotos.insert(0, updatedPhoto);
             }
          }
      }
    }

    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // 수동 분류 시작
  Future<void> startClassification(String userId) async {
    try {
      _setProcessing(true);
      _clearError();
      print('🤖 수동 분류 시작...');
      await createDefaultAlbums(userId);
      await loadLatestScreenshots();
      
      print('📸 모든 스크린샷 분류 시작...');
      final processedPhotos = await _photoService.processNewScreenshots(userId, forceReprocess: true);
      
      if (processedPhotos.isNotEmpty) {
        print('✅ ${processedPhotos.length}개 스크린샷 분류 완료');
      } else {
        print('ℹ️ 분류할 스크린샷이 없습니다');
      }
      
      await loadUserPhotos(userId);
      await loadFavoritePhotos(userId);
      
      print('✅ 수동 분류 완료');
    } catch (e) {
      _errorMessage = '분류 실패: $e';
      print('❌ 분류 오류: $e');
    } finally {
      _setProcessing(false);
    }
  }

  // 앱 시작 시 초기화
  Future<void> initialize(String userId) async {
    await checkPermissions();
    if (_hasPermissions) {
      await Future.wait([
        loadUserPhotos(userId),
        loadFavoritePhotos(userId),
        loadLatestScreenshots(),
      ]);
      // await startGalleryChangeListener(); // Auto-sync disabled
    }
  }

  // 수동 새로고침
  Future<void> refresh(String userId, {bool forceReprocess = false}) async {
    try {
      _setLoading(true);
      _clearError();
      print('🔄 수동 새로고침 시작... (강제 재처리: $forceReprocess)');
      await createDefaultAlbums(userId);
      await loadLatestScreenshots();
      
      print('📸 새 스크린샷 처리 시작...');
      final processedPhotos = await _photoService.processNewScreenshots(userId, forceReprocess: forceReprocess);
      
      if (processedPhotos.isNotEmpty) {
        print('✅ ${processedPhotos.length}개 새 스크린샷 처리 완료');
      } else {
        print('ℹ️ 처리할 새 스크린샷이 없습니다');
      }
      
      await loadUserPhotos(userId);
      await loadFavoritePhotos(userId);
      print('✅ 수동 새로고침 완료');
    } catch (e) {
      _errorMessage = '새로고침 실패: $e';
      print('❌ 새로고침 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 모든 카테고리 폴더 생성
  Future<void> createAllCategoryFolders(String userId) async {
    try {
      await _photoService.createAllCategoryFolders(userId);
    } catch (e) {
      print('카테고리 폴더 생성 실패: $e');
    }
  }

  // 사진 생성
  Future<String> createPhoto(PhotoModel photo) async {
    return await _photoService.createPhoto(photo);
  }

  // AssetEntity 즐겨찾기 토글
  Future<bool> toggleAssetFavorite(AssetEntity asset) async {
    try {
      final isFavorite = _favoriteScreenshots.any((fav) => fav.id == asset.id);
      if (isFavorite) {
        _favoriteScreenshots.removeWhere((fav) => fav.id == asset.id);
      } else {
        _favoriteScreenshots.add(asset);
      }
      notifyListeners();
      return !isFavorite; 
    } catch (e) {
      print('❌ 즐겨찾기 토글 실패: $e');
      return false;
    }
  }

  // AssetEntity가 즐겨찾기인지 확인
  bool isAssetFavorite(AssetEntity asset) {
    return _favoriteScreenshots.any((fav) => fav.id == asset.id);
  }

  // ID로 AssetEntity 찾기
  AssetEntity? findAssetById(String id) {
    if (id.isEmpty) return null;
    try {
      return _latestScreenshots.firstWhere((asset) => asset.id == id);
    } catch (e) {
      return null;
    }
  }

  // 기본 앨범들 생성
  Future<void> createDefaultAlbums(String userId) async {
    try {
      print('📁 기본 앨범 생성 시작: $userId');
      final existingAlbums = await _firestoreService.getUserAlbums(userId);
      
      final defaultCategories = [
        '옷', '제품', '정보/참고용', '일정/예약', '증빙/거래', '재미/밈/감정', '학습/업무 메모', '대화/메시지',
      ];
      
      int createdCount = 0;
      for (int i = 0; i < defaultCategories.length; i++) {
        final category = defaultCategories[i];
        final exists = existingAlbums.any((album) => album.name == category);
        
        if (!exists) {
          final colorCode = '#${(0xFF000000 | (i * 0x123456)).toRadixString(16).substring(2)}';
          final album = AlbumModel(
            id: '', 
            name: category,
            description: '$category 관련 사진들',
            iconPath: _getCategoryIconPath(category),
            userId: userId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            photoCount: 0,
            colorCode: colorCode,
            isDefault: true,
          );
          
          await _firestoreService.createAlbum(album);
          createdCount++;
        }
      }
      print('✅ 기본 앨범 생성 완료: $createdCount개 새로 생성');
    } catch (e) {
      print('❌ 기본 앨범 생성 실패: $e');
    }
  }

  // 카테고리별 아이콘 경로 반환 (Internal)
  // 카테고리별 아이콘 경로 반환 (Internal)
  // 카테고리별 아이콘 경로 반환 (Internal) - 이모지 대신 텍스트(한글) 사용
  String _getCategoryIconPath(String category) {
    // 사용자가 "글자만 넣을 것" 요청 -> 아이콘 대신 카테고리 이름 자체를 반환하거나 약어 반환
    // UI에서 fontSize 조절 필요
    // 여기서는 전체 이름을 반환하고 UI에서 처리
    return category;
  }

  // 폴더 위치 정보 가져오기
  Future<String> getFolderLocationInfo() async {
    try {
      return await _photoService.getFolderLocationInfo();
    } catch (e) {
      return '폴더 위치 정보를 가져올 수 없습니다.';
    }
  }

  // 웹 이미지 캐시 초기화
  void _initializeWebImageCache() {
    print('🔄 웹 이미지 캐시 초기화 중...');
    for (final photo in _photos) {
      if (!_webImageCache.containsKey(photo.id)) {
        // print('📷 기존 사진 캐시 마킹: ${photo.fileName}');
      }
    }
    print('✅ 웹 이미지 캐시 초기화 완료: ${_photos.length}개 사진');
  }

  // ID로 사진 가져오기
  PhotoModel? getPhoto(String id) {
    try {
      return _photos.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // 카테고리의 대표 사진(최신) 반환
  PhotoModel? getCoverPhotoForCategory(String categoryName) {
    try {
      final categoryPhotos = _photos.where((p) => p.category == categoryName).toList();
      if (categoryPhotos.isNotEmpty) {
        // 최신순 정렬 (이미 되어있을 수 있지만 보장)
        categoryPhotos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return categoryPhotos.first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
