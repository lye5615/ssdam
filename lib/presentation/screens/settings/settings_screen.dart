import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/gemini_service.dart';
import '../../../core/di/service_locator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/photo_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import 'category_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 프로필 섹션
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: (authProvider.currentUser?.photoUrl != null && 
                                        authProvider.currentUser!.photoUrl!.isNotEmpty &&
                                        authProvider.currentUser!.photoUrl!.startsWith('http'))
                            ? NetworkImage(authProvider.currentUser!.photoUrl!)
                            : null,
                        child: (authProvider.currentUser?.photoUrl == null || 
                                authProvider.currentUser!.photoUrl!.isEmpty ||
                                !authProvider.currentUser!.photoUrl!.startsWith('http'))
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.currentUser?.displayName ?? '사용자',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authProvider.currentUser?.email ?? '',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 앱 설정
              Text(
                '앱 설정',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.brightness_6),
                      title: const Text('테마 설정'),
                      subtitle: Text(
                        Provider.of<ThemeProvider>(context).isDarkMode ? '다크 모드' : '라이트 모드'
                      ),
                      trailing: Switch(
                        value: Provider.of<ThemeProvider>(context).isDarkMode,
                        onChanged: (value) {
                          Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('갤러리 권한'),
                      subtitle: const Text('스크린샷 자동 불러오기'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Open permission settings
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('알림 설정'),
                      subtitle: const Text('알림 시간 및 방식 설정'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Open notification settings
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.category),
                      title: const Text('카테고리 관리'),
                      subtitle: const Text('분류 카테고리 수정'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 정보
              Text(
                '정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('앱 정보'),
                      subtitle: Text('버전 ${AppConstants.appVersion}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Show app info
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('개인정보처리방침'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Open privacy policy
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('이용약관'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Open terms of service
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // 개발자 도구 (디버그)
              Text(
                '개발자 도구',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.search),
                      title: const Text('제품 검색 테스트 (최근 스크린샷)'),
                      subtitle: const Text('Gemini + 제품 링크 생성 로그 출력'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _testProductSearch(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('기한 인식 테스트 (최근 스크린샷)'),
                      subtitle: const Text('기한 추출 및 알림 계산 로그 출력'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _testDeadlineExtraction(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // 계정 관리
              Text(
                '계정 관리',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      title: const Text('로그아웃'),
                      onTap: () => _showLogoutDialog(context, authProvider),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: AppColors.error),
                      title: const Text('계정 삭제', style: TextStyle(color: AppColors.error)),
                      onTap: () => _showDeleteAccountDialog(context, authProvider),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text(
          '계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다.\n'
          '이 작업은 되돌릴 수 없습니다.\n\n'
          '정말 계정을 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await authProvider.deleteAccount();
              if (success && context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showFolderLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text('폴더 위치'),
          ],
        ),
        content: FutureBuilder<String>(
          future: Provider.of<PhotoProvider>(context, listen: false).getFolderLocationInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Text('오류: ${snapshot.error}');
            }
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '분류된 사진이 저장되는 위치:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    snapshot.data ?? '정보를 가져올 수 없습니다.',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '💡 팁:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• iOS: Photos 앱에서 확인하세요\n'
                  '• Android: 파일 관리자에서 Downloads/FinalCapture 폴더를 확인하세요\n'
                  '• 웹: 브라우저의 다운로드 폴더를 확인하세요',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _testProductSearch(BuildContext context) async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('제품 검색 테스트 시작...')));

      final photoService = ServiceLocator.photoService;
      final screenshots = await photoService.getLatestScreenshots(count: 1);
      if (screenshots.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('최근 스크린샷을 찾지 못했습니다.')));
        return;
      }

      final file = await screenshots.first.file;
      if (file == null) {
        messenger.showSnackBar(const SnackBar(content: Text('파일을 열 수 없습니다.')));
        return;
      }

      final gemini = GeminiService();
      final result = await gemini.extractProductInfoFromFile(file);

      final hasError = result['error'] != null;
      final links = (result['links'] is Map) ? (result['links'] as Map).length : 0;
      messenger.showSnackBar(SnackBar(content: Text(hasError ? '제품 검색 실패' : '제품 검색 완료: 링크 $links개')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }

  Future<void> _testDeadlineExtraction(BuildContext context) async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('기한 인식 테스트 시작...')));

      final photoService = ServiceLocator.photoService;
      final screenshots = await photoService.getLatestScreenshots(count: 1);
      if (screenshots.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('최근 스크린샷을 찾지 못했습니다.')));
        return;
      }

      final file = await screenshots.first.file;
      if (file == null) {
        messenger.showSnackBar(const SnackBar(content: Text('파일을 열 수 없습니다.')));
        return;
      }

      final gemini = GeminiService();
      final result = await gemini.extractDeadlineInfoFromFile(file);

      final hasError = result['error'] != null;
      final hasDeadline = result['has_deadline'] == true;
      messenger.showSnackBar(SnackBar(content: Text(hasError ? '기한 인식 실패' : (hasDeadline ? '기한 감지됨' : '기한 없음'))));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }
}
