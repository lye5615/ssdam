import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/photo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/album_provider.dart';
import '../../../data/models/album_model.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/di/service_locator.dart';
import '../photo_detail_screen.dart';
import '../../widgets/photo_grid.dart';

class CategoryPhotosScreen extends StatefulWidget {
  final String category;
  final String categoryIcon;

  const CategoryPhotosScreen({
    super.key,
    required this.category,
    required this.categoryIcon,
  });

  @override
  State<CategoryPhotosScreen> createState() => _CategoryPhotosScreenState();
}

class _CategoryPhotosScreenState extends State<CategoryPhotosScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedPhotoIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedPhotoIds.clear();
    });
  }

  void _togglePhotoSelection(String photoId) {
    setState(() {
      if (_selectedPhotoIds.contains(photoId)) {
        _selectedPhotoIds.remove(photoId);
        if (_selectedPhotoIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPhotoIds.add(photoId);
      }
    });
  }

  void _selectAll(List<String> allIds) {
    setState(() {
      if (_selectedPhotoIds.length == allIds.length) {
        _selectedPhotoIds.clear();
      } else {
        _selectedPhotoIds.addAll(allIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedPhotoIds.length}개 선택됨')
            : GestureDetector(
                onTap: () => _showRenameCategoryDialog(context, widget.category),
                child: Row(
                  children: [
                    Text(
                      widget.category,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final photos = photoProvider.photos
                    .where((photo) => photo.category == widget.category && photo.userId == authProvider.currentUser!.uid)
                    .map((e) => e.id)
                    .toList();
                _selectAll(photos);
              },
            )
          else ...[
             TextButton(
              onPressed: _toggleSelectionMode,
              child: const Text(
                '선택',
                style: TextStyle(color: AppColors.textOnPrimary),
              ),
            ),
            if (kIsWeb)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _downloadCategoryPhotos(context),
                tooltip: '폴더 다운로드',
              ),
          ],
        ],
      ),
      body: Consumer2<AuthProvider, PhotoProvider>(
        builder: (context, authProvider, photoProvider, child) {
          if (!authProvider.isAuthenticated) {
            return const Center(
              child: Text('로그인이 필요합니다.'),
            );
          }

          final categoryPhotos = photoProvider.photos
              .where((photo) => photo.category == widget.category && photo.userId == authProvider.currentUser!.uid)
              .toList();

          if (categoryPhotos.isEmpty) {
            return _buildEmptyState();
          }

          return Stack(
            children: [
              PhotoGrid(
                photos: categoryPhotos,
                isSelectionMode: _isSelectionMode,
                selectedPhotoIds: _selectedPhotoIds,
                onPhotoTap: (photos, index) {
                  final photo = photos[index];
                  if (_isSelectionMode) {
                    _togglePhotoSelection(photo.id);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoDetailScreen(
                          allPhotos: photos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  }
                },
                onPhotoLongPress: (photo) {
                  if (!_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedPhotoIds.add(photo.id);
                    });
                  } else {
                    _togglePhotoSelection(photo.id);
                  }
                },
              ),
              if (_isSelectionMode && _selectedPhotoIds.isNotEmpty)
                _buildBottomActionBar(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10,
          top: 10,
          left: 16,
          right: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(Icons.drive_file_move_outline, '이동', () => _showMoveDialog(context)),
            _buildActionButton(Icons.favorite_border, '즐겨찾기', () => _toggleBulkFavorite(context)),
            _buildActionButton(Icons.share_outlined, '공유', () => _shareSelectedPhotos(context)),
            _buildActionButton(Icons.delete_outline, '삭제', () => _deleteSelectedPhotos(context), isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isDestructive ? AppColors.error : AppColors.textPrimary),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDestructive ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.categoryIcon,
            style: const TextStyle(
              fontSize: 64,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.category} 폴더가 비어있습니다',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '사진을 업로드하면 자동으로 분류됩니다',
            style: TextStyle(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareSelectedPhotos(BuildContext context) async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final selectedPhotos = photoProvider.photos.where((p) => _selectedPhotoIds.contains(p.id)).toList();
    
    if (selectedPhotos.isEmpty) return;

    final xFiles = selectedPhotos.map((p) => XFile(p.localPath)).toList();
    await Share.shareXFiles(xFiles, text: '사진 공유');
    _toggleSelectionMode();
  }

  Future<void> _toggleBulkFavorite(BuildContext context) async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    
    for (var id in _selectedPhotoIds) {
      await photoProvider.togglePhotoFavorite(id);
    }
    
    _toggleSelectionMode();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('즐겨찾기 상태가 변경되었습니다.')),
    );
  }

  Future<void> _deleteSelectedPhotos(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사진 삭제'),
        content: Text('${_selectedPhotoIds.length}장의 사진을 삭제하시겠습니까?\n(갤러리 원본은 유지됩니다)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
      int successCount = 0;
      
      // Copy list to avoid concurrent modification issues if any
      final idsToDelete = List<String>.from(_selectedPhotoIds);
      
      for (var id in idsToDelete) {
        if (await photoProvider.deletePhoto(id)) {
          successCount++;
        }
      }

      if (mounted) {
        _toggleSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$successCount장의 사진이 삭제되었습니다.')),
        );
      }
    }
  }

  void _showMoveDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<AlbumProvider>(
        builder: (context, albumProvider, child) {
          final albums = albumProvider.albums.where((a) => a.name != widget.category).toList();
          
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    '이동할 카테고리 선택',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return ListTile(
                        leading: _buildAlbumIcon(album),
                        title: Text(album.name),
                        subtitle: Text('${album.photoCount}장'),
                        onTap: () => _moveSelectedPhotos(context, album),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAlbumIcon(AlbumModel album) {
      // If iconPath is 1 char (Emoji), show text. Else Icon.
      if (album.iconPath.length <= 2) {
          return Container(
             width: 40, height: 40,
             alignment: Alignment.center,
             decoration: BoxDecoration(
                 color: AppColors.surfaceVariant,
                 borderRadius: BorderRadius.circular(8),
             ),
             child: Text(album.iconPath, style: const TextStyle(fontSize: 24)),
          );
      }
      return const Icon(Icons.folder);
  }

  Future<void> _moveSelectedPhotos(BuildContext context, AlbumModel targetAlbum) async {
    Navigator.pop(context); // Close sheet
    
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final count = _selectedPhotoIds.length;
    final idsToMove = List<String>.from(_selectedPhotoIds);
    
    int successCount = 0;
    for (var id in idsToMove) {
      if (await photoProvider.movePhotoToAlbum(id, targetAlbum.id, newCategoryName: targetAlbum.name)) {
        successCount++;
      }
    }

    if (mounted) {
      _toggleSelectionMode();
      if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$successCount장의 사진을 "${targetAlbum.name}"(으)로 이동했습니다.')),
          );
          // If all moved, this screen might become empty, which is handled by build
      } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이동 실패')),
          );
      }
    }
  }

  // ... (Existing download methods: _downloadCategoryPhotos, _downloadPhoto, _showRenameCategoryDialog)
  // Re-implementing them briefly or keeping them if I could partial edit, but since I am overwriting, 
  // I must include them.

  Future<void> _downloadCategoryPhotos(BuildContext context) async {
    // ... Same implementation as before ...
     final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final categoryPhotos = photoProvider.photos
        .where((photo) => photo.category == widget.category && photo.userId == authProvider.currentUser!.uid)
        .toList();

    if (categoryPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('다운로드할 사진이 없습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.category} 폴더의 ${categoryPhotos.length}개 사진을 다운로드합니다.'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: '확인',
          textColor: AppColors.textOnPrimary,
          onPressed: () {
            // TODO: 실제 다운로드 구현
          },
        ),
      ),
    );
  }

  void _showRenameCategoryDialog(BuildContext context, String currentName) {
     // Find album ID
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);
    final album = albumProvider.albums.firstWhere(
      (a) => a.name == currentName,
      orElse: () => AlbumModel(id: '', name: '', userId: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), iconPath: '', colorCode: ''), // Dummy
    );

    if (album.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리 정보를 찾을 수 없습니다.')),
      );
      return;
    }

    final TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 이름 변경'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: '새 이름',
                    hintText: '카테고리 이름을 입력하세요',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                // Color Picker Button (Basic)
                Row(
                    children: [
                        const Text('색상: '),
                        const SizedBox(width: 8),
                        GestureDetector(
                            onTap: () {
                                Navigator.pop(context); // Close rename dialog
                                _showColorPickerDialog(context, album);
                            },
                             child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                    color: _parseColor(album.colorCode),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey),
                                ),
                             ),
                        ),
                        const SizedBox(width: 8),
                         const Text('(터치하여 변경)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ]
                )
            ]
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                final success = await albumProvider.renameAlbum(album.id, newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    Navigator.pop(context); // Go back to Home as category name changed
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이름이 변경되었습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(albumProvider.errorMessage ?? '변경 실패')),
                    );
                  }
                }
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }
  
  void _showColorPickerDialog(BuildContext context, AlbumModel album) {
      // Simple color picker
      final List<String> colors = [
          '#FF0000', '#FF7F00', '#FFFF00', '#00FF00', '#0000FF', '#4B0082', '#9400D3', // Rainbow
          '#000000', '#FFFFFF', '#808080', // Mono
          '#FFC0CB', '#008080', '#A52A2A', // Extra
      ];
      
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text('색상 선택'),
              content: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: colors.map((c) => GestureDetector(
                      onTap: () async {
                          final albumProvider = Provider.of<AlbumProvider>(context, listen: false);
                          await albumProvider.changeAlbumColor(album.id, c);
                          if (context.mounted) {
                              Navigator.pop(context);
                              // Re-open rename dialog? or just finish.
                              // Just finish is fine for now.
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('색상이 변경되었습니다.')),
                              );
                              setState(() {}); // Refresh if needed
                          }
                      },
                      child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: _parseColor(c),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                          ),
                      ),
                  )).toList(),
              ),
          ),
      );
  }
  
  Color _parseColor(String? colorCode) {
      if (colorCode == null) return Colors.grey;
      try {
          return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
      } catch (e) {
          return Colors.grey;
      }
  }
}
