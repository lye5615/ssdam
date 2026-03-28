import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/photo_model.dart';
import '../../data/models/reminder_model.dart';
import '../providers/photo_provider.dart';
import '../../core/di/service_locator.dart';
import '../providers/album_provider.dart';
import '../../data/models/album_model.dart';
import '../../data/services/notification_service.dart';

class PhotoDetailScreen extends StatefulWidget {
  final List<PhotoModel> allPhotos;
  final int initialIndex;

  const PhotoDetailScreen({
    super.key, 
    required this.allPhotos, 
    required this.initialIndex,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  bool _showControls = true;
  late PhotoModel _currentPhoto;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentPhoto = widget.allPhotos[widget.initialIndex];
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for navigation
          GestureDetector(
            onTap: _toggleControls,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.allPhotos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPhoto = widget.allPhotos[index];
                });
              },
              itemBuilder: (context, index) {
                final photo = widget.allPhotos[index];
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Hero(
                      tag: 'photo_${photo.id}',
                      child: _buildPhotoItem(photo),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top Bar (AppBar equivalent)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -80,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 10,
                left: 10,
                right: 10,
              ),
              color: Colors.black45,
              child: Row(
                children: [
                   IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _currentPhoto.category, 
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar (Actions)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 10,
                top: 10,
                left: 20,
                right: 20,
              ),
              color: Colors.black45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Delete
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: _deletePhoto,
                    tooltip: '삭제',
                  ),
                  // Move
                   IconButton(
                    icon: const Icon(Icons.drive_file_move_outline, color: Colors.white),
                    onPressed: _showMoveDialog,
                    tooltip: '이동',
                  ),
                  // Share
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: _sharePhoto,
                    tooltip: '공유',
                  ),
                  // Favorite
                  Consumer<PhotoProvider>(
                    builder: (context, provider, child) {
                      final isFav = provider.getPhoto(_currentPhoto.id)?.isFavorite ?? _currentPhoto.isFavorite;
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                        ),
                        onPressed: _toggleFavorite,
                        tooltip: '즐겨찾기',
                      );
                    },
                  ),
                  // Reminder
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: _showReminderSetup,
                    tooltip: '알림 설정',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('앱에서 이 사진을 삭제하시겠습니까?\n(갤러리 원본은 유지됩니다)'),
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
      final success = await Provider.of<PhotoProvider>(context, listen: false)
          .deletePhoto(_currentPhoto.id);
      
      if (mounted) {
        if (success) {
          Navigator.pop(context); // Close detail screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제 실패')),
          );
        }
      }
    }
  }

  void _sharePhoto() {
    Share.shareXFiles([XFile(_currentPhoto.localPath)], text: '공유할 사진');
  }

  void _toggleFavorite() {
    Provider.of<PhotoProvider>(context, listen: false)
        .togglePhotoFavorite(_currentPhoto.id);
    // UI update handled by Consumer
  }

  void _showReminderSetup() {
    DateTime selectedDate = DateTime.now().add(const Duration(minutes: 5));
    final memoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // For keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 500,
          child: Column(
            children: [
              const Text(
               '알림 & 메모',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Date & Time Selectors
              // Date & Time Selectors (Hybrid)
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setInnerState) {
                    return Column(
                      children: [
                        // Date Selection (Calendar)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                          title: Text('날짜', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text(
                            "${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일",
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          ),
                          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData(
                                    brightness: Theme.of(context).brightness,
                                    colorScheme: Theme.of(context).colorScheme,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setInnerState(() {
                                selectedDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  selectedDate.hour,
                                  selectedDate.minute,
                                );
                              });
                            }
                          },
                        ),
                        // Time Selection (Dial)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                          title: Text('시간', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text(
                            "${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          ),
                          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              builder: (context) => SizedBox(
                                height: 250,
                                child: CupertinoTheme(
                                  data: CupertinoThemeData(
                                    brightness: Theme.of(context).brightness,
                                    textTheme: CupertinoTextThemeData(
                                       dateTimePickerTextStyle: TextStyle(
                                         color: Theme.of(context).colorScheme.onSurface, 
                                         fontSize: 20
                                       ),
                                    ),
                                  ),
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.time,
                                    initialDateTime: selectedDate,
                                    use24hFormat: true,
                                    onDateTimeChanged: (val) {
                                       setInnerState(() {
                                         selectedDate = DateTime(
                                           selectedDate.year,
                                           selectedDate.month,
                                           selectedDate.day,
                                           val.hour,
                                           val.minute,
                                         );
                                       });
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }
                ),
              ),
              const SizedBox(height: 10),
              // Memo Field
              TextField(
                controller: memoController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: '메모 (선택)',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final reminder = ReminderModel(
                        id: '',
                        photoId: _currentPhoto.id,
                        userId: _currentPhoto.userId,
                        title: '스크린샷 알림',
                        description: memoController.text.isNotEmpty 
                            ? memoController.text 
                            : '사진: ${_currentPhoto.fileName}',
                        reminderDate: selectedDate,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        metadata: {'photoFileName': _currentPhoto.fileName},
                        type: ReminderType.general,
                      );
                      
                      final reminderId = await ServiceLocator.firestoreService.createReminder(reminder);
                      
                      // 실제 기기 알림 예약
                      await NotificationService().scheduleNotification(
                        id: reminderId.hashCode,
                        title: '김치찜 알림',
                        body: reminder.description ?? '스크린샷 관련 알림입니다.',
                        scheduledDate: selectedDate,
                        payload: _currentPhoto.id,
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              '알림이 등록되었습니다',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.black.withOpacity(0.7),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('오류: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('저장', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer2<AlbumProvider, PhotoProvider>(
        builder: (context, albumProvider, photoProvider, child) {
          // Filter out current category
          final albums = albumProvider.albums.where((a) => a.name != _currentPhoto.category).toList();
          
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
                      // Calculate real-time photo count
                      final photoCount = photoProvider.photos
                          .where((photo) => photo.category == album.name)
                          .length;
                      
                      return ListTile(
                        leading: _buildAlbumIcon(album),
                        title: Text(album.name),
                        subtitle: Text('$photoCount장'),
                        onTap: () => _movePhoto(context, album),
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

  Future<void> _movePhoto(BuildContext context, AlbumModel targetAlbum) async {
    Navigator.pop(context); // Close sheet
    
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final success = await photoProvider.movePhotoToAlbum(_currentPhoto.id, targetAlbum.id, newCategoryName: targetAlbum.name);

    if (mounted) {
      if (success) {
          setState(() {
              _currentPhoto = _currentPhoto.copyWith(
                  category: targetAlbum.name, 
                  albumId: targetAlbum.id
              );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('사진을 "${targetAlbum.name}"(으)로 이동했습니다.')),
          );
      } else {
           final errorMsg = photoProvider.errorMessage ?? '이동 실패';
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(errorMsg)),
           );
      }
    }
  }
  Widget _buildPhotoItem(PhotoModel photo) {
    return Consumer<PhotoProvider>(
      builder: (context, photoProvider, child) {
        if (photo.assetEntityId != null && photo.assetEntityId!.isNotEmpty) {
          return FutureBuilder<AssetEntity?>(
            future: photoProvider.findAssetById(photo.assetEntityId!),
            builder: (context, assetSnapshot) {
              if (assetSnapshot.connectionState == ConnectionState.done &&
                  assetSnapshot.data != null) {
                return FutureBuilder<Uint8List?>(
                  future: assetSnapshot.data!.originBytes,
                  builder: (context, imageSnapshot) {
                    if (imageSnapshot.connectionState == ConnectionState.done &&
                        imageSnapshot.data != null) {
                      return Image.memory(
                        imageSnapshot.data!,
                        fit: BoxFit.contain,
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                );
              }
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
          );
        } else {
          return Image.file(
            File(photo.localPath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image, color: Colors.white, size: 64);
            },
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
