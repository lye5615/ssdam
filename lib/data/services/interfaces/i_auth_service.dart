import '../../models/user_model.dart';

abstract class IAuthService {
  // 현재 로그인된 사용자
  UserModel? get currentUser;
  
  // 사용자 상태 스트림
  Stream<UserModel?> get authStateChanges;

  // Google 로그인
  Future<UserModel?> signInWithGoogle();

  // Apple 로그인
  Future<UserModel?> signInWithApple();

  // 로그아웃
  Future<void> signOut();

  // 계정 삭제
  Future<void> deleteAccount();

  // 현재 사용자 정보 가져오기
  Future<UserModel?> getCurrentUserData();

  // 사용자 프로필 업데이트
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });
}
