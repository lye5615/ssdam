import 'dart:async';
import '../interfaces/i_auth_service.dart';
import '../../models/user_model.dart';

class MockAuthService implements IAuthService {
  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();

  MockAuthService() {
    // Start with no user logged in, or mock auto-login? 
    // Let's start logged out for realism, or logged in for convenience?
    // Plan: Start logged out.
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserModel?> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate delay
    final user = _createMockUser();
    _updateUser(user);
    return user;
  }

  @override
  Future<UserModel?> signInWithApple() async {
    await Future.delayed(const Duration(seconds: 1));
    final user = _createMockUser();
    _updateUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _updateUser(null);
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(seconds: 1));
    _updateUser(null);
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    // In mock mode, we assume currentUser has latest data or fetch from MockFirestore
    return _currentUser;
  }

  @override
  Future<void> updateUserProfile({String? displayName, String? photoUrl}) async {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      _updateUser(updatedUser);
    }
  }

  void _updateUser(UserModel? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  UserModel _createMockUser() {
    return UserModel(
      uid: 'mock_user_123',
      email: 'mock@example.com',
      displayName: 'Mock User',
      photoUrl: '', // Removed network dependency
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }
}
