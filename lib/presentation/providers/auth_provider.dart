import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/interfaces/i_auth_service.dart';
import '../../core/di/service_locator.dart';
import '../../data/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  IAuthService get _authService => ServiceLocator.authService;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _currentUser = _authService.currentUser;
    _init();
  }

  void _init() {
    // Auth 상태 변화 리스너
    _authService.authStateChanges.listen((UserModel? user) {
      _currentUser = user;
      if (user != null) {
        _loadUserData();
        _updateFcmToken();
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> _updateFcmToken() async {
    try {
      if (_currentUser == null) return;
      
      final notificationService = NotificationService();
      final token = await notificationService.getToken();
      
      if (token != null && token != _currentUser!.fcmToken) {
        final updatedUser = _currentUser!.copyWith(fcmToken: token);
        await ServiceLocator.firestoreService.createOrUpdateUser(updatedUser);
        _currentUser = updatedUser;
        notifyListeners();
        print('✅ FCM 토큰 업데이트 성공: $token');
      }
    } catch (e) {
      print('⚠️ FCM 토큰 업데이트 실패: $e');
    }
  }

  // 사용자 데이터 로드
  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getCurrentUserData();
      if (userData != null) {
        _currentUser = userData;
      }
    } catch (e) {
      _errorMessage = '사용자 정보를 불러오는데 실패했습니다: $e';
    }
    notifyListeners();
  }

  // Google 로그인
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _authService.signInWithGoogle();
      
      if (user != null) {
        _currentUser = user; // Optimistic update
        return true;
      } else {
        _errorMessage = '로그인이 취소되었습니다.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Google 로그인 실패: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Apple 로그인
  Future<bool> signInWithApple() async {
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _authService.signInWithApple();
      
      if (user != null) {
        _currentUser = user;
        return true;
      } else {
        _errorMessage = '로그인이 취소되었습니다.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Apple 로그인 실패: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.signOut();
      _currentUser = null;
      
    } catch (e) {
      _errorMessage = '로그아웃 실패: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 계정 삭제
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.deleteAccount();
      _currentUser = null;
      
      return true;
    } catch (e) {
      _errorMessage = '계정 삭제 실패: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 프로필 업데이트
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.updateUserProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      
      // 로컬 사용자 정보 업데이트 (낙관적 업데이트)
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          displayName: displayName,
          photoUrl: photoUrl,
        );
      }
      
      return true;
    } catch (e) {
      _errorMessage = '프로필 업데이트 실패: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 사용자 권한 확인 및 요청
  Future<bool> checkAndRequestPermissions() async {
    try {
      _setLoading(true);
      _clearError();
      
      // PhotoService를 통한 권한 확인은 다른 Provider에서 처리
      return true;
      
    } catch (e) {
      _errorMessage = '권한 확인 실패: $e';
      return false;
    } finally {
      _setLoading(false);
    }
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
}
