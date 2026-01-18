import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/album_provider.dart';
import '../../providers/photo_provider.dart';
import '../../widgets/album_grid.dart';
import '../../widgets/photo_grid.dart';
import '../../widgets/permission_dialog.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../photo_detail_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) return;

    try {
      // 권한 확인 및 요청
      final hasPermissions = await photoProvider.requestPermissions();
      
      if (!hasPermissions && mounted) {
        _showPermissionDialog();
        return;
      }

      final userId = authProvider.currentUser!.uid;

      // 기본 앨범 초기화 (새 사용자인 경우)
      await albumProvider.loadUserAlbums(userId);
      if (albumProvider.albums.isEmpty) {
        await albumProvider.initializeDefaultAlbums(userId);
      }

      // 카테고리별 폴더 생성
      await photoProvider.createAllCategoryFolders(userId);

      // 데이터 로드
      await Future.wait([
        photoProvider.initialize(userId),
        albumProvider.loadUserAlbums(userId),
      ]);

      // 자동 분류 제거 - 사용자가 수동으로 분류시작 버튼을 눌러야 함

    } catch (e) {
      print('App initialization error: $e');
      _showErrorSnackbar('앱 초기화 중 오류가 발생했습니다: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PermissionDialog(),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      final userId = authProvider.currentUser!.uid;
      
      // 사진 새로고침 (새로 추가된 사진만 처리 - API 비용 절약)
      await photoProvider.refresh(userId, forceReprocess: false);
      
      // 앨범 데이터도 새로고침
      await albumProvider.loadUserAlbums(userId);
    }
  }

  Future<void> _startClassification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) return;

    try {
      final userId = authProvider.currentUser!.uid;
      
      // 분류 시작 (이미 분류된 사진도 재분류)
      await photoProvider.startClassification(userId);
      
      // 앨범 데이터도 새로고침
      await albumProvider.loadUserAlbums(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('분류가 완료되었습니다!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('분류 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black, // Replaced explicit primaryGradient
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: Colors.white,
                  ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // 기존 사용자용 분류 시작 버튼 (사진이 1개 이상일 때만 표시)
          Consumer<PhotoProvider>(
            builder: (context, photoProvider, child) {
              if (photoProvider.recentPhotos.isNotEmpty) {
                return IconButton(
                  onPressed: photoProvider.isProcessing ? null : () => _startClassification(),
                  icon: photoProvider.isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                  tooltip: '사진 분류 시작',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // 갤러리 불러오기 버튼 (수동 동기화)
          IconButton(
            onPressed: () async {
              final user = context.read<AuthProvider>().currentUser;
              if (user != null) {
                await context.read<PhotoProvider>().refresh(user.uid, forceReprocess: false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('갤러리에서 최신 스크린샷을 불러옵니다...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.sync),
            tooltip: '갤러리 불러오기',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
            icon: const Icon(Icons.search),
            tooltip: '검색',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).tabBarTheme.labelColor ?? Theme.of(context).colorScheme.primary, 
          unselectedLabelColor: Theme.of(context).tabBarTheme.unselectedLabelColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: Theme.of(context).tabBarTheme.indicatorColor ?? Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.photo_library_outlined),
              text: '앨범',
            ),
            Tab(
              icon: Icon(Icons.access_time_outlined),
              text: '최근',
            ),
            Tab(
              icon: Icon(Icons.favorite_outline),
              text: '즐겨찾기',
            ),
          ],
        ),
      ),
      body: Consumer3<AuthProvider, AlbumProvider, PhotoProvider>(
        builder: (context, authProvider, albumProvider, photoProvider, child) {
          if (!authProvider.isAuthenticated) {
            return const Center(
              child: Text('로그인이 필요합니다.'),
            );
          }

          if (!photoProvider.hasPermissions) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '갤러리 접근 권한이 필요합니다',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '설정에서 권한을 허용해주세요',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // 앨범 탭
              RefreshIndicator(
                onRefresh: _handleRefresh,
                child: AlbumGrid(
                  onTabChange: (index) => _tabController.animateTo(index),
                ),
              ),
              
              // 최근 탭
              RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _buildRecentPhotosTab(photoProvider),
              ),
              
              // 즐겨찾기 탭
              RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _buildFavoritePhotosTab(photoProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecentPhotosTab(PhotoProvider photoProvider) {
    if (photoProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Use recentPhotos (PhotoModel) instead of latestScreenshots (AssetEntity)
    if (photoProvider.recentPhotos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              '아직 사진이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '동기화 버튼을 눌러 갤러리를 불러오세요',
              style: TextStyle(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 초기 사용자용 분류시작 버튼 (사진이 0개일 때만 표시)
        if (photoProvider.recentPhotos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: photoProvider.isProcessing ? null : () => _startClassification(),
              icon: photoProvider.isProcessing 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
              label: Text(
                photoProvider.isProcessing ? '분류 중...' : '사진 불러오기 및 분류 시작',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        // 사진 그리드 (PhotoGrid 재사용)
        Expanded(
          child: PhotoGrid(
            photos: photoProvider.recentPhotos,
            onPhotoTap: (photo) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoDetailScreen(photo: photo),
                ),
              );
            },
            onPhotoLongPress: (photo) {
              // Option to show options bottom sheet
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritePhotosTab(PhotoProvider photoProvider) {
    if (photoProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (photoProvider.favoritePhotos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              '즐겨찾기한 사진이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '사진을 즐겨찾기에 추가해보세요',
              style: TextStyle(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return PhotoGrid(
      photos: photoProvider.favoritePhotos,
      onPhotoTap: (photo) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhotoDetailScreen(photo: photo),
          ),
        );
      },
    );
  }
  // _buildAssetTile removed as it is replaced by PhotoGrid internal logic


  // AssetEntity 즐겨찾기 토글
  Future<void> _toggleAssetFavorite(BuildContext context, AssetEntity asset, PhotoProvider photoProvider) async {
    try {
      // AssetEntity 즐겨찾기 토글
      final isNowFavorite = await photoProvider.toggleAssetFavorite(asset);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNowFavorite ? '즐겨찾기에 추가되었습니다!' : '즐겨찾기에서 제거되었습니다!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 즐겨찾기 토글 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('즐겨찾기 변경 실패: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant, // Replaced backgroundGradient
      ),
      child: const Center(
        child: Icon(
          Icons.photo,
          size: 32,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
