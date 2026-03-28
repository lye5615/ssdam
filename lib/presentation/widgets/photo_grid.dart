import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/photo_model.dart';
import '../providers/photo_provider.dart';

class PhotoGrid extends StatelessWidget {
  final List<PhotoModel> photos;
  final void Function(List<PhotoModel> photos, int index)? onPhotoTap;
  final void Function(PhotoModel)? onPhotoLongPress;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.onPhotoTap,
    this.onPhotoLongPress,
    this.isSelectionMode = false,
    this.selectedPhotoIds = const {},
  });

  final bool isSelectionMode;
  final Set<String> selectedPhotoIds;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
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
              '사진이 없습니다',
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.gridCrossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: AppConstants.gridAspectRatio,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return _PhotoTile(
          photo: photo,
          onTap: () => onPhotoTap?.call(photos, index),
          onLongPress: () => onPhotoLongPress?.call(photo),
          isSelected: selectedPhotoIds.contains(photo.id),
          isSelectionMode: isSelectionMode,
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final PhotoModel photo;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _PhotoTile({
    required this.photo,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  final bool isSelected;
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 이미지 표시
          GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: _buildImage(),
          ),
          
          // Selection Overlay
          if (isSelectionMode)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.black38,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                ),
              ),
            ),
          
          // Selection Overlay
          if (isSelectionMode)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.black38,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                ),
              ),
            ),
          
          if (!isSelectionMode)
          // 즐겨찾기 아이콘
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                photo.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          
          // 카테고리 배지 및 OCR 아이콘 제거됨 (사용자 요청)
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      // 웹에서는 Provider를 통해 이미지 바이트 데이터 가져오기
      return Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          final imageBytes = photoProvider.getWebImageBytes(photo.id);
          if (imageBytes != null) {
            return Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildWebPlaceholder();
              },
            );
          } else {
            // 바이트 데이터가 없으면 카테고리 아이콘과 함께 플레이스홀더 표시
            return _buildWebPlaceholder();
          }
        },
      );
    } else {
      // 모바일: assetEntityId가 있으면 갤러리에서 로드, 없으면 localPath 사용
      if (photo.assetEntityId != null && photo.assetEntityId!.isNotEmpty) {
        return Consumer<PhotoProvider>(
          builder: (context, photoProvider, child) {
            return FutureBuilder<AssetEntity?>(
              future: photoProvider.findAssetById(photo.assetEntityId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  final asset = snapshot.data;
                  if (asset != null) {
                    return FutureBuilder<Uint8List?>(
                      future: asset.thumbnailDataWithSize(
                        const ThumbnailSize(400, 400),
                      ),
                      builder: (context, thumbSnapshot) {
                        if (thumbSnapshot.connectionState == ConnectionState.done && 
                            thumbSnapshot.data != null) {
                          return Image.memory(
                            thumbSnapshot.data!,
                            fit: BoxFit.cover,
                          );
                        }
                        return _placeholder();
                      },
                    );
                  }
                }
                // 로딩 중이거나 asset을 찾지 못한 경우
                return _placeholder();
              },
            );
          },
        );
      } else {
        // assetEntityId가 없는 경우 localPath 사용 (fallback)
        return Image.file(
          File(photo.localPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _placeholder();
          },
        );
      }
    }
  }

  Widget _buildWebPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black12,
            Colors.black26,
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getCategoryIcon(photo.category),
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              photo.category,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              photo.fileName,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '웹에서 업로드됨',
              style: TextStyle(
                fontSize: 8,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
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

  String _getCategoryIcon(String category) {
    switch (category) {
      case '정보/참고용':
        return '📄';
      case '대화/메시지':
        return '💬';
      case '학습/업무 메모':
        return '📝';
      case '재미/밈/감정':
        return '😄';
      case '일정/예약':
        return '📅';
      case '증빙/거래':
        return '💳';
      case '옷':
        return '👕';
      case '제품':
        return '📦';
      default:
        return '📷';
    }
  }
}
