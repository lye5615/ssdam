class AppConstants {
  // App Information
  static const String appName = '쓰담';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String albumsCollection = 'albums';
  static const String photosCollection = 'photos';
  static const String remindersCollection = 'reminders';
  
  // Photo Categories
  static const List<String> defaultCategories = [
    '정보/참고용',
    '대화/메시지',
    '학습/업무 메모',
    '재미/밈/감정',
    '일정/예약',
    '증빙/거래',
    '옷',
    '제품',
  ];
  
  // Special Albums
  static const String recentAlbum = '최근 항목';
  static const String favoritesAlbum = '즐겨찾기';
  static const String scheduledAlbum = '기한이 있는 항목';
  
  // API Keys & URLs
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  // Notification Settings
  static const String notificationChannelId = 'kimchi_jjim_notifications';
  static const String notificationChannelName = '김치찜 알림';
  static const String notificationChannelDescription = '스크린샷 관리 알림';
  
  // Permissions
  static const List<String> requiredPermissions = [
    'storage',
    'photos',
    'notification',
  ];
  
  // UI Constants
  static const int gridCrossAxisCount = 3;
  static const double gridAspectRatio = 1.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
