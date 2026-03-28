import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/album_model.dart';
import '../models/photo_model.dart';
import '../models/reminder_model.dart';
import '../../core/constants/app_constants.dart';
import 'interfaces/i_firestore_service.dart';

class FirebaseFirestoreService implements IFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // _firestore getter for external access (if needed, but interface hides it)
  FirebaseFirestore get firestore => _firestore;

  // User CRUD Operations
  @override
  Future<void> createOrUpdateUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toJson(), SetOptions(merge: true));
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    
    if (doc.exists && doc.data() != null) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> deleteUser(String uid) async {
    final batch = _firestore.batch();
    
    // Delete user document
    batch.delete(_firestore.collection(AppConstants.usersCollection).doc(uid));
    
    // Delete user's albums
    final albums = await _firestore
        .collection(AppConstants.albumsCollection)
        .where('userId', isEqualTo: uid)
        .get();
    
    for (final album in albums.docs) {
      batch.delete(album.reference);
    }
    
    // Delete user's photos
    final photos = await _firestore
        .collection(AppConstants.photosCollection)
        .where('userId', isEqualTo: uid)
        .get();
    
    for (final photo in photos.docs) {
      batch.delete(photo.reference);
    }
    
    // Delete user's reminders
    final reminders = await _firestore
        .collection(AppConstants.remindersCollection)
        .where('userId', isEqualTo: uid)
        .get();
    
    for (final reminder in reminders.docs) {
      batch.delete(reminder.reference);
    }
    
    await batch.commit();
  }

  // Album CRUD Operations
  @override
  Future<String> createAlbum(AlbumModel album) async {
    final docRef = await _firestore
        .collection(AppConstants.albumsCollection)
        .add(album.toJson());
    return docRef.id;
  }

  @override
  Future<void> updateAlbum(AlbumModel album) async {
    await _firestore
        .collection(AppConstants.albumsCollection)
        .doc(album.id)
        .update(album.toJson());
  }

  @override
  Future<void> deleteAlbum(String albumId, String userId) async {
    final batch = _firestore.batch();
    
    // Delete album
    batch.delete(_firestore.collection(AppConstants.albumsCollection).doc(albumId));
    
    // Delete photos in this album
    final photos = await _firestore
        .collection(AppConstants.photosCollection)
        .where('albumId', isEqualTo: albumId)
        .where('userId', isEqualTo: userId)
        .get();
    
    for (final photo in photos.docs) {
      batch.delete(photo.reference);
    }
    
    await batch.commit();
  }

  @override
  Future<List<AlbumModel>> getUserAlbums(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.albumsCollection)
        .where('userId', isEqualTo: userId)
        .get();
    
    // 클라이언트 사이드에서 정렬 (인덱스 문제 해결)
    final albums = snapshot.docs
        .map((doc) => AlbumModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
    
    // isPinned 먼저, 그 다음 updatedAt으로 정렬
    albums.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return b.isPinned ? 1 : -1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    
    return albums;
  }

  @override
  Stream<List<AlbumModel>> getUserAlbumsStream(String userId) {
    return _firestore
        .collection(AppConstants.albumsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final albums = snapshot.docs
              .map((doc) => AlbumModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          
          // 클라이언트 사이드에서 정렬
          albums.sort((a, b) {
            if (a.isPinned != b.isPinned) {
              return b.isPinned ? 1 : -1;
            }
            return b.updatedAt.compareTo(a.updatedAt);
          });
          
          return albums;
        });
  }

  // Photo CRUD Operations
  @override
  Future<String> createPhoto(PhotoModel photo) async {
    final docRef = await _firestore
        .collection(AppConstants.photosCollection)
        .add(photo.toJson());
    return docRef.id;
  }

  @override
  Future<void> updatePhoto(PhotoModel photo) async {
    await _firestore
        .collection(AppConstants.photosCollection)
        .doc(photo.id)
        .update(photo.toJson());
  }

  @override
  Future<void> deletePhoto(String photoId, String userId) async {
    final batch = _firestore.batch();
    
    // Delete photo
    batch.delete(_firestore.collection(AppConstants.photosCollection).doc(photoId));
    
    // Delete related reminders
    final reminders = await _firestore
        .collection(AppConstants.remindersCollection)
        .where('photoId', isEqualTo: photoId)
        .where('userId', isEqualTo: userId)
        .get();
    
    for (final reminder in reminders.docs) {
      batch.delete(reminder.reference);
    }
    
    await batch.commit();
  }

  @override
  Future<List<PhotoModel>> getAlbumPhotos(String albumId, String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.photosCollection)
        .where('albumId', isEqualTo: albumId)
        .where('userId', isEqualTo: userId)
        .orderBy('captureDate', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => PhotoModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Stream<List<PhotoModel>> getAlbumPhotosStream(String albumId, String userId) {
    return _firestore
        .collection(AppConstants.photosCollection)
        .where('albumId', isEqualTo: albumId)
        .where('userId', isEqualTo: userId)
        .orderBy('captureDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PhotoModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  @override
  Future<List<PhotoModel>> getUserPhotos(String userId, {int? limit}) async {
    print('📸 Firestore getUserPhotos 시작: $userId');
    print('🔍 쿼리 조건: userId = $userId');
    
    try {
      // 임시로 단순 쿼리 사용 (인덱스 문제 해결)
      Query query = _firestore
          .collection(AppConstants.photosCollection)
          .where('userId', isEqualTo: userId);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      print('📸 Firestore 쿼리 실행 중...');
      final snapshot = await query.get();
      print('📸 Firestore 쿼리 결과: ${snapshot.docs.length}개 문서');
      
      // 각 문서의 userId 확인
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('📄 문서 ID: ${doc.id}, userId: ${data['userId']}');
      }
      
      final photos = snapshot.docs
          .map((doc) => PhotoModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
      
      // 클라이언트에서 날짜순 정렬
      photos.sort((a, b) => b.captureDate.compareTo(a.captureDate));
      
      print('📸 Firestore getUserPhotos 완료: ${photos.length}개 사진');
      return photos;
      
    } catch (e) {
      print('❌ Firestore getUserPhotos 오류: $e');
      rethrow;
    }
  }

  @override
  Future<List<PhotoModel>> getFavoritePhotos(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.photosCollection)
        .where('userId', isEqualTo: userId)
        .where('isFavorite', isEqualTo: true)
        .orderBy('captureDate', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => PhotoModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Reminder CRUD Operations
  @override
  Future<String> createReminder(ReminderModel reminder) async {
    final docRef = await _firestore
        .collection(AppConstants.remindersCollection)
        .add(reminder.toJson());
    return docRef.id;
  }

  @override
  Future<void> updateReminder(ReminderModel reminder) async {
    await _firestore
        .collection(AppConstants.remindersCollection)
        .doc(reminder.id)
        .update(reminder.toJson());
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    await _firestore
        .collection(AppConstants.remindersCollection)
        .doc(reminderId)
        .delete();
  }

  @override
  Future<List<ReminderModel>> getUserReminders(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.remindersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('reminderDate')
        .get();
    
    return snapshot.docs
        .map((doc) => ReminderModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Stream<List<ReminderModel>> getUserRemindersStream(String userId) {
    return _firestore
        .collection(AppConstants.remindersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('reminderDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReminderModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  @override
  Future<List<ReminderModel>> getTodayReminders(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final snapshot = await _firestore
        .collection(AppConstants.remindersCollection)
        .where('userId', isEqualTo: userId)
        .where('reminderDate', isGreaterThanOrEqualTo: startOfDay)
        .where('reminderDate', isLessThanOrEqualTo: endOfDay)
        .where('isCompleted', isEqualTo: false)
        .orderBy('reminderDate')
        .get();
    
    return snapshot.docs
        .map((doc) => ReminderModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Batch Operations
  @override
  Future<void> batchUpdatePhotos(List<PhotoModel> photos) async {
    final batch = _firestore.batch();
    
    for (final photo in photos) {
      final docRef = _firestore.collection(AppConstants.photosCollection).doc(photo.id);
      batch.update(docRef, photo.toJson());
    }
    
    await batch.commit();
  }

  // Album Photo Count Update
  @override
  Future<void> updateAlbumPhotoCount(String albumId, String userId) async {
    final photoCount = await _firestore
        .collection(AppConstants.photosCollection)
        .where('albumId', isEqualTo: albumId)
        .where('userId', isEqualTo: userId)
        .count()
        .get();
    
    await _firestore
        .collection(AppConstants.albumsCollection)
        .doc(albumId)
        .update({'photoCount': photoCount.count});
  }
}
