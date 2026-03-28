import 'package:flutter/material.dart';
import '../../data/models/album_model.dart';
import '../../data/services/interfaces/i_firestore_service.dart';
import '../../core/di/service_locator.dart';
import '../../core/constants/app_constants.dart';

class AlbumProvider extends ChangeNotifier {
  IFirestoreService get _firestoreService => ServiceLocator.firestoreService;
  
  List<AlbumModel> _albums = [];
  List<AlbumModel> _pinnedAlbums = [];
  List<AlbumModel> _defaultAlbums = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<AlbumModel> get albums => _albums;
  List<AlbumModel> get pinnedAlbums => _pinnedAlbums;
  List<AlbumModel> get defaultAlbums => _defaultAlbums;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 사용자 앨범 로드
  Future<void> loadUserAlbums(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('📁 앨범 로드 시작: $userId');
      _albums = await _firestoreService.getUserAlbums(userId);
      print('📁 로드된 앨범 수: ${_albums.length}');
      
      for (final album in _albums) {
        print('📁 앨범: ${album.name} - 사진 수: ${album.photoCount}');
      }
      
      _categorizeAlbums();
      
    } catch (e) {
      _errorMessage = '앨범 로드 실패: $e';
      print('❌ 앨범 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 앨범 분류 (고정, 기본, 일반)
  void _categorizeAlbums() {
    _pinnedAlbums = _albums.where((album) => album.isPinned).toList();
    _defaultAlbums = _albums.where((album) => album.isDefault).toList();
    notifyListeners();
  }

  // 새 앨범 생성
  Future<bool> createAlbum({
    required String userId,
    required String name,
    String? description,
    required String iconPath,
    required String colorCode,
  }) async {
    try {
      _clearError();
      
      final newAlbum = AlbumModel(
        id: '', // Firestore에서 생성됨
        name: name,
        description: description,
        iconPath: iconPath,
        colorCode: colorCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: userId,
      );

      final albumId = await _firestoreService.createAlbum(newAlbum);
      final createdAlbum = newAlbum.copyWith(id: albumId);
      
      _albums.add(createdAlbum);
      _categorizeAlbums();
      
      return true;
    } catch (e) {
      _errorMessage = '앨범 생성 실패: $e';
      return false;
    }
  }

  // 앨범 업데이트
  Future<bool> updateAlbum(AlbumModel album) async {
    try {
      _clearError();
      
      final updatedAlbum = album.copyWith(updatedAt: DateTime.now());
      await _firestoreService.updateAlbum(updatedAlbum);
      
      // 로컬 목록 업데이트
      final index = _albums.indexWhere((a) => a.id == album.id);
      if (index != -1) {
        _albums[index] = updatedAlbum;
        _categorizeAlbums();
      }
      
      return true;
    } catch (e) {
      _errorMessage = '앨범 업데이트 실패: $e';
      return false;
    }
  }

  Future<bool> deleteAlbum(String albumId) async {
    try {
      _clearError();
      
      final album = _albums.firstWhere((a) => a.id == albumId);
      if (album.isDefault) {
        _errorMessage = '기본 앨범은 삭제할 수 없습니다.';
        return false;
      }
      
      await _firestoreService.deleteAlbum(albumId, album.userId);
      
      // 로컬 목록에서 제거
      _albums.removeWhere((album) => album.id == albumId);
      _categorizeAlbums();
      
      return true;
    } catch (e) {
      _errorMessage = '앨범 삭제 실패: $e';
      return false;
    }
  }

  // 앨범 고정 토글
  Future<bool> toggleAlbumPin(String albumId) async {
    try {
      _clearError();
      
      final albumIndex = _albums.indexWhere((a) => a.id == albumId);
      if (albumIndex == -1) return false;
      
      final album = _albums[albumIndex];
      
      // 고정된 앨범이 3개 이상이면 고정 해제만 가능
      if (!album.isPinned && _pinnedAlbums.length >= 3) {
        _errorMessage = '고정 앨범은 최대 3개까지 가능합니다.';
        return false;
      }
      
      final updatedAlbum = album.copyWith(
        isPinned: !album.isPinned,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.updateAlbum(updatedAlbum);
      
      _albums[albumIndex] = updatedAlbum;
      _categorizeAlbums();
      
      return true;
    } catch (e) {
      _errorMessage = '앨범 고정 토글 실패: $e';
      return false;
    }
  }

  // 앨범 이름 변경
  Future<bool> renameAlbum(String albumId, String newName) async {
    try {
      _clearError();
      
      final albumIndex = _albums.indexWhere((a) => a.id == albumId);
      if (albumIndex == -1) return false;
      
      final album = _albums[albumIndex];
      
      /*
      // User requested to allow renaming even for default categories
      // 기본 앨범 이름 변경 제한
      if (album.isDefault && AppConstants.defaultCategories.contains(album.name)) {
        _errorMessage = '기본 카테고리 앨범의 이름은 변경할 수 없습니다.';
        return false;
      }
      */
      
      final updatedAlbum = album.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.updateAlbum(updatedAlbum);
      
      _albums[albumIndex] = updatedAlbum;
      _categorizeAlbums();
      
      return true;
    } catch (e) {
      _errorMessage = '앨범 이름 변경 실패: $e';
      return false;
    }
  }

  // 앨범 색상 변경
  Future<bool> changeAlbumColor(String albumId, String colorCode) async {
    try {
      _clearError();
      
      final albumIndex = _albums.indexWhere((a) => a.id == albumId);
      if (albumIndex == -1) return false;
      
      final album = _albums[albumIndex];
      final updatedAlbum = album.copyWith(
        colorCode: colorCode,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.updateAlbum(updatedAlbum);
      
      _albums[albumIndex] = updatedAlbum;
      _categorizeAlbums();
      
      return true;
    } catch (e) {
      _errorMessage = '앨범 색상 변경 실패: $e';
      return false;
    }
  }

  // 특정 앨범 가져오기
  AlbumModel? getAlbum(String albumId) {
    try {
      return _albums.firstWhere((album) => album.id == albumId);
    } catch (e) {
      return null;
    }
  }

  // 앨범 이름으로 검색
  AlbumModel? getAlbumByName(String name) {
    try {
      return _albums.firstWhere((album) => album.name == name);
    } catch (e) {
      return null;
    }
  }

  // 기본 앨범들 초기화 (새 사용자용)
  Future<void> initializeDefaultAlbums(String userId) async {
    try {
      _clearError();
      
      // 기존 앨범 이름들 확인
      final existingNames = _albums.map((album) => album.name).toSet();
      
      // 기본 카테고리 앨범들 생성 (중복 체크)
      final defaultAlbums = <AlbumModel>[];
      
      // 카테고리 앨범들만 생성
      for (int i = 0; i < AppConstants.defaultCategories.length; i++) {
        final category = AppConstants.defaultCategories[i];
        
        // 이미 존재하는 앨범인지 확인
        if (!existingNames.contains(category)) {
          defaultAlbums.add(AlbumModel(
            id: '',
            name: category,
            description: '$category 관련 스크린샷',
            iconPath: _getCategoryIcon(category),
            colorCode: _getCategoryColor(i),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: userId,
            isDefault: true,
          ));
        }
      }

      // Firestore에 생성 (중복되지 않는 앨범들만)
      for (final album in defaultAlbums) {
        await _firestoreService.createAlbum(album);
      }

      // 다시 로드
      await loadUserAlbums(userId);
      
    } catch (e) {
      _errorMessage = '기본 앨범 초기화 실패: $e';
    }
  }

  // 카테고리별 아이콘
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

  // 카테고리별 색상
  String _getCategoryColor(int index) {
    final colors = [
      '#6B73FF', '#00C851', '#FFBB33', '#FF6B6B',
      '#33B5E5', '#9C27B0', '#FF9800', '#795548',
    ];
    return colors[index % colors.length];
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // 앨범 사진 개수 업데이트
  void updateAlbumPhotoCount(String albumId, int count) {
    final albumIndex = _albums.indexWhere((a) => a.id == albumId);
    if (albumIndex != -1) {
      _albums[albumIndex] = _albums[albumIndex].copyWith(photoCount: count);
      _categorizeAlbums();
    }
  }
}
