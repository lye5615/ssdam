import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // For ImageFilter
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../providers/album_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/category/category_photos_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../../data/models/photo_model.dart'; // Import PhotoModel
import 'dart:io'; // For File
import 'package:flutter/foundation.dart'; // For kIsWeb

class AlbumGrid extends StatelessWidget {
  final Function(int)? onTabChange;

  const AlbumGrid({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AlbumProvider, AuthProvider, PhotoProvider>(
      builder: (context, albumProvider, authProvider, photoProvider, child) {
        if (albumProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (albumProvider.albums.isEmpty) {
          return _buildEmptyState();
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Quick Access (Horizontal Scroll)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'Quick Access',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 100, // Fixed height for horizontal list
                margin: const EdgeInsets.only(bottom: 20),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _QuickAccessChip(
                      label: 'Recent',
                      icon: Icons.access_time_filled,
                      color: AppColors.primary,
                      onTap: () => onTabChange?.call(1),
                    ),
                    const SizedBox(width: 12),
                    _QuickAccessChip(
                      label: 'Alerts',
                      icon: Icons.notifications_active,
                      color: Colors.orange,
                      onTap: () => _navigateToScheduled(context),
                    ),
                    const SizedBox(width: 12),
                    _QuickAccessChip(
                      label: 'Favorites',
                      icon: Icons.favorite,
                      color: Colors.pinkAccent,
                      onTap: () => onTabChange?.call(2),
                    ),
                  ],
                ),
              ),
            ),

            // Categories Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Collections',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // Premium Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns for larger, clearer cards
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85, // Taller cards
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final categoryAlbums = albumProvider.albums.toList(); 
                    if (index == categoryAlbums.length) {
                       return _AddCategoryCard();
                    }
                    final album = categoryAlbums[index];
                    return _PremiumAlbumCard(
                      album: album,
                      coverPhoto: photoProvider.getCoverPhotoForCategory(album.name),
                    );
                  },
                  childCount: albumProvider.albums.length + 1,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text(
            'No Albums',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScheduled(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }
}

class _QuickAccessChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumAlbumCard extends StatelessWidget {
  final dynamic album;
  final PhotoModel? coverPhoto;

  const _PremiumAlbumCard({required this.album, this.coverPhoto});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (AppConstants.defaultCategories.contains(album.name) || true) { // Allow all for now
           Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CategoryPhotosScreen(
                category: album.name,
                categoryIcon: album.iconPath ?? '📁',
              ),
            ),
          );
        }
      },
      onLongPress: () => _showAlbumOptions(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image or Gradient
            _buildCoverImage(context),

            // 2. Gradient Overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 0.7, 1.0],
                ),
              ),
            ),

            // 3. Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      backgroundBlendMode: BlendMode.overlay,
                    ),
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Icon(Icons.folder_open, color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    album.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${album.photoCount ?? 0} photos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
             // Pin Indicator
             if (album.isPinned ?? false)
               Positioned(
                 top: 12,
                 right: 12,
                 child: Container(
                   padding: const EdgeInsets.all(6),
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.9),
                     shape: BoxShape.circle,
                   ),
                   child: const Icon(Icons.push_pin, size: 14, color: AppColors.primary),
                 ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getAlbumColor().withOpacity(0.8),
            _getAlbumColor().withOpacity(0.4),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '옷':
        return Icons.checkroom;
      case '제품':
        return Icons.shopping_bag_outlined;
      case '정보/참고용':
        return Icons.info_outline;
      case '일정/예약':
        return Icons.calendar_today;
      case '증빙/거래':
        return Icons.receipt_long;
      case '재미/밈/감정':
        return Icons.sentiment_satisfied_alt;
      case '학습/업무 메모':
        return Icons.note_alt_outlined;
      case '대화/메시지':
        return Icons.chat_bubble_outline;
      default:
        return Icons.folder_open;
    }
  }
  
  Color _getAlbumColor() {
     if (album.colorCode != null) {
       try {
         return Color(int.parse(album.colorCode.replaceFirst('#', '0xFF')));
       } catch (e) {
         return AppColors.primary;
       }
     }
     return AppColors.primary;
  }

  Widget _buildCoverImage(BuildContext context) {
    if (coverPhoto == null) return _buildGradientBackground();

    if (kIsWeb) {
       // Web: Try to get from cache
       // Note: This requires access to PhotoProvider. 
       // Since this is inside consumer, we might need to pass bytes or provider.
       // However, StatelessWidget context gives access.
       final provider = Provider.of<PhotoProvider>(context, listen: false);
       final bytes = provider.getWebImageBytes(coverPhoto!.id);
       if (bytes != null) {
         return Image.memory(
           bytes,
           fit: BoxFit.cover,
           errorBuilder: (context, error, stackTrace) => _buildGradientBackground(),
         );
       }
       // Fallback for Web if not in memory (maybe just use gradient for safety or try network if url existed)
       return _buildGradientBackground();
    } else {
       // Mobile: Use File
       if (coverPhoto!.localPath.isEmpty) return _buildGradientBackground();
       return Image.file(
         File(coverPhoto!.localPath),
         fit: BoxFit.cover,
         errorBuilder: (context, error, stackTrace) => _buildGradientBackground(),
       );
    }
  }

  void _showAlbumOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Name'),
              onTap: () {
                Navigator.pop(context);
                _showRenameAlbumDialog(context);
              },
            ),
            ListTile(
              leading: Icon(album.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(album.isPinned ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.pop(context);
                final albumProvider = Provider.of<AlbumProvider>(context, listen: false);
                albumProvider.toggleAlbumPin(album.id);
              },
            ),
            if (!album.isDefault)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRenameAlbumDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: album.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Album'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Name',
            hintText: 'Enter album name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != album.name) {
                final albumProvider = Provider.of<AlbumProvider>(context, listen: false);
                final success = await albumProvider.renameAlbum(album.id, newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(albumProvider.errorMessage ?? 'Rename failed')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Album'),
        content: Text('Are you sure you want to delete "${album.name}"?\nAll photos in this album will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final albumProvider = Provider.of<AlbumProvider>(context, listen: false);
              albumProvider.deleteAlbum(album.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}


class _AddCategoryCard extends StatelessWidget {
    @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => _showAddCategoryDialog(context),
        child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5, style: BorderStyle.solid),
            ),
            child: const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.add_circle_outline, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Add New', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ]
                )
            ),
        ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Travel, Project',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'This name will be used as a keyword for AI classification.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final albumProvider = Provider.of<AlbumProvider>(context, listen: false);
                
                if (authProvider.currentUser == null) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Login required')),
                   );
                   return;
                }

                // Create new album
                final success = await albumProvider.createAlbum(
                  userId: authProvider.currentUser!.uid,
                  name: name,
                  iconPath: '📁',
                  colorCode: '#607D8B', // Blue Grey
                  description: 'Custom Category',
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category added')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(albumProvider.errorMessage ?? 'Failed to add')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
