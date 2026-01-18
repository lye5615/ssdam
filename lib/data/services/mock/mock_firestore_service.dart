import 'dart:async';
import '../interfaces/i_firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/album_model.dart';
import '../../models/rule_model.dart';
import '../../models/photo_model.dart';
import '../../models/reminder_model.dart';
import '../../../core/constants/app_constants.dart';

class MockFirestoreService implements IFirestoreService {
  // In-memory storage
  final Map<String, UserModel> _users = {};
  final Map<String, AlbumModel> _albums = {};
  final Map<String, PhotoModel> _photos = {};
  final Map<String, ReminderModel> _reminders = {};

  final _albumsController = StreamController<List<AlbumModel>>.broadcast();
  final _photosController = StreamController<List<PhotoModel>>.broadcast(); 
  final _remindersController = StreamController<List<ReminderModel>>.broadcast();
  // Stream management for specific queries is complex in mock. 
  // We will emit events to listeners when data changes.

  MockFirestoreService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Initial data if needed
    final mockUserId = 'mock_user_123';
    
    // Create Mock User
    _users[mockUserId] = UserModel(
      uid: mockUserId,
      email: 'mock@example.com',
      displayName: 'Mock User',
      photoUrl: '', // Removed network dependency
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
    );

    // Default albums
    final categories = AppConstants.defaultCategories;
    for (var i = 0; i < categories.length; i++) {
      final category = categories[i];
      final id = 'album_$i';
      
      // Assign specific icons/colors based on index or category
      String colorCode = '#CCCCCC';
      // Simple color generation logic from AlbumProvider
      final colors = [
        '#6B73FF', '#00C851', '#FFBB33', '#FF6B6B',
        '#33B5E5', '#9C27B0', '#FF9800', '#795548',
      ];
      colorCode = colors[i % colors.length];

      // Assign specific icons based on category
      String icon = category; // User requested text only
      /*
      switch (category) {
        case '정보/참고용': icon = '📚'; break;
        case '대화/메시지': icon = '💬'; break;
        case '학습/업무 메모': icon = '📝'; break;
        case '재미/밈/감정': icon = '😂'; break;
        case '일정/예약': icon = '📅'; break;
        case '증빙/거래': icon = '🧾'; break;
        case '옷': icon = '👕'; break;
        case '제품': icon = '📦'; break;
      }
      */

      _albums[id] = AlbumModel(
        id: id,
        name: category,
        description: '$category related screenshots',
        iconPath: icon,
        userId: mockUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photoCount: 0, 
        colorCode: colorCode,
        isDefault: true,
      );
    }
    
    // Add Sample Photos - CLEARED GARBAGE DATA
    // Only keeping one welcome photo or none
    // _addSamplePhoto(mockUserId, 'photo_1', 'screenshot_kakao.jpg', '대화/메시지', 'album_7', '예약 확인 부탁드립니다.');
    
    // Update Album Counts
    for (var album in _albums.values) {
       final count = _photos.values.where((p) => p.albumId == album.id).length;
       _albums[album.id] = album.copyWith(photoCount: count);
    }
  }

  // 데이터 초기화 (사용자 요청 시)
  Future<void> clearData() async {
    _users.clear();
    _albums.clear();
    _photos.clear();
    _reminders.clear();
    
    // Re-initialize basic structure
    _initializeMockData();
    
    // Notify listeners
    _albumsController.add([]);
    _photosController.add([]);
    _remindersController.add([]);
  }

  void _addSamplePhoto(String userId, String id, String fileName, String category, String albumId, String ocrText) {
    _photos[id] = PhotoModel(
      id: id,
      localPath: 'assets/mock/$fileName', // UI should handle missing files gracefully or we need to put assets
      fileName: fileName,
      captureDate: DateTime.now().subtract(Duration(days: _photos.length)), // Spread out dates
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
      albumId: albumId,
      category: category,
      ocrText: ocrText,
      metadata: {
        'confidence': 0.95,
        'reasoning': 'Mock classification',
      },
      tags: ['mock', category],
    );
  }

  // User
  @override
  Future<void> createOrUpdateUser(UserModel user) async {
    _users[user.uid] = user;
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    return _users[uid];
  }

  @override
  Future<void> deleteUser(String uid) async {
    _users.remove(uid);
    _albums.removeWhere((key, value) => value.userId == uid);
    _photos.removeWhere((key, value) => value.userId == uid);
    _reminders.removeWhere((key, value) => value.userId == uid);
  }

  // --- Rules ---
  final List<RuleModel> _rules = [];

  @override
  Future<List<RuleModel>> getUserRules(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _rules.where((r) => r.userId == userId).toList(); // Filter by userId
  }

  @override
  Future<String> createRule(String userId, RuleModel rule) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newRule = RuleModel(
      id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
      type: rule.type,
      pattern: rule.pattern,
      categoryId: rule.categoryId,
      categoryName: rule.categoryName,
      weight: rule.weight,
      source: rule.source,
      createdAt: DateTime.now(),
      userId: userId, // Ensure userId is set
    );
    _rules.add(newRule);
    return newRule.id;
  }

  @override
  Future<void> deleteRule(String ruleId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _rules.removeWhere((r) => r.id == ruleId);
  }

  // Album
  @override
  Future<String> createAlbum(AlbumModel album) async {
    final id = album.id.isEmpty ? 'album_${DateTime.now().millisecondsSinceEpoch}' : album.id;
    final newAlbum = album.copyWith(id: id);
    _albums[id] = newAlbum;
    _notifyAlbumStream(album.userId);
    return id;
  }

  @override
  Future<void> updateAlbum(AlbumModel album) async {
    if (_albums.containsKey(album.id)) {
      _albums[album.id] = album;
      _notifyAlbumStream(album.userId);
    }
  }

  @override
  Future<void> deleteAlbum(String albumId) async {
    if (_albums.containsKey(albumId)) {
      final userId = _albums[albumId]!.userId;
      _albums.remove(albumId);
      _photos.removeWhere((key, value) => value.albumId == albumId);
      _notifyAlbumStream(userId);
    }
  }

  @override
  Future<List<AlbumModel>> getUserAlbums(String userId) async {
    return _albums.values.where((a) => a.userId == userId).toList();
  }

  @override
  Stream<List<AlbumModel>> getUserAlbumsStream(String userId) {
    // Return initial data immediately
    Future.microtask(() => _notifyAlbumStream(userId));
    return _albumsController.stream.map((albums) => albums.where((a) => a.userId == userId).toList());
  }
  
  void _notifyAlbumStream(String userId) {
    _albumsController.add(_albums.values.toList());
  }

  @override
  Future<void> updateAlbumPhotoCount(String albumId) async {
    if (_albums.containsKey(albumId)) {
      final count = _photos.values.where((p) => p.albumId == albumId).length;
      final album = _albums[albumId]!;
      _albums[albumId] = album.copyWith(photoCount: count);
      _notifyAlbumStream(album.userId);
    }
  }

  // Photo
  @override
  Future<String> createPhoto(PhotoModel photo) async {
    final id = photo.id.isEmpty ? 'photo_${DateTime.now().millisecondsSinceEpoch}' : photo.id;
    final newPhoto = photo.copyWith(id: id);
    _photos[id] = newPhoto;
    return id;
  }

  @override
  Future<void> updatePhoto(PhotoModel photo) async {
    if (_photos.containsKey(photo.id)) {
      _photos[photo.id] = photo;
    }
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    _photos.remove(photoId);
  }

  @override
  Future<List<PhotoModel>> getUserPhotos(String userId, {int? limit}) async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 300));
    var photos = _photos.values.where((p) => p.userId == userId).toList();
    photos.sort((a, b) => b.captureDate.compareTo(a.captureDate));
    if (limit != null && photos.length > limit) {
      photos = photos.sublist(0, limit);
    }
    return photos;
  }

  @override
  Future<List<PhotoModel>> getAlbumPhotos(String albumId, String userId) async {
    var photos = _photos.values.where((p) => p.albumId == albumId && p.userId == userId).toList();
    photos.sort((a, b) => b.captureDate.compareTo(a.captureDate));
    return photos;
  }

  @override
  Future<List<PhotoModel>> getFavoritePhotos(String userId) async {
    var photos = _photos.values.where((p) => p.userId == userId && p.isFavorite).toList();
    photos.sort((a, b) => b.captureDate.compareTo(a.captureDate));
    return photos;
  }

  @override
  Stream<List<PhotoModel>> getAlbumPhotosStream(String albumId, String userId) {
    return Stream.value([]); // Simplification: just return empty stream or implement proper stream logic
  }

  @override
  Future<void> batchUpdatePhotos(List<PhotoModel> photos) async {
    for (var photo in photos) {
      updatePhoto(photo);
    }
  }

  // Reminder
  @override
  Future<String> createReminder(ReminderModel reminder) async {
    final id = reminder.id.isEmpty ? 'reminder_${DateTime.now().millisecondsSinceEpoch}' : reminder.id;
    _reminders[id] = reminder.copyWith(id: id);
    _notifyReminderStream(reminder.userId);
    return id;
  }

  @override
  Future<void> updateReminder(ReminderModel reminder) async {
    if (_reminders.containsKey(reminder.id)) {
      _reminders[reminder.id] = reminder;
      _notifyReminderStream(reminder.userId);
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    if (_reminders.containsKey(reminderId)) {
      final userId = _reminders[reminderId]!.userId;
      _reminders.remove(reminderId);
      _notifyReminderStream(userId);
    }
  }

  @override
  Future<List<ReminderModel>> getUserReminders(String userId) async {
    return _reminders.values.where((r) => r.userId == userId).toList();
  }

  @override
  Stream<List<ReminderModel>> getUserRemindersStream(String userId) {
    // Return initial data immediately
    Future.microtask(() => _notifyReminderStream(userId));
    return _remindersController.stream.map((reminders) => reminders.where((r) => r.userId == userId).toList());
  }

  void _notifyReminderStream(String userId) {
    _remindersController.add(_reminders.values.toList());
  }

  @override
  Future<List<ReminderModel>> getTodayReminders(String userId) async {
    return [];
  }
}
