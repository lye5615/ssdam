import '../../models/user_model.dart';
import '../../models/album_model.dart';
import '../../models/rule_model.dart';
import '../../models/photo_model.dart';
import '../../models/reminder_model.dart';
import '../../models/rule_model.dart'; // Added this import for RuleModel

abstract class IFirestoreService {
  // User CRUD
  Future<void> createOrUpdateUser(UserModel user);
  Future<UserModel?> getUser(String uid);
  Future<void> deleteUser(String uid);
  
  // Album CRUD
  Future<String> createAlbum(AlbumModel album);
  Future<void> updateAlbum(AlbumModel album);
  Future<void> deleteAlbum(String albumId);
  Future<List<AlbumModel>> getUserAlbums(String userId);
  Stream<List<AlbumModel>> getUserAlbumsStream(String userId);
  Future<void> updateAlbumPhotoCount(String albumId);
  
  // Photo CRUD
  Future<String> createPhoto(PhotoModel photo);
  Future<void> updatePhoto(PhotoModel photo);
  Future<void> deletePhoto(String photoId);
  Future<List<PhotoModel>> getUserPhotos(String userId, {int? limit});
  Future<List<PhotoModel>> getAlbumPhotos(String albumId, String userId);
  Stream<List<PhotoModel>> getAlbumPhotosStream(String albumId, String userId);
  Future<List<PhotoModel>> getFavoritePhotos(String userId);
  Future<void> batchUpdatePhotos(List<PhotoModel> photos);
  
  // Reminder CRUD
  Future<String> createReminder(ReminderModel reminder);
  Future<void> updateReminder(ReminderModel reminder);
  Future<void> deleteReminder(String reminderId);
  Future<List<ReminderModel>> getUserReminders(String userId);
  Stream<List<ReminderModel>> getUserRemindersStream(String userId);
  Future<List<ReminderModel>> getTodayReminders(String userId);
}
